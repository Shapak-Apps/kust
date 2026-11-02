import 'package:dartchess/dartchess.dart';

import 'package:kust/features/game/chess/move_feedback.dart';

class MoveRecord {
  const MoveRecord({
    required this.side,
    required this.san,
    required this.move,
    this.capturedPiece,
    this.feedback,
    this.bestSan,
    this.bestMove,
  });

  final Side side;
  final String san;
  final NormalMove move;
  final Piece? capturedPiece;
  final MoveFeedback? feedback;
  final String? bestSan;

  /// The engine's choice instead, for the Show best arrow.
  final NormalMove? bestMove;

  MoveRecord copyWith({
    MoveFeedback? feedback,
    String? bestSan,
    NormalMove? bestMove,
  }) {
    return MoveRecord(
      side: side,
      san: san,
      move: move,
      capturedPiece: capturedPiece,
      feedback: feedback ?? this.feedback,
      bestSan: bestSan ?? this.bestSan,
      bestMove: bestMove ?? this.bestMove,
    );
  }
}
