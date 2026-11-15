import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/error_log.dart';

void main() {
  test('keeps the last errors, with where they happened, for the report', () {
    ErrorLog.entries.clear();
    expect(ErrorLog.report(), contains('No errors recorded.'));
    for (var i = 0; i < ErrorLog.capacity + 5; i++) {
      ErrorLog.record('boom $i', StackTrace.current);
    }
    expect(ErrorLog.entries.length, ErrorLog.capacity);
    expect(ErrorLog.entries.first, contains('boom 5'));
    final report = ErrorLog.report();
    expect(report, contains('boom ${ErrorLog.capacity + 4}'));
    expect(report, contains('error_log_test.dart'));
  });
}
