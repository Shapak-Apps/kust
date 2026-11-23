import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/train/train_openings.dart';
import 'package:kust/l10n/app_locale.dart';

import 'dart:ui' show Locale;

void main() {
  test('every line is legal from the start, three lines at most', () {
    final ids = <String>{};
    for (final o in kTrainOpenings) {
      expect(ids.add(o.id), isTrue, reason: 'duplicate id ${o.id}');
      expect(o.lines, isNotEmpty, reason: o.id);
      expect(o.lines.length, lessThanOrEqualTo(3), reason: o.id);
      for (final line in o.lines) {
        Position p = Chess.initial;
        for (final san in line.san) {
          final move = p.parseSan(san);
          expect(move, isNotNull, reason: '${o.id} ${line.en}: $san');
          p = p.play(move!);
        }
        expect(line.uci.length, line.san.length);
        expect(p.isGameOver, isFalse, reason: '${o.id} ${line.en}');
      }
    }
  });

  test('castling is kept as king takes rook, as saved games want it', () {
    final italian = kTrainOpenings.firstWhere((o) => o.id == 'italian');
    expect(italian.lines.first.uci, contains('e1h1'));
  });

  test('every opening has a description and an origin in each language', () {
    for (final code in ['en', 'ru', 'tk']) {
      final t = lookupAppL10n(Locale(code));
      for (final o in kTrainOpenings) {
        expect(o.descriptionIn(t), isNotEmpty, reason: '${o.id} $code');
        expect(o.originIn(t), isNotEmpty, reason: '${o.id} $code');
      }
    }
    final ru = lookupAppL10n(const Locale('ru'));
    final london = kTrainOpenings.firstWhere((o) => o.id == 'london');
    expect(london.originIn(ru), 'Лондонский турнир, 1922');
  });
}
