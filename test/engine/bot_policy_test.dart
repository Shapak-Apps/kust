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

void main() {
  test('stronger bots look deeper and may think longer', () {
    final weak = BotPolicy(elo: 600);
    final mid = BotPolicy(elo: 1400);
    final strong = BotPolicy(elo: 2000);
    expect(weak.depth, lessThan(mid.depth));
    expect(mid.depth, lessThan(strong.depth));
    expect(weak.thinkTime, lessThan(strong.thinkTime));
    expect(BotPolicy(elo: 100).depth, 2);
    expect(BotPolicy(elo: 9000).depth, 18);
  });

  test('2000 and up play as before; below they are weaker', () {
    final master = BotPolicy(elo: 2000);
    expect(master.depth, 10);
    expect(master.temperature, 25);
    expect(master.maxLoss, 70);
    expect(master.slipChance, 0);
    final club = BotPolicy(elo: 1400);
    expect(club.depth, 5);
    expect(club.temperature, greaterThan(80));
    expect(BotPolicy(elo: 600).depth, 2);
  });

  test('the engine itself always plays at full strength', () {
    expect(BotPolicy(elo: 600).skillLevel, 20);
    expect(BotPolicy(elo: 600).uciElo, isNull);
    expect(BotPolicy(elo: 2400).uciElo, isNull);
  });

  test('a 2000 bot nearly always plays a good move and never a bad one', () {
    final picks = _picks(2000);
    expect(picks['best']! / 4000, greaterThan(0.7));
    expect(picks['bad'] ?? 0, 0);
    expect(picks['awful'] ?? 0, 0);
  });

  test('a 600 bot plays normal moves mostly, and makes more mistakes', () {
    final weak = _picks(600);
    final strong = _picks(2000);
    // Mostly sensible moves...
    final sensible =
        (weak['best'] ?? 0) + (weak['ok'] ?? 0) + (weak['meh'] ?? 0);
    expect(sensible / 4000, greaterThan(0.7));
    // ...but far more often a weaker one than the 2000 bot.
    expect(weak['best']!, lessThan(strong['best']!));
    expect((weak['bad'] ?? 0), greaterThan(0));
    // A slip that throws the game away stays rare at 600...
    expect((weak['awful'] ?? 0) / 4000, lessThan(0.01));
    // ...and never happens from 1400 up.
    expect(_picks(1400)['awful'] ?? 0, 0);
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
    double m(int elo) => BotPolicy(elo: elo).maxLoss;
    for (var elo = 400; elo < 2800; elo += 100) {
      expect(t(elo), greaterThanOrEqualTo(t(elo + 100)));
      expect(m(elo), greaterThanOrEqualTo(m(elo + 100)));
    }
    expect(BotPolicy(elo: 1600).slipChance, 0);
    expect(BotPolicy(elo: 1200).slipChance, greaterThan(0));
    expect(BotPolicy(elo: 400).slipChance, greaterThan(0.1));
  });
}
