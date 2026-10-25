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
import 'package:kust/ui/kust_top_bar.dart';
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

  group('slot', () {
    test('is big enough for the bubble at every text size', () {
      // Measured on a phone at normal size: the bubble's text needed 64 px
      // (59 were available and it overflowed by 5), plus 21 px of padding in
      // the bubble and the gap above the board. The text scales with the
      // text size.
      for (var scale = 1.0; scale <= 2.0; scale += 0.1) {
        expect(
          coachSlotHeight(scale),
          greaterThanOrEqualTo(64 * scale + 21 + CoachBubble.standingGap),
          reason: 'text scale $scale',
        );
        expect(coachSlotHeight(scale), greaterThanOrEqualTo(coachFigureHeight));
      }
    });

    test('is as tall as the person at normal size', () {
      expect(coachSlotHeight(1), coachFigureHeight);
    });

    test('never shrinks below the normal size, nor grows without limit', () {
      expect(coachSlotHeight(0.5), coachSlotHeight(1));
      expect(coachSlotHeight(5), coachSlotHeight(2));
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

    testWidgets('the slot above the board grows with the text size', (
      tester,
    ) async {
      // Nothing on the screen, the control bar included, overflows.
      for (final scale in [1.0, 1.5]) {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: PuzzleGameScreen(
              level: 3,
              index: 0,
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
        final slot = find
            .ancestor(
              of: find.byType(CoachBubble),
              matching: find.byType(SizedBox),
            )
            .evaluate()
            .map((e) => tester.getSize(find.byWidget(e.widget)).height)
            .firstWhere((h) => h > 60);
        expect(slot, coachSlotHeight(scale));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the coach stands right on top of the board', (tester) async {
      await pump(tester, 2, 0);
      final coach = tester.getRect(find.byType(CoachBubble));
      final board = tester.getRect(find.byType(PuzzleBoard));
      // Flush: the coach's slot ends where the board begins, and both are
      // as wide as the screen allows.
      expect(coach.bottom, board.top);
      expect(board.width, 400);
      expect(coach.left, greaterThanOrEqualTo(0));
      final image = tester.getRect(
        find.descendant(
          of: find.byType(CoachBubble),
          matching: find.byType(Image),
        ),
      );
      expect(image.bottom, board.top);
      expect(image.height, coachFigureHeight);
      // Both sit right under the top bar, not in the middle of the screen.
      final topBar = tester.getRect(find.byType(KustTopBar));
      expect(coach.top - topBar.bottom, lessThan(12));
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
