import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/learn/lessons.dart';

/// Which lessons the player has finished, kept on the phone.
class LearnProgress {
  LearnProgress._();

  static final LearnProgress instance = LearnProgress._();

  static const String _key = 'learn_done';

  /// The ids of the finished lessons.
  final ValueNotifier<Set<String>> done = ValueNotifier(const {});

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    done.value = {...?prefs.getStringList(_key)};
  }

  Future<void> complete(String id) async {
    if (done.value.contains(id)) return;
    done.value = {...done.value, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, done.value.toList());
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
