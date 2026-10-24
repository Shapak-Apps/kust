import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/puzzles/puzzle_data.dart';

void main() {
  final seen = <String>{};

  for (final n in [1, 2, 3, 4, 5]) {
    test('bundled level $n puzzles are all valid', () {
      final json = jsonDecode(
        File('assets/puzzles/level$n.json').readAsStringSync(),
      );
      final level = PuzzleLevel.fromJson(json as Map<String, dynamic>);
      expect(level.level, n);
      expect(level.skipped, 0);
      expect(level.puzzles, isNotEmpty);
      // Ids are unique across levels: progress is stored by id.
      for (final puzzle in level.puzzles) {
        expect(seen.add(puzzle.id), isTrue, reason: puzzle.id);
        expect(puzzle.id, startsWith('l$n-'));
      }
    });
  }

  test('each level plays the theme it is named after', () {
    const themes = {
      2: {'mateIn2'},
      3: {'fork'},
      4: {'pin'},
      5: {'endgame'},
    };
    for (final entry in themes.entries) {
      final json = jsonDecode(
        File('assets/puzzles/level${entry.key}.json').readAsStringSync(),
      );
      final level = PuzzleLevel.fromJson(json as Map<String, dynamic>);
      expect(level.puzzles.map((p) => p.theme).toSet(), entry.value);
    }
  });
}
