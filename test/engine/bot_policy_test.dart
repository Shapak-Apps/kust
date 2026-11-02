import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/bot_policy.dart';

/// A position with one best move and others from a little to much worse.
const _candidates = [
  CandidateMove('best', 50),
  CandidateMove('ok', 20),
  CandidateMove('meh', -40),
  CandidateMove('bad', -200),
  CandidateMove('awful', -600),
];

Map<String, int> _picks(int elo, {int games = 4000}) {
  final policy = BotPolicy(elo: elo, seed: 3);
  final counts = <String, int>{};
  for (var i = 0; i < games; i++) {
    final move = policy.pick(_candidates);
    counts[move] = (counts[move] ?? 0) + 1;
  }
  return counts;
}

Map<String, int> _phasePicks(int elo, GamePhase phase) {
  final policy = BotPolicy(elo: elo, seed: 5);
  final counts = <String, int>{};
  for (var i = 0; i < 4000; i++) {
    final move = policy.pick(_candidates, phase: phase);
    counts[move] = (counts[move] ?? 0) + 1;
  }
  return counts;
}

void main() {
  test('stronger bots look deeper and may think longer', () {
    expect(BotPolicy(elo: 600).depth, lessThan(BotPolicy(elo: 1400).depth));
    expect(BotPolicy(elo: 1400).depth, lessThan(BotPolicy(elo: 2000).depth));
    expect(BotPolicy(elo: 100).depth, 2);
    expect(BotPolicy(elo: 9000).depth, 18);
    expect(BotPolicy(elo: 600).skillLevel, 20);
    expect(BotPolicy(elo: 600).uciElo, isNull);
  });

  test('a 2000 bot plays mostly the best move but is not perfect', () {
    final picks = _picks(2000);
    expect(picks['best']! / 4000, greaterThan(0.5));
    expect((picks['best']! + picks['ok']!) / 4000, greaterThan(0.85));
    expect(picks['best']! / 4000, lessThan(0.95));
    expect(picks['awful'] ?? 0, 0);
  });

  test('from 1000 up a bot makes mistakes but never blunders', () {
    for (final elo in [1000, 1400, 2000]) {
      final picks = _picks(elo);
      expect(picks['awful'] ?? 0, 0, reason: '\$elo');
      expect((picks['meh'] ?? 0) + (picks['bad'] ?? 0), greaterThan(0));
    }
  });

  test('a 600 bot plays normal moves mostly, and makes more mistakes', () {
    final weak = _picks(600);
    final strong = _picks(2000);
    final sensible =
        (weak['best'] ?? 0) + (weak['ok'] ?? 0) + (weak['meh'] ?? 0);
    expect(sensible / 4000, greaterThan(0.6));
    expect(weak['best']!, lessThan(strong['best']!));
    expect(weak['bad'] ?? 0, greaterThan(0));
  });

  test('the middlegame is played less cleanly than the opening or endgame', () {
    int errors(Map<String, int> p) => (p['meh'] ?? 0) + (p['bad'] ?? 0);
    final mid = errors(_phasePicks(1400, GamePhase.middlegame));
    expect(mid, greaterThan(errors(_phasePicks(1400, GamePhase.opening))));
    expect(mid, greaterThan(errors(_phasePicks(1400, GamePhase.endgame))));
  });

  test('the phase comes from the move count and the pieces left', () {
    const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    expect(phaseOf(start, 0), GamePhase.opening);
    expect(phaseOf(start, 30), GamePhase.middlegame);
    expect(phaseOf('4k3/8/8/8/8/8/4P3/R3K3 w - - 0 1', 60), GamePhase.endgame);
  });

  test('a bot takes a forced mate and never walks into one', () {
    final policy = BotPolicy(elo: 600, seed: 1);
    for (var i = 0; i < 200; i++) {
      expect(
        policy.pick(const [
          CandidateMove('mate', 100000),
          CandidateMove('other', 300),
        ]),
        'mate',
      );
      expect(
        policy.pick(const [
          CandidateMove('safe', -100),
          CandidateMove('mated', -100000),
        ]),
        'safe',
      );
    }
  });

  test('mistakes grow steadily as the rating falls', () {
    double t(int elo) => BotPolicy(elo: elo).temperature;
    double l(int elo) => BotPolicy(elo: elo).lapseChance(GamePhase.middlegame);
    for (var elo = 400; elo < 2800; elo += 100) {
      expect(t(elo), greaterThanOrEqualTo(t(elo + 100)));
      expect(l(elo), greaterThanOrEqualTo(l(elo + 100)));
    }
  });
}
