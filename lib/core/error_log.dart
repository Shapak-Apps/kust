import 'package:flutter/foundation.dart';

/// Keeps the last few errors in memory so they can be shown or reported later.
/// Nothing leaves the device.
class ErrorLog {
  ErrorLog._();

  static const int capacity = 20;
  static final List<String> entries = [];

  /// Optional hook, e.g. a crash reporter.
  static void Function(Object error, StackTrace? stack)? reporter;

  static void record(Object error, StackTrace? stack) {
    entries.add('$error');
    if (entries.length > capacity) entries.removeAt(0);
    if (kDebugMode) debugPrint('ErrorLog: $error\n$stack');
    reporter?.call(error, stack);
  }
}
