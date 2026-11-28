import 'dart:async';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/chat_repository.dart';
import 'package:kust/core/net/online_repository.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/l10n/app_locale.dart';

/// Sends the player's name, bio, flag, games, achievements and puzzle
/// progress to the server, so other players can see them on their profile. Games against bots are played on
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
    PuzzleProgressStore.instance.listenable().addListener(_soon);
    AuthService.instance.state.addListener(_soon);
    AppStorage.instance.profileListenable().addListener(_soon);
    _soon();
  }

  void _soon() {
    _timer?.cancel();
    _timer = Timer(_settle, () => unawaited(sync()));
  }

  /// [PuzzleProgressStore.signature] of progress as the server has it.
  static String _signatureOf(Map progress) {
    int count(String key) =>
        (progress[key] is List) ? (progress[key] as List).toSet().length : 0;
    return '${count('solved')}:${count('attempted')}:${count('revealed')}:'
        '${progress['rating']}:${progress['highest']}';
  }

  /// What was sent of a game: it goes again when its analysis changes.
  static String signature(GameRecord g) =>
      '${g.id}:${g.analyzed}:${g.accuracy?.toStringAsFixed(1)}';

  /// Signing in on this phone: the account's own games and achievements
  /// come down from the server (and count as sent).
  Future<void> restore(Account account) async {
    try {
      final repo = PlayersRepository.instance;
      final games = await repo.games(account.username, limit: 200);
      final box = Hive.box(AppStorage.userBoxName);
      final gamesKey = 'synced_games_${account.id}';
      final sent = <String>{
        ...((box.get(gamesKey) as List?) ?? const []).whereType<String>(),
      };
      for (final g in games.games) {
        await GameHistoryStore.instance.add(g);
        sent.add(signature(g));
      }
      await box.put(gamesKey, sent.toList());
      final earned = await repo.achievements(account.username);
      await AchievementStore.instance.restore(earned);
      await box.put('synced_achievements_${account.id}', earned.length);
      final auth = AuthService.instance;
      final puzzles = await auth.authed(
        (token) => auth.api.get('/v1/me/puzzles', token: token),
      );
      final progress = puzzles['progress'];
      if (progress is Map) {
        final store = PuzzleProgressStore.instance;
        await store.merge(Map<String, dynamic>.from(progress));
        // Sent again only if this phone added to it.
        if (store.signature() == _signatureOf(progress)) {
          await box.put('synced_puzzles_${account.id}', store.signature());
        }
      }
    } on ApiException {
      // Not verified yet, or offline: they come with the next sign-in.
    }
  }

  /// Signing out: this phone forgets the account's games, achievements,
  /// rating and puzzle progress, so the next account (or guest) doesn't see them. They stay on
  /// the server.
  Future<void> forget() async {
    PlayersRepository.instance.friendsCache.value = null;
    PlayersRepository.instance.incoming.value = const [];
    ChatRepository.instance.summaries.value = const [];
    ChatRepository.instance.unread.value = 0;
    OnlineRepository.instance.open.value = const [];
    await GameHistoryStore.instance.clear();
    await AchievementStore.instance.clear();
    await PuzzleProgressStore.instance.clear();
    await PlayerRatingStore.instance.setStartingRating(
      PlayerRatingStore.startRating,
    );
  }

  /// The name, bio and flag edited on the phone, when they differ from
  /// the account's.
  Future<void> _syncProfile(Account account) async {
    final store = AppStorage.instance;
    final name = store.displayName(AppText.now);
    final custom = name != AppText.now.defaultPlayerName;
    final country = store.country ?? '';
    if ((custom && name != account.displayName) ||
        store.bio != account.bio ||
        country != (account.country ?? '')) {
      await AuthService.instance.updateProfile(
        displayName: custom ? name : null,
        bio: store.bio,
        country: country,
      );
    }
  }

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
      await _syncProfile(account);
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

      final puzzles = PuzzleProgressStore.instance;
      final puzzlesKey = 'synced_puzzles_${account.id}';
      final progress = puzzles.toMap();
      final puzzlesMark = puzzles.signature();
      if (progress != null && box.get(puzzlesKey) != puzzlesMark) {
        await auth.authed(
          (token) => auth.api.put(
            '/v1/me/puzzles',
            body: {'progress': progress},
            token: token,
          ),
        );
        await box.put(puzzlesKey, puzzlesMark);
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
