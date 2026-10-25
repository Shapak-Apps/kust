import 'dart:math' as math;

/// Chance of winning, 0..100, for an engine score in centipawns from one
/// side's point of view. Same curve Lichess uses.
double winPercent(int cp) {
  final clamped = cp.clamp(-1000, 1000);
  return 50 + 50 * (2 / (1 + math.exp(-0.00368208 * clamped)) - 1);
}

/// Accuracy of one move, 0..100: how little winning chance it gave up
/// compared with the engine's best move. Both scores are from the mover's
/// point of view.
double moveAccuracy({required int bestCp, required int playedCp}) {
  final loss = math.max(0.0, winPercent(bestCp) - winPercent(playedCp));
  final accuracy = 103.1668 * math.exp(-0.04354 * loss) - 3.1669;
  return accuracy.clamp(0.0, 100.0);
}

/// Accuracy of a whole game, 0..100, the way lichess works it out: the
/// mean of two averages of the per-move [moves] accuracies.
///
/// - A weighted mean that counts tense moments more: each move weighs as
///   much as the winning chances swung around it ([winPercents], the
///   player's winning chance after each move).
/// - A harmonic mean, which a few very bad moves drag down hard.
///
/// A plain average would let a lost game look accurate: once the game is
/// gone, every further bad move costs almost no winning chance and scores
/// near 100. Null when there is nothing to average.
double? gameAccuracy(Iterable<double> moves, {List<double>? winPercents}) {
  final list = moves.toList();
  if (list.isEmpty) return null;
  final weights = winPercents != null && winPercents.length == list.length
      ? _volatility(winPercents)
      : List<double>.filled(list.length, 1);

  var weightedSum = 0.0, weightTotal = 0.0, inverseSum = 0.0;
  for (var i = 0; i < list.length; i++) {
    weightedSum += list[i] * weights[i];
    weightTotal += weights[i];
    inverseSum += 1 / math.max(list[i], 1);
  }
  final weighted = weightedSum / weightTotal;
  final harmonic = list.length / inverseSum;
  return ((weighted + harmonic) / 2).clamp(0.0, 100.0);
}

/// How much the winning chances move around each point of the game: the
/// spread of [winPercents] in a window around it, kept between 0.5 and 12
/// as lichess does.
List<double> _volatility(List<double> winPercents) {
  final n = winPercents.length;
  final half = (n / 10).round().clamp(1, 4);
  return [
    for (var i = 0; i < n; i++)
      _spread(
        winPercents.sublist(math.max(0, i - half), math.min(n, i + half + 1)),
      ).clamp(0.5, 12.0),
  ];
}

double _spread(List<double> values) {
  if (values.length < 2) return 0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance =
      values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
      values.length;
  return math.sqrt(variance);
}
