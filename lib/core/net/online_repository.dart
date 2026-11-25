import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/live_socket.dart';

/// A live game with a friend, as the server keeps it: who is White and
/// Black, the moves so far (UCI), both clocks and how it stands.
@immutable
class OnlineGame {
  const OnlineGame({
    required this.id,
    required this.white,
    required this.black,
    required this.challenger,
    required this.baseMs,
    required this.incMs,
    required this.status,
    required this.moves,
    required this.whiteMs,
    required this.blackMs,
    required this.turnStartedAt,
    required this.result,
    required this.reason,
    required this.clockOffset,
  });

  final int id;
  final String white;
  final String black;
  final String challenger;
  final int baseMs;
  final int incMs;

  /// pending, active, finished, declined or cancelled.
  final String status;
  final List<String> moves;
  final int whiteMs;
  final int blackMs;
  final DateTime? turnStartedAt;

  /// white, black or draw, once finished.
  final String? result;

  /// checkmate, resign, timeout, stalemate or draw.
  final String? reason;

  /// Server time minus this phone's time, to run the clocks in step.
  final Duration clockOffset;

  bool get pending => status == 'pending';
  bool get active => status == 'active';
  bool get over => !pending && !active;
  bool get whiteToMove => moves.length.isEven;

  String opponentOf(String me) => me == white ? black : white;

  /// Time left now for each side, the running clock counted down.
  ({Duration white, Duration black}) clocksNow() {
    var w = whiteMs;
    var b = blackMs;
    final started = turnStartedAt;
    if (active && started != null) {
      final now = DateTime.now().add(clockOffset);
      final spent = now.difference(started).inMilliseconds;
      if (whiteToMove) {
        w -= spent;
      } else {
        b -= spent;
      }
    }
    return (
      white: Duration(milliseconds: w < 0 ? 0 : w),
      black: Duration(milliseconds: b < 0 ? 0 : b),
    );
  }

  factory OnlineGame.fromJson(Map<String, dynamic> json) {
    final serverNow = DateTime.tryParse(json['server_now'] as String? ?? '');
    return OnlineGame(
      id: (json['id'] as num).toInt(),
      white: json['white'] as String,
      black: json['black'] as String,
      challenger: json['challenger'] as String,
      baseMs: (json['base_ms'] as num).toInt(),
      incMs: (json['inc_ms'] as num).toInt(),
      status: json['status'] as String,
      moves: [
        for (final m in (json['moves'] as List? ?? const [])) m as String,
      ],
      whiteMs: (json['white_ms'] as num).toInt(),
      blackMs: (json['black_ms'] as num).toInt(),
      turnStartedAt: DateTime.tryParse(
        json['turn_started_at'] as String? ?? '',
      ),
      result: json['result'] as String?,
      reason: json['reason'] as String?,
      clockOffset: serverNow == null
          ? Duration.zero
          : serverNow.difference(DateTime.now()),
    );
  }
}

/// Live games with friends: challenges, moves, resigning, the open ones
/// for the bell. Every change arrives on [changes] from the socket.
class OnlineRepository {
  OnlineRepository({required this.auth, LiveSocket? socket})
    : _socket = socket ?? LiveSocket.instance {
    _socket.events.listen(_onEvent);
  }

  static OnlineRepository? _instance;
  static OnlineRepository get instance =>
      _instance ??= OnlineRepository(auth: AuthService.instance);

  final AuthService auth;
  final LiveSocket _socket;

  /// My pending and active games: challenges to answer show in the bell.
  final ValueNotifier<List<OnlineGame>> open = ValueNotifier(const []);

  final StreamController<OnlineGame> _changes = StreamController.broadcast();
  Stream<OnlineGame> get changes => _changes.stream;

  String? get me => auth.state.value.account?.username;

  /// Challenges sent to me, waiting for my answer.
  List<OnlineGame> get invites => [
    for (final g in open.value)
      if (g.pending && g.challenger != me) g,
  ];

  void _onEvent(LiveEvent e) {
    if (e.type == 'hello') {
      unawaited(refresh());
      return;
    }
    if (e.type != 'online_game') return;
    final g = OnlineGame.fromJson(e.data);
    _changes.add(g);
    _keep(g);
  }

  void _keep(OnlineGame g) {
    open.value = [
      if (!g.over) g,
      for (final x in open.value)
        if (x.id != g.id) x,
    ];
  }

  OnlineGame _game(Map<String, dynamic> json) {
    final g = OnlineGame.fromJson(json['game'] as Map<String, dynamic>);
    _keep(g);
    return g;
  }

  Future<void> refresh() async {
    if (!auth.state.value.isVerified) {
      open.value = const [];
      return;
    }
    try {
      final json = await auth.authed(
        (token) => auth.api.get('/v1/online/games', token: token),
      );
      open.value = [
        for (final g in (json['games'] as List? ?? const []))
          OnlineGame.fromJson(g as Map<String, dynamic>),
      ];
    } on ApiException {
      // Kept as it was.
    }
  }

  /// Challenges [username]; [side] is mine: white, black or random.
  Future<OnlineGame> challenge(
    String username, {
    required int baseMinutes,
    required int incrementSeconds,
    required String side,
  }) async => _game(
    await auth.authed(
      (token) => auth.api.post(
        '/v1/online/challenges',
        body: {
          'username': username,
          'base_minutes': baseMinutes,
          'increment_seconds': incrementSeconds,
          'side': side,
        },
        token: token,
      ),
    ),
  );

  Future<OnlineGame> game(int id) async => _game(
    await auth.authed(
      (token) => auth.api.get('/v1/online/games/$id', token: token),
    ),
  );

  Future<OnlineGame> _action(int id, String what, [Object? body]) async =>
      _game(
        await auth.authed(
          (token) => auth.api.post(
            '/v1/online/games/$id/$what',
            body: body,
            token: token,
          ),
        ),
      );

  Future<OnlineGame> accept(int id) => _action(id, 'accept');
  Future<OnlineGame> decline(int id) => _action(id, 'decline');
  Future<OnlineGame> resign(int id) => _action(id, 'resign');
  Future<OnlineGame> flag(int id) => _action(id, 'flag');

  /// Plays [uci] as move [ply]; [end] says how it ends the game, if it
  /// does: checkmate, stalemate or draw.
  Future<OnlineGame> move(int id, int ply, String uci, {String? end}) =>
      _action(id, 'move', {'ply': ply, 'uci': uci, 'end': ?end});
}
