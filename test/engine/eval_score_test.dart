import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/chess_engine.dart';

void main() {
  test('after checkmate the bar shows the result on the winner side', () {
    const white = EvalScore(mate: 1, result: '1-0');
    expect(white.whiteShare, 1.0);
    expect(white.label, '1-0');
    const black = EvalScore(mate: -1, result: '0-1');
    expect(black.whiteShare, 0.0);
    expect(black.label, '0-1');
  });
}
