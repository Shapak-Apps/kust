import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';
import 'package:kust/features/history/history_analysis.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/theme.dart';
import 'package:kust/ui/kust_controls.dart';

GameRecord _game(
  String id,
  int at,
  String result, {
  double? accuracy,
  bool practice = false,
}) => GameRecord(
  id: id,
  playedAt: at,
  isLocal: false,
  result: result,
  reason: '',
  playerIsWhite: true,
  uciMoves: const ['e2e4', 'e7e5'],
  sanMoves: const ['e4', 'e5'],
  botId: 'karl',
  botName: 'Karl',
  botElo: 1000,
  accuracy: accuracy,
  practice: practice,
);

void main() {
  late Directory dir;
  late Box<dynamic> box;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_history_ui');
    Hive.init(dir.path);
    box = await Hive.openBox(AppStorage.historyBoxName);
    final store = GameHistoryStore.instance;
    await store.add(_game('a', 3, GameRecord.win, accuracy: 71.6));
    await store.add(_game('b', 2, GameRecord.loss));
    await store.add(_game('c', 1, GameRecord.draw, practice: true));
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets('games are flat rows with edge-to-edge hairlines', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: HistoryScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Karl'), findsNWidgets(3));
    // No cards at all, and no summary block.
    expect(find.byType(KustCard), findsNothing);
    expect(find.text('Wins'), findsNothing);
    expect(find.text('Win rate'), findsNothing);

    // Hairlines between the 3 rows, running across the whole screen.
    final dividers = find.byType(Divider);
    expect(dividers, findsNWidgets(2));
    final rect = tester.getRect(dividers.first);
    expect(rect.left, 0);
    expect(rect.width, 400);

    // The content is padded inside the row instead.
    final avatarOrIcon = tester.getTopLeft(
      find.byIcon(Icons.hourglass_empty_rounded).first,
    );
    expect(avatarOrIcon.dx, greaterThanOrEqualTo(20));
  });

  testWidgets('rows show no move count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: HistoryScreen()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('moves'), findsNothing);
    expect(find.textContaining('Today'), findsNothing); // old dates
    expect(find.textContaining('Practice'), findsOneWidget);
  });

  testWidgets('shows a result badge and the accuracy of each game', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: HistoryScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('+'), findsOneWidget);
    expect(find.text('\u2212'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('71.6%'), findsOneWidget);
    expect(find.text('(1000)'), findsNWidgets(3));
  });

  testWidgets('Analyze runs the analysis and then shows the accuracy', (
    tester,
  ) async {
    final long = GameRecord(
      id: 'long',
      playedAt: 4,
      isLocal: false,
      result: GameRecord.win,
      reason: '',
      playerIsWhite: true,
      uciMoves: const [
        'e2e4',
        'e7e5',
        'g1f3',
        'b8c6',
        'f1c4',
        'g8f6',
        'd2d3',
        'd7d6',
      ],
      sanMoves: const [],
      botName: 'Karl',
      botElo: 1000,
    );
    // Hive does real file IO, which needs the real event loop.
    await tester.runAsync(() => GameHistoryStore.instance.add(long));

    final saved = HistoryAnalysis.instance;
    addTearDown(() => HistoryAnalysis.instance = saved);
    final savedAccuracy = <String, double>{};
    HistoryAnalysis.instance = HistoryAnalysis(
      save: (id, value) async => savedAccuracy[id] = value,
      analyzer: GameAnalyzer(
        analyze: ({
          required beforeFen,
          required playedUci,
          required afterFen,
          required thinkTime,
          isStale,
        }) async => const MoveAnalysis(bestUci: 'a', bestCp: 0, playedCp: 0),
      ),
      tick: const Duration(milliseconds: 5),
      finishHold: const Duration(milliseconds: 5),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: HistoryScreen()),
      ),
    );
    await tester.pump();

    // Only the long, unanalyzed bot game offers the button, as an icon.
    expect(find.text('Analyze'), findsNothing);
    expect(find.byIcon(Icons.insights_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.insights_rounded));
    await tester.pump();
    // Let the paced percentage run and the finish hold pass (fake time).
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    expect(savedAccuracy['long'], closeTo(100, 0.01));
    // Back to idle after saving.
    expect(HistoryAnalysis.instance.stateFor('long').value, isNull);
  });

  test('box is the one the screen reads', () {
    expect(box.name, AppStorage.historyBoxName);
  });
}
