import 'package:dartchess/dartchess.dart';

import 'package:Kust/features/game/chess/move_feedback.dart';

class MoveRecord {
  const MoveRecord({
    required this.side,
    required this.san,
    required this.move,
    this.capturedPiece,
    this.feedback,
    this.bestSan,
  });

  final Side side;
  final String san;
  final NormalMove move;
  final Piece? capturedPiece;
  final MoveFeedback? feedback;
  final String? bestSan;

  MoveRecord copyWith({MoveFeedback? feedback, String? bestSan}) {
    return MoveRecord(
      side: side,
      san: san,
      move: move,
      capturedPiece: capturedPiece,
      feedback: feedback ?? this.feedback,
      bestSan: bestSan ?? this.bestSan,
    );
  }
}

