import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kust/features/puzzles/gol.dart';

/// Sizes of the carpet runner the puzzle levels are woven into. Level 0 sits
/// at the bottom; carpets are woven bottom up, so the work moves upward.
abstract final class LoomMetrics {
  static const double width = 160;
  static const double border = 14;

  /// Size of one göl knot and one border knot.
  static const double knot = 2.6;
  static const double borderKnot = 3;

  /// Vertical room for each level's göl.
  static const double slot = 100;

  /// Bare warp above the last göl.
  static const double top = 40;

  /// End band and fringe below the woven carpet.
  static const double band = 10;
  static const double fringe = 16;

  static double height(int levels) => top + levels * slot + band + fringe;

  /// Bottom edge of the woven carpet, where the end band starts.
  static double carpetBottom(int levels) => height(levels) - band - fringe;

  static double golCenter(int levels, int index) =>
      carpetBottom(levels) - slot * (index + 0.5);

  static double golTop(int levels, int index) =>
      golCenter(levels, index) - (golRows + 0.5) * knot;

  static double golBottom(int levels, int index) =>
      golCenter(levels, index) + (golRows + 0.5) * knot;

  /// The fell line, where weaving has reached: [woven] is the current level
  /// index plus the share of its puzzles done, e.g. 0.25 for a quarter of
  /// level 1.
  static double fell(int levels, double woven) {
    final index = woven.floor().clamp(0, levels - 1);
    final share = (woven - index).clamp(0.0, 1.0);
    final bottom = golBottom(levels, index), top = golTop(levels, index);
    return bottom - (bottom - top) * share;
  }
}

/// Paints the runner: bare warp above the fell, woven carpet below it, the
/// göls (charted dots where unwoven, knots where woven), the borders, the
/// weft thread with its shuttle and the fringe.
class LoomPainter extends CustomPainter {
  const LoomPainter({
    required this.gols,
    required this.woven,
    required this.current,
  });

  /// Göl of each level, bottom to top.
  final List<GolKind> gols;

  /// See [LoomMetrics.fell].
  final double woven;

  /// Level on the loom now; its outline is woven in saffron.
  final int current;

  static final Paint _fill = Paint()..isAntiAlias = false;

