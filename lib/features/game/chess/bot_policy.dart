import 'dart:math';

/// One move the engine considered, with its score in centipawns from the
/// side to move's point of view (mates are ±100000).
class CandidateMove {
  const CandidateMove(this.uci, this.cp);

  final String uci;
  final int cp;
}

/// How a bot of a given rating picks its moves.
///
/// Every bot asks the engine, at full strength, for its best few moves at a
/// search depth that suits the rating, and then chooses among them: the
/// better a move, the likelier it is picked. A strong bot nearly always
/// takes the best move and never a bad one; a weak bot spreads its choice
/// wider and may pick a move that loses material. The same rule holds from
/// the first move to the last, so a bot plays at one level the whole game
/// instead of perfect openings followed by random blunders.
class BotPolicy {
  BotPolicy({required this.elo, int? seed}) : _random = Random(seed);

  final int elo;
  final Random _random;

  /// The engine plays at full strength; the policy weakens it.
  int get skillLevel => 20;
  int? get uciElo => null;

  /// How many moves the engine lists for the bot to choose from.
  int get lines => 5;

  /// How deep the engine looks. Shallow searches miss deeper tactics, the
  /// way weaker players do. From 2000 up the bots see as before; below,
  /// they look noticeably less far ahead (1400: 5 plies, 1000: 4, 600: 2).
  int get depth => elo >= 2000
      ? (1 + elo / 220).round().clamp(3, 18)
      : (elo / 260).round().clamp(2, 10);

  /// The longest a search may take; most end at [depth] well before.
  Duration get thinkTime => Duration(
    milliseconds: (150 + (elo - 400).clamp(0, 2400) / 2400 * 1050).round(),
  );

  static const List<int> _elos = [400, 800, 1200, 1600, 2000, 2400, 2800];

  /// How far below the best a move may be and still be likely: the lower
  /// the rating, the more a weaker move is tolerated.
  static const List<double> _temperatures = [230, 170, 115, 70, 25, 12, 5];

  /// The most a bot will knowingly give up in one move.
  static const List<double> _maxLosses = [560, 420, 290, 170, 70, 35, 15];

  static double _byElo(List<double> values, int elo) {
    if (elo <= _elos.first) return values.first;
    if (elo >= _elos.last) return values.last;
    var i = 0;
    while (elo > _elos[i + 1]) {
      i++;
    }
    final t = (elo - _elos[i]) / (_elos[i + 1] - _elos[i]);
    return values[i] + (values[i + 1] - values[i]) * t;
  }

  double get temperature => _byElo(_temperatures, elo);
  double get maxLoss => _byElo(_maxLosses, elo);

  /// How often a bot overlooks something and allows half again the usual
  /// loss: one move in eight at 600, rarely at 1400, never from 1600 up.
  double get slipChance => ((1600 - elo) / 1000 * 0.125).clamp(0.0, 0.125);

  /// Picks one of [candidates] (best first, as the engine lists them).
  String pick(List<CandidateMove> candidates) {
    assert(candidates.isNotEmpty);
    final best = candidates.map((c) => c.cp).reduce(max);
    final limit = _random.nextDouble() < slipChance ? maxLoss * 1.5 : maxLoss;
    final allowed = [
      for (final c in candidates)
        if (best - c.cp <= limit) c,
    ];
    if (allowed.length <= 1) return candidates.first.uci;
    final weights = [
      for (final c in allowed) exp(-(best - c.cp) / temperature),
    ];
    var roll = _random.nextDouble() * weights.reduce((a, b) => a + b);
    for (var i = 0; i < allowed.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return allowed[i].uci;
    }
    return allowed.last.uci;
  }
}
