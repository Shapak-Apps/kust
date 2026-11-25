import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/live_socket.dart';
import 'package:kust/core/net/online_repository.dart';
import 'package:kust/core/net/token_storage.dart';
import 'package:kust/features/online/online_game_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';

import '../core/net/fake_adapter.dart';

Map<String, dynamic> _game({
  String status = 'active',
  String challenger = 'ann',
  List<String> moves = const [],
  String? result,
  String? reason,
}) => {
  'id': 7,
  'white': 'me',
  'black': 'ann',
  'challenger': challenger,
  'base_ms': 180000,
  'inc_ms': 2000,
  'status': status,
  'moves': moves,
  'white_ms': 180000,
  'black_ms': 180000,
  'turn_started_at': status == 'active'
      ? DateTime.now().toUtc().toIso8601String()
      : null,
  'result': result,
  'reason': reason,
  'server_now': DateTime.now().toUtc().toIso8601String(),
};

void main() {
  late FakeAdapter adapter;
  late OnlineRepository repo;
  late Map<String, dynamic> current;

  Future<void> setUpWith(Map<String, dynamic> game) async {
    current = game;
    final t = testApi((o) {
      final key = '${o.method} ${o.path}';
      if (key == 'POST /v1/auth/login') {
        return jsonBody({
          'user': {
            'id': 'me',
            'email': 'me@example.com',
            'username': 'me',
            'display_name': 'Me',
            'bio': '',
            'rating': 1200,
            'email_verified': true,
          },
          'access_token': 'a',
          'refresh_token': 'r',
          'expires_in': 900,
        });
      }
      if (key == 'POST /v1/online/games/7/accept') {
        current = _game(challenger: 'ann');
      }
      if (o.path.startsWith('/v1/online/games/7')) {
        return jsonBody({'game': current});
      }
      return jsonBody({
        'error': {'code': 'not_found'},
      }, status: 404);
    });
    adapter = t.adapter;
    final auth = AuthService(
      api: t.api,
      storage: MemoryTokenStorage(),
      cache: MemoryAccountCache(),
    );
    await auth.login(identifier: 'me', password: 'Password123');
    repo = OnlineRepository(
      auth: auth,
      socket: LiveSocket(
        url: Uri.parse('ws://localhost'),
        tokenProvider: () async => null,
      ),
    );
  }

  Widget app() => ProviderScope(
    child: MaterialApp(
      theme: appTheme,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: kLocalizationDelegates,
      home: OnlineGameScreen(gameId: 7, repository: repo),
    ),
  );

  test('only the clock of the side to move runs', () {
    final g = OnlineGame.fromJson({
      ..._game(),
      'turn_started_at': DateTime.now()
          .subtract(const Duration(seconds: 10))
          .toUtc()
          .toIso8601String(),
    });
    final c = g.clocksNow();
    expect(c.white.inSeconds, inInclusiveRange(169, 170));
    expect(c.black, const Duration(minutes: 3));
  });

  testWidgets('an invite can be accepted', (tester) async {
    await tester.runAsync(() => setUpWith(_game(status: 'pending')));
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    // The clock ticks while the game runs: pump, don't wait to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      adapter.requests.any((r) => r.path == '/v1/online/games/7/accept'),
      isTrue,
    );
    // The "you play as" card shows a moment, then goes.
    expect(find.text('Game start'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    // Playing: draw and resign by the moves, Back, Forward and Flip.
    expect(find.text('Draw'), findsOneWidget);
    expect(find.text('Resign'), findsOneWidget);
    expect(find.text('Flip board'), findsOneWidget);
    expect(find.text('3:00'), findsWidgets);
    await tester.tap(find.text('Draw'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Offer a draw?'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a finished game shows its result', (tester) async {
    await tester.runAsync(
      () => setUpWith(
        _game(
          status: 'finished',
          moves: ['f2f3', 'e7e5', 'g2g4', 'd8h4'],
          result: 'black',
          reason: 'checkmate',
        ),
      ),
    );
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('You lost'), findsOneWidget);
    expect(find.text('by checkmate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
