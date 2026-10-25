// The tests set the controller's state directly to stage a position.
// ignore_for_file: invalid_use_of_protected_member
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/board/board_geometry.dart';
import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/board/move_arrow.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/theme.dart';

const _castleFen = 'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1';

Future<ChessController> _board(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: Center(child: ChessBoard())),
      ),
    ),
  );
  final notifier = container.read(chessControllerProvider.notifier);
  await notifier.startGame(kInternationalBots.first, playerSide: Side.white);
  await tester.pumpAndSettle();
  return notifier;
}

void _stage(ChessController c, String fen) {
  c.state = c.state.copyWith(
    position: Chess.fromSetup(Setup.parseFen(fen)),
    status: GameStatus.playing,
    engineFailed: true,
  );
}

/// The centre of [square] on screen, white at the bottom.
Offset _centre(WidgetTester tester, Square square) {
  final board = tester.getRect(find.byType(ChessBoard));
  final cell = board.width / 8;
  return board.topLeft +
      Offset((fileOf(square) + 0.5) * cell, (7.5 - rankOf(square)) * cell);
}

/// Drags the piece on [from] so that it is shown over [to]. The piece floats
/// a little above the finger, so the finger ends just below [to].
Future<void> _drag(WidgetTester tester, Square from, Square to) async {
  final cell = tester.getRect(find.byType(ChessBoard)).width / 8;
  final start = _centre(tester, from);
  final end = _centre(tester, to) + Offset(0, cell * 0.3);
  final gesture = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 20));
  for (var i = 1; i <= 6; i++) {
    await gesture.moveTo(Offset.lerp(start, end, i / 6)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump();
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 31));
}

