import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/train/train_openings.dart';

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
}
