import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/features/review/retry_screen.dart';
import 'package:kust/theme.dart';

const _uci = [
  'e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'f3g5', 'd7d5', //
];

GameRecord _record() {
  Position p = Chess.initial;
  final san = <String>[];
  for (final u in _uci) {
    final m = NormalMove.fromUci(u);
    san.add(p.makeSan(m).$2);
    p = p.play(m);
  }
  return GameRecord(
    id: 'g1',
    playedAt: 0,
    isLocal: false,
    result: GameRecord.loss,
    reason: 'checkmate',
    playerIsWhite: true,
    uciMoves: _uci,
    sanMoves: san,
  );
}

/// The game's Ng5? loses; d3 is best, c3 is nearly as good, a3 is bad.
Future<MoveAnalysis?> _fake({
  required String beforeFen,
  required String playedUci,
  required String afterFen,
  required Duration thinkTime,
  bool Function()? isStale,
}) async {
  final played = switch (playedUci) {
    'd2d3' => 40,
    'c2c3' => 36,
    'a2a3' => -300,
    _ => -400,
  };
  return MoveAnalysis(
    bestUci: 'd2d3',
    bestCp: 40,
    playedCp: played,
    secondBestCp: 30,
  );
}

Future<void> _drag(WidgetTester tester, String from, String to) async {
  final rect = tester.getRect(find.byType(PuzzleBoard));
  final cell = rect.width / 8;
  Offset at(String sq) {
    final file = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(sq[1]) - 1;
    return rect.topLeft + Offset((file + 0.5) * cell, (7 - rank + 0.5) * cell);
  }

  final g = await tester.startGesture(at(from));
  await tester.pump(const Duration(milliseconds: 20));
  await g.moveTo(at(from) + const Offset(0, -12));
  await tester.pump(const Duration(milliseconds: 20));
  await g.moveTo(at(to));
  await tester.pump(const Duration(milliseconds: 20));
  await g.up();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: appDarkTheme,
      home: RetryScreen(
        gameId: 'g1',
        ply: 7,
        record: _record(),
        analyzer: _fake,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('the best move is the answer', (tester) async {
    await _open(tester);
    expect(find.text('What should you have played?'), findsWidgets);
    await _drag(tester, 'd2', 'd3');
    expect(find.text("That's the move!"), findsOneWidget);
  });

  testWidgets('a nearly as good move counts too', (tester) async {
    await _open(tester);
    await _drag(tester, 'c2', 'c3');
    expect(find.text("That's the move!"), findsOneWidget);
  });

  testWidgets('a bad move stays and another try is allowed', (
    tester,
  ) async {
    await _open(tester);
    await _drag(tester, 'a2', 'a3');
    expect(find.text('Not quite. Try again.'), findsOneWidget);
    expect(find.text("That's the move!"), findsNothing);

    await _drag(tester, 'd2', 'd3'); // a second try works
    expect(find.text("That's the move!"), findsOneWidget);
  });

  testWidgets('Show answer reveals it and offers the way back', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Show answer'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Show answer'), findsNothing);
    expect(find.text('Back'), findsWidgets);
  });

  testWidgets('a move that cannot be shown says so', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme,
        home: RetryScreen(
          gameId: 'g1',
          ply: 99,
          record: _record(),
          analyzer: _fake,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('This move cannot be shown.'), findsOneWidget);
  });
}