void main() {
  tearDown(() => AppSettings.instance.castleOnRook.value = false);

  group('castling', () {
    testWidgets('off: the king castles from the square beside the rook', (
      tester,
    ) async {
      final c = await _board(tester);
      _stage(c, _castleFen);
      c.selectSquare(Square.e1);
      expect(c.state.legalDestinations, containsAll([Square.g1, Square.c1]));
      expect(c.state.legalDestinations, isNot(contains(Square.h1)));
      // Tapping the rook just picks the rook.
      c.selectSquare(Square.h1);
      expect(c.state.selectedSquare, Square.h1);
      await _finish(tester);
    });

    testWidgets('on: tapping the king then its rook castles', (tester) async {
      final c = await _board(tester);
      AppSettings.instance.castleOnRook.value = true;
      _stage(c, _castleFen);
      c.selectSquare(Square.e1);
      expect(c.state.legalDestinations, containsAll([Square.g1, Square.h1]));
      c.selectSquare(Square.h1);
      await tester.pump();
      final board = c.state.position.board;
      expect(board.pieceAt(Square.g1)?.role, Role.king);
      expect(board.pieceAt(Square.f1)?.role, Role.rook);
      // The rook slides beside the king instead of jumping.
      expect(find.byKey(const ValueKey('moving_rook')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('moving_rook')), findsNothing);
      await _finish(tester);
    });

    testWidgets('on: the queen side castles on the a-rook', (tester) async {
      final c = await _board(tester);
      AppSettings.instance.castleOnRook.value = true;
      _stage(c, _castleFen);
      c.selectSquare(Square.e1);
      c.selectSquare(Square.a1);
      await tester.pump();
      expect(c.state.position.board.pieceAt(Square.c1)?.role, Role.king);
      expect(c.state.position.board.pieceAt(Square.d1)?.role, Role.rook);
      await tester.pump(const Duration(milliseconds: 400));
      await _finish(tester);
    });

    test('the setting is saved', () async {
      SharedPreferences.setMockInitialValues({'castle_on_rook': true});
      await AppSettings.instance.load();
      expect(AppSettings.instance.castleOnRook.value, isTrue);
      await AppSettings.instance.setCastleOnRook(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('castle_on_rook'), isFalse);
    });
  });

  group('drag and drop', () {
    testWidgets('dropping on a legal square plays the move, without a glide', (
      tester,
    ) async {
      final c = await _board(tester);
      await _drag(tester, Square.e2, Square.e4);
      expect(c.state.position.board.pieceAt(Square.e4)?.role, Role.pawn);
      expect(c.state.position.board.pieceAt(Square.e2), isNull);
      // It is already there: no copy glides in from e2.
      expect(find.byKey(const ValueKey('moving_piece')), findsNothing);
      expect(find.byKey(const ValueKey('dragged_piece')), findsNothing);
      await _finish(tester);
    });

    testWidgets('an illegal drop flies back and keeps the piece selected', (
      tester,
    ) async {
      final c = await _board(tester);
      await _drag(tester, Square.e2, Square.e5);
      expect(c.state.position.board.pieceAt(Square.e2)?.role, Role.pawn);
      expect(c.state.selectedSquare, Square.e2);
      expect(find.byKey(const ValueKey('snapping_piece')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('snapping_piece')), findsNothing);
      await _finish(tester);
    });

    testWidgets('while dragging the piece follows the finger over a ring', (
      tester,
    ) async {
      await _board(tester);
      final start = _centre(tester, Square.g1);
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      await gesture.moveBy(const Offset(-20, -40));
      await tester.pump();
      expect(find.byKey(const ValueKey('dragged_piece')), findsOneWidget);
      expect(find.byKey(const ValueKey('drag_hover')), findsOneWidget);
      await gesture.cancel();
      await tester.pump(const Duration(milliseconds: 300));
      await _finish(tester);
    });

    testWidgets('the opponent\'s pieces cannot be picked up', (tester) async {
      final c = await _board(tester);
      await _drag(tester, Square.e7, Square.e5);
      expect(c.state.position.board.pieceAt(Square.e7)?.role, Role.pawn);
      expect(find.byKey(const ValueKey('snapping_piece')), findsNothing);
      await _finish(tester);
    });
  });

  testWidgets('a hint shows as an arrow from the piece to its square', (
    tester,
  ) async {
    final c = await _board(tester);
    c.state = c.state.copyWith(hintSquares: {Square.g1, Square.f3});
    await tester.pump();
    final arrow = tester.widget<MoveArrow>(find.byType(MoveArrow));
    expect((arrow.fromRow, arrow.fromCol), (7, 6));
    expect((arrow.toRow, arrow.toCol), (5, 5));
    await tester.pump(const Duration(milliseconds: 400));
    await _finish(tester);
  });

  test('arrows run straight, and bend once for a knight', () {
    expect(MoveArrowPainter.route((6, 4), (4, 4)), [
      const Offset(4.5, 6.5),
      const Offset(4.5, 4.5),
    ]);
    // g1-f3: two up, one left: up first, then across.
    expect(MoveArrowPainter.route((7, 6), (5, 5)), [
      const Offset(6.5, 7.5),
      const Offset(6.5, 5.5),
      const Offset(5.5, 5.5),
    ]);
    // b1-d2: two across, one up: across first.
    expect(MoveArrowPainter.route((7, 1), (6, 3)), [
      const Offset(1.5, 7.5),
      const Offset(3.5, 7.5),
      const Offset(3.5, 6.5),
    ]);
  });

  test('glides take longer for longer moves, within limits', () {
    expect(glideDuration(1), lessThan(glideDuration(5)));
    expect(glideDuration(0.5).inMilliseconds, 170);
    expect(glideDuration(20).inMilliseconds, 320);
  });

  testWidgets('the puzzle board takes a dragged move too', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    NormalMove? played;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox.square(
              dimension: 400,
              child: PuzzleBoard(
                position: Chess.initial,
                flipped: false,
                interactive: true,
                onMove: (m) => played = m,
                hintFrom: Square.g1,
                hintTo: Square.f3,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(MoveArrow), findsOneWidget);
    // g1 is at (6.5, 7.5) squares of 50 px; f3 at (5.5, 5.5).
    final gesture = await tester.startGesture(const Offset(325, 375));
    for (var i = 1; i <= 6; i++) {
      await gesture.moveTo(
        Offset.lerp(const Offset(325, 375), const Offset(275, 290), i / 6)!,
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();
    expect(played, NormalMove(from: Square.g1, to: Square.f3));
    await tester.pump(const Duration(milliseconds: 400));
  });
}
