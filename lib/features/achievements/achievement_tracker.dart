import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/puzzles/daily.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';

/// Looks at what just happened and unlocks what it earned. Never throws:
/// an achievement must not get in the way of the game.
abstract final class AchievementTracker {
  /// After a bot game is saved. Practice games (with takebacks and hints)
  /// only count as played.
  static Future<void> gameFinished({
    required bool won,
    required bool byCheckmate,
    required bool practice,
    required int playerMoves,
    required int totalMoves,
    required int botElo,
    required int playerRating,
  }) async {
    try {
      final facts = GameFacts(
        won: won && !practice,
        byCheckmate: byCheckmate,
        playerMoves: playerMoves,
        totalMoves: totalMoves,
        botElo: botElo,
        playerRating: playerRating,
        botsBeaten: AppStorage.instance.beatenBotIds.length,
        botCount: kInternationalBots.length + kTkmBots.length,
      );
      await AchievementStore.instance.unlock(earnedByGame(facts));
    } catch (_) {}
  }

  static Future<void> accuracy(double value) async {
    try {
      await AchievementStore.instance.unlock(earnedByAccuracy(value));
    } catch (_) {}
  }

  static Future<void> brilliantMove() async {
    try {
      await AchievementStore.instance.unlock(const {'brilliant'});
    } catch (_) {}
  }

  /// After a puzzle is solved or its solution shown.
  static Future<void> puzzleDone({int levelCount = 5}) async {
    try {
      final progress = PuzzleProgressStore.instance.load();
      var woven = 0;
      for (var n = 1; n <= levelCount; n++) {
        final level = await PuzzleRepository.instance.loadLevel(n);
        if (level.puzzles.isNotEmpty &&
            level.puzzles.every((p) => progress.isCompleted(p.id))) {
          woven++;
        }
      }
      await AchievementStore.instance.unlock(
        earnedByPuzzles(
          solved: progress.solved.length,
          levelsWoven: woven,
          levelCount: levelCount,
        ),
      );
    } catch (_) {}
  }

  static Future<void> dailySolved() async {
    try {
      final streak = DailyStore.instance.load().on(DateTime.now());
      await AchievementStore.instance.unlock(earnedByStreak(streak));
    } catch (_) {}
  }
}
