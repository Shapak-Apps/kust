import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Message notices the player closed: for each friend, the last message id
/// closed. A notice stays in the list, read or not, until closed here; a
/// newer message from that friend brings it back.
class NoticeDismissals {
  NoticeDismissals._();

  static final NoticeDismissals instance = NoticeDismissals._();

  static const _key = 'dismissed_message_notices';

  final ValueNotifier<Map<String, int>> closed = ValueNotifier(const {});
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      closed.value = {
        for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries)
          e.key: (e.value as num).toInt(),
      };
    } catch (_) {
      // Nothing closed yet, then.
    }
  }

  bool isClosed(String username, int messageId) =>
      (closed.value[username] ?? -1) >= messageId;

  /// Closes the notices of these friends up to these message ids.
  void close(Map<String, int> upTo) {
    closed.value = {...closed.value, ...upTo};
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(closed.value));
    } catch (_) {
      // Kept in memory for this run.
    }
  }
}
