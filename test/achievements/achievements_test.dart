import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/features/achievements/achievement_toast.dart';
import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/features/achievements/achievements_screen.dart';
import 'package:kust/features/play/pick_time_modal.dart';
import 'package:kust/theme.dart';

GameFacts _facts({
  bool won = true,
  bool mate = true,
  int playerMoves = 30,
  int totalMoves = 30,
  int botElo = 1200,
  int rating = 1200,
  int beaten = 1,
}) => GameFacts(
  won: won,
  byCheckmate: mate,
  playerMoves: playerMoves,
  totalMoves: totalMoves,
  botElo: botElo,
  playerRating: rating,
  botsBeaten: beaten,
  botCount: 9,
);

void main() {
  test('ids are unique and every rule names a real achievement', () {
    final ids = kAchievements.map((a) => a.id).toSet();
    expect(ids.length, kAchievements.length);
    final all = {
      ...earnedByGame(
        _facts(playerMoves: 10, totalMoves: 70, botElo: 2000, beaten: 9),
      ),
      ...earnedByAccuracy(95),
      ...earnedByPuzzles(solved: 30, levelsWoven: 5, levelCount: 5),
      ...earnedByStreak(8),
      'brilliant',
    };
    expect(ids, all);
  });

  test('a game earns what it shows', () {
    expect(earnedByGame(_facts(won: false, mate: false)), {'first_game'});
    expect(earnedByGame(_facts()), {'first_game', 'first_win', 'checkmate'});
    expect(earnedByGame(_facts(playerMoves: 20)), contains('quick_mate'));
    expect(
      earnedByGame(_facts(playerMoves: 21)),
      isNot(contains('quick_mate')),
    );
    expect(earnedByGame(_facts(botElo: 1500)), contains('giant_slayer'));
    expect(earnedByGame(_facts(botElo: 1499)), isNot(contains('giant_slayer')));
    expect(
      earnedByGame(_facts(won: false, botElo: 2000)),
      isNot(contains('giant_slayer')),
    );
    expect(earnedByGame(_facts(beaten: 3)), contains('three_bots'));
    expect(earnedByGame(_facts(beaten: 9)), contains('all_bots'));
    expect(earnedByGame(_facts(totalMoves: 60)), contains('marathon'));
  });

  test('accuracy, puzzles and streaks have their thresholds', () {
    expect(earnedByAccuracy(89.9), isEmpty);
    expect(earnedByAccuracy(90), {'accurate'});
    expect(earnedByPuzzles(solved: 0, levelsWoven: 0, levelCount: 5), isEmpty);
    expect(earnedByPuzzles(solved: 25, levelsWoven: 1, levelCount: 5), {
      'first_puzzle',
      'puzzles_25',
      'first_gol',
    });
    expect(earnedByStreak(2), isEmpty);
    expect(earnedByStreak(3), {'streak_3'});
    expect(earnedByStreak(7), {'streak_3', 'streak_7'});
  });

  group('with storage', () {
    late Directory dir;
    late AchievementStore saved;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('kust_achievements');
      Hive.init(dir.path);
      saved = AchievementStore.instance;
      AchievementStore.instance = AchievementStore.withBox(
        await Hive.openBox('achievements_test'),
      );
    });

    tearDown(() async {
      AchievementStore.instance = saved;
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('unlocks once, remembers when, and announces the new one', () async {
      final store = AchievementStore.instance;
      final fresh = await store.unlock({'first_game', 'first_win'});
      expect(fresh.map((a) => a.id), ['first_game', 'first_win']);
      expect(store.justUnlocked.value?.id, 'first_game');
      store.justUnlocked.value = null;

      expect(await store.unlock({'first_game'}), isEmpty);
      expect(store.justUnlocked.value, isNull);
      expect(store.unlocked().keys, {'first_game', 'first_win'});
      expect(await store.unlock({'not_a_thing'}), isEmpty);
    });

    testWidgets('the list shows earned and locked achievements', (
      tester,
    ) async {
      await tester.runAsync(
        () => AchievementStore.instance.unlock({'first_puzzle'}),
      );
      AchievementStore.instance.justUnlocked.value = null;
      await tester.pumpWidget(
        MaterialApp(theme: appTheme, home: const AchievementsScreen()),
      );
      expect(find.text('1 of ${kAchievements.length} earned'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Puzzler'), 200);
      bool earned(String title) => tester
          .widget<AchievementTile>(
            find.ancestor(
              of: find.text(title),
              matching: find.byType(AchievementTile),
            ),
          )
          .earned;
      expect(earned('Puzzler'), isTrue);
      expect(earned('Knot by knot'), isFalse);
    });

    testWidgets('an unlock slides a banner in, then away', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: const AchievementToastHost(child: Scaffold()),
        ),
      );
      AchievementStore.instance.justUnlocked.value = achievementById(
        'checkmate',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Achievement unlocked'), findsOneWidget);
      expect(find.text('Checkmate!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 400));
      final opacity = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.byType(AchievementBanner),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(opacity.opacity.value, 0);
    });
  });

  testWidgets('time controls fit their text at a large font size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PickTimeControlModal(onPick: (_) {}),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('3+2'), findsOneWidget);
  });
}
