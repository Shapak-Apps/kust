import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/features/puzzles/puzzle_game_screen.dart';
import 'package:kust/theme.dart';

class _FakeRecorder implements PuzzleProgressRecorder {
  @override
  Future<void> recordMistake(PuzzleEntry puzzle) async {}

  @override
  Future<void> recordRevealed(PuzzleEntry puzzle) async {}

  @override
  Future<void> recordSolved(PuzzleEntry puzzle, {required bool clean}) async {}
}

/// Opens puzzle [index] of [level], shows its solution and returns once the
/// bar with the result buttons is on screen.
Future<void> _showSolution(WidgetTester tester, int level, int index) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      home: PuzzleGameScreen(
        level: level,
        index: index,
        progress: _FakeRecorder(),
      ),
    ),
  );
  for (var i = 0; i < 50; i++) {
    if (find.byType(PuzzleBoard).evaluate().isNotEmpty) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  // Let the check for a next level finish too.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();

  await tester.tap(find.text('Solution'));
  await tester.pump(const Duration(seconds: 3));
  expect(find.text('Solution shown'), findsOneWidget);
}

void main() {
  testWidgets('the last puzzle of a level offers the next level', (
    tester,
  ) async {
    await _showSolution(tester, 1, 35);
    expect(find.text('Next level'), findsOneWidget);
    expect(find.text('Next puzzle'), findsNothing);
  });

  testWidgets('a puzzle in the middle of a level offers the next puzzle', (
    tester,
  ) async {
    await _showSolution(tester, 2, 0);
    expect(find.text('Next puzzle'), findsOneWidget);
  });

  testWidgets('the last puzzle of the last level goes back to the map', (
    tester,
  ) async {
    await _showSolution(tester, 5, 39);
    expect(find.text('Back to puzzles'), findsOneWidget);
    expect(find.text('Next level'), findsNothing);
  });

  testWidgets('puzzles of the new levels show their theme', (tester) async {
    await _showSolution(tester, 3, 0);
    expect(find.text('Fork'), findsOneWidget);
  });
}
