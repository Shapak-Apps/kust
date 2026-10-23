import 'package:dartchess/dartchess.dart';

import 'package:kust/features/game/chess/board/board_geometry.dart';

/// Sound file for [move], played from [before] and leading to [after].
///
/// Check wins over everything else, then castling, promotion and captures
/// (including en passant); a quiet move gets the plain move sound.
String moveSoundFor(Position before, NormalMove move, Position after) {
  if (after.isCheck) return 'check.wav';

  final mover = before.board.pieceAt(move.from);
  final target = before.board.pieceAt(move.to);

  // dartchess writes castling as the king moving onto its own rook.
  final isCastle =
      mover?.role == Role.king &&
      target != null &&
      target.color == mover!.color;
  if (isCastle) return 'castle.wav';
  if (move.promotion != null) return 'promote.wav';

  final isEnPassant =
      mover?.role == Role.pawn &&
      target == null &&
      fileOf(move.from) != fileOf(move.to);
  if (target != null || isEnPassant) return 'capture.wav';

  return 'move.wav';
}
