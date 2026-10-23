import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';
import 'package:kust/features/history/analysis_pacer.dart';
import 'package:kust/features/history/replay_positions.dart';

enum AnalysisStatus { running, failed }

/// What a history row shows while (or after failing) to analyze its game.
@immutable
class AnalysisState {
  const AnalysisState(this.status, this.percent);

  final AnalysisStatus status;

  /// Percentage to show, 0..100.
  final int percent;

  @override
  bool operator ==(Object other) =>
      other is AnalysisState &&
      other.status == status &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(status, percent);
}

/// Runs "Analyze" for saved games and reports a paced percentage per game.
///
/// It is a long-lived singleton, so an analysis keeps going when the History
/// tab is left and the finished accuracy is stored on the game.
class HistoryAnalysis {
  HistoryAnalysis({
    GameAnalyzer? analyzer,
    this.store,
    this.save,
    this.pacer = const AnalysisPacer(),
    this.tick = const Duration(milliseconds: 100),
    this.finishHold = const Duration(milliseconds: 350),
  }) : _analyzer = analyzer ?? GameAnalyzer();

  /// The app-wide instance. Tests swap in one with a fake analyzer.
  static HistoryAnalysis instance = HistoryAnalysis();

  final GameAnalyzer _analyzer;
  final GameHistoryStore? store;

  /// Overrides how a finished accuracy is saved; for tests.
  final Future<void> Function(String id, double accuracy)? save;
  final AnalysisPacer pacer;
  final Duration tick;

  /// How long 100% stays on screen before the accuracy replaces it.
  final Duration finishHold;

  final Map<String, ValueNotifier<AnalysisState?>> _states = {};

  GameHistoryStore get _history => store ?? GameHistoryStore.instance;

  /// Live state of [gameId]'s analysis; null when idle.
  ValueListenable<AnalysisState?> stateFor(String gameId) =>
      _states.putIfAbsent(gameId, () => ValueNotifier(null));

  /// Whether the row for [game] should offer an Analyze button.
  static bool canAnalyze(GameRecord game) {
    if (game.isLocal || game.accuracy != null) return false;
    final playerMoves =
        (game.uciMoves.length + (game.playerIsWhite ? 1 : 0)) ~/ 2;
    return playerMoves >= kMinAnalysisMoves;
  }

  /// Analyzes [game]. Returns false when it could not be done (no engine, too
  /// few moves); the state then shows as failed so the user can retry.
  Future<bool> start(GameRecord game) async {
    final notifier = _states.putIfAbsent(game.id, () => ValueNotifier(null));
    if (notifier.value?.status == AnalysisStatus.running) return true;

    final replay = replayPositions(game.uciMoves);
    final jobs = playerMoveJobs(
      positions: replay.positions,
      moves: [for (final m in replay.moves.skip(1)) m!],
      playerIsWhite: game.playerIsWhite,
    );
    if (jobs.length < kMinAnalysisMoves) {
      notifier.value = const AnalysisState(AnalysisStatus.failed, 0);
      return false;
    }

    var real = 0.0; // true progress, 0..100
    var shown = 0.0; // paced progress, never ahead of the real one
    notifier.value = const AnalysisState(AnalysisStatus.running, 0);

    final timer = Timer.periodic(tick, (_) {
      shown = pacer.step(
        current: shown,
        target: real,
        seconds: tick.inMilliseconds / 1000,
      );
      notifier.value = AnalysisState(AnalysisStatus.running, shown.floor());
    });

    final double? accuracy;
    try {
      accuracy = await _analyzer.accuracy(
        jobs,
        onProgress: (done, total) => real = done / total * 100,
      );
    } catch (_) {
      timer.cancel();
      notifier.value = const AnalysisState(AnalysisStatus.failed, 0);
      return false;
    }
    timer.cancel();

    if (accuracy == null) {
      notifier.value = const AnalysisState(AnalysisStatus.failed, 0);
      return false;
    }

    notifier.value = const AnalysisState(AnalysisStatus.running, 100);
    await Future<void>.delayed(finishHold);
    await (save ?? _history.setAccuracy)(game.id, accuracy);
    notifier.value = null;
    return true;
  }
}
