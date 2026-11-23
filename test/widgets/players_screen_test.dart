import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/live_socket.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/net/presence.dart';
import 'package:kust/core/net/token_storage.dart';
import 'package:kust/features/players/players_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';

import '../core/net/fake_adapter.dart';

Map<String, dynamic> _player(
  String name, {
  String? country,
  int rating = 1200,
}) => {
  'id': 'id-$name',
  'username': name,
  'display_name': name[0].toUpperCase() + name.substring(1),
  'bio': '',
  'country': country,
  'avatar_key': null,
  'rating': rating,
};

Map<String, dynamic> _session() => {
  'user': {
    'id': 'me',
    'email': 'me@example.com',
    'username': 'me_one',
    'display_name': 'me_one',
    'bio': '',
    'country': null,
    'rating': 1200,
    'email_verified': true,
  },
  'access_token': 'access',
  'refresh_token': 'refresh',
  'expires_in': 900,
};

class _Rig {
  _Rig(FakeHandler playersHandler) {
    final t = testApi((o) {
      if (o.path == '/v1/players') return playersHandler(o);
      return jsonBody(_session());
    });
    adapter = t.adapter;
    auth = AuthService(
      api: t.api,
      storage: MemoryTokenStorage(),
      cache: MemoryAccountCache(),
    );
    cache = MemoryPlayersCache();
    repo = PlayersRepository(auth: auth, cache: cache);
    socket = LiveSocket(
      url: Uri.parse('ws://127.0.0.1:1'),
      tokenProvider: () async => null,
    );
    presence = PresenceService(socket);
  }

  late final FakeAdapter adapter;
  late final AuthService auth;
  late final MemoryPlayersCache cache;
  late final PlayersRepository repo;
  late final LiveSocket socket;
  late final PresenceService presence;

  static Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.runAsync(
      () => auth.login(identifier: 'me_one', password: 'password123'),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationDelegates,
        home: PlayersScreen(repository: repo, presence: presence),
      ),
    );
    await settle(tester);
  }

  void dispose() {
    presence.dispose();
    socket.dispose();
  }
}

void main() {
  testWidgets('lists the players the server returns', (tester) async {
    final rig = _Rig(
      (o) => jsonBody({
        'players': [
          _player('alpha', country: 'TM', rating: 1500),
          _player('bravo'),
        ],
        'next_cursor': '',
      }),
    );
    await rig.pump(tester);

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('@alpha'), findsOneWidget);
    expect(find.text('1500'), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
    expect(rig.cache.read()?.players.length, 2);
    rig.dispose();
  });

  testWidgets('searching asks the server for the query', (tester) async {
    final rig = _Rig((o) {
      final q = o.queryParameters['q'];
      return jsonBody({
        'players': q == 'br'
            ? [_player('bravo')]
            : [_player('alpha'), _player('bravo')],
        'next_cursor': '',
      });
    });
    await rig.pump(tester);

    await tester.enterText(find.byType(TextField), 'Br');
    await tester.pump(const Duration(milliseconds: 400));
    await _Rig.settle(tester);

    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Bravo'), findsOneWidget);
    expect(rig.adapter.requests.last.queryParameters['q'], 'br');
    rig.dispose();
  });

  testWidgets('offline, it shows the saved list and says so', (tester) async {
    final rig = _Rig(networkDown);
    await rig.cache.write(
      [_player('alpha'), _player('bravo')].map(Player.fromJson).toList(),
      DateTime(2026),
    );
    await rig.pump(tester);

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Showing your saved list'), findsOneWidget);
    rig.dispose();
  });

  testWidgets('offline with nothing saved, it offers a retry', (tester) async {
    final rig = _Rig(networkDown);
    await rig.pump(tester);

    expect(
      find.text("No connection. Try again when you're online."),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    rig.dispose();
  });

  testWidgets('an empty result says no players found', (tester) async {
    final rig = _Rig((o) => jsonBody({'players': [], 'next_cursor': ''}));
    await rig.pump(tester);
    expect(find.text('No players found'), findsOneWidget);
    rig.dispose();
  });
}
