import 'package:dartchess/dartchess.dart';

import 'package:kust/features/game/chess/board/board_geometry.dart';

/// A move queued while the opponent thinks.
typedef Premove = ({Square from, Square to});

/// The most premoves that can be queued at once.
const int kMaxPremoves = 8;

/// Where the [side] piece on [from] may be premoved to on [board].
///
/// Like chess.com and lichess, this goes by how the piece moves and ignores
/// the other pieces: the opponent's reply is not known yet, so a blocked
/// line may open, a pawn may get something to take, and a square held by
/// one's own piece may be where the opponent captures (the classic premove
/// recapture). Whether the move is legal is checked when it is played.
Set<Square> premoveDestinations(
  Board board,
  Square from,
  Side side, {
  required Castles castles,
  bool castleOnRook = false,
}) {
  final piece = board.pieceAt(from);
  if (piece == null || piece.color != side) return const {};
  final file = fileOf(from), rank = rankOf(from);
  final result = <Square>{};

  void add(int f, int r) {
    if (f < 0 || f > 7 || r < 0 || r > 7) return;
    if (f == file && r == rank) return;
    result.add(squareAt(f, r));
  }

  void line(int df, int dr) {
    for (var i = 1; i < 8; i++) {
      add(file + df * i, rank + dr * i);
    }
  }

  switch (piece.role) {
    case Role.pawn:
      final dir = side == Side.white ? 1 : -1;
      add(file, rank + dir);
      if (rank == (side == Side.white ? 1 : 6)) add(file, rank + 2 * dir);
      add(file - 1, rank + dir);
      add(file + 1, rank + dir);
    case Role.knight:
      for (final (df, dr) in const [
        (1, 2), (2, 1), (2, -1), (1, -2), //
        (-1, -2), (-2, -1), (-2, 1), (-1, 2),
      ]) {
        add(file + df, rank + dr);
      }
    case Role.bishop:
      for (final (df, dr) in const [(1, 1), (1, -1), (-1, 1), (-1, -1)]) {
        line(df, dr);
      }
    case Role.rook:
      for (final (df, dr) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        line(df, dr);
      }
    case Role.queen:
      for (final (df, dr) in const [
        (1, 1), (1, -1), (-1, 1), (-1, -1), //
        (1, 0), (-1, 0), (0, 1), (0, -1),
      ]) {
        line(df, dr);
      }
    case Role.king:
      for (var df = -1; df <= 1; df++) {
        for (var dr = -1; dr <= 1; dr++) {
          add(file + df, rank + dr);
        }
      }
      // Castling, while the king and that rook have not moved.
      final home = side == Side.white ? 0 : 7;
      if (file == 4 && rank == home) {
        for (final (cs, kingFile) in const [
          (CastlingSide.king, 6),
          (CastlingSide.queen, 2),
        ]) {
          final rook = castles.rookOf(side, cs);
          if (rook == null) continue;
          final standing = board.pieceAt(rook);
          if (standing?.role != Role.rook || standing?.color != side) continue;
          add(kingFile, home);
          if (castleOnRook) result.add(rook);
        }
      }
  }
  return result;
}

/// Whether [p], for the [side] king, is a castling move: from its home
/// square two files across, or onto its own rook.
bool _isCastling(Board board, Premove p, Side side) {
  final piece = board.pieceAt(p.from);
  if (piece?.role != Role.king) return false;
  final home = side == Side.white ? 0 : 7;
  if (p.from != squareAt(4, home) || rankOf(p.to) != home) return false;
  final target = board.pieceAt(p.to);
  final ontoRook = target?.role == Role.rook && target?.color == side;
  return ontoRook || (fileOf(p.to) - 4).abs() == 2;
}

/// [board] with [p] made as it would look once played: a castling king
/// takes its rook along, a pawn reaching the last rank becomes a queen, and
/// whatever stood on the target square is gone.
Board applyPremove(Board board, Premove p, Side side) {
  final piece = board.pieceAt(p.from);
  if (piece == null) return board;
  if (_isCastling(board, p, side)) {
    final home = side == Side.white ? 0 : 7;
    final kingSide = fileOf(p.to) > 4;
    final rookFrom = squareAt(kingSide ? 7 : 0, home);
    final rook = board.pieceAt(rookFrom);
    var next = board.removePieceAt(p.from).removePieceAt(rookFrom);
    next = next.setPieceAt(squareAt(kingSide ? 6 : 2, home), piece);
    if (rook != null) {
      next = next.setPieceAt(squareAt(kingSide ? 5 : 3, home), rook);
    }
    return next;
  }
  final lastRank = side == Side.white ? 7 : 0;
  final promotes = piece.role == Role.pawn && rankOf(p.to) == lastRank;
  return board
      .removePieceAt(p.from)
      .setPieceAt(
        p.to,
        promotes ? Piece(color: side, role: Role.queen) : piece,
      );
}

/// The board as the player sees it with [queue] made on top of [real], and
/// how many of the premoves still make sense: one whose piece is no longer
/// there (the opponent took it) ends the queue.
({Board board, int valid}) premoveBoard(
  Board real,
  Side side,
  List<Premove> queue,
) {
  var board = real;
  for (var i = 0; i < queue.length; i++) {
    final piece = board.pieceAt(queue[i].from);
    if (piece == null || piece.color != side) {
      return (board: board, valid: i);
    }
    board = applyPremove(board, queue[i], side);
  }
  return (board: board, valid: queue.length);
}
