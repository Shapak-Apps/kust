import 'dart:async';

import 'package:kust/features/game/chess/bot_policy.dart';
import 'package:kust/features/game/chess/chess_engine.dart';

/// An engine that answers each bot request with the next of [replies],
/// once [release] completes the pending one.
class FakeEngine implements ChessEngine {
  FakeEngine(this.replies);

  final List<String> replies;
  Completer<void>? _gate;

  /// Lets the bot's current search finish.
  void release() => _gate?.complete();

  @override
  Future<void> start() async {}

  @override
  void setSkillLevel(int level, {int? uciElo}) {}

  @override
  void stopThinking() {}

  @override
  Future<List<CandidateMove>> candidateMoves(
    String fen, {
    required int lines,
    required int depth,
    required Duration thinkTime,
  }) async {
    _gate = Completer<void>();
    await _gate!.future;
    return [CandidateMove(replies.removeAt(0), 0)];
  }

  @override
  Future<EvalScore?> evaluateFen(
    String fen, {
    Duration thinkTime = const Duration(milliseconds: 250),
    bool Function()? isStale,
  }) async => null;

  @override
  Future<String> evaluateBestHint(
    String fen, {
    bool Function()? isStale,
  }) async => '(none)';

  @override
  Future<MoveAnalysis?> analyzeMove({
    required String beforeFen,
    required String playedUci,
    required String afterFen,
    Duration thinkTime = const Duration(milliseconds: 700),
    int depth = ChessEngine.analysisDepth,
    bool Function()? isStale,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
