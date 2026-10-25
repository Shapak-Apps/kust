import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/puzzles/daily.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/features/puzzles/puzzle_game_screen.dart';
import 'package:kust/theme.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';

class _Streak implements DailyRecorder {
  final days = <DateTime>[];

  @override
  Future<void> markSolved(DateTime day) async => days.add(day);
}

class _Recorder implements PuzzleProgressRecorder {
  @override
  PuzzleProgress load() => const PuzzleProgress();

  @override
  Future<void> recordMistake(PuzzleEntry puzzle) async {}

  @override
  Future<void> recordRevealed(PuzzleEntry puzzle) async {}

  @override
  Future<void> recordSolved(PuzzleEntry puzzle, {required bool clean}) async {}
}

PuzzleEntry _p(String id) =>
    PuzzleEntry(id: id, fen: '', moves: const [], rating: 1000);

PuzzleLevel _level(int n, int count) => PuzzleLevel(
  level: n,
  puzzles: [for (var i = 0; i < count; i++) _p('$n-$i')],
);

void main() {
  group('dailyPuzzle', () {
    final levels = [_level(1, 3), null, _level(3, 2)];

    test('is the same all day and changes the next day', () {
      final morning = dailyPuzzle(levels, DateTime(2026, 10, 25, 7));
      final night = dailyPuzzle(levels, DateTime(2026, 10, 25, 23, 59));
      final next = dailyPuzzle(levels, DateTime(2026, 10, 26, 7));
      expect(morning!.puzzle.id, night!.puzzle.id);
      expect(next!.puzzle.id, isNot(morning.puzzle.id));
    });

    test('cycles through every puzzle and maps back to its level', () {
      final seen = <String>{};
      for (var d = 0; d < 5; d++) {
        final pick = dailyPuzzle(levels, DateTime(2026, 3, 1 + d))!;
        expect(pick.puzzle.id, '${pick.level}-${pick.index}');
        seen.add(pick.puzzle.id);
      }
      expect(seen, {'1-0', '1-1', '1-2', '3-0', '3-1'});
    });

    test('is null with no puzzles', () {
      expect(dailyPuzzle(const [], DateTime(2026)), isNull);
      expect(dailyPuzzle([null, _level(2, 0)], DateTime(2026)), isNull);
    });
  });

  group('DailyStreak', () {
    final mon = DateTime(2026, 10, 26);
    final tue = DateTime(2026, 10, 27);
    final thu = DateTime(2026, 10, 29);

    test('grows one a day and counts a day only once', () {
      var s = const DailyStreak().solvedOn(mon);
      expect(s.on(mon), 1);
      expect(s.solvedOn(mon).length, 1);
      s = s.solvedOn(tue);
      expect(s.on(tue), 2);
      expect(s.doneOn(tue), isTrue);
      expect(s.doneOn(mon), isFalse);
    });

    test('is kept until the end of the next day, then lost', () {
      final s = const DailyStreak().solvedOn(mon).solvedOn(tue);
      expect(s.on(DateTime(2026, 10, 28)), 2);
      expect(s.on(thu), 0);
      final again = s.solvedOn(thu);
      expect(again.on(thu), 1);
      expect(again.best, 2);
    });

    test('works across a month and a year end', () {
      final s = const DailyStreak().solvedOn(DateTime(2026, 12, 31));
      expect(s.solvedOn(DateTime(2027, 1, 1)).length, 2);
    });
  });

  group('DailyStore', () {
    late Directory dir;
    late DailyStore store;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('kust_daily');
      Hive.init(dir.path);
      store = DailyStore.withBox(await Hive.openBox('daily_test'));
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('saves the streak', () async {
      expect(store.load().length, 0);
      await store.markSolved(DateTime(2026, 10, 26));
      await store.markSolved(DateTime(2026, 10, 27));
      final s = store.load();
      expect(s.length, 2);
      expect(s.best, 2);
      expect(s.doneOn(DateTime(2026, 10, 27)), isTrue);
    });
  });

  group('the daily puzzle on screen', () {
    late Directory dir;
    late _Streak store;

    setUp(() async {
      store = _Streak();
      // There is no audio plugin in tests.
      SoundService.instance.soundEnabled = false;
      dir = await Directory.systemTemp.createTemp('kust_daily_ui');
      Hive.init(dir.path);
    });

    tearDown(() async {
      SoundService.instance.soundEnabled = true;
      await Hive.close();
      await dir.delete(recursive: true);
    });

    Future<void> solve(WidgetTester tester, {required bool daily}) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: PuzzleGameScreen(
            level: 1,
            index: 0,
            daily: daily,
            dailyStore: store,
            progress: _Recorder(),
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
      tester
          .widget<PuzzleBoard>(find.byType(PuzzleBoard))
          .onMove(NormalMove.fromUci('e2f3'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Puzzle solved!'), findsOneWidget);
      // The save runs on real file I/O, and its steps are finished on the
      // test clock: let each side take turns.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump(const Duration(milliseconds: 40));
      }
    }

    testWidgets('solving it counts for the streak', (tester) async {
      await solve(tester, daily: true);
      expect(store.days, hasLength(1));
      expect(
        DateTime.now().difference(store.days.single).inSeconds,
        lessThan(60),
      );
    });

    testWidgets('solving any other puzzle does not', (tester) async {
      await solve(tester, daily: false);
      expect(store.days, isEmpty);
    });
  });
}
