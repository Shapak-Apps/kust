import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/accuracy.dart';

void main() {
  test('winPercent is 50 for equal, rises with advantage and is symmetric', () {
    expect(winPercent(0), closeTo(50, 0.001));
    expect(winPercent(200), greaterThan(winPercent(100)));
    expect(winPercent(300) + winPercent(-300), closeTo(100, 0.001));
    expect(winPercent(100000), closeTo(97.5, 1)); // mate scores are capped
    expect(winPercent(-100000), closeTo(2.5, 1));
  });

  test('playing the best move is (nearly) perfectly accurate', () {
    expect(moveAccuracy(bestCp: 50, playedCp: 50), closeTo(100, 0.01));
    // Played a move that is even better than the search found: no penalty.
    expect(moveAccuracy(bestCp: 50, playedCp: 80), closeTo(100, 0.01));
  });

  test('accuracy falls as more winning chance is thrown away', () {
    final small = moveAccuracy(bestCp: 100, playedCp: 50);
    final big = moveAccuracy(bestCp: 100, playedCp: -200);
    final blunder = moveAccuracy(bestCp: 300, playedCp: -600);
    expect(small, greaterThan(big));
    expect(big, greaterThan(blunder));
    expect(blunder, inInclusiveRange(0, 25));
  });

  test('always stays between 0 and 100', () {
    for (final best in [-100000, -500, 0, 500, 100000]) {
      for (final played in [-100000, -500, 0, 500, 100000]) {
        final a = moveAccuracy(bestCp: best, playedCp: played);
        expect(a, inInclusiveRange(0, 100), reason: '$best $played');
      }
    }
  });

  test('a steady game scores what each move scored; empty is null', () {
    expect(gameAccuracy([80, 80, 80]), closeTo(80, 0.0001));
    expect(gameAccuracy([]), isNull);
  });

  test('a few awful moves drag a game down, unlike a plain average', () {
    // 20 fine moves and 3 blunders: a plain average would say 84.
    final moves = [...List.filled(20, 95.0), 10.0, 10.0, 10.0];
    final plain = moves.reduce((a, b) => a + b) / moves.length;
    expect(plain, greaterThan(80));
    expect(gameAccuracy(moves)!, lessThan(68));
  });

  test('a lost game played badly does not look accurate', () {
    // Blunders early lose the game; after that every move costs little
    // winning chance and scores high on its own.
    final moves = [
      90.0, 85.0, 20.0, 15.0, // the game goes
      ...List.filled(12, 97.0), // hopeless moves cost nothing more
    ];
    final chances = [55.0, 50.0, 20.0, 5.0, ...List.filled(12, 2.0)];
    final plain = moves.reduce((a, b) => a + b) / moves.length;
    final game = gameAccuracy(moves, winPercents: chances)!;
    expect(plain, greaterThan(80));
    expect(game, lessThan(70));
  });
}
