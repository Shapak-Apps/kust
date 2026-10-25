import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/loom_progress.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/features/puzzles/puzzle_game_screen.dart';
import 'package:kust/features/puzzles/woven_dialog.dart';
import 'package:kust/theme.dart';

PuzzleEntry _p(String id) =>
    PuzzleEntry(id: id, fen: '', moves: const [], rating: 1000, theme: 'x');

class _Recorder implements PuzzleProgressRecorder {
  _Recorder(this.done);
  Set<String> done;

  @override
  PuzzleProgress load() => PuzzleProgress(revealed: done);

  @override
  Future<void> recordMistake(PuzzleEntry puzzle) async {}

  @override
  Future<void> recordRevealed(PuzzleEntry puzzle) async =>
      done = {...done, puzzle.id};

  @override
  Future<void> recordSolved(PuzzleEntry puzzle, {required bool clean}) async =>
      done = {...done, puzzle.id};
}

void main() {
  group('levelJustWoven', () {
    final puzzles = [_p('a'), _p('b'), _p('c')];
    PuzzleProgress done(Set<String> ids) => PuzzleProgress(solved: ids);

    test('is true only for the knot that finishes the level', () {
      expect(
        levelJustWoven(puzzles, done({'a', 'b'}), done({'a', 'b', 'c'})),
        isTrue,
      );
      expect(levelJustWoven(puzzles, done({'a'}), done({'a', 'b'})), isFalse);
      // Playing a finished level again weaves nothing new.
      expect(
        levelJustWoven(puzzles, done({'a', 'b', 'c'}), done({'a', 'b', 'c'})),
        isFalse,
      );
      expect(levelJustWoven(const [], done({}), done({})), isFalse);
    });

    test('a revealed puzzle counts as done', () {
      expect(
        levelJustWoven(
          puzzles,
          const PuzzleProgress(solved: {'a'}, revealed: {'b'}),
          const PuzzleProgress(solved: {'a'}, revealed: {'b', 'c'}),
        ),
        isTrue,
      );
    });
  });

  group('woven card', () {
    testWidgets('weaves the göl and continues', (tester) async {
      var continued = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: Center(
              child: WovenCard(
                gol: GolKind.teke,
                tribe: 'Teke',
                knots: 20,
                nextTribe: 'Ýomut',
                onContinue: () => continued++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Teke göl woven'), findsOneWidget);
      expect(find.textContaining('The Ýomut göl is next'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Continue'));
      expect(continued, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the last göl says the carpet is done', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: WovenCard(
              gol: GolKind.saryk,
              tribe: 'Saryk',
              knots: 20,
              nextTribe: null,
              onContinue: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('whole carpet is done'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    test('the painter fills in from the bottom and repaints on change', () {
      final a = GolPainter(kind: GolKind.teke, woven: 0.2);
      expect(
        a.shouldRepaint(GolPainter(kind: GolKind.teke, woven: 0.2)),
        false,
      );
      expect(a.shouldRepaint(GolPainter(kind: GolKind.teke, woven: 0.5)), true);
    });
  });

  testWidgets('showing the solution of the last puzzle weaves the göl', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final level = (await tester.runAsync(
      () => PuzzleRepository.instance.loadLevel(1),
    ))!;
    final recorder = _Recorder({
      for (final p in level.puzzles.take(level.puzzles.length - 1)) p.id,
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: PuzzleGameScreen(
          level: 1,
          index: level.puzzles.length - 1,
          progress: recorder,
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
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.byType(WovenCard), findsNothing);
    await tester.tap(find.text('Solution'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Teke göl woven'), findsOneWidget);
    expect(find.textContaining('The Ýomut göl is next'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(WovenCard), findsNothing);
  });
}