  void _rect(Canvas canvas, double x, double y, double w, double h, Color c) {
    canvas.drawRect(Rect.fromLTWH(x, y, w, h), _fill..color = c);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const w = LoomMetrics.width, b = LoomMetrics.border;
    const bk = LoomMetrics.borderKnot;
    final n = gols.length;
    final bottom = LoomMetrics.carpetBottom(n);
    final fell = (LoomMetrics.fell(n, woven) / bk).roundToDouble() * bk;

    // Shadow the runner casts on the felt.
    _rect(
      canvas,
      4,
      0,
      w,
      bottom + LoomMetrics.band + 10,
      Colors.black.withValues(alpha: 0.2),
    );

    // Bare warp above the fell.
    _rect(canvas, 0, 0, w, fell, LoomColors.warp);
    final thread = LoomColors.warpThread.withValues(alpha: 0.9);
    for (var x = 2.0; x < w; x += 5) {
      _rect(canvas, x, 0, 1.6, fell, thread);
    }

    // Woven field with a ragged top edge and faint weft rows.
    _rect(canvas, 0, fell, w, bottom - fell, LoomColors.madder);
    final random = math.Random(11);
    for (var x = 0.0; x < w; x += bk) {
      final teeth = random.nextInt(3);
      if (teeth > 0) {
        _rect(canvas, x, fell - teeth * bk, bk, teeth * bk, LoomColors.madder);
      }
    }
    final weft = Colors.black.withValues(alpha: 0.05);
    for (var y = fell + 3; y < bottom; y += 3) {
      _rect(canvas, 0, y, w, 1, weft);
    }

    // Borders: a woven zig-zag below the fell, charted dots above it.
    final sketch = LoomColors.walnut.withValues(alpha: 0.6);
    for (final x0 in const [0.0, w - b]) {
      _rect(canvas, x0, fell, b, bottom - fell, LoomColors.indigo);
      for (var k = 0; fell + k * bk < bottom; k++) {
        final t = k % 6, off = t < 3 ? t : 6 - t;
        _rect(
          canvas,
          x0 + 2.5 + off * bk,
          fell + k * bk,
          bk,
          bk,
          LoomColors.wool,
        );
      }
      _rect(
        canvas,
        x0 == 0 ? b - 1.5 : x0,
        fell,
        1.5,
        bottom - fell,
        LoomColors.saffron.withValues(alpha: 0.85),
      );
      for (var k = 0; k * bk < fell - 6; k += 2) {
        final t = k % 6, off = t < 3 ? t : 6 - t;
        _rect(canvas, x0 + 3.5 + off * bk, k * bk + 1, 2, 2, sketch);
      }
    }

    // Small star between göls.
    const g = LoomMetrics.knot;
    for (var i = 0; i < n - 1; i++) {
      final y = LoomMetrics.carpetBottom(n) - LoomMetrics.slot * (i + 1);
      for (final (dx, dy) in const [
        (0, 0),
        (-1, 1),
        (1, 1),
        (-1, -1),
        (1, -1),
        (0, 2),
        (0, -2),
        (-2, 0),
        (2, 0),
      ]) {
        final cx = w / 2 + dx * g, cy = y + dy * g;
        if (cy >= fell) {
          _rect(
            canvas,
            cx - g / 2,
            cy - g / 2,
            g,
            g,
            dx == 0 && dy == 0 ? LoomColors.saffron : LoomColors.wool,
          );
        } else if (dx * dy == 0 && (dx + dy).abs() == 2) {
          _rect(canvas, cx - 1, cy - 1, 2, 2, sketch);
        }
      }
    }

    // End band and fringe.
    _rect(canvas, 0, bottom, w, LoomMetrics.band, LoomColors.indigo);
    for (var x = 3.0; x < w - 3; x += 8) {
      _rect(canvas, x, bottom + 3, 4, 4, LoomColors.wool);
    }
    for (var x = 2.0; x < w; x += 5) {
      _rect(
        canvas,
        x,
        bottom + LoomMetrics.band,
        1.6,
        10 + (x * 7).round() % 5,
        LoomColors.fringe,
      );
    }

    for (var i = 0; i < n; i++) {
      _paintGol(
        canvas,
        GolChart.of(gols[i]),
        LoomMetrics.golCenter(n, i),
        fell,
        i == current,
      );
    }

    // Weft thread at the fell and the shuttle resting at its end.
    _rect(canvas, b, fell - 2, w - 2 * b, 2, LoomColors.saffron);
    final shuttle = Path()
      ..moveTo(w - 8, fell - 1)
      ..quadraticBezierTo(w + 8, fell - 10, w + 32, fell - 1)
      ..quadraticBezierTo(w + 8, fell + 8, w - 8, fell - 1)
      ..close();
    canvas.drawPath(shuttle, Paint()..color = LoomColors.walnut);
    _rect(canvas, w + 6, fell - 4, 12, 6, LoomColors.saffron);
  }

  void _paintGol(
    Canvas canvas,
    GolChart chart,
    double centerY,
    double fell,
    bool current,
  ) {
    const g = LoomMetrics.knot;
    final left = LoomMetrics.width / 2 - (golCols + 0.5) * g;
    final top = centerY - (golRows + 0.5) * g;
    final dot = current
        ? LoomColors.saffron
        : LoomColors.walnut.withValues(alpha: 0.7);
    for (var r = 0; r < chart.rows; r++) {
      final y = top + r * g;
      final woven = y >= fell;
      final row = chart.knots[r];
      final outline = chart.outline[r];
      final contour = chart.contour[r];
      if (woven) {
        // Merge runs of one colour into a single rect.
        var start = 0;
        Color? color;
        for (var c = 0; c <= row.length; c++) {
          Color? next;
          if (c < row.length && row[c] != null) {
            next = current && outline[c]
                ? LoomColors.saffron
                : LoomColors.of(row[c]!);
          }
          if (c == row.length || next != color) {
            if (color != null) {
              _rect(
                canvas,
                left + start * g,
                y,
                (c - start) * g + 0.05,
                g + 0.05,
                color,
              );
            }
            start = c;
            color = next;
          }
        }
      } else {
        for (var c = 0; c < row.length; c++) {
          if (row[c] == null) continue;
          // Sketch the lines of the design with a dot on every other knot.
          if (contour[c] && (r + c).isEven) {
            _rect(canvas, left + c * g + 0.3, y + 0.3, 2, 2, dot);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(LoomPainter old) =>
      old.woven != woven || old.current != current || old.gols != gols;
}
