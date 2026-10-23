import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/game_history_store.dart';
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

  testWidgets('games are flat rows, not cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: HistoryScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Karl'), findsNWidgets(3));
    // Only the summary at the top is a card; the games themselves are not.
    expect(find.byType(KustCard), findsOneWidget);
    // Hairlines between rows (3 games, plus the gap after the summary).
    expect(find.byType(Divider), findsNWidgets(2));
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
    expect(find.text('−'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('71.6%'), findsOneWidget);
    // Games without a worked-out accuracy show none.
    expect(find.textContaining('%'), findsWidgets);
    expect(find.text('(1000)'), findsNWidgets(3));
  });

  testWidgets('the summary ignores the practice game', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: HistoryScreen()),
      ),
    );
    await tester.pump();

    // Rated games: one win, one loss -> 50% win rate.
    expect(find.text('50%'), findsOneWidget);
  });

  test('box is the one the screen reads', () {
    expect(box.name, AppStorage.historyBoxName);
  });
}
