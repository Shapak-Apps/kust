import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/storage/app_storage.dart';

/// One achievement: what it is called, how it is earned and its icon.
@immutable
class Achievement {
  const Achievement(this.id, this.title, this.description, this.icon);

  final String id;
  final String title;
  final String description;
  final IconData icon;
}

/// Every achievement, in the order the list shows them.
const List<Achievement> kAchievements = [
  // Games against bots.
  Achievement(
    'first_game',
    'First move',
    'Finish a game against a bot',
    Icons.flag_rounded,
  ),
  Achievement(
    'first_win',
    'First victory',
    'Win a game against a bot',
    Icons.emoji_events_rounded,
  ),
  Achievement(
    'checkmate',
    'Checkmate!',
    'Win a game by checkmate',
    Icons.gpp_good_rounded,
  ),
  Achievement(
    'quick_mate',
    'Lightning',
    'Checkmate a bot in 20 moves or less',
    Icons.bolt_rounded,
  ),
  Achievement(
    'giant_slayer',
    'Giant slayer',
    'Beat a bot rated 300 or more above you',
    Icons.trending_up_rounded,
  ),
  Achievement(
    'three_bots',
    'Rising star',
    'Beat 3 different bots',
    Icons.star_rounded,
  ),
  Achievement(
    'all_bots',
    'Champion',
    'Beat every bot',
    Icons.workspace_premium_rounded,
  ),
  Achievement(
    'marathon',
    'Marathon',
    'Play a game of 60 moves or more',
    Icons.timer_rounded,
  ),
  Achievement(
    'accurate',
    'Sharpshooter',
    'Play a game with 90% accuracy',
    Icons.gps_fixed_rounded,
  ),
  Achievement(
    'brilliant',
    'Brilliant!',
    'Play a brilliant move',
    Icons.auto_awesome_rounded,
  ),
  // Puzzles.
  Achievement(
    'first_puzzle',
    'Puzzler',
    'Solve your first puzzle',
    Icons.extension_rounded,
  ),
  Achievement(
    'puzzles_25',
    'Knot by knot',
    'Solve 25 puzzles',
    Icons.grid_view_rounded,
  ),
  Achievement(
    'first_gol',
    'First göl',
    'Weave a whole göl',
    Icons.texture_rounded,
  ),
  Achievement(
    'whole_carpet',
    'Master weaver',
    'Weave all five göls',
    Icons.auto_fix_high_rounded,
  ),
  Achievement(
    'streak_3',
    'On a roll',
    'Solve the daily puzzle 3 days in a row',
    Icons.local_fire_department_rounded,
  ),
  Achievement(
    'streak_7',
    'Week of fire',
    'Solve the daily puzzle 7 days in a row',
    Icons.whatshot_rounded,
  ),
];

Achievement? achievementById(String id) {
  for (final a in kAchievements) {
    if (a.id == id) return a;
  }
  return null;
}

/// What one finished bot game says about the player.
@immutable
class GameFacts {
  const GameFacts({
    required this.won,
    required this.byCheckmate,
    required this.playerMoves,
    required this.totalMoves,
    required this.botElo,
    required this.playerRating,
    required this.botsBeaten,
    required this.botCount,
  });

  final bool won;
  final bool byCheckmate;

  /// Moves made by the player.
  final int playerMoves;

  /// Full moves of the game (white and black together count as one).
  final int totalMoves;
  final int botElo;

  /// The player's rating before the game.
  final int playerRating;

  /// Different bots beaten so far, this game included.
  final int botsBeaten;
  final int botCount;
}

/// The achievements a finished bot game earns.
Set<String> earnedByGame(GameFacts f) => {
  'first_game',
  if (f.won) 'first_win',
  if (f.won && f.byCheckmate) 'checkmate',
  if (f.won && f.byCheckmate && f.playerMoves <= 20) 'quick_mate',
  if (f.won && f.botElo - f.playerRating >= 300) 'giant_slayer',
  if (f.botsBeaten >= 3) 'three_bots',
  if (f.botCount > 0 && f.botsBeaten >= f.botCount) 'all_bots',
  if (f.totalMoves >= 60) 'marathon',
};

/// The achievements a game's accuracy earns.
Set<String> earnedByAccuracy(double accuracy) => {
  if (accuracy >= 90) 'accurate',
};

/// The achievements puzzle progress earns.
Set<String> earnedByPuzzles({
  required int solved,
  required int levelsWoven,
  required int levelCount,
}) => {
  if (solved >= 1) 'first_puzzle',
  if (solved >= 25) 'puzzles_25',
  if (levelsWoven >= 1) 'first_gol',
  if (levelCount > 0 && levelsWoven >= levelCount) 'whole_carpet',
};

/// The achievements a daily streak earns.
Set<String> earnedByStreak(int days) => {
  if (days >= 3) 'streak_3',
  if (days >= 7) 'streak_7',
};

/// Which achievements the player has, kept per guest on this device.
class AchievementStore {
  AchievementStore._() : _boxOverride = null, _userIdOverride = null;

  @visibleForTesting
  AchievementStore.withBox(Box<dynamic> box, {String userId = 'test'})
    : _boxOverride = box,
      _userIdOverride = userId;

  static AchievementStore instance = AchievementStore._();

  final Box<dynamic>? _boxOverride;
  final String? _userIdOverride;

  /// The latest achievement unlocked, a signal for the celebration.
  /// Cleared once picked up.
  final ValueNotifier<Achievement?> justUnlocked = ValueNotifier(null);

  final List<Achievement> _toCelebrate = [];

  /// Every achievement unlocked since the last call, oldest first.
  List<Achievement> takeUnlocked() {
    final taken = List<Achievement>.of(_toCelebrate);
    _toCelebrate.clear();
    return taken;
  }

  Box<dynamic> get _box => _boxOverride ?? Hive.box(AppStorage.userBoxName);

  String get _key =>
      'achievements_${_userIdOverride ?? AppStorage.instance.guestId}';

  ValueListenable<Box<dynamic>> listenable() => _box.listenable(keys: [_key]);

  /// Unlocked achievement ids with when each was earned.
  Map<String, DateTime> unlocked() {
    final raw = _box.get(_key);
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        if (e.key is String && e.value is int)
          e.key as String: DateTime.fromMillisecondsSinceEpoch(e.value as int),
    };
  }

  /// Unlocks [ids]; returns the ones that are new. The first new one is
  /// announced through [justUnlocked].
  Future<List<Achievement>> unlock(Iterable<String> ids) async {
    final have = unlocked();
    final now = DateTime.now().millisecondsSinceEpoch;
    final fresh = [
      for (final id in ids)
        if (!have.containsKey(id)) ?achievementById(id),
    ];
    if (fresh.isEmpty) return fresh;
    await _box.put(_key, {
      for (final e in have.entries) e.key: e.value.millisecondsSinceEpoch,
      for (final a in fresh) a.id: now,
    });
    _toCelebrate.addAll(fresh);
    justUnlocked.value = fresh.first;
    return fresh;
  }
}
