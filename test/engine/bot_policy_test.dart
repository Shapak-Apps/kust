import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/bot_policy.dart';

void main() {
  test('weaker bots blunder more and think for less time', () {
    final weak = BotPolicy(elo: 400, seed: 1);
    final mid = BotPolicy(elo: 1000, seed: 1);
    final strong = BotPolicy(elo: 2000, seed: 1);

    expect(weak.blunderChance, greaterThan(mid.blunderChance));
    expect(mid.blunderChance, greaterThan(strong.blunderChance));
    expect(weak.thinkTime, lessThan(strong.thinkTime));
  });

  test('engine strength is clamped to the range Stockfish supports', () {
    expect(BotPolicy(elo: 400).uciElo, 1320);
    expect(BotPolicy(elo: 2000).uciElo, 2000);
    expect(BotPolicy(elo: 5000).uciElo, 3190);
  });

  test('random blunders are always legal moves', () {
    final policy = BotPolicy(elo: 400, seed: 7);
    var position = Chess.initial as Position;
    for (var i = 0; i < 20 && !position.isGameOver; i++) {
      final move = policy.randomLegalMove(position);
      expect(move, isNotNull);
      expect(position.isLegal(move!), isTrue);
      position = position.play(move);
    }
  });
}
