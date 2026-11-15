import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/l10n/app_locale.dart';

/// Self-assessed experience. It seeds the player's starting rating so the
/// first games are not wildly mismatched.
enum OnboardingLevel {
  beginner(icon: Icons.school_outlined, startingRating: 800),
  intermediate(icon: Icons.trending_up_rounded, startingRating: 1200),
  advanced(icon: Icons.psychology_outlined, startingRating: 1600),
  competitive(icon: Icons.emoji_events_outlined, startingRating: 1900);

  const OnboardingLevel({required this.icon, required this.startingRating});

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
