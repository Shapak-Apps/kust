import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/puzzles/loom_progress.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/features/puzzles/puzzle_theme.dart';

PuzzleLevel _level(int number, int count) => PuzzleLevel(
  level: number,
  puzzles: [
    for (var i = 1; i <= count; i++)
      PuzzleEntry(
        id: 'l$number-$i',
        fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
        moves: const ['a1a8'],
        rating: 1000,
      ),
  ],
);

PuzzleProgress _done(
  Iterable<String> ids, {
  Iterable<String> revealed = const [],
}) => PuzzleProgress(solved: ids.toSet(), revealed: revealed.toSet());

void main() {
  group('theme labels', () {
    test('every theme has a readable name', () {
      expect(puzzleThemeLabel('mateIn1'), 'Mate in 1');
      expect(puzzleThemeLabel('mateIn3'), 'Mate in 3');
      expect(puzzleThemeLabel('fork'), 'Fork');
      expect(puzzleThemeLabel('pin'), 'Pin');
      expect(puzzleThemeLabel('endgame'), 'Endgame');
      expect(puzzleThemeLabel('winMaterial'), 'Win material');
      expect(puzzleThemeLabel('tactic'), 'Win material');
    });
  });

  group('LoomProgress', () {
    final levels = <PuzzleLevel?>[
      _level(1, 4),
      _level(2, 4),
      _level(3, 4),
      null,
      null,
    ];

    test('starts on the first puzzle of the first level', () {
      final loom = LoomProgress.from(levels, const PuzzleProgress());
      expect(loom.current, 0);
      expect(loom.nextPuzzle, 0);
      expect(loom.allDone, isFalse);
      expect(loom.woven, 0);
      expect(loom.done, 0);
      expect(loom.total, 12);
      expect(
        [for (final l in loom.levels) l.state],
        [
          LevelState.onLoom,
          LevelState.waiting,
          LevelState.waiting,
          LevelState.comingSoon,
          LevelState.comingSoon,
        ],
      );
      expect(loom.levels[0].status, '0 of 4 knots');
      expect(loom.levels[1].status, 'Not started');
      expect(loom.levels[3].status, 'Coming soon');
    });

    test('the share of the current level weaves in', () {
      final loom = LoomProgress.from(levels, _done(['l1-1', 'l1-2']));
      expect(loom.current, 0);
      expect(loom.nextPuzzle, 2);
      expect(loom.woven, 0.5);
      expect(loom.levels[0].status, '2 of 4 knots');
    });

    test('a revealed puzzle counts as done', () {
      final loom = LoomProgress.from(
        levels,
        _done(['l1-1'], revealed: ['l1-2']),
      );
      expect(loom.nextPuzzle, 2);
      expect(loom.levels[0].done, 2);
    });

    test('finishing a level opens the next one', () {
      final loom = LoomProgress.from(
        levels,
        _done(['l1-1', 'l1-2', 'l1-3', 'l1-4', 'l2-1']),
      );
      expect(loom.current, 1);
      expect(loom.nextPuzzle, 1);
      expect(loom.woven, 1.25);
      expect(loom.levels[0].state, LevelState.woven);
      expect(loom.levels[0].status, 'Woven ✓');
      expect(loom.levels[1].state, LevelState.onLoom);
      expect(loom.levels[2].state, LevelState.waiting);
    });

    test('puzzles are taken in order, even if a later one was solved', () {
      final loom = LoomProgress.from(levels, _done(['l1-1', 'l1-3']));
      expect(loom.nextPuzzle, 1);
    });

    test('with every available level done, nothing is left on the loom', () {
      final all = [
        for (final l in levels.whereType<PuzzleLevel>())
          for (final p in l.puzzles) p.id,
      ];
      final loom = LoomProgress.from(levels, _done(all));
      expect(loom.allDone, isTrue);
      expect(loom.current, 2);
      expect(loom.woven, 3);
      expect(loom.done, 12);
      expect(loom.levels.where((l) => l.state == LevelState.onLoom), isEmpty);
      expect(loom.levels[2].state, LevelState.woven);
      expect(loom.levels[4].state, LevelState.comingSoon);
    });

    test('a level without puzzles is skipped, not an error', () {
      final loom = LoomProgress.from([
        _level(1, 2),
        PuzzleLevel(level: 2, puzzles: const []),
        _level(3, 2),
      ], _done(['l1-1', 'l1-2']));
      expect(loom.current, 2);
      expect(loom.levels[1].state, LevelState.comingSoon);
    });

    test('no puzzles at all', () {
      final loom = LoomProgress.from(const [
        null,
        null,
      ], const PuzzleProgress());
      expect(loom.hasPuzzles, isFalse);
      expect(loom.allDone, isTrue);
      expect(loom.current, 0);
      expect(loom.woven, 0);
    });
  });
}
