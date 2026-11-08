import 'package:dartchess/dartchess.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/accuracy.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';
import 'package:kust/features/game/chess/move_feedback.dart';
import 'package:kust/features/history/replay_positions.dart';

/// One move of a reviewed game, rated.
class ReviewedMove {
  const ReviewedMove({
    required this.ply,
    required this.side,
    required this.san,
    required this.bestSan,
    required this.quality,
    required this.accuracy,
    required this.lossPercent,
    required this.whiteWin,
  });

  /// 1 for White's first move, 2 for Black's reply, and so on.
  final int ply;
  final Side side;
  final String san;

  /// The engine's choice in this position, in SAN.
  final String bestSan;
  final MoveQuality quality;

  /// 0..100.
  final double accuracy;

  /// How many points of winning chance the move gave up, 0..100.
  final double lossPercent;

  /// White's winning chance after the move, 0..100.
  final double whiteWin;

  /// The move number in the game: 1 for the first move of each side.
  int get moveNumber => (ply + 1) ~/ 2;
}

/// A whole game, rated move by move for both sides.
class GameReviewData {
  GameReviewData(this.moves);

  final List<ReviewedMove> moves;

  Iterable<ReviewedMove> by(Side side) => moves.where((m) => m.side == side);

  /// Lichess-style accuracy of [side], null when it made no rated move.
  double? accuracy(Side side) {
    final own = by(side).toList();
    return gameAccuracy(
      [for (final m in own) m.accuracy],
      winPercents: [
        for (final m in own) side == Side.white ? m.whiteWin : 100 - m.whiteWin,
      ],
    );
  }

  /// How many moves of [side] got each rating.
  Map<MoveQuality, int> counts(Side side) {
    final map = <MoveQuality, int>{};
    for (final m in by(side)) {
      map[m.quality] = (map[m.quality] ?? 0) + 1;
    }
    return map;
  }

  /// The moves of [side] that cost the most, worst first: only real errors
  /// (an inaccuracy or worse that gave up at least 8 points).
  List<ReviewedMove> worst(Side side, {int count = 3}) {
    final bad =
        by(side)
            .where(
              (m) =>
                  m.lossPercent >= 8 &&
                  (m.quality == MoveQuality.inaccuracy ||
                      m.quality == MoveQuality.mistake ||
                      m.quality == MoveQuality.miss ||
                      m.quality == MoveQuality.blunder),
            )
            .toList()
          ..sort((a, b) => b.lossPercent.compareTo(a.lossPercent));
    final top = bad.take(count).toList()
      ..sort((a, b) => a.ply.compareTo(b.ply));
    return top;
  }
}

/// The most plies rated, to keep the wait short.
const int kReviewMaxPlies = 160;

/// Rates every move of [game] for both sides with [analyze]. [onProgress]
/// hears how many moves are done. Returns null when [isStale] turned true.
/// Engine errors are rethrown.
Future<GameReviewData?> reviewGame(
  GameRecord game, {
  required MoveAnalyzer analyze,
  Duration thinkTime = const Duration(milliseconds: 200),
  void Function(int done, int total)? onProgress,
  bool Function()? isStale,
}) async {
  final replay = replayPositions(game.uciMoves);
  final total = (replay.moves.length - 1).clamp(0, kReviewMaxPlies);
  final moves = <ReviewedMove>[];

  for (var i = 0; i < total; i++) {
    if (isStale?.call() ?? false) return null;
    final before = replay.positions[i];
    final move = replay.moves[i + 1]!;
    final after = replay.positions[i + 1];
    final uci = engineUci(move, before);

    final a = await analyze(
      beforeFen: before.fen,
      playedUci: uci,
      afterFen: after.fen,
      thinkTime: thinkTime,
      isStale: isStale,
    );
    if (isStale?.call() ?? false) return null;
    onProgress?.call(i + 1, total);
    if (a == null) continue;

    final quality = classifyPlayedMove(
      before: before,
      after: after,
      move: move,
      bestCp: a.bestCp,
      playedCp: a.playedCp,
      secondBestCp: a.secondBestCp,
      isBest: a.bestUci == uci,
    );
    final mover = before.turn;
    final win = winPercent(a.playedCp);
    String bestSan = '';
    try {
      var best = Move.parse(a.bestUci);
      // The engine writes castling as the king's two steps; dartchess wants
      // the king to take its own rook.
      if (best is NormalMove &&
          before.board.roleAt(best.from) == Role.king &&
          (best.to.file - best.from.file).abs() == 2) {
        final rookFile = best.to.file > best.from.file ? File.h : File.a;
        best = NormalMove(
          from: best.from,
          to: Square.fromCoords(rookFile, best.from.rank),
        );
      }
      if (best is NormalMove && before.isLegal(best)) {
        bestSan = before.makeSan(best).$2;
      }
    } catch (_) {}
    moves.add(
      ReviewedMove(
        ply: i + 1,
        side: mover,
        san: i < game.sanMoves.length ? game.sanMoves[i] : '',
        bestSan: bestSan,
        quality: quality,
        accuracy: moveAccuracy(bestCp: a.bestCp, playedCp: a.playedCp),
        lossPercent: (winPercent(a.bestCp) - win).clamp(0.0, 100.0),
        whiteWin: mover == Side.white ? win : 100 - win,
      ),
    );
  }
  return moves.isEmpty ? null : GameReviewData(moves);
}
