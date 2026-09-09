import 'package:dartchess/dartchess.dart';

import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:Kust/features/game/chess/move_record.dart';

String assetForPiece(Piece piece) {
  final color = piece.color == Side.white ? 'w' : 'b';

  final role = switch (piece.role) {
    Role.king => 'K',
    Role.queen => 'Q',
    Role.rook => 'R',
    Role.bishop => 'B',
    Role.knight => 'N',
    Role.pawn => 'P',
  };

  return 'assets/pieces/$color$role.svg';
}

int pieceValue(Role role) {
  return switch (role) {
    Role.pawn => 1,
    Role.knight => 3,
    Role.bishop => 3,
    Role.rook => 5,
    Role.queen => 9,
    Role.king => 0,
  };
}

Side oppositeSide(Side side) {
  return side == Side.white ? Side.black : Side.white;
}

String fileChar(int file) {
  return String.fromCharCode('a'.codeUnitAt(0) + file);
}

String squareName(Square square) {
  return '${fileChar(fileOf(square))}${rankOf(square) + 1}';
}

String roleChar(Role role) {
  return switch (role) {
    Role.king => 'K',
    Role.queen => 'Q',
    Role.rook => 'R',
    Role.bishop => 'B',
    Role.knight => 'N',
    Role.pawn => 'P',
  };
}

List<Piece> piecesCapturedBy(Side side, List<MoveRecord> moves) {
  final pieces = moves
      .where((m) => m.side == side && m.capturedPiece != null)
      .map((m) => m.capturedPiece!)
      .toList();

  pieces.sort((a, b) => pieceValue(b.role).compareTo(pieceValue(a.role)));

  return pieces;
}

int boardMaterialAdvantageFor(Position position, Side side) {
  int white = 0;
  int black = 0;

  for (final square in Square.values) {
    final piece = position.board.pieceAt(square);
    if (piece == null || piece.role == Role.king) continue;

    final value = pieceValue(piece.role);

    if (piece.color == Side.white) {
      white += value;
    } else {
      black += value;
    }
  }

  return side == Side.white ? white - black : black - white;
}

String moveToSan({
  required Position before,
  required NormalMove move,
  required Position after,
  Square? capturedSquare,
}) {
  final piece = before.board.pieceAt(move.from);
  if (piece == null) return '--';

  final isKingsideCastle =
      (move.from == Square.e1 &&
          (move.to == Square.h1 || move.to == Square.g1)) ||
      (move.from == Square.e8 &&
          (move.to == Square.h8 || move.to == Square.g8));

  final isQueensideCastle =
      (move.from == Square.e1 &&
          (move.to == Square.a1 || move.to == Square.c1)) ||
      (move.from == Square.e8 &&
          (move.to == Square.a8 || move.to == Square.c8));

  if (isKingsideCastle) return _withCheck('O-O', after);
  if (isQueensideCastle) return _withCheck('O-O-O', after);

  final isCapture = capturedSquare != null;
  final buffer = StringBuffer();

  if (piece.role == Role.pawn) {
    if (isCapture) {
      buffer.write(fileChar(fileOf(move.from)));
      buffer.write('x');
    }

    buffer.write(squareName(move.to));

    if (move.promotion != null) {
      buffer.write('=');
      buffer.write(roleChar(move.promotion!));
    }
  } else {
    buffer.write(roleChar(piece.role));
    buffer.write(_disambiguation(before, move, piece));

    if (isCapture) {
      buffer.write('x');
    }

    buffer.write(squareName(move.to));
  }

  return _withCheck(buffer.toString(), after);
}

String _withCheck(String san, Position after) {
  if (after.isCheckmate) return '$san#';
  if (after.isCheck) return '$san+';
  return san;
}

String _disambiguation(Position before, NormalMove move, Piece piece) {
  final candidates = <Square>[];

  for (final square in Square.values) {
    if (square == move.from) continue;

    final candidatePiece = before.board.pieceAt(square);
    if (candidatePiece == null) continue;

    if (candidatePiece.color != piece.color ||
        candidatePiece.role != piece.role) {
      continue;
    }

    final candidateMove = NormalMove(from: square, to: move.to);

    if (before.isLegal(candidateMove)) {
      candidates.add(square);
    }
  }

  if (candidates.isEmpty) return '';

  final fromFile = fileOf(move.from);
  final fromRank = rankOf(move.from);

  final fileIsUnique = candidates.every((sq) => fileOf(sq) != fromFile);
  if (fileIsUnique) {
    return fileChar(fromFile);
  }

  final rankIsUnique = candidates.every((sq) => rankOf(sq) != fromRank);
  if (rankIsUnique) {
    return (fromRank + 1).toString();
  }

  return squareName(move.from);
}
