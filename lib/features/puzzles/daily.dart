import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';

/// The puzzle of the day: one of the bundled puzzles, the same for everyone.
class DailyPick {
  const DailyPick(this.level, this.index, this.puzzle);

  /// The level number, counting from 1, and the puzzle's place in it.
  final int level;
  final int index;
  final PuzzleEntry puzzle;
}

/// Picks the daily puzzle for [day] from every puzzle there is. Walks the
/// levels in order, so the pick changes every day and cycles through all of
/// them. Returns null when there are no puzzles at all.
DailyPick? dailyPuzzle(List<PuzzleLevel?> levels, DateTime day) {
  final total = levels.fold<int>(0, (n, l) => n + (l?.puzzles.length ?? 0));
  if (total == 0) return null;
  var at = _dayNumber(day) % total;
  for (final level in levels) {
    final puzzles = level?.puzzles ?? const <PuzzleEntry>[];
    if (at < puzzles.length) {
      return DailyPick(level!.level, at, puzzles[at]);
    }
    at -= puzzles.length;
  }
  return null;
}

/// Days since 1970-01-01 of the calendar day [d] falls on, in its own zone.
int _dayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Days in a row on which the daily puzzle was solved.
@immutable
class DailyStreak {
  const DailyStreak({this.last, this.length = 0, this.best = 0});

  /// The last day it was solved, as `yyyy-mm-dd`.
  final String? last;
  final int length;
  final int best;

  bool doneOn(DateTime day) => last == _dayKey(day);

  /// The streak as it stands on [today]: it is kept while yesterday's puzzle
  /// was solved, and gone after a day was missed.
  int on(DateTime today) {
    final l = last;
    if (l == null) return 0;
    final parts = l.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return 0;
    final gap =
        _dayNumber(today) -
        _dayNumber(DateTime(parts[0]!, parts[1]!, parts[2]!));
    return gap == 0 || gap == 1 ? length : 0;
  }

  /// The streak after the puzzle of [day] is solved.
  DailyStreak solvedOn(DateTime day) {
    if (doneOn(day)) return this;
    final next = on(day) + 1;
    return DailyStreak(
      last: _dayKey(day),
      length: next,
      best: next > best ? next : best,
    );
  }
}

/// The part of the streak store the puzzle screen writes to.
abstract class DailyRecorder {
  Future<void> markSolved(DateTime day);
}

/// Keeps the streak of the player on this device.
class DailyStore implements DailyRecorder {
  DailyStore._() : _boxOverride = null, _userIdOverride = null;

  @visibleForTesting
  DailyStore.withBox(Box<dynamic> box, {String userId = 'test'})
    : _boxOverride = box,
      _userIdOverride = userId;

  static final DailyStore instance = DailyStore._();

  final Box<dynamic>? _boxOverride;
  final String? _userIdOverride;

  Box<dynamic> get _box => _boxOverride ?? Hive.box(AppStorage.puzzleBoxName);

  String get _key => 'daily_${_userIdOverride ?? AppStorage.instance.guestId}';

  ValueListenable<Box<dynamic>> listenable() => _box.listenable(keys: [_key]);

  DailyStreak load() {
    final raw = _box.get(_key);
    if (raw is! Map) return const DailyStreak();
    return DailyStreak(
      last: raw['last'] is String ? raw['last'] as String : null,
      length: raw['length'] is int ? raw['length'] as int : 0,
      best: raw['best'] is int ? raw['best'] as int : 0,
    );
  }

  @override
  Future<void> markSolved(DateTime day) async {
    final next = load().solvedOn(day);
    await _box.put(_key, {
      'last': next.last,
      'length': next.length,
      'best': next.best,
    });
  }
}
