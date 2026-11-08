import 'dart:math';

/// One move the engine considered, with its score in centipawns from the
/// side to move's point of view (mates are ±100000).
class CandidateMove {
  const CandidateMove(this.uci, this.cp);

  final String uci;
  final int cp;
}

/// The stage of the game, which changes how carefully a bot plays.
enum GamePhase { opening, middlegame, endgame }

/// The phase of a position from its FEN and how many moves have been made:
/// the opening for the first 12 moves of each side, the endgame once the
/// queens are gone or few pieces are left, the middlegame in between.
GamePhase phaseOf(String fen, int ply) {
  final board = fen.split(' ').first;
  var queens = 0, pieces = 0;
  for (final c in board.split('')) {
    switch (c.toLowerCase()) {
      case 'q':
        queens++;
        pieces++;
      case 'r':
      case 'b':
      case 'n':
        pieces++;
    }
  }
  if (pieces <= 6 || (queens == 0 && pieces <= 8)) return GamePhase.endgame;
  if (ply < 24) return GamePhase.opening;
  return GamePhase.middlegame;
}

/// How a bot of a given rating picks its moves, like a person of that
/// rating would.
///
/// The engine, at full strength, lists the best few moves at a search depth
/// that suits the rating, and the bot chooses among them: mostly good moves,
/// weighted towards the best. People are not equally sharp all game, so on
/// top of that the bot now and then has a lapse and plays an inaccuracy or
/// a mistake. Lapses come mostly in the middlegame, where plans and tactics
/// are hardest; the opening (known moves) and the endgame (simple ideas:
/// the king forward, the passed pawn on) are played more cleanly. The
/// longer a bot has played accurately, the likelier its next lapse, so good
/// moves and slips come in human runs. From 1000 up a bot never knowingly
/// gives away a piece; below that, it sometimes blunders.
class BotPolicy {
  BotPolicy({required this.elo, int? seed}) : _random = Random(seed);

  final int elo;
  final Random _random;

  /// Accurate moves played since the last lapse.
  int _streak = 0;

  /// The engine plays at full strength; the policy weakens it.
  int get skillLevel => 20;
  int? get uciElo => null;

  /// How many moves the engine lists for the bot to choose from.
  int get lines => 6;

  /// How deep the engine looks. Shallow searches miss deeper tactics, the
  /// way weaker players do (2000: 8 plies, 1400: 5, 1000: 4, 600: 2).
  int get depth => (elo / 250).round().clamp(2, 18);

  /// The longest a search may take; most end at [depth] well before.
  Duration get thinkTime => Duration(
    milliseconds: (150 + (elo - 400).clamp(0, 2400) / 2400 * 1050).round(),
  );

  static const List<int> _elos = [400, 800, 1200, 1600, 2000, 2400, 2800];

  /// How far below the best a move may be and still be likely, outside a
  /// lapse: the lower the rating, the more a weaker move is tolerated.
  static const List<double> _temperatures = [200, 140, 90, 60, 35, 18, 6];

  /// The most a bot will give up in one move.
  static const List<double> _maxLosses = [600, 450, 280, 260, 220, 120, 40];

  /// How often a middlegame move is a lapse, before the streak adds to it.
  static const List<double> _lapseChances = [
    0.22,
    0.18,
    0.14,
    0.11,
    0.08,
    0.05,
    0.02,
  ];

  /// Of the lapses, how many are mistakes rather than inaccuracies.
  static const List<double> _mistakeShares = [
    0.7,
    0.6,
    0.5,
    0.4,
    0.3,
    0.2,
    0.1,
  ];

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

  /// From 1000 up, never more than a mistake: no blunders.
  double get maxLoss => _byElo(_maxLosses, elo);

  double get mistakeShare => _byElo(_mistakeShares, elo);

  /// The chance that the next move in [phase] is a lapse.
  double lapseChance(GamePhase phase) {
    final base = _byElo(_lapseChances, elo);
    final scale = switch (phase) {
      GamePhase.opening => 0.3,
      GamePhase.middlegame => 1.0,
      GamePhase.endgame => 0.45,
    };
    // Every accurate move in a row makes the next slip a little likelier.
    return ((base + _streak * base * 0.25) * scale).clamp(0.0, 0.6);
  }

