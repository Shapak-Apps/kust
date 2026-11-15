import 'package:dartchess/dartchess.dart';

/// dartchess writes a castling move as the king taking its own rook (`e1h1`);
/// the board shows, and engines say, the king's two steps (`e1g1`).
///
/// The square the king lands on when [target] is a rook's corner; any other
/// square is returned as it is.
Square castlingDisplaySquare(Square target) => switch (target) {
  Square.h1 => Square.g1,
  Square.a1 => Square.c1,
  Square.h8 => Square.g8,
  Square.a8 => Square.c8,
  _ => target,
};
