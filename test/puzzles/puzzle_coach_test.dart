import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/puzzles/coach_bubble.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/features/puzzles/puzzle_coach.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/features/puzzles/puzzle_game_screen.dart';
import 'package:kust/features/puzzles/speech_bubble.dart';
import 'package:kust/theme.dart';
import 'package:dartchess/dartchess.dart';

class _FakeRecorder implements PuzzleProgressRecorder {
  @override
  Future<void> recordMistake(PuzzleEntry puzzle) async {}

  @override
  Future<void> recordRevealed(PuzzleEntry puzzle) async {}

  @override
  Future<void> recordSolved(PuzzleEntry puzzle, {required bool clean}) async {}
}

void main() {
  group('wording', () {
    test('every theme has lines of its own, other themes get a default', () {
      for (final theme in [
        'mateIn1',
        'mateIn2',
        'mateIn3',
        'fork',
        'pin',
        'endgame',
        'winMaterial',
      ]) {
        final tip = coachTip(mood: CoachMood.thinking, theme: theme, seed: 0);
        expect(tip, isNotEmpty, reason: theme);
      }
      expect(
        coachTip(mood: CoachMood.thinking, theme: 'fork', seed: 0),
        isNot(coachTip(mood: CoachMood.thinking, theme: 'pin', seed: 0)),
      );
    });

    test('the same seed gives the same line, other seeds vary it', () {
      String tip(int seed) =>
          coachTip(mood: CoachMood.solved, theme: 'fork', seed: seed);
      expect(tip(5), tip(5));
      expect({for (var i = 0; i < 8; i++) tip(i)}.length, greaterThan(1));
    });

    test('repeated mistakes get different words', () {
      final lines = {
        for (var m = 0; m < 4; m++)
          coachTip(mood: CoachMood.mistake, theme: 'pin', seed: 10 + m),
      };
      expect(lines.length, 4);
    });

    test('each mood sounds different and lines are short enough', () {
      for (final mood in CoachMood.values) {
        for (var seed = 0; seed < 6; seed++) {
          final tip = coachTip(mood: mood, theme: 'mateIn2', seed: seed);
          expect(tip.length, lessThanOrEqualTo(60), reason: tip);
        }
      }
      final moods = {
        for (final m in CoachMood.values)
          coachTip(mood: m, theme: 'mateIn1', seed: 0),
      };
      expect(moods.length, CoachMood.values.length);
    });

    test('a puzzle id always gives the same seed', () {
      expect(coachSeed('l2-001'), coachSeed('l2-001'));
      expect(coachSeed('l2-001'), isNot(coachSeed('l2-002')));
    });

    test('a negative seed does not crash', () {
      expect(
        coachTip(mood: CoachMood.thinking, theme: 'fork', seed: -7),
        isNotEmpty,
      );
    });
  });

  group('puzzle screen', () {
    Future<void> pump(WidgetTester tester, int level, int index) async {
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
    }

    testWidgets('the coach says whose move it is, with a line for the theme', (
      tester,
    ) async {
      await pump(tester, 3, 0);
      expect(find.byType(CoachBubble), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is SpeechBubblePainter,
        ),
        findsOneWidget,
      );
      expect(find.textContaining(RegExp('(White|Black) to move')), findsOne);
      final puzzle = (await PuzzleRepository.instance.loadLevel(3)).puzzles[0];
      final tip = coachTip(
        mood: CoachMood.thinking,
        theme: 'fork',
        seed: coachSeed(puzzle.id),
      );
      expect(find.text(tip), findsOneWidget);
    });

    testWidgets('the coach reacts to a wrong move and to the solution', (
      tester,
    ) async {
      await pump(tester, 2, 0);
      final board = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard));
      final puzzle = (await PuzzleRepository.instance.loadLevel(2)).puzzles[0];
      final position = Chess.fromSetup(Setup.parseFen(puzzle.fen));
      // Any legal move that is not the solution.
      final wrong = position.legalMoves.entries
          .expand(
            (e) => e.value.squares.map((to) => NormalMove(from: e.key, to: to)),
          )
          .firstWhere((m) => m.uci != puzzle.moves.first);
      board.onMove(wrong);
      await tester.pump();
      expect(find.text('Not that one'), findsOneWidget);
      final mistakeTip = coachTip(
        mood: CoachMood.mistake,
        theme: puzzle.theme,
        seed: coachSeed(puzzle.id) + 1,
      );
      expect(find.text(mistakeTip), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Solution'));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Solution shown'), findsOneWidget);
      expect(
        find.text(
          coachTip(
            mood: CoachMood.revealed,
            theme: puzzle.theme,
            seed: coachSeed(puzzle.id) + 1,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the board stays in place whatever the coach says', (
      tester,
    ) async {
      await pump(tester, 2, 0);
      final start = tester.getRect(find.byType(PuzzleBoard));
      final puzzle = (await PuzzleRepository.instance.loadLevel(2)).puzzles[0];
      tester
          .widget<PuzzleBoard>(find.byType(PuzzleBoard))
          .onMove(NormalMove.fromUci(puzzle.moves.first));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.getRect(find.byType(PuzzleBoard)), start);
    });
  });
}
