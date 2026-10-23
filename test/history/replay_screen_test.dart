import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/history/replay_screen.dart';
import 'package:kust/theme.dart';

const _game = GameRecord(
  id: 'g',
  playedAt: 0,
  isLocal: false,
  result: GameRecord.win,
  reason: '',
  playerIsWhite: true,
  uciMoves: ['e2e4', 'e7e5', 'g1f3', 'b8c6'],
  sanMoves: ['e4', 'e5', 'Nf3', 'Nc6'],
  botName: 'Karl',
  botElo: 1000,
);

Widget _app() => MaterialApp(
  theme: appTheme,
  home: const ReplayScreen(gameId: 'g', record: _game),
);

void main() {
  testWidgets('shows the game and steps through it', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('Start position'), findsOneWidget);
    expect(find.text('Move 0 of 4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(find.text('Move 1 of 4'), findsOneWidget);

    await tester.tap(find.text('2. Nf3'));
    await tester.pump();
    expect(find.text('Move 3 of 4'), findsOneWidget);
  });

  testWidgets('watch plays the game on its own, then stops at the end', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Move 1 of 4'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Move 2 of 4'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Move 4 of 4'), findsOneWidget);
    // Finished: back to the play icon and nothing left scheduled.
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Move 4 of 4'), findsOneWidget);
  });

  testWidgets('pause holds the position, 2x speeds it up', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('Speed 1x'));
    await tester.pump();
    expect(find.text('Speed 2x'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(milliseconds: 460));
    expect(find.text('Move 1 of 4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Move 1 of 4'), findsOneWidget);
  });

  testWidgets('play at the end starts over', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byIcon(Icons.last_page_rounded));
    await tester.pump();
    expect(find.text('Move 4 of 4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(find.text('Move 0 of 4'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
