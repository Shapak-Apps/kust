import 'package:dartchess/dartchess.dart';

class MoveRecord {
  const MoveRecord({
    required this.side,
    required this.san,
    required this.move,
    this.capturedPiece,
  });

  final Side side;
  final String san;
  final NormalMove move;
  final Piece? capturedPiece;
}
