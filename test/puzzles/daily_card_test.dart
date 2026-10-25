import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/puzzles/daily.dart';
import 'package:kust/features/puzzles/daily_card.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/theme.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_daily_card');
    Hive.init(dir.path);
    await Hive.openBox(AppStorage.userBoxName);
    await Hive.openBox(AppStorage.puzzleBoxName);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets('shows today\'s puzzle, then the streak once solved', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: DailyPuzzleCard()),
      ),
    );
    for (var i = 0; i < 50; i++) {
      if (find.text('Daily puzzle').evaluate().isNotEmpty) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('Daily puzzle'), findsOneWidget);

    final levels = (await tester.runAsync(
      () => Future.wait([
        for (var n = 1; n <= 5; n++) PuzzleRepository.instance.loadLevel(n),
      ]),
    ))!;
    final pick = dailyPuzzle(levels, DateTime.now())!;
    expect(find.textContaining('${pick.puzzle.rating}'), findsOneWidget);

    await tester.runAsync(() => DailyStore.instance.markSolved(DateTime.now()));
    await tester.pump();
    expect(find.text('Solved today'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
  });
}
