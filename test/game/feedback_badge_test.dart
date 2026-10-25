// The tests set the controller's state directly to stage a position.
// ignore_for_file: invalid_use_of_protected_member
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/move_feedback.dart';
import 'package:kust/features/game/chess/move_record.dart';
import 'package:kust/features/game/feedback_glow.dart';
import 'package:kust/features/game/move_feedback_badge.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/theme.dart';

const _best = MoveFeedback(
  quality: MoveQuality.best,
  bestSan: 'x',
  playedSan: 'x',
);

/// Plays [ucis] from the start; the player (white) gets [_best] on each of
/// their moves.
GameState _staged(GameState base, List<String> ucis) {
  Position position = Chess.initial;
  final history = <Position>[];
  final moves = <MoveRecord>[];
  NormalMove? last;
  for (final uci in ucis) {
    final move = NormalMove.fromUci(uci);
    final captured = position.board.pieceAt(move.to);
    moves.add(
      MoveRecord(
        side: position.turn,
        san: uci,
        move: move,
        capturedPiece: captured,
        feedback: position.turn == Side.white ? _best.copyWithSan(uci) : null,
      ),
    );
    history.add(position);
    position = position.play(move);
    last = move;
  }
  return base.copyWith(
    position: position,
    history: history,
    moves: moves,
    lastMove: last,
    moveSquares: last == null ? const [] : [last.from, last.to],
    practiceMode: true,
    moveFeedbackEnabled: true,
    status: GameStatus.playing,
    engineFailed: true,
  );
}

extension on MoveFeedback {
  MoveFeedback copyWithSan(String san) =>
      MoveFeedback(quality: quality, bestSan: bestSan, playedSan: san);
}

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

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 31));
}

void main() {
  testWidgets('the badge and glow do not replay when the opponent moves', (
    tester,
  ) async {
    final controller = await _board(tester);
    controller.state = _staged(controller.state, ['e2e4']);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final badge = tester.state(find.byType(MoveFeedbackBadge));
    final glow = tester.state(find.byType(FeedbackGlow));

    // The bot answers: its piece glides in on a new layer above the grid.
    controller.state = _staged(controller.state, ['e2e4', 'e7e5']);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      identical(tester.state(find.byType(MoveFeedbackBadge)), badge),
      isTrue,
    );
    expect(identical(tester.state(find.byType(FeedbackGlow)), glow), isTrue);
    await tester.pump(const Duration(seconds: 1));
    await _finish(tester);
  });

  testWidgets('the rating goes away once the piece is taken', (tester) async {
    final controller = await _board(tester);
    controller.state = _staged(controller.state, ['e2e4', 'd7d5']);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MoveFeedbackBadge), findsOneWidget);

    // The rated pawn takes on f6 and is taken back.
    controller.state = _staged(controller.state, [
      'e2e4',
      'd7d5',
      'e4e5',
      'f7f6',
      'e5f6',
      'g7f6',
    ]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // The pawn that took on f6 is gone: no badge, no glow.
    expect(find.byType(MoveFeedbackBadge), findsNothing);
    expect(find.byType(FeedbackGlow), findsNothing);
    await _finish(tester);
  });

  testWidgets('on the right-hand file the badge moves to the left corner', (
    tester,
  ) async {
    final controller = await _board(tester);
    controller.state = _staged(controller.state, ['h2h4']);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final board = tester.getRect(find.byType(ChessBoard));
    final badge = tester.getRect(find.byType(MoveFeedbackBadge));
    expect(badge.right, lessThanOrEqualTo(board.right));

    controller.state = _staged(controller.state, ['e2e4']);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final square = board.width / 8;
    final e4Right = board.left + 5 * square;
    // Elsewhere it keeps the usual top-right corner, over the edge.
    expect(
      tester.getRect(find.byType(MoveFeedbackBadge)).right,
      greaterThan(e4Right),
    );
    await _finish(tester);
  });
}
