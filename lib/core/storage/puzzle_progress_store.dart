import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';

class PuzzleProgress {
  const PuzzleProgress({
    this.solved = const {},
    this.attempted = const {},
    this.revealed = const {},
    this.rating = 1000,
    this.highest = 1000,
  });

  final Set<String> solved;
  final Set<String> attempted;

  /// Puzzles whose solution was shown. Tracked apart from [solved]; a puzzle
  /// can be in both if it was later solved after a retry.
  final Set<String> revealed;
  final int rating;
  final int highest;

  int get attempts => attempted.length;

  bool isSolved(String puzzleId) => solved.contains(puzzleId);

  /// Revealed and never solved by the user.
  bool isRevealed(String puzzleId) =>
      revealed.contains(puzzleId) && !solved.contains(puzzleId);

  /// Solved or revealed, i.e. the user has moved past it.
  bool isCompleted(String puzzleId) =>
      solved.contains(puzzleId) || revealed.contains(puzzleId);
}

class PuzzleProgressStore {
  PuzzleProgressStore._() : _boxOverride = null, _userIdOverride = null;

  /// Builds a store over an arbitrary box, for tests.
  @visibleForTesting
  PuzzleProgressStore.withBox(Box<dynamic> box, {String userId = 'test'})
    : _boxOverride = box,
      _userIdOverride = userId;

  static final PuzzleProgressStore instance = PuzzleProgressStore._();

  final Box<dynamic>? _boxOverride;
  final String? _userIdOverride;

  static const int _startRating = 1000;
  static const double _kFactor = 32;

  Box<dynamic> get _box => _boxOverride ?? Hive.box(AppStorage.puzzleBoxName);

  String get _key =>
      'progress_${_userIdOverride ?? AppStorage.instance.guestId}';

  ValueListenable<Box<dynamic>> listenable() => _box.listenable(keys: [_key]);

  PuzzleProgress load() {
    final raw = _box.get(_key);
    if (raw is! Map) {
      return const PuzzleProgress(rating: _startRating, highest: _startRating);
    }
    return PuzzleProgress(
      solved: _ids(raw['solved']),
      attempted: _ids(raw['attempted']),
      revealed: _ids(raw['revealed']),
      rating: raw['rating'] is int ? raw['rating'] as int : _startRating,
      highest: raw['highest'] is int ? raw['highest'] as int : _startRating,
    );
  }

  Future<void> recordMistake(PuzzleEntry puzzle) {
    return _record(puzzle, won: false);
  }

  Future<void> recordSolved(PuzzleEntry puzzle, {required bool clean}) {
    return _record(puzzle, won: clean, solved: true);
  }

  /// The solution was shown. Counts as a failed first attempt and is stored
  /// separately from solved puzzles.
  Future<void> recordRevealed(PuzzleEntry puzzle) {
    return _record(puzzle, won: false, revealed: true);
  }

  Future<void> _record(
    PuzzleEntry puzzle, {
    required bool won,
    bool solved = false,
    bool revealed = false,
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

    final nowRevealed = revealed
        ? {...current.revealed, puzzle.id}
        : current.revealed;

    await _box.put(_key, {
      'solved': nowSolved.toList(),
      'revealed': nowRevealed.toList(),
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