  /// Picks one of [candidates] (best first, as the engine lists them) for a
  /// position in [phase].
  String pick(
    List<CandidateMove> candidates, {
    GamePhase phase = GamePhase.middlegame,
  }) {
    assert(candidates.isNotEmpty);
    final best = candidates.map((c) => c.cp).reduce(max);
    // Once a game is clearly won or lost, centipawns stop meaning much.
    final decided = best.abs() > 1500;

    if (!decided && _random.nextDouble() < lapseChance(phase)) {
      final lapse = _lapse(candidates, best);
      if (lapse != null) {
        _streak = 0;
        return lapse.uci;
      }
    }

    final scale = phase == GamePhase.middlegame ? 1.0 : 0.6;
    final temp = temperature * scale;
    final allowed = [
      for (final c in candidates)
        if (best - c.cp <= min(maxLoss, temp * 2.5)) c,
    ];
    final chosen = allowed.length <= 1
        ? candidates.first
        : _weighted(allowed, best, temp);
    if (best - chosen.cp < 40) {
      _streak++;
    } else {
      _streak = 0;
    }
    return chosen.uci;
  }

  /// How long the bot sits on its move before playing it, like a person
  /// would: quick in the opening, longest in the middlegame. A forced move
  /// or one that is far better than the rest comes fast; a position with
  /// several close options takes longer. Weaker bots are more impulsive. On
  /// a clock it never spends more than a twentieth of what is left
  /// ([clockLeft], null when untimed).
  Duration moveDelay(
    List<CandidateMove> candidates, {
    GamePhase phase = GamePhase.middlegame,
    Duration? clockLeft,
  }) {
    final (low, high) = switch (phase) {
      GamePhase.opening => (450.0, 1100.0),
      GamePhase.middlegame => (1000.0, 2800.0),
      GamePhase.endgame => (600.0, 1700.0),
    };
    var ms = low + (high - low) * _random.nextDouble();
    ms *= 0.8 + 0.35 * ((elo - 400) / 1600).clamp(0.0, 1.0);

    if (candidates.length <= 1) {
      ms = 300.0 + _random.nextInt(250);
    } else {
      final sorted = [for (final c in candidates) c.cp]
        ..sort((a, b) => b.compareTo(a));
      final lead = sorted[0] - sorted[1];
      final close = sorted.where((cp) => sorted[0] - cp <= 60).length;
      if (lead > 300) {
        ms *= 0.45;
      } else if (close >= 3) {
        ms *= 1.3;
      }
    }

    if (clockLeft != null) {
      ms = min(ms, clockLeft.inMilliseconds / 20);
    }
    return Duration(milliseconds: ms.round().clamp(150, 4000));
  }

  /// An inaccuracy (40 to 100 lost) or a mistake (100 up to [maxLoss]),
  /// whichever the candidates offer, or null when none fits.
  CandidateMove? _lapse(List<CandidateMove> candidates, int best) {
    final mistake = _random.nextDouble() < mistakeShare;
    final (low, high) = mistake ? (100.0, maxLoss) : (40.0, 100.0);
    final fits = [
      for (final c in candidates)
        if (best - c.cp >= low && best - c.cp <= high) c,
    ];
    if (fits.isEmpty) {
      // Nothing that bad on the list: take the gentlest weaker move.
      final weaker = [
        for (final c in candidates)
          if (best - c.cp >= 30 && best - c.cp <= maxLoss) c,
      ];
      return weaker.isEmpty ? null : weaker.first;
    }
    return fits[_random.nextInt(fits.length)];
  }

  CandidateMove _weighted(List<CandidateMove> allowed, int best, double temp) {
    final weights = [for (final c in allowed) exp(-(best - c.cp) / temp)];
    var roll = _random.nextDouble() * weights.reduce((a, b) => a + b);
    for (var i = 0; i < allowed.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return allowed[i];
    }
    return allowed.last;
  }
}
