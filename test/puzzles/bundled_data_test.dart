import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/puzzles/puzzle_data.dart';

void main() {
  test('bundled level 1 puzzles are all valid', () {
    final json = jsonDecode(
      File('assets/puzzles/level1.json').readAsStringSync(),
    );
    final level = PuzzleLevel.fromJson(json as Map<String, dynamic>);
    expect(level.skipped, 0);
    expect(level.puzzles, isNotEmpty);
  });
}
