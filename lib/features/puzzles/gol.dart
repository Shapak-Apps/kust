import 'package:flutter/painting.dart';

import 'package:kust/features/puzzles/gol_charts.dart';

/// The five göls of the Turkmen flag (the carpet guls of the Teke, Yomut,
/// Arsary, Chowdur and Saryk or Salyr tribes) the puzzle carpet is woven
/// from, one per level. Each is a chart the way carpets are charted: every
/// cell is one knot with one colour. The charts come from the flag itself,
/// see `tools/guls`.
enum GolKind { teke, yomut, arsary, cowdur, salyr }

/// The colour of a single knot.
enum Knot { ivory, deep, indigo, rust, saffron }

/// Natural-dye colours shared by the göls and the loom.
abstract final class LoomColors {
  static const Color felt = Color(0xFF0F4A33);
  static const Color feltDark = Color(0xFF0B3325);
  static const Color cream = Color(0xFFF4EDE0);
  static const Color wool = Color(0xFFF1E6D0);
  static const Color warp = Color(0xFFE3D6BE);
  static const Color warpThread = Color(0xFFF6EFE2);
  static const Color madder = Color(0xFF8E1E1E);
  static const Color deep = Color(0xFF4E1010);
  static const Color rust = Color(0xFFB5402F);
  static const Color indigo = Color(0xFF1E2433);
  static const Color saffron = Color(0xFFE3A72F);
  static const Color walnut = Color(0xFF6B4A2F);
  static const Color fringe = Color(0xFFCDBEA3);

  static Color of(Knot knot) => switch (knot) {
    Knot.ivory => wool,
    Knot.deep => deep,
    Knot.indigo => indigo,
    Knot.rust => rust,
    Knot.saffron => saffron,
  };
}

/// Width of every chart, in knots.
const int golChartWidth = 97;

/// Columns and rows either side of the centre of the chart grid. The tallest
/// göl is 67 knots high.
const int golCols = 50;
const int golRows = 37;

/// The knot a flag colour becomes: the flag's yellow is the carpet's saffron
/// dye, green becomes dark indigo, white wool stays ivory, the dark outline is
/// a deep brown-red and red inside the göl is a lighter madder.
Knot? knotOfLetter(String letter) => switch (letter) {
  'y' => Knot.saffron,
  'w' => Knot.ivory,
  'g' => Knot.indigo,
  'k' => Knot.deep,
  'r' => Knot.rust,
  _ => null,
};

/// The knot at column [i], row [j] of a göl, counted from its centre, or null
/// where there is no knot.
Knot? golKnot(GolKind kind, int i, int j) {
  final rows = kGolChartRows[kind.name]!;
  final r = j + rows.length ~/ 2, c = i + golChartWidth ~/ 2;
  if (r < 0 || r >= rows.length || c < 0 || c >= golChartWidth) return null;
  return knotOfLetter(rows[r][c]);
}

/// A göl's chart, computed once per kind: the knot of every cell, which cells
/// sit on its outline and which sit where colours change.
class GolChart {
  GolChart._(this.kind)
    : knots = List.generate(
        2 * golRows + 1,
        (r) => List.generate(
          2 * golCols + 1,
          (c) => golKnot(kind, c - golCols, r - golRows),
        ),
      ) {
    bool differs(int r, int c, int dr, int dc) {
      final rr = r + dr, cc = c + dc;
      if (rr < 0 || rr >= knots.length || cc < 0 || cc >= knots[r].length) {
        return true;
      }
      return knots[rr][cc] != knots[r][c];
    }

    bool touchesEmpty(int r, int c) {
      for (final (dc, dr) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final rr = r + dr, cc = c + dc;
        if (rr < 0 || rr >= knots.length || cc < 0 || cc >= knots[r].length) {
          return true;
        }
        if (knots[rr][cc] == null) return true;
      }
      return false;
    }

    outline = List.generate(
      knots.length,
      (r) => List.generate(
        knots[r].length,
        (c) => knots[r][c] != null && touchesEmpty(r, c),
      ),
    );
    contour = List.generate(
      knots.length,
      (r) => List.generate(
        knots[r].length,
        (c) =>
            knots[r][c] != null &&
            (differs(r, c, 0, 1) ||
                differs(r, c, 0, -1) ||
                differs(r, c, 1, 0) ||
                differs(r, c, -1, 0)),
      ),
    );
  }

  final GolKind kind;

  /// Rows top to bottom, columns left to right.
  final List<List<Knot?>> knots;

  /// Knots next to a cell with no knot: the edge of the göl.
  late final List<List<bool>> outline;

  /// Knots next to a different colour: the lines of the design, which are
  /// sketched on the bare warp before the göl is woven.
  late final List<List<bool>> contour;

  int get rows => knots.length;
  int get cols => knots.first.length;

  static final Map<GolKind, GolChart> _cache = {};

  static GolChart of(GolKind kind) => _cache[kind] ??= GolChart._(kind);
}
