import 'dart:async';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/achievements/achievements.dart';

/// Sends the player's games and achievements to the server, so other
/// players can see them on their profile. Games against bots are played on
/// the phone; this copies each one up once (again if its analysis changes),
/// a moment after it is saved, and only for a verified account.
class ProfileSync {
  ProfileSync._();

  static final ProfileSync instance = ProfileSync._();

  static const int _batch = 50;
  static const Duration _settle = Duration(seconds: 2);

  Timer? _timer;
  bool _running = false;
  bool _again = false;

  void start() {
    GameHistoryStore.instance.listenable().addListener(_soon);
    AchievementStore.instance.listenable().addListener(_soon);
    AuthService.instance.state.addListener(_soon);
    _soon();
  }

  void _soon() {
    _timer?.cancel();
    _timer = Timer(_settle, () => unawaited(sync()));
  }

  /// What was sent of a game: it goes again when its analysis changes.
  static String signature(GameRecord g) =>
      '${g.id}:${g.analyzed}:${g.accuracy?.toStringAsFixed(1)}';

  Future<void> sync() async {
    final auth = AuthService.instance;
    final account = auth.state.value.account;
    if (!auth.state.value.isVerified || account == null) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      final box = Hive.box(AppStorage.userBoxName);
      // Kept per account: another account on this phone starts afresh.
      final gamesKey = 'synced_games_${account.id}';
      final achKey = 'synced_achievements_${account.id}';
      final sent = <String>{
        ...((box.get(gamesKey) as List?) ?? const []).whereType<String>(),
      };
      final waiting = [
        for (final g in GameHistoryStore.instance.all())
          if (!sent.contains(signature(g))) g,
      ];
      for (var i = 0; i < waiting.length; i += _batch) {
        final batch = waiting.skip(i).take(_batch).toList();
        await auth.authed(
          (token) => auth.api.put(
            '/v1/me/games',
            body: {
              'games': [for (final g in batch) g.toMap()],
            },
            token: token,
          ),
        );
        sent.addAll(batch.map(signature));
        await box.put(gamesKey, sent.toList());
      }

      final unlocked = AchievementStore.instance.unlocked();
      if (unlocked.isNotEmpty && box.get(achKey) != unlocked.length) {
        await auth.authed(
          (token) => auth.api.put(
            '/v1/me/achievements',
            body: {
              'achievements': {
                for (final e in unlocked.entries)
                  e.key: e.value.millisecondsSinceEpoch,
              },
            },
            token: token,
          ),
        );
        await box.put(achKey, unlocked.length);
      }
    } on ApiException {
      // Offline or refused: tried again on the next change or sign-in.
    } finally {
      _running = false;
      if (_again) {
        _again = false;
        _soon();
      }
    }
  }
}
