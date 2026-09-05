import 'package:dartchess/dartchess.dart';

int fileOf(Square square) => Square.values.indexOf(square) % 8;

int rankOf(Square square) => Square.values.indexOf(square) ~/ 8;

Square squareAt(int file, int rank) => Square.values[rank * 8 + file];
