import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Keeps the last few errors, in memory and in a file on the phone, so a
/// crash can still be reported after the app restarts. Nothing leaves the
/// device unless the player shares a report.
class ErrorLog {
  ErrorLog._();

  static const int capacity = 20;
  static const String _gap = '\n---\n';
  static final List<String> entries = [];
  static File? _file;

  /// Optional hook, e.g. a crash reporter.
  static void Function(Object error, StackTrace? stack)? reporter;

  /// Loads the errors kept from earlier runs. Without it the log is memory only.
  static Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      _file = File('${dir.path}/errors.log');
      if (await _file!.exists()) {
        final old = (await _file!.readAsString()).split(_gap);
        entries.insertAll(0, old.where((e) => e.trim().isNotEmpty));
        _trim();
      }
    } catch (_) {
      _file = null;
    }
  }

  static void record(Object error, StackTrace? stack) {
    final where = stack?.toString().split('\n').take(8).join('\n') ?? '';
    entries.add('${DateTime.now().toIso8601String()} $error\n$where'.trim());
    _trim();
    _file?.writeAsString(entries.join(_gap)).ignore();
    if (kDebugMode) debugPrint('ErrorLog: $error\n$stack');
    reporter?.call(error, stack);
  }

  static void _trim() {
    if (entries.length > capacity) {
      entries.removeRange(0, entries.length - capacity);
    }
  }

  /// The text a player sends us: the phone's system and the kept errors.
  static String report() => [
    'Küşt error report',
    '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    if (entries.isEmpty) 'No errors recorded.' else ...entries,
  ].join(_gap);
}
