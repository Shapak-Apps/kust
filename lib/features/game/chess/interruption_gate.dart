import 'dart:async';

/// A search was cut short because the app went to the background, so its
/// answer is not the one the engine would have given.
class SearchInterruptedException implements Exception {
  const SearchInterruptedException();

  @override
  String toString() => 'SearchInterruptedException';
}

/// Keeps searches from running while the app is hidden, and from being
/// trusted when the app was hidden while they ran.
class InterruptionGate {
  int _count = 0;
  Completer<void>? _shown;

  bool get hidden => _shown != null;

  /// Changes whenever the app is hidden. Read it when a search starts.
  int get epoch => _count;

  void hide() {
    if (_shown != null) return;
    _count++;
    _shown = Completer<void>();
  }

  void show() {
    final shown = _shown;
    _shown = null;
    if (shown != null && !shown.isCompleted) shown.complete();
  }

  /// Completes at once while the app is visible.
  Future<void> whenShown() => _shown?.future ?? Future<void>.value();

  /// Throws if the app was hidden since [startEpoch].
  void check(int startEpoch) {
    if (_count != startEpoch) throw const SearchInterruptedException();
  }

  /// Runs [body] once the app is visible, and again from the start if it was
  /// hidden meanwhile, up to [attempts] times.
  Future<T> retrying<T>(Future<T> Function() body, {int attempts = 3}) async {
    for (var attempt = 1; ; attempt++) {
      await whenShown();
      try {
        return await body();
      } on SearchInterruptedException {
        if (attempt >= attempts) rethrow;
      }
    }
  }
}
