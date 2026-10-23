import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/features/puzzles/puzzle_game_screen.dart';
import 'package:kust/features/puzzles/puzzle_session.dart';
import 'package:kust/theme.dart';

const _mate = PuzzleEntry(
  id: 'm',
  fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
  moves: ['a1a8'],
  rating: 800,
);

class _FakeRecorder implements PuzzleProgressRecorder {
  @override
  Future<void> recordMistake(PuzzleEntry puzzle) async {}

  @override
  Future<void> recordRevealed(PuzzleEntry puzzle) async {}

  @override
  Future<void> recordSolved(PuzzleEntry puzzle, {required bool clean}) async {}
}

void main() {
  group('piece hint after a wrong move', () {
    test('points at the piece but not at the target', () {
      final s = PuzzleSession(_mate);
      expect(s.hintFrom, isNull);
      s.submit(NormalMove.fromUci('a1a2'));
      s.revealPieceHint();
      expect(s.hintFrom, Square.a1);
      expect(s.hintTo, isNull);
    });

    test('the Hint button still reveals the target afterwards', () {
      final s = PuzzleSession(_mate);
      s.revealPieceHint();
      expect(s.useHint(), isTrue);
      expect(s.hintTo, Square.a8);
    });

    test('does not reduce an existing hint and clears after a right move', () {
      final s = PuzzleSession(_mate)
        ..useHint()
        ..useHint();
      s.revealPieceHint();
      expect(s.hintLevel, 2);
      s.submit(NormalMove.fromUci('a1a8'));
      expect(s.hintLevel, 0);
    });
  });

  group('slideBetween', () {
    final line = ['e2e4', 'e7e5', 'g1f3'];
    final positions = <Position>[Chess.initial];
    final moves = <NormalMove?>[null];
    for (final uci in line) {
      final move = Move.parse(uci)! as NormalMove;
      positions.add(positions.last.play(move));
      moves.add(move);
    }

    test('forward, back, and nothing for bigger jumps', () {
      expect(slideBetween(positions, moves, 0, 1), (
        from: Square.e2,
        to: Square.e4,
      ));
      expect(slideBetween(positions, moves, 3, 2), (
        from: Square.f3,
        to: Square.g1,
      ));
      expect(slideBetween(positions, moves, 0, 3), isNull);
      expect(slideBetween(positions, moves, 2, 2), isNull);
    });

    test('castling shows the king on its real square', () {
      final start = Chess.fromSetup(
        Setup.parseFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'),
      );
      final castle = Move.parse('e1h1')! as NormalMove;
      final after = start.play(castle);
      final slide = slideBetween([start, after], [null, castle], 0, 1);
      expect(slide, (from: Square.e1, to: Square.g1));
      final back = slideBetween([start, after], [null, castle], 1, 0);
      expect(back, (from: Square.g1, to: Square.e1));
    });
  });

  group('puzzle screen layout', () {
    testWidgets('the board does not move when text or controls change', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: PuzzleGameScreen(level: 1, index: 0, progress: _FakeRecorder()),
        ),
      );
      // The puzzle loads from the asset bundle; wait for the board.
      for (var i = 0; i < 50; i++) {
        if (find.byType(PuzzleBoard).evaluate().isNotEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byType(PuzzleBoard), findsOneWidget);

      final start = tester.getRect(find.byType(PuzzleBoard));
      expect(start.width, 400);

      void play(String uci) => tester
          .widget<PuzzleBoard>(find.byType(PuzzleBoard))
          .onMove(NormalMove.fromUci(uci));

      // A wrong move: the status text changes and the piece is pointed out.
      play('a2a3');
      await tester.pump();
      expect(find.text('Not that one'), findsOneWidget);
      expect(tester.getRect(find.byType(PuzzleBoard)), start);
      final hinted = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard));
      expect(hinted.hintFrom, Square.e2);
      expect(hinted.hintTo, isNull);
      await tester.pump(const Duration(seconds: 1));

      // The right move finishes the puzzle: the controls swap for the result
      // bar and the board stays put.
      play('e2f3');
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Puzzle solved!'), findsOneWidget);
      expect(tester.getRect(find.byType(PuzzleBoard)), start);
    });
  });
}
