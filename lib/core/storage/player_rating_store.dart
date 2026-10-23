import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/storage/app_storage.dart';

/// The player's own Elo-style rating, updated after rated bot games.
class PlayerRatingStore {
  PlayerRatingStore._() : _boxOverride = null;

  @visibleForTesting
  PlayerRatingStore.withBox(Box<dynamic> box) : _boxOverride = box;

  static final PlayerRatingStore instance = PlayerRatingStore._();

  static const int startRating = 1200;
  static const int minRating = 100;
  static const double kFactor = 32;
  static const String _key = 'player_rating';

  final Box<dynamic>? _boxOverride;

  Box<dynamic> get _box => _boxOverride ?? Hive.box(AppStorage.userBoxName);

  ValueListenable<Box<dynamic>> listenable() => _box.listenable(keys: [_key]);

  int get rating {
    final value = _box.get(_key);
    return value is int ? value : startRating;
  }

  /// Sets the starting rating, e.g. from the level chosen in onboarding.
  Future<void> setStartingRating(int value) =>
      _box.put(_key, math.max(minRating, value));

  /// Rating change for [score] (1 win, 0.5 draw, 0 loss) against a bot.
  static int delta({
    required int rating,
    required int opponent,
    required double score,
  }) {
    final expected = 1 / (1 + math.pow(10, (opponent - rating) / 400));
    return (kFactor * (score - expected)).round();
  }

  /// Applies a result and returns the change that was actually applied.
  Future<int> record({required int opponent, required double score}) async {
    final current = rating;
    final next = math.max(
      minRating,
      current + delta(rating: current, opponent: opponent, score: score),
    );
    await _box.put(_key, next);
    return next - current;
  }
}
