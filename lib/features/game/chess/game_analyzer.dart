import 'package:dartchess/dartchess.dart';

import 'package:kust/features/game/chess/accuracy.dart';
import 'package:kust/features/game/chess/chess_engine.dart';

/// UCI text for [move] as the engine wants it: castling is the king's two
/// step (`e1g1`), not dartchess' king-takes-rook.
String engineUci(NormalMove move, Position before) {
  final piece = before.board.pieceAt(move.from);
  final target = before.board.pieceAt(move.to);
  var to = move.to;
  if (piece?.role == Role.king &&
      target != null &&
      target.color == piece!.color) {
    to = switch (move.to) {
      Square.h1 => Square.g1,
      Square.a1 => Square.c1,
      Square.h8 => Square.g8,
      Square.a8 => Square.c8,
      _ => move.to,
    };
  }
  final promotion = switch (move.promotion) {
    Role.queen => 'q',
    Role.rook => 'r',
    Role.bishop => 'b',
    Role.knight => 'n',
    _ => '',
  };
  return '${move.from.name}${to.name}$promotion';
}

/// Games with fewer of the player's moves than this are not analyzed.
const int kMinAnalysisMoves = 3;

/// One move of the player to rate.
class AnalysisJob {
  const AnalysisJob({
    required this.beforeFen,
    required this.playedUci,
    required this.afterFen,
  });

  final String beforeFen;
  final String playedUci;
  final String afterFen;
}

/// The jobs for a game: every move made by the player, at most [maxMoves].
///
/// [positions] holds the position before each move in [moves] (index i is the
/// position before move i); extra entries are ignored.
List<AnalysisJob> playerMoveJobs({
  required List<Position> positions,
  required List<NormalMove> moves,
  required bool playerIsWhite,
  int maxMoves = 80,
}) {
  final jobs = <AnalysisJob>[];
  final count = moves.length < positions.length
      ? moves.length
      : positions.length;
  for (var i = 0; i < count && jobs.length < maxMoves; i++) {
    final isWhiteMove = i.isEven;
    if (isWhiteMove != playerIsWhite) continue;
    final before = positions[i];
    jobs.add(
      AnalysisJob(
        beforeFen: before.fen,
        playedUci: engineUci(moves[i], before),
        afterFen: before.play(moves[i]).fen,
      ),
    );
  }
  return jobs;
}

typedef MoveAnalyzer = Future<MoveAnalysis?> Function({
  required String beforeFen,
  required String playedUci,
  required String afterFen,
  required Duration thinkTime,
  bool Function()? isStale,
});

/// Rates a game's moves against the engine's best move.
class GameAnalyzer {
  GameAnalyzer({
    MoveAnalyzer? analyze,
    this.thinkTime = const Duration(milliseconds: 250),
  }) : _analyze = analyze ?? _engineAnalyze;

  final MoveAnalyzer _analyze;
  final Duration thinkTime;

  static Future<MoveAnalysis?> _engineAnalyze({
    required String beforeFen,
    required String playedUci,
    required String afterFen,
    required Duration thinkTime,
    bool Function()? isStale,
  }) {
    return ChessEngine.instance.analyzeMove(
      beforeFen: beforeFen,
      playedUci: playedUci,
      afterFen: afterFen,
      thinkTime: thinkTime,
      isStale: isStale,
    );
  }

  /// Average accuracy over [jobs], or null when [isStale] turned true or no
  /// move could be rated. [onProgress] is told how many jobs are done.
  /// Engine errors are rethrown.
  Future<double?> accuracy(
    List<AnalysisJob> jobs, {
    void Function(int done, int total)? onProgress,
    bool Function()? isStale,
  }) async {
    final scores = <double>[];
    final chances = <double>[];
    for (var i = 0; i < jobs.length; i++) {
      if (isStale?.call() ?? false) return null;
      final job = jobs[i];
      final analysis = await _analyze(
        beforeFen: job.beforeFen,
        playedUci: job.playedUci,
        afterFen: job.afterFen,
        thinkTime: thinkTime,
        isStale: isStale,
      );
      if (isStale?.call() ?? false) return null;
      if (analysis != null) {
        scores.add(
          moveAccuracy(bestCp: analysis.bestCp, playedCp: analysis.playedCp),
        );
        chances.add(winPercent(analysis.playedCp));
      }
      onProgress?.call(i + 1, jobs.length);
    }
    return gameAccuracy(scores, winPercents: chances);
  }
}
