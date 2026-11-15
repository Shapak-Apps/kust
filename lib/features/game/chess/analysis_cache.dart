import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';

/// Rated moves, remembered by position and move, so a move is searched once:
/// the result sheet, Review and Replay then agree on every number, and a
/// game that was analyzed once opens at once, also after a restart.
class AnalysisCache {
  AnalysisCache._(this._boxOverride) : maxEntries = 8000;

  /// The app-wide cache, kept in the analysis box.
  static final AnalysisCache instance = AnalysisCache._(null);

  /// A cache in [box], for tests.
  AnalysisCache.withBox(Box<dynamic> box, {this.maxEntries = 8000})
    : _boxOverride = box;

  /// Oldest entries are dropped beyond this many (about 1.5 MB).
  final int maxEntries;

  final Box<dynamic>? _boxOverride;

  Box<dynamic>? get _box {
    if (_boxOverride != null) return _boxOverride;
    return Hive.isBoxOpen(AppStorage.analysisBoxName)
        ? Hive.box(AppStorage.analysisBoxName)
        : null;
  }

  final Map<String, Future<MoveAnalysis?>> _inFlight = {};

  static String keyFor(String beforeFen, String playedUci) =>
      '$beforeFen|$playedUci';

  MoveAnalysis? get(String key) {
    final raw = _box?.get(key);
    if (raw is! List || raw.length < 4) return null;
    final best = raw[0];
    final bestCp = raw[1];
    final playedCp = raw[2];
    final second = raw[3];
    if (best is! String || bestCp is! int || playedCp is! int) return null;
    return MoveAnalysis(
      bestUci: best,
      bestCp: bestCp,
      playedCp: playedCp,
      secondBestCp: second is int ? second : null,
    );
  }

  Future<void> put(String key, MoveAnalysis a) async {
    final box = _box;
    if (box == null) return;
    await box.put(key, [a.bestUci, a.bestCp, a.playedCp, a.secondBestCp]);
    if (box.length > maxEntries) {
      await box.deleteAll(box.keys.take(maxEntries ~/ 8).toList());
    }
  }

  /// [inner] with this cache in front: a move already rated is answered
  /// from it, one being rated is waited for, and every search uses the same
  /// think time whoever asks.
  MoveAnalyzer wrap(MoveAnalyzer inner) =>
      ({
        required String beforeFen,
        required String playedUci,
        required String afterFen,
        required Duration thinkTime,
        bool Function()? isStale,
      }) async {
        final key = keyFor(beforeFen, playedUci);
        final hit = get(key);
        if (hit != null) return hit;

        final pending = _inFlight[key];
        if (pending != null) {
          final shared = await pending;
          if (shared != null || (isStale?.call() ?? false)) return shared;
        }

        final future = inner(
          beforeFen: beforeFen,
          playedUci: playedUci,
          afterFen: afterFen,
          thinkTime: kAnalysisThinkTime,
          isStale: isStale,
        );
        _inFlight[key] = future;
        try {
          final result = await future;
          if (result != null) await put(key, result);
          return result;
        } finally {
          if (identical(_inFlight[key], future)) _inFlight.remove(key);
        }
      };
}

/// The engine's move rating with the shared cache in front: what Review,
/// Replay, History and the result sheet all use.
final MoveAnalyzer sharedMoveAnalyzer = AnalysisCache.instance.wrap(
  ({
    required String beforeFen,
    required String playedUci,
    required String afterFen,
    required Duration thinkTime,
    bool Function()? isStale,
  }) => ChessEngine.instance.analyzeMove(
    beforeFen: beforeFen,
    playedUci: playedUci,
    afterFen: afterFen,
    thinkTime: thinkTime,
    isStale: isStale,
  ),
);
