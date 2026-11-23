import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/learn/lesson_moments.dart';

Position _after(String fen, String uci) =>
    Chess.fromSetup(Setup.parseFen(fen)).play(NormalMove.fromUci(uci));

void main() {
  test('the rook giving check arrives from the far end of its rank', () {
    final p = Chess.fromSetup(Setup.parseFen('4r2k/8/8/8/8/8/8/4K3 w - - 0 1'));
    expect(checkArrival(p), (from: Square.a8, to: Square.e8));
  });

  test('a knight giving check arrives from a knight jump away', () {
    final p = Chess.fromSetup(
      Setup.parseFen('7k/8/8/8/8/5n2/6P1/4K3 w - - 0 1'),
    );
    final a = checkArrival(p)!;
    expect(a.to, Square.f3);
    expect(
      attacks(
        const Piece(color: Side.black, role: Role.knight),
        a.from,
        SquareSet.empty,
      ).has(Square.f3),
      isTrue,
    );
  });

  test('no arrival when nobody gives check', () {
    expect(checkArrival(Chess.initial), isNull);
  });

  test('a fork points at both pieces', () {
    final after = _after('r3k3/8/8/1N6/8/8/8/4K3 w - - 0 1', 'b5c7');
    expect(
      tacticArrows(after, Square.c7, throughLine: false).map((a) => a.to),
      unorderedEquals([Square.a8, Square.e8]),
    );
  });

  test('a pin points through the knight to the king', () {
    final after = _after('4k3/8/2n5/8/8/8/8/5BK1 w - - 0 1', 'f1b5');
    expect(tacticArrows(after, Square.b5, throughLine: true), [
      (from: Square.b5, to: Square.e8),
    ]);
  });

  test('a skewer points through the king to the queen', () {
    final after = _after('4q3/8/8/4k3/8/8/7K/R7 w - - 0 1', 'a1e1');
    expect(tacticArrows(after, Square.e1, throughLine: true), [
      (from: Square.e1, to: Square.e8),
    ]);
  });
}
