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

/// Average accuracy over [moves], or null when there is nothing to average.
double? gameAccuracy(Iterable<double> moves) {
  final list = moves.toList();
  if (list.isEmpty) return null;
  return list.reduce((a, b) => a + b) / list.length;
}
