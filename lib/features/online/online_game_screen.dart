import 'dart:async';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/online_repository.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/game/time_control.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/move_strip.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/tokens.dart';

/// A live game with a friend. The board is the same as everywhere; moves
/// are checked here with the chess rules, sent to the server, and the
/// friend's arrive over the socket. The server keeps both clocks.
class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key, required this.gameId, this.repository});

  final int gameId;
  final OnlineRepository? repository;

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  OnlineRepository get _repo => widget.repository ?? OnlineRepository.instance;

  OnlineGame? _game;

  /// Moves shown: the server's, plus mine while it is on its way.
  List<String> _moves = const [];
  Position _position = Chess.initial;
  List<String> _san = const [];
  NormalMove? _last;
  Player? _opponent;
  bool _sending = false;
  bool _flagged = false;
  bool _saved = false;
  Timer? _tick;
  StreamSubscription<OnlineGame>? _sub;

  String get _me => _repo.me ?? '';
  bool get _iAmWhite => _game?.white == _me;
  bool get _myTurn {
    final g = _game;
    if (g == null || !g.active || _sending) return false;
    return (_moves.length.isEven) == _iAmWhite;
  }

  @override
  void initState() {
    super.initState();
    _sub = _repo.changes.listen((g) {
      if (g.id == widget.gameId) _show(g);
    });
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) => _onTick());
    _load();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _show(await _repo.game(widget.gameId));
    } on ApiException {
      // Shown as loading until the socket brings it.
    }
  }

  void _show(OnlineGame g) {
    final before = _game;
    _replay(g.moves);
    setState(() {
      _game = g;
      _sending = false;
    });
    if (_opponent == null) _loadOpponent(g.opponentOf(_me));
    // Their move arrived: the sound of it.
    if (before != null && g.moves.length > before.moves.length) {
      final lastMine = (g.moves.length.isOdd) == _iAmWhite;
      if (!lastMine) _playSound(isUser: false);
    }
    if (g.over && before != null && !before.over) {
      HapticFeedback.heavyImpact();
      _save(g);
    }
  }

  Future<void> _loadOpponent(String username) async {
    try {
      final got = await PlayersRepository.instance.player(username);
      if (mounted) setState(() => _opponent = got.player);
    } on ApiException {
      // The bar shows the username alone.
    }
  }

  /// The position and the move list from the start, move by move.
  void _replay(List<String> moves) {
    Position pos = Chess.initial;
    final san = <String>[];
    NormalMove? last;
    for (final uci in moves) {
      final parsed = Move.parse(uci);
      if (parsed is! NormalMove) break;
      final move = pos.normalizeMove(parsed);
      if (!pos.isLegal(move)) break;
      final (next, s) = pos.makeSan(move);
      san.add(s);
      pos = next;
      last = parsed;
    }
    _moves = moves;
    _position = pos;
    _san = san;
    _last = last;
  }

  void _onTick() {
    final g = _game;
    if (g == null || !g.active || !mounted) return;
    setState(() {}); // the running clock
    final clocks = g.clocksNow();
    final left = g.whiteToMove ? clocks.white : clocks.black;
    if (left == Duration.zero && !_flagged) {
      _flagged = true;
      unawaited(_repo.flag(g.id).then(_show, onError: (_) => _flagged = false));
    }
  }

  void _playSound({required bool isUser}) {
    final pos = _position;
    SoundService.instance.playSfx(
      pos.isCheck ? 'check.wav' : (isUser ? 'move.wav' : 'move-opponent.wav'),
    );
    SoundService.instance.buzz(heavy: pos.isCheck);
  }

  Future<void> _onMove(NormalMove move) async {
    final g = _game;
    if (g == null || !_myTurn) return;
    final normal = _position.normalizeMove(move);
    if (!_position.isLegal(normal)) {
      _say(context.t.onlineNotLegal);
      return;
    }
    final next = _position.play(normal);
    final end = next.isCheckmate
        ? 'checkmate'
        : next.isStalemate
        ? 'stalemate'
        : next.isInsufficientMaterial
        ? 'draw'
        : null;
    final ply = _moves.length;
    setState(() {
      _replay([..._moves, move.uci]);
      _sending = true;
    });
    _playSound(isUser: true);
    try {
      _show(await _repo.move(g.id, ply, move.uci, end: end));
    } on ApiException {
      // Out of step (or offline): the server's game is the truth.
      await _load();
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Once over, the game joins my history like any other, which also
  /// sends it to my profile.
  Future<void> _save(OnlineGame g) async {
    if (_saved || g.moves.isEmpty) return;
    _saved = true;
    final mine = _iAmWhite ? 'white' : 'black';
    await GameHistoryStore.instance.add(
      GameRecord(
        id: 'online-${g.id}',
        playedAt: DateTime.now().millisecondsSinceEpoch,
        isLocal: false,
        result: g.result == 'draw'
            ? GameRecord.draw
            : g.result == mine
            ? GameRecord.win
            : GameRecord.loss,
        reason: g.reason ?? '',
        playerIsWhite: _iAmWhite,
        uciMoves: [for (final uci in g.moves) uci],
        sanMoves: _san,
        botId: 'online',
        botName: g.opponentOf(_me),
        botElo: _opponent?.rating,
        timeControl: TimeControl(
          baseMinutes: g.baseMs ~/ 60000,
          incrementSeconds: g.incMs ~/ 1000,
        ).label,
      ),
    );
  }

  /// Cancelling my challenge: say so, and leave the screen.
  Future<void> _cancel() async {
    final g = _game;
    if (g == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final text = context.t.onlineCancelled;
    try {
      await _repo.decline(g.id);
    } on ApiException {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go('/play');
  }

  void _confirmResign() {
    final g = _game;
    if (g == null) return;
    final t = context.t;
    showKustSheet<void>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KustSheetHeader(title: t.resignTitle, subtitle: t.resignSubtitle),
          KustButton(
            label: t.resign,
            style: KustButtonStyle.danger,
            onTap: () {
              Navigator.of(sheet).pop();
              _repo.resign(g.id).then(_show, onError: (_) {});
            },
          ),
          const SizedBox(height: 8),
          KustButton(
            label: t.keep,
            style: KustButtonStyle.outline,
            onTap: () => Navigator.of(sheet).pop(),
          ),
        ],
      ),
    );
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final g = _game;
    final opponent = g?.opponentOf(_me) ?? '';
    return Scaffold(
      backgroundColor: k.bg,
      body: SafeArea(
        child: Column(
          children: [
            KustTopBar(
              // Just the friend's name: "Game with …" was cut short.
              title: g == null ? '' : opponent,
              subtitle: g == null
                  ? null
                  : TimeControl(
                      baseMinutes: g.baseMs ~/ 60000,
                      incrementSeconds: g.incMs ~/ 1000,
                    ).labelIn(t),
              leading: KustIconButton(
                icon: Icons.arrow_back_rounded,
                label: t.back,
                onTap: () =>
                    context.canPop() ? context.pop() : context.go('/play'),
              ),
            ),
            if (g == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else ...[
              MoveStrip(
                labels: [
                  for (var i = 0; i < _san.length; i++) moveLabel(i, _san[i]),
                ],
                selected: _san.length,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = (box.maxHeight - 2 * 56 - 16).clamp(
                      0.0,
                      box.maxWidth,
                    );
                    return Center(
                      child: SizedBox(
                        width: side,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _bar(context, g, white: !_iAmWhite),
                            SizedBox(
                              width: side,
                              height: side,
                              child: PuzzleBoard(
                                position: _position,
                                flipped: !_iAmWhite,
                                interactive: _myTurn,
                                onMove: _onMove,
                                lastMove: _last,
                              ),
                            ),
                            _bar(context, g, white: _iAmWhite),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _footer(context, g),
            ],
          ],
        ),
      ),
    );
  }

  /// A player: photo, name and flag, and their clock (bright while it
  /// runs).
  Widget _bar(BuildContext context, OnlineGame g, {required bool white}) {
    final k = context.k;
    final username = white ? g.white : g.black;
    final isMe = username == _me;
    final p = isMe ? null : _opponent;
    final clocks = g.clocksNow();
    final left = white ? clocks.white : clocks.black;
    final running = g.active && g.whiteToMove == white;
    final low = left < const Duration(seconds: 20);
    return Container(
      height: 56,
      // A little room at the sides for the photo and the clock.
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          PlayerAvatar(
            size: 36,
            name: p?.displayName ?? username,
            // Mine: the photo on this phone, else my account's.
            photo: isMe
                ? (AppStorage.isReady && AppStorage.instance.photoPath != null
                      ? FileImage(io.File(AppStorage.instance.photoPath!))
                      : avatarImage(
                          avatarUrlFor(
                            AuthService.instance.state.value.account?.avatarKey,
                          ),
                        ))
                : avatarImage(avatarUrlFor(p?.avatarKey)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (p?.country != null) ...[
                  const SizedBox(width: 6),
                  CountryFlag(p!.country!, height: 14),
                ],
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: running
                  ? (low ? k.danger : const Color(0xFFF2EFE8))
                  : k.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              TimeControl.format(TimeControl.display(left)),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: running
                    ? (low ? Colors.white : const Color(0xFF17181A))
                    : k.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, OnlineGame g) {
    final k = context.k;
    final t = context.t;
    final opponent = g.opponentOf(_me);
    final Widget body;
    if (g.pending && g.challenger == _me) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.onlineWaiting(opponent),
            textAlign: TextAlign.center,
            style: k.body.copyWith(color: k.muted),
          ),
          const SizedBox(height: 10),
          KustButton(
            label: t.onlineCancel,
            style: KustButtonStyle.secondary,
            onTap: _cancel,
          ),
        ],
      );
    } else if (g.pending) {
      body = Row(
        children: [
          Expanded(
            child: KustButton(
              label: t.friendAccept,
              onTap: () => _repo.accept(g.id).then(_show, onError: (_) {}),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: KustButton(
              label: t.friendDecline,
              style: KustButtonStyle.secondary,
              onTap: () => _repo.decline(g.id).then(_show, onError: (_) {}),
            ),
          ),
        ],
      );
    } else if (g.active) {
      body = Row(
        children: [
          Expanded(
            child: Text(
              _myTurn ? t.onlineYourMove : t.onlineTheirMove(opponent),
              style: k.body.copyWith(
                fontWeight: FontWeight.w800,
                color: _myTurn ? k.success : k.muted,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _confirmResign,
            icon: Icon(Icons.flag_outlined, color: k.danger),
            label: Text(t.resign, style: TextStyle(color: k.danger)),
          ),
        ],
      );
    } else {
      final mine = _iAmWhite ? 'white' : 'black';
      final title = switch (g.status) {
        'declined' => t.onlineDeclined(opponent),
        'cancelled' => t.onlineCancelled,
        _ =>
          g.result == 'draw'
              ? t.onlineDraw
              : g.result == mine
              ? t.youWonTitle
              : t.youLostTitle,
      };
      final reason = switch (g.reason) {
        'checkmate' => t.byCheckmate,
        'resign' => t.byResignation,
        'timeout' => t.byTimeout,
        'stalemate' => t.byStalemate,
        'draw' => t.byInsufficient,
        _ => '',
      };
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: k.title.copyWith(fontWeight: FontWeight.w800),
          ),
          if (reason.isNotEmpty)
            Text(
              reason,
              textAlign: TextAlign.center,
              style: k.body.copyWith(color: k.muted),
            ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: body,
    );
  }
}
