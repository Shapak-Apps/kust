import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The five Turkmen tribal göls the puzzle carpet is woven from, one per
/// level. Each is drawn on a knot grid the way carpets are charted: every
/// cell is one knot with one colour.
enum GolKind { teke, yomut, arsary, cowdur, salyr }

/// The colour of a single knot.
enum Knot { ivory, deep, indigo, rust, saffron, leaf, orange }

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
  static const Color leaf = Color(0xFF3C7A57);
  static const Color orange = Color(0xFFC8642C);
  static const Color fringe = Color(0xFFCDBEA3);

  static Color of(Knot knot) => switch (knot) {
    Knot.ivory => wool,
    Knot.deep => deep,
    Knot.indigo => indigo,
    Knot.rust => rust,
    Knot.saffron => saffron,
    Knot.leaf => leaf,
    Knot.orange => orange,
  };
}

/// Half width and half height of a göl body, in knots.
const int golA = 24;
const int golB = 15;

/// Columns and rows of the chart around the body, wide enough for the claws
/// and hooks some göls carry outside their outline.
const int golCols = golA + 3;
const int golRows = golB + 3;

bool _oct(int i, int j, num a, num b, [double k = 1.42]) =>
    i.abs() <= a && j.abs() <= b && i.abs() / a + j.abs() / b <= k;

bool _dm(num i, num j, num a, num b) => i.abs() / a + j.abs() / b <= 1.0001;

bool _hookAt(int i, int j, int cx, int cy) =>
    (i == cx && j == cy) ||
    (i == cx + 1 && j == cy) ||
    (i == cx + 1 && j == cy + 1) ||
    (i == cx + 2 && j == cy + 1);

/// The knot at column [i], row [j] of a göl, measured from its centre, or
/// null outside the göl.
Knot? golKnot(GolKind kind, int i, int j) => switch (kind) {
  GolKind.teke => _teke(i, j),
  GolKind.yomut => _yomut(i, j),
  GolKind.arsary => _arsary(i, j),
  GolKind.cowdur => _cowdur(i, j),
  GolKind.salyr => _salyr(i, j),
};

/// Quartered octagon with diagonal colour pairs, a serrated inner contour
/// and a plant motif (lozenge with three leaves) in every quarter.
Knot? _teke(int i, int j) {
  if (!_oct(i, j, golA, golB)) return null;
  if (!_oct(i, j, golA - 1, golB - 1)) return Knot.ivory;
  if (!_oct(i, j, golA - 2, golB - 2)) return Knot.deep;
  if (!_oct(i, j, golA - 3, golB - 3)) {
    return (i.abs() + j.abs()).isEven ? Knot.ivory : Knot.deep;
  }
  if (_oct(i, j, 4, 3, 1.5)) {
    if (i.abs() <= 1 && j == 0) return Knot.saffron;
    if (_oct(i, j, 3, 2, 1.5)) return Knot.ivory;
    return Knot.deep;
  }
  if (i == 0 || j == 0) {
    return (i.abs() + j.abs()) % 3 == 0 ? Knot.ivory : Knot.deep;
  }
  final u = i.abs(), v = j.abs();
  const qx = 11, qy = 6;
  if (_dm(u - qx, v - qy, 2.6, 1.6)) {
    return u == qx && v == qy ? Knot.deep : Knot.ivory;
  }
  for (final (lx, ly) in const [(qx + 5, qy), (qx, qy + 4), (qx - 5, qy)]) {
    if (_dm(u - lx, v - ly, 1.4, 1.1)) return Knot.ivory;
  }
  if (v == qy && ((u > qx + 2 && u < qx + 4) || (u < qx - 2 && u > qx - 4))) {
    return Knot.ivory;
  }
  if (u == qx && v > qy + 1 && v < qy + 3) return Knot.ivory;
  if (_dm(u - qx, v - (qy - 4), 0.9, 0.6)) return Knot.deep;
  return i.sign == j.sign ? Knot.indigo : Knot.rust;
}

/// Dyrnak ("claw") göl: a diamond whose edges carry hooked claws, filled
/// with stepped diamond bands.
Knot? _yomut(int i, int j) {
  final t = i.abs() / golA + j.abs() / golB;
  if (t > 1.0001) {
    final u = i.abs();
    if (u % 4 == 0 && u > 2 && u < golA - 2) {
      final edge = (golB * (1 - u / golA)).round();
      if (j.abs() == edge + 1 || j.abs() == edge + 2) return Knot.ivory;
    }
    if (u % 4 == 1 && u > 2 && u < golA - 2) {
      final edge = (golB * (1 - (u - 1) / golA)).round();
      if (j.abs() == edge + 2) return Knot.ivory;
    }
    return null;
  }
  if (t > 0.9) return Knot.ivory;
  if (t > 0.82) return Knot.deep;
  if (t < 0.18) return t < 0.09 ? Knot.saffron : Knot.ivory;
  if (t < 0.3) return Knot.indigo;
  if ((t * 10).floor().isEven) {
    return i.abs() % 3 == 0 && j.abs().isEven ? Knot.ivory : Knot.rust;
  }
  return Knot.indigo;
}

