import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';

/// Where one level of the carpet stands.
enum LevelState {
  /// Every puzzle is done: the göl is woven.
  woven,

  /// The level being solved now.
  onLoom,

  /// Has puzzles, but an earlier level comes first.
  waiting,

  /// No puzzles for this level yet.
  comingSoon,
}

class LevelProgress {
  const LevelProgress({
    required this.state,
    required this.done,
    required this.total,
  });

  final LevelState state;

  /// Puzzles solved or revealed.
  final int done;
  final int total;

  /// The text shown under the level's name on the map.
  String get status => switch (state) {
    LevelState.woven => 'Woven ✓',
    LevelState.onLoom => '$done of $total knots',
    LevelState.waiting => 'Not started',
    LevelState.comingSoon => 'Coming soon',
  };
}

/// How far the player has got through all the levels. Levels are played in
/// order: a level opens once the one before it is done.
class LoomProgress {
  const LoomProgress._({
    required this.levels,
    required this.current,
    required this.nextPuzzle,
    required this.allDone,
    required this.woven,
    required this.done,
    required this.total,
  });

  /// [levels] holds one entry per göl, bottom to top. A level that is null
  /// or empty has no puzzles yet.
  factory LoomProgress.from(
    List<PuzzleLevel?> levels,
    PuzzleProgress progress,
  ) {
    final entries = <LevelProgress>[];
    var firstOpen = -1;
    var lastAvailable = -1;

    for (var i = 0; i < levels.length; i++) {
      final puzzles = levels[i]?.puzzles ?? const <PuzzleEntry>[];
      final done = puzzles.where((p) => progress.isCompleted(p.id)).length;
      final available = puzzles.isNotEmpty;
      if (available) {
        lastAvailable = i;
        if (firstOpen == -1 && done < puzzles.length) firstOpen = i;
      }
      entries.add(
        LevelProgress(
          state: !available
              ? LevelState.comingSoon
              : done == puzzles.length
              ? LevelState.woven
              : LevelState.waiting,
          done: done,
          total: puzzles.length,
        ),
      );
    }

    final allDone = firstOpen == -1;
    final current = allDone
        ? (lastAvailable == -1 ? 0 : lastAvailable)
        : firstOpen;
    if (!allDone) {
      entries[current] = LevelProgress(
        state: LevelState.onLoom,
        done: entries[current].done,
        total: entries[current].total,
      );
    }

    final currentPuzzles = levels.isEmpty
        ? const <PuzzleEntry>[]
        : levels[current]?.puzzles ?? const <PuzzleEntry>[];
    var nextPuzzle = currentPuzzles.indexWhere(
      (p) => !progress.isCompleted(p.id),
    );
    if (nextPuzzle == -1) {
      nextPuzzle = currentPuzzles.isEmpty ? 0 : currentPuzzles.length - 1;
    }

    final woven = allDone
        ? (lastAvailable + 1).toDouble()
        : current + entries[current].done / entries[current].total;

    return LoomProgress._(
      levels: entries,
      current: current,
      nextPuzzle: nextPuzzle,
      allDone: allDone,
      woven: woven,
      done: entries.fold(0, (sum, e) => sum + e.done),
      total: entries.fold(0, (sum, e) => sum + e.total),
    );
  }

  final List<LevelProgress> levels;

  /// Index of the level being solved (the last available one when all done).
  final int current;

  /// Index of the next puzzle to play within [current].
  final int nextPuzzle;

  /// Every available level is finished.
  final bool allDone;

  /// Levels woven so far plus the share of the current one, 0 to 5.
  final double woven;

  /// Puzzles done and available, across all levels.
  final int done;
  final int total;

  bool get hasPuzzles => total > 0;
}
