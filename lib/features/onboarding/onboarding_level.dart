import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/l10n/app_locale.dart';

/// Self-assessed experience. It seeds the player's starting rating so the
/// first games are not wildly mismatched.
enum OnboardingLevel {
  beginner(
    title: 'Beginner',
    description: 'I’m just getting started with chess.',
    icon: Icons.school_outlined,
    startingRating: 800,
  ),
  intermediate(
    title: 'Intermediate',
    description: 'I know the basics and play regularly.',
    icon: Icons.trending_up_rounded,
    startingRating: 1200,
  ),
  advanced(
    title: 'Advanced',
    description: 'I understand strategy and complex positions.',
    icon: Icons.psychology_outlined,
    startingRating: 1600,
  ),
  competitive(
    title: 'Competitive',
    description: 'I play seriously and may compete in tournaments.',
    icon: Icons.emoji_events_outlined,
    startingRating: 1900,
  );

  const OnboardingLevel({
    required this.title,
    required this.description,
    required this.icon,
    required this.startingRating,
  });

  /// The English title and description; see [titleIn] and [descriptionIn].
  final String title;
  final String description;
  final IconData icon;

  String titleIn(AppL10n t) => switch (this) {
    OnboardingLevel.beginner => t.lvlBeginner,
    OnboardingLevel.intermediate => t.lvlIntermediate,
    OnboardingLevel.advanced => t.lvlAdvanced,
    OnboardingLevel.competitive => t.lvlCompetitive,
  };

  String descriptionIn(AppL10n t) => switch (this) {
    OnboardingLevel.beginner => t.lvlBeginnerD,
    OnboardingLevel.intermediate => t.lvlIntermediateD,
    OnboardingLevel.advanced => t.lvlAdvancedD,
    OnboardingLevel.competitive => t.lvlCompetitiveD,
  };
  final int startingRating;
}

/// Marks onboarding as done and applies the chosen level. With no [level]
/// (the user skipped) the default rating is left alone.
Future<void> completeOnboarding({
  required SharedPreferences prefs,
  required PlayerRatingStore ratingStore,
  OnboardingLevel? level,
}) async {
  if (level != null) {
    await prefs.setString('chess_level', level.name);
    await ratingStore.setStartingRating(level.startingRating);
  }
  await prefs.setBool('onboarding_completed', true);
}
