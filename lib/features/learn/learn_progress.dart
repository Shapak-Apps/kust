import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/learn/lessons.dart';

/// Which lessons the player has finished, and how well (1 to 3 stars), kept
/// on the phone.
class LearnProgress {
  LearnProgress._();

  static final LearnProgress instance = LearnProgress._();

  static const String _key = 'learn_done';
  static const String _starsKey = 'learn_stars';

  /// The ids of the finished lessons.
  final ValueNotifier<Set<String>> done = ValueNotifier(const {});

  /// The best stars earned in each finished lesson.
  final Map<String, int> _stars = {};

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in prefs.getStringList(_starsKey) ?? const <String>[]) {
      final parts = entry.split(':');
      if (parts.length == 2) _stars[parts[0]] = int.tryParse(parts[1]) ?? 1;
    }
    done.value = {...?prefs.getStringList(_key)};
  }

  /// The stars of lesson [id]: 0 when not finished.
  int starsOf(String id) =>
      done.value.contains(id) ? (_stars[id] ?? 1).clamp(1, 3) : 0;

  /// The stars of every finished lesson, by id.
  Map<String, int> get stars => {
    for (final l in kLessons)
      if (done.value.contains(l.id)) l.id: starsOf(l.id),
  };

  /// All the stars earned so far.
  int get totalStars => kLessons.fold(0, (sum, l) => sum + starsOf(l.id));

  /// Stars for a run of a lesson: three when nothing went wrong, two after a
  /// slip or two, one otherwise.
  static int starsFor({required int mistakes, required int hints}) {
    final slips = mistakes + hints;
    if (slips == 0) return 3;
    if (slips <= 2) return 2;
    return 1;
  }

  Future<void> complete(String id, {int stars = 1}) async {
    final best = stars > (_stars[id] ?? 0) ? stars : _stars[id]!;
    _stars[id] = best;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_starsKey, [
      for (final e in _stars.entries) '${e.key}:${e.value}',
    ]);
    if (!done.value.contains(id)) {
      done.value = {...done.value, id};
      await prefs.setStringList(_key, done.value.toList());
    } else {
      // Same set, new stars: tell the listeners anyway.
      done.value = {...done.value};
    }
  }

  /// The first lesson not finished yet, or null when all are.
  Lesson? get next {
    for (final lesson in kLessons) {
      if (!done.value.contains(lesson.id)) return lesson;
    }
    return null;
  }

  /// The lesson after [id], or null for the last one.
  Lesson? after(String id) {
    final i = kLessons.indexWhere((l) => l.id == id);
    return i < 0 || i + 1 >= kLessons.length ? null : kLessons[i + 1];
  }
}
