import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/theme.dart';

Future<ProviderContainer> _pumpBoard(
  WidgetTester tester, {
  bool local = false,
}) async {
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
  // A bot game: in pass-and-play every piece turns around after each move,
  // which legitimately redraws the whole board.
  final notifier = container.read(chessControllerProvider.notifier);
  if (local) {
    await notifier.startLocalGame();
  } else {
    await notifier.startGame(kInternationalBots.first, playerSide: Side.white);
  }
  await tester.pumpAndSettle();
  return container;
}

/// Unmounts the board and lets the controller's keep-alive timer run out, so
/// no timer is left pending when the test ends.
Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 31));
}

void main() {
  testWidgets('a move rebuilds only the squares that changed', (tester) async {
    final container = await _pumpBoard(tester);
    final controller = container.read(chessControllerProvider.notifier);

    BoardSquareCell.debugBuildCount = 0;
    controller.selectSquare(Square.e2);
    await tester.pump();
    // Selecting highlights e2 and shows the legal targets e3 and e4.
    final afterSelect = BoardSquareCell.debugBuildCount;
    expect(afterSelect, inInclusiveRange(1, 6));

    BoardSquareCell.debugBuildCount = 0;
    controller.selectSquare(Square.e4);
    await tester.pumpAndSettle();
    // e2, e3, e4, the last-move squares and the hidden/shown moving piece:
    // far fewer than the 64 squares of the board.
    expect(BoardSquareCell.debugBuildCount, inInclusiveRange(1, 10));
    expect(
      container.read(chessControllerProvider).position.fen,
      contains('4P3'),
    );
    await _finish(tester);
  });

  testWidgets('frames of the move animation rebuild no squares', (
    tester,
  ) async {
    final container = await _pumpBoard(tester);
    final controller = container.read(chessControllerProvider.notifier);
    controller.selectSquare(Square.g1);
    await tester.pump();
    controller.selectSquare(Square.f3);
    await tester.pump(); // first frame of the move

    BoardSquareCell.debugBuildCount = 0;
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Mid-flight frames only move the glide layer.
    expect(BoardSquareCell.debugBuildCount, lessThanOrEqualTo(2));
    await tester.pumpAndSettle();
    await _finish(tester);
  });

  testWidgets('the board still shows all 32 pieces after moving', (
    tester,
  ) async {
    final container = await _pumpBoard(tester, local: true);
    final controller = container.read(chessControllerProvider.notifier);
    controller.selectSquare(Square.e2);
    controller.selectSquare(Square.e4);
    await tester.pumpAndSettle();
    controller.selectSquare(Square.d7);
    controller.selectSquare(Square.d5);
    await tester.pumpAndSettle();
    controller.selectSquare(Square.e4);
    controller.selectSquare(Square.d5);
    await tester.pumpAndSettle();

    final pieces = container
        .read(chessControllerProvider)
        .position
        .board
        .pieces
        .length;
    expect(pieces, 31); // one pawn captured
    await _finish(tester);
  });
}
