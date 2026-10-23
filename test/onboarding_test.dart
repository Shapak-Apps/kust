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

    testWidgets('requires a level before continuing, and can skip', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      expect(find.text('Chess that helps you improve'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(find.text('How strong are you?'), findsOneWidget);

      // Continue is disabled until a level is chosen.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('How strong are you?'), findsOneWidget);

      await tester.tap(find.text('Advanced'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Your starting rating is 1600.'), findsNothing);
      expect(find.textContaining('starting rating is 1600'), findsOneWidget);
    });

    testWidgets('back returns to the previous step', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Chess that helps you improve'), findsOneWidget);
    });

    testWidgets('skip goes to the final step with the default rating', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      expect(find.textContaining('starting rating is 1200'), findsOneWidget);
    });
  });
}
