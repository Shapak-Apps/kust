import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/onboarding/onboarding_level.dart';
import 'package:kust/features/onboarding/onboarding_screen.dart';
import 'package:kust/theme.dart';

void main() {
  group('completeOnboarding', () {
    late Directory dir;
    late PlayerRatingStore ratings;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('kust_onboarding_test');
      Hive.init(dir.path);
      ratings = PlayerRatingStore.withBox(await Hive.openBox('r'));
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('stores the level and seeds the starting rating', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await completeOnboarding(
        prefs: prefs,
        ratingStore: ratings,
        level: OnboardingLevel.advanced,
      );
      expect(prefs.getBool('onboarding_completed'), isTrue);
      expect(prefs.getString('chess_level'), 'advanced');
      expect(ratings.rating, 1600);
    });

    test('skipping keeps the default rating but still completes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await completeOnboarding(prefs: prefs, ratingStore: ratings);
      expect(prefs.getBool('onboarding_completed'), isTrue);
      expect(prefs.getString('chess_level'), isNull);
      expect(ratings.rating, PlayerRatingStore.startRating);
    });

    test('every level has a distinct, ordered starting rating', () {
      final ratings = [
        for (final l in OnboardingLevel.values) l.startingRating,
      ];
      expect(ratings.toSet().length, ratings.length);
      expect([...ratings]..sort(), ratings);
    });
  });

  group('OnboardingScreen', () {
    Widget app() =>
        MaterialApp(theme: appTheme, home: const OnboardingScreen());

    Future<void> toLevels(WidgetTester tester) async {
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(find.text('What should we call you?'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'Aýna');
      await tester.enterText(find.byType(TextField).at(1), 'Ayna_1');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks for a name and a valid username, then a level', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      expect(find.text('Chess that helps you improve'), findsOneWidget);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      // Continue is off until both are filled in, the username lowercased.
      await tester.enterText(find.byType(TextField).at(0), 'Aýna');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('What should we call you?'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'Ayna_1');
      await tester.pump();
      expect(find.text('ayna_1'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('How strong are you?'), findsOneWidget);

      await tester.ensureVisible(find.text('Advanced'));
      await tester.tap(find.text('Advanced'));
      await tester.pump();
      expect(find.text('Start playing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('back returns to the previous step', (tester) async {
      await tester.pumpWidget(app());
      await toLevels(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('What should we call you?'), findsOneWidget);
      // What was typed is still there.
      expect(find.text('ayna_1'), findsOneWidget);
    });

    testWidgets('a beginner is offered the first lesson', (tester) async {
      await tester.pumpWidget(app());
      await toLevels(tester);
      await tester.tap(find.text('Beginner'));
      await tester.pump();
      expect(find.text('Start the first lesson'), findsOneWidget);
    });
  });
}
