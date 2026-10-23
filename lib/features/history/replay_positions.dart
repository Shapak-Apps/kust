import 'package:dartchess/dartchess.dart';

/// Positions reached by [uciMoves], starting from the initial position.
/// Stops at the first move that cannot be played, so a damaged record still
/// opens up to that point.
({List<Position> positions, List<NormalMove?> moves}) replayPositions(
  List<String> uciMoves,
) {
  final positions = <Position>[Chess.initial];
  final moves = <NormalMove?>[null];
  for (final uci in uciMoves) {
    final move = Move.parse(uci);
    final current = positions.last;
    if (move is! NormalMove || !current.isLegal(move)) break;
    positions.add(current.play(move));
    moves.add(move);
  }
  return (positions: positions, moves: moves);
}
