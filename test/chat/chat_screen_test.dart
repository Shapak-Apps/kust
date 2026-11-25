import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/chat_repository.dart';
import 'package:kust/core/net/live_socket.dart';
import 'package:kust/core/net/token_storage.dart';
import 'package:kust/features/chat/chat_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';

import '../core/net/fake_adapter.dart';

Map<String, dynamic> _msg(int id, String from, String to, String body) => {
  'id': id,
  'from': from,
  'to': to,
  'body': body,
  'reply_to': null,
  'created_at': DateTime.now().toUtc().toIso8601String(),
  'read': false,
  'reactions': <String, String>{},
};

void main() {
  late FakeAdapter adapter;
  late ChatRepository repo;

  setUp(() async {
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
      if (key == 'GET /v1/chats/ann/messages') {
        return jsonBody({
          'messages': [
            _msg(2, 'ann', 'me', 'Oýun oýnaýarysmy?'),
            _msg(1, 'me', 'ann', 'Salam!'),
          ],
          'more': false,
        });
      }
      if (key == 'POST /v1/chats/ann/messages') {
        return jsonBody({
          'message': _msg(3, 'me', 'ann', (o.data as Map)['body'] as String),
        }, status: 201);
      }
      if (o.method == 'PATCH' && o.path == '/v1/messages/1') {
        return jsonBody({
          'message': {
            ..._msg(1, 'me', 'ann', (o.data as Map)['body'] as String),
            'edited': true,
          },
        });
      }
      return jsonBody({'read': 1});
    });
    adapter = t.adapter;
    final auth = AuthService(
      api: t.api,
      storage: MemoryTokenStorage(),
      cache: MemoryAccountCache(),
    );
    await auth.login(identifier: 'me', password: 'Password123');
    repo = ChatRepository(
      auth: auth,
      socket: LiveSocket(
        url: Uri.parse('ws://localhost'),
        tokenProvider: () async => null,
      ),
    );
  });

  Widget app() => MaterialApp(
    theme: appTheme,
    supportedLocales: kSupportedLocales,
    localizationsDelegates: kLocalizationDelegates,
    home: ChatScreen(
      username: 'ann',
      repository: repo,
      player: const Player(
        id: 'ann',
        username: 'ann',
        displayName: 'Ann',
        bio: '',
        country: 'TM',
        rating: 1500,
      ),
    ),
  );

  testWidgets('shows the chat, sends at once, swipes to reply', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.textContaining('Salam!'), findsOneWidget);
    expect(find.textContaining('Oýun oýnaýarysmy?'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    // Opening the chat marks Ann's message read.
    expect(adapter.requests.any((r) => r.path == '/v1/chats/ann/read'), isTrue);

    // Swipe her message right: the reply preview shows.
    await tester.drag(
      find.textContaining('Oýun oýnaýarysmy?'),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Replying to Ann'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hawa, gel!');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(find.textContaining('Hawa, gel!'), findsOneWidget);
    expect(find.text('Replying to Ann'), findsNothing);
    await tester.pumpAndSettle();
    final sent = adapter.requests.lastWhere(
      (r) => r.method == 'POST' && r.path == '/v1/chats/ann/messages',
    );
    expect((sent.data as Map)['reply_to'], 2);
    expect(find.textContaining('Hawa, gel!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('holding a message offers reactions', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('Salam!'));
    await tester.pumpAndSettle();
    for (final e in kQuickReactions) {
      expect(find.text(e), findsOneWidget);
    }
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('my message can be edited; theirs cannot', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('Oýun'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('Salam!'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Editing'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Salam, dost!');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();
    expect(find.textContaining('Salam, dost!'), findsOneWidget);
    expect(find.textContaining('edited'), findsOneWidget);
    expect(
      adapter.requests.any(
        (r) => r.method == 'PATCH' && r.path == '/v1/messages/1',
      ),
      isTrue,
    );
  });

  testWidgets('the hold menu stays on a small screen', (tester) async {
    tester.view.physicalSize = const Size(720, 1280); // 360 x 640
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    // The newest message sits at the very bottom, over the input.
    await tester.longPress(find.textContaining('Oýun'));
    await tester.pumpAndSettle();
    final screen = Offset.zero & const Size(360, 640);
    for (final f in [
      ...kQuickReactions.map(find.text),
      find.text('Reply'),
      find.text('Copy'),
      find.text('Delete'),
    ]) {
      final r = tester.getRect(f.last);
      expect(
        screen.contains(r.topLeft) && screen.contains(r.bottomRight),
        isTrue,
        reason: '$f at $r',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('holding a message keeps the keyboard open', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
    await tester.longPress(find.textContaining('Salam!'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsOneWidget);
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets('the held message stays put; the card opens beside it', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final before = tester.getRect(find.textContaining('Salam!'));
    await tester.longPress(find.textContaining('Salam!'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.textContaining('Salam!').last), before);
    // Mine is on the right: the card opens on its left.
    expect(tester.getRect(find.text('Reply')).right, lessThan(before.left));
    // Telegram's order: reactions on top, right above the card.
    final bar = tester.getRect(find.text('❤️'));
    final header = tester.getRect(find.textContaining('Sent'));
    expect(bar.bottom, lessThan(header.top));
    expect(header.top - bar.bottom, lessThan(40));
  });
}
