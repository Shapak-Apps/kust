import 'package:dartchess/dartchess.dart';

/// Where the piece giving check in [position] could have come from: an
/// empty square from which it moves to where it stands, without already
/// giving check there. The farthest such square, so the arrival is seen.
/// Null when the side to move is not in check.
({Square from, Square to})? checkArrival(Position position) {
  final king = position.board.kingOf(position.turn);
  final checkers = position.checkers;
  if (king == null || checkers.isEmpty) return null;
  final at = checkers.squares.first;
  final piece = position.board.pieceAt(at)!;
  final occupied = position.board.occupied.withoutSquare(at);
  Square? best;
  var far = 0;
  for (final from in Square.values) {
    if (occupied.has(from) || from == at) continue;
    if (!attacks(piece, from, occupied).has(at)) continue;
    if (attacks(piece, from, occupied).has(king)) continue;
    final d = _distance(from, at);
    if (d > far) {
      far = d;
      best = from;
    }
  }
  return best == null ? null : (from: best, to: at);
}

/// The arrows that show a tactic just played by the piece now on [at]:
/// a fork points at every enemy piece (other than pawns) it attacks; a pin
/// or a skewer points through the piece in front to the one behind it.
List<({Square from, Square to})> tacticArrows(
  Position after,
  Square at, {
  required bool throughLine,
}) {
  final board = after.board;
  final piece = board.pieceAt(at);
  if (piece == null) return const [];
  final enemy = board.bySide(piece.color.opposite);
  final hit = attacks(piece, at, board.occupied) & enemy;
  if (!throughLine) {
    return [
      for (final s in hit.squares)
        if (board.pieceAt(s)?.role != Role.pawn) (from: at, to: s),
    ];
  }
  final arrows = <({Square from, Square to})>[];
  for (final front in hit.squares) {
    // Past the piece in front, the first piece on the same line.
    final behind = attacks(
      piece,
      at,
      board.occupied.withoutSquare(front),
    ).diff(attacks(piece, at, board.occupied)).intersect(enemy);
    for (final back in behind.squares) {
      if (ray(at, front).has(back)) arrows.add((from: at, to: back));
    }
  }
  return arrows;
}

int _distance(Square a, Square b) {
  final df = (a.file.value - b.file.value).abs();
  final dr = (a.rank.value - b.rank.value).abs();
  return df > dr ? df : dr;
}
