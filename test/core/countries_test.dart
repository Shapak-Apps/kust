import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/countries.dart';

void main() {
  test('every country has its flag, and the flags carry their licence', () {
    expect(kCountries.length, greaterThan(240));
    for (final code in kCountries.keys) {
      expect(File(flagAsset(code)).existsSync(), isTrue, reason: code);
    }
    expect(kCountries['TM'], 'Turkmenistan');
    expect(File('assets/flags/LICENSE.txt').existsSync(), isTrue);
  });
}