/// Gülli göl: quartered octagon with clover sprays growing toward the
/// corners and an eight-point star in the middle.
Knot? _arsary(int i, int j) {
  if (!_oct(i, j, golA, golB)) return null;
  if (!_oct(i, j, golA - 1, golB - 1)) return Knot.ivory;
  if (!_oct(i, j, golA - 3, golB - 2)) {
    return (i.abs() + j.abs()) % 3 == 0 ? Knot.ivory : Knot.indigo;
  }
  if (!_oct(i, j, golA - 4, golB - 3)) return Knot.deep;
  final star = (i.abs() <= 6 && j.abs() <= 3) || _dm(i, j, 9, 5.5);
  if (star) {
    if (i.abs() + j.abs() <= 1) return Knot.saffron;
    if (_dm(i, j, 3, 2)) return Knot.deep;
    if ((i.abs() <= 5 && j.abs() <= 2) || _dm(i, j, 7.5, 4.5)) {
      return Knot.ivory;
    }
    return Knot.deep;
  }
  if (i == 0 || j == 0) return Knot.deep;
  final u = i.abs(), v = j.abs();
  if (((u - 6) * 0.5).round() == v - 2 && u >= 9 && u <= 16) return Knot.ivory;
  for (final (lx, ly) in const [(11, 6), (13, 3), (15, 7)]) {
    if (math.pow(u - lx, 2) / 2.4 + math.pow(v - ly, 2) / 1.1 <= 1.1) {
      return Knot.leaf;
    }
  }
  for (final (cx, cy) in const [(18, 7), (20, 6), (18, 9), (16, 6)]) {
    if (math.pow(u - cx, 2) / 1.6 + math.pow(v - cy, 2) / 1.1 <= 1) {
      return Knot.ivory;
    }
  }
  return i.sign == j.sign ? Knot.rust : Knot.indigo;
}

/// Ertmen göl: stepped lozenge with hooks at its corners, a central panel
/// and paired S-hooks.
Knot? _cowdur(int i, int j) {
  final qi = (i.abs() ~/ 2) * 2, qj = (j.abs() ~/ 2) * 2;
  if (!_dm(qi, qj, golA + 1, golB + 1)) {
    if (_hookAt(i.abs(), j.abs(), golA - 2, 2) ||
        _hookAt(i.abs(), j.abs(), 3, golB - 1)) {
      return Knot.ivory;
    }
    return null;
  }
  if (!_dm(qi, qj, golA - 1, golB - 1)) return Knot.ivory;
  if (!_dm(qi, qj, golA - 3, golB - 2)) return Knot.deep;
  if (i.abs() <= 4 && j.abs() <= 7) {
    if (i.abs() <= 1 && j.abs() <= 5) {
      return j.abs() <= 1 ? Knot.saffron : Knot.ivory;
    }
    if (i.abs() == 4 || j.abs() == 7) return Knot.deep;
    return Knot.indigo;
  }
  final si = i.abs() - 11, sj = j * (i == 0 ? 1 : i.sign);
  if ((si == 0 && sj >= -3 && sj <= 0) ||
      (sj == 0 && si >= 0 && si <= 2) ||
      (si == 2 && sj >= 0 && sj <= 3) ||
      (sj == 3 && si >= 2 && si <= 4)) {
    return Knot.ivory;
  }
  return i.abs().isEven && j.abs().isOdd && i.abs() > 14
      ? Knot.orange
      : Knot.rust;
}

/// Lobed octagon around an eight-point star, with pendant diamonds toward
/// the corners.
Knot? _salyr(int i, int j) {
  final theta = math.atan2(j / golB, i / golA);
  final r = math.sqrt(math.pow(i / golA, 2) + math.pow(j / golB, 2));
  final edge = 0.92 + 0.08 * math.cos(8 * theta);
  if (r > edge) return null;
  if (r > edge - 0.06) return Knot.ivory;
  if (r > edge - 0.13) return Knot.deep;
  final star = (i.abs() <= 9 && j.abs() <= 5) || _dm(i, j, 13, 8);
  final inner = (i.abs() <= 8 && j.abs() <= 4) || _dm(i, j, 11.5, 7);
  if (star && !inner) return Knot.ivory;
  if (inner) {
    if (_dm(i, j, 3, 2)) return Knot.saffron;
    if (_dm(i, j, 5, 3)) return Knot.ivory;
    return Knot.indigo;
  }
  final sx = i == 0 ? 1 : i.sign, sy = j == 0 ? 1 : j.sign;
  if (_dm(i - sx * 15, j - sy * 9, 2, 1.5)) {
    return _dm(i - sx * 15, j - sy * 9, 1, 0.7) ? Knot.saffron : Knot.ivory;
  }
  return Knot.rust;
}

/// A göl's chart, computed once per kind: the knot of every cell and which
/// cells sit on its outline.
class GolChart {
  GolChart._(this.kind)
    : knots = List.generate(
        2 * golRows + 1,
        (r) => List.generate(
          2 * golCols + 1,
          (c) => golKnot(kind, c - golCols, r - golRows),
        ),
      ) {
    outline = List.generate(
      knots.length,
      (r) => List.generate(knots[r].length, (c) {
        if (knots[r][c] == null) return false;
        for (final (dc, dr) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final rr = r + dr, cc = c + dc;
          if (rr < 0 || rr >= knots.length || cc < 0 || cc >= knots[r].length) {
            return true;
          }
          if (knots[rr][cc] == null) return true;
        }
        return false;
      }),
    );
  }

  final GolKind kind;

  /// Rows top to bottom, columns left to right.
  final List<List<Knot?>> knots;
  late final List<List<bool>> outline;

  int get rows => knots.length;
  int get cols => knots.first.length;

  static final Map<GolKind, GolChart> _cache = {};

  static GolChart of(GolKind kind) => _cache[kind] ??= GolChart._(kind);
}
