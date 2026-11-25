import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/error_log.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/chat_repository.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/l10n/app_locale.dart';

/// Phone notifications (Firebase Cloud Messaging) for a verified player:
/// friend requests and accepted ones, even with the app closed. The phone
/// tells the server its token; tapping a notification opens the screen it
/// is about. Without Firebase set up (no google-services.json) it does
/// nothing.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  /// Where tapped notifications navigate; set once the router exists.
  GoRouter? router;

  bool _firebase = false;
  bool _listening = false;
  String? _token;

  void start(GoRouter appRouter) {
    router = appRouter;
    AuthService.instance.state.addListener(_sync);
    _sync();
  }

  void _sync() {
    if (AuthService.instance.state.value.isVerified) unawaited(_register());
  }

  Future<bool> _ready() async {
    if (_firebase) return true;
    try {
      await Firebase.initializeApp();
      _firebase = true;
    } catch (e) {
      // Not set up on this build: no notifications, nothing else changes.
      return false;
    }
    return true;
  }

  Future<void> _register() async {
    if (!await _ready()) return;
    try {
      final messaging = FirebaseMessaging.instance;
      // Android 13 and newer ask the player once.
      await messaging.requestPermission();
      // The registration token, which the server's FCM v1 sends use. The
      // newer register()/onRegistered hands out an installation id for a
      // different send API instead; this one still works.
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await _send(token);
      if (!_listening) {
        _listening = true;
        // ignore: deprecated_member_use
        messaging.onTokenRefresh.listen((t) => unawaited(_send(t)));
        // In the app: no banner from the system, so the bell updates.
        FirebaseMessaging.onMessage.listen((m) {
          unawaited(PlayersRepository.instance.refreshIncoming());
          if (m.data['type'] == 'chat_message') {
            unawaited(ChatRepository.instance.refreshUnread());
          }
        });
        FirebaseMessaging.onMessageOpenedApp.listen(_open);
        final first = await messaging.getInitialMessage();
        if (first != null) _open(first);
      }
    } catch (e, st) {
      ErrorLog.record(e, st);
    }
  }

  Future<void> _send(String token) async {
    _token = token;
    final auth = AuthService.instance;
    if (!auth.state.value.isVerified) return;
    try {
      await auth.authed(
        (access) => auth.api.post(
          '/v1/me/devices',
          body: {'token': token, 'lang': AppText.now.localeName},
          token: access,
        ),
      );
    } on ApiException {
      // Sent again on the next sign-in or token change.
    }
  }

  /// Before signing out: this phone stops getting that account's
  /// notifications.
  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    final auth = AuthService.instance;
    try {
      await auth.authed(
        (access) => auth.api.deleteJson(
          '/v1/me/devices',
          body: {'token': token},
          token: access,
        ),
      );
    } on ApiException {
      // The server forgets it when another account signs in here.
    }
  }

  /// A tapped notification: requests open Notifications, an accepted one
  /// opens the new friend.
  void _open(RemoteMessage message) {
    final type = message.data['type'];
    final username = message.data['username'];
    final go = router;
    if (go == null) return;
    final game = message.data['game'];
    if (type == 'challenge' && game is String) {
      go.push('/online/$game');
    } else if (type == 'chat_message' && username is String) {
      go.push('/chat/$username');
    } else if (type == 'friend_accepted' && username is String) {
      go.push('/player/$username');
    } else if (type == 'friend_request') {
      go.push('/notifications');
    }
    unawaited(PlayersRepository.instance.refreshIncoming());
  }
}
