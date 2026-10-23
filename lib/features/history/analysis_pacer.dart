/// Paces the percentage shown while a game is analyzed, so it reads as a
/// smooth run: very quick through the first half, then easing off, and slow
/// over the last stretch. It never runs ahead of the real progress.
class AnalysisPacer {
  const AnalysisPacer();

  /// Percent per second at displayed [percent].
  static double rateAt(double percent) {
    if (percent < 50) return 50; // 0-50: fast
    if (percent < 60) return 25; // 50-60: still quick, but slower
    if (percent < 80) return 10; // 60-80: medium
    return 2; // 80-100: about two percent a second
  }

  /// Highest percent shown before the analysis is truly finished.
  static const double ceiling = 99;

  /// The displayed percent after [seconds], given the [current] one and the
  /// real progress [target] (0..100).
  double step({
    required double current,
    required double target,
    required double seconds,
  }) {
    final limit = target.clamp(0.0, ceiling);
    if (current >= limit) return current;
    final next = current + rateAt(current) * seconds;
    return next > limit ? limit : next;
  }
}
