import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:Kust/core/storage/app_storage.dart';
import 'package:Kust/features/puzzles/puzzle_data.dart';

class PuzzleProgress {
  const PuzzleProgress({
    this.solved = const {},
    this.attempted = const {},
    this.rating = 1000,
    this.highest = 1000,
  });

  final Set<String> solved;
  final Set<String> attempted;
  final int rating;
  final int highest;

  int get attempts => attempted.length;

  bool isSolved(String puzzleId) => solved.contains(puzzleId);
}

class PuzzleProgressStore {
  PuzzleProgressStore._();
  static final PuzzleProgressStore instance = PuzzleProgressStore._();

  static const int _startRating = 1000;
  static const double _kFactor = 32;

  Box<dynamic> get _box => Hive.box(AppStorage.puzzleBoxName);

  String get _key => 'progress_${AppStorage.instance.guestId}';

  ValueListenable<Box<dynamic>> listenable() => _box.listenable(keys: [_key]);

  PuzzleProgress load() {
    final raw = _box.get(_key);
    if (raw is! Map) {
      return const PuzzleProgress(
        rating: _startRating,
        highest: _startRating,
      );
    }
    return PuzzleProgress(
      solved: _ids(raw['solved']),
      attempted: _ids(raw['attempted']),
      rating: (raw['rating'] as int?) ?? _startRating,
      highest: (raw['highest'] as int?) ?? _startRating,
    );
  }

  Future<void> recordMistake(PuzzleEntry puzzle) {
    return _record(puzzle, won: false, solved: false);
  }

  Future<void> recordSolved(PuzzleEntry puzzle, {required bool clean}) {
    return _record(puzzle, won: clean, solved: true);
  }

  Future<void> _record(
    PuzzleEntry puzzle, {
    required bool won,
    required bool solved,
  }) async {
    final current = load();
    var rating = current.rating;
    var highest = current.highest;
    final attempted = {...current.attempted};

    if (!attempted.contains(puzzle.id)) {
      rating = _nextRating(rating, puzzle.rating, won);
      highest = math.max(highest, rating);
      attempted.add(puzzle.id);
    }

    final nowSolved = solved ? {...current.solved, puzzle.id} : current.solved;

    await _box.put(_key, {
      'solved': nowSolved.toList(),
      'attempted': attempted.toList(),
      'rating': rating,
      'highest': highest,
    });
  }

  int _nextRating(int rating, int puzzleRating, bool won) {
    final expected = 1 / (1 + math.pow(10, (puzzleRating - rating) / 400));
    final score = won ? 1.0 : 0.0;
    final next = rating + (_kFactor * (score - expected)).round();
    return math.max(0, next);
  }

  Set<String> _ids(Object? value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }
}
