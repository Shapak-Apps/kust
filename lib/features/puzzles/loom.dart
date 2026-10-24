import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/gol_charts.dart';

/// Sizes of the carpet runner the puzzle levels are woven into. Level 0 sits
/// at the bottom; carpets are woven bottom up, so the work moves upward.
abstract final class LoomMetrics {
  static const double width = 160;

  /// Width of the side border, including the thin line inside it.
  static const double border = 14;

  /// Size of one knot, in göls and in the side border.
  static const double knot = 1.3;

  /// Size of the coarser knots of the small stars and the end band.
  static const double bigKnot = 2.6;

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

/// One layer of the runner, recorded once and drawn many times. It is turned
/// into an image when the engine allows, so the weave animation only copies
/// pixels; otherwise the recording itself is replayed.
class _Layer {
  _Layer(ui.Picture picture, this.scale, double width, double height)
    : _picture = picture {
    try {
      _image = picture.toImageSync(
        (width * scale).ceil(),
        (height * scale).ceil(),
      );
    } catch (_) {
      _image = null;
    }
  }

  final ui.Picture _picture;
  final double scale;
  ui.Image? _image;

  /// Draws the part of the layer between [from] and [to] (in runner units).
  void draw(Canvas canvas, double width, double from, double to, Paint paint) {
    if (to <= from) return;
    final image = _image;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTRB(0, from * scale, width * scale, to * scale),
        Rect.fromLTRB(0, from, width, to),
        paint,
      );
    } else {
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(0, from, width, to))
        ..drawPicture(_picture)
        ..restore();
    }
  }
}

/// The two layers of a runner: what it looks like woven and what it looks
/// like still on the warp.
class _RunnerArt {
  _RunnerArt._(this.woven, this.warp);

  final _Layer woven;
  final _Layer warp;

  static final Map<String, _RunnerArt> _cache = {};

  static _RunnerArt of(List<GolKind> gols, double scale) {
    final key = '${gols.map((g) => g.name).join(',')}@$scale';
    return _cache[key] ??= _build(gols, scale);
  }

  static _RunnerArt _build(List<GolKind> gols, double scale) {
    const w = LoomMetrics.width;
    final h = LoomMetrics.height(gols.length);
    ui.Picture record(void Function(Canvas) paint) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(scale);
      paint(canvas);
      return recorder.endRecording();
    }

    return _RunnerArt._(
      _Layer(record((c) => _paintWoven(c, gols)), scale, w, h),
      _Layer(record((c) => _paintWarp(c, gols)), scale, w, h),
    );
  }
}

final Paint _fill = Paint()..isAntiAlias = false;

void _rect(Canvas canvas, double x, double y, double w, double h, Color c) {
  canvas.drawRect(Rect.fromLTWH(x, y, w, h), _fill..color = c);
}

/// A knot's colour with a little change of shade, as in hand-dyed wool. The
/// shade depends only on the knot's place, so it never flickers.
class _Wool {
  static final Map<Knot, List<Color>> _shades = {
    for (final knot in Knot.values)
      knot: [
        for (var v = 0; v < 5; v++)
          () {
            final base = LoomColors.of(knot);
            final amount = (v - 2) * 0.035;
            return amount < 0
                ? Color.lerp(base, Colors.black, -amount)!
                : Color.lerp(base, Colors.white, amount)!;
          }(),
      ],
  };

  static Color of(Knot knot, int row, int col) =>
      _shades[knot]![(row * 31 + col * 17 + (row ^ col) * 7) % 5];
}

/// The layer drawn below the fell: the field, göls, borders and stars, the
/// end band and the fringe.
void _paintWoven(Canvas canvas, List<GolKind> gols) {
  const w = LoomMetrics.width, k = LoomMetrics.knot;
  final n = gols.length;
  final bottom = LoomMetrics.carpetBottom(n);

  _rect(canvas, 0, 0, w, bottom, LoomColors.madder);
  final weft = Colors.black.withValues(alpha: 0.05);
  for (var y = 0.0; y < bottom; y += k * 2) {
    _rect(canvas, 0, y, w, k * 0.5, weft);
  }

  _paintBorders(canvas, bottom, woven: true);

  // A small star between göls.
  const g = LoomMetrics.bigKnot;
  for (var i = 0; i < n - 1; i++) {
    final y = bottom - LoomMetrics.slot * (i + 1);
    for (final (dx, dy) in _star) {
      _rect(
        canvas,
        w / 2 + dx * g - g / 2,
        y + dy * g - g / 2,
        g,
        g,
        dx == 0 && dy == 0 ? LoomColors.saffron : LoomColors.wool,
      );
    }
  }

  for (var i = 0; i < n; i++) {
    final chart = GolChart.of(gols[i]);
    final left = w / 2 - (golCols + 0.5) * k;
    final top = LoomMetrics.golCenter(n, i) - (golRows + 0.5) * k;
    for (var r = 0; r < chart.rows; r++) {
      final row = chart.knots[r];
      for (var c = 0; c < row.length; c++) {
        final knot = row[c];
        if (knot == null) continue;
        _rect(
          canvas,
          left + c * k,
          top + r * k,
          k + 0.05,
          k + 0.05,
          _Wool.of(knot, r, c),
        );
      }
    }
  }

  // End band and fringe.
  const b = LoomMetrics.bigKnot;
  _rect(canvas, 0, bottom, w, LoomMetrics.band, LoomColors.indigo);
  for (var x = 3.0; x < w - 3; x += b * 3) {
    _rect(canvas, x, bottom + 3, b, b, LoomColors.wool);
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
}

const List<(int, int)> _star = [
  (0, 0),
  (-1, 1),
  (1, 1),
  (-1, -1),
  (1, -1),
  (0, 2),
  (0, -2),
  (-2, 0),
  (2, 0),
];

/// The side borders, from the pattern of the flag's carpet strip, repeating
/// from top to bottom. [woven] draws the dyed wool; otherwise a faint sketch.
void _paintBorders(Canvas canvas, double bottom, {required bool woven}) {
  const w = LoomMetrics.width, k = LoomMetrics.knot;
  final tile = kBorderRows;
  final tileWidth = tile.first.length * k;
  final sketch = LoomColors.walnut.withValues(alpha: 0.55);
  for (final left in const [true, false]) {
    if (woven) {
      _rect(
        canvas,
        left ? 0 : w - tileWidth,
        0,
        tileWidth,
        bottom,
        LoomColors.indigo,
      );
    }
    var row = 0;
    for (var y = 0.0; y < bottom; y += k, row++) {
      final letters = tile[row % tile.length];
      for (var c = 0; c < letters.length; c++) {
        final knot = knotOfLetter(letters[c]);
        if (knot == null) continue;
        final x = left ? c * k : w - tileWidth + (letters.length - 1 - c) * k;
        if (woven) {
          _rect(canvas, x, y, k + 0.05, k + 0.05, _Wool.of(knot, row, c));
        } else if ((row + c).isEven) {
          _rect(canvas, x, y, k, k, sketch);
        }
      }
    }
    // A thin line of saffron closes the border on the side of the field.
    final lineX = left ? tileWidth : w - tileWidth - k;
    if (woven) {
      _rect(
        canvas,
        lineX,
        0,
        k,
        bottom,
        LoomColors.saffron.withValues(alpha: 0.85),
      );
    }
  }
}

/// The layer drawn above the fell: the bare warp with the design sketched on
/// it in dots, so the göl can be seen before it is woven.
void _paintWarp(Canvas canvas, List<GolKind> gols) {
  const w = LoomMetrics.width, k = LoomMetrics.knot;
  final n = gols.length;
  final bottom = LoomMetrics.carpetBottom(n);

  _rect(canvas, 0, 0, w, bottom, LoomColors.warp);
  final thread = LoomColors.warpThread.withValues(alpha: 0.9);
  for (var x = 2.0; x < w; x += 5) {
    _rect(canvas, x, 0, 1.6, bottom, thread);
  }

  _paintBorders(canvas, bottom, woven: false);

  final dot = LoomColors.walnut.withValues(alpha: 0.7);
  for (var i = 0; i < n; i++) {
    final chart = GolChart.of(gols[i]);
    final left = w / 2 - (golCols + 0.5) * k;
    final top = LoomMetrics.golCenter(n, i) - (golRows + 0.5) * k;
    for (var r = 0; r < chart.rows; r++) {
      for (var c = 0; c < chart.cols; c++) {
        if (chart.contour[r][c] && (r + c).isEven) {
          _rect(canvas, left + c * k, top + r * k, k, k, dot);
        }
      }
    }
  }

  // The sketch of a small star between göls.
  const g = LoomMetrics.bigKnot;
  for (var i = 0; i < n - 1; i++) {
    final y = bottom - LoomMetrics.slot * (i + 1);
    for (final (dx, dy) in _star) {
      if (dx * dy == 0 && (dx + dy).abs() == 2) {
        _rect(canvas, w / 2 + dx * g - 1, y + dy * g - 1, 2, 2, dot);
      }
    }
  }
}

/// Paints the runner: bare warp above the fell, woven carpet below it, the
/// weft thread with its shuttle, and the ragged edge where weaving has
/// reached. The art itself is drawn once and reused, so the weave animation
/// is cheap.
class LoomPainter extends CustomPainter {
  const LoomPainter({required this.gols, required this.woven});

  /// Göl of each level, bottom to top.
  final List<GolKind> gols;

  /// See [LoomMetrics.fell].
  final double woven;

  static double get _scale {
    final views = ui.PlatformDispatcher.instance.views;
    final ratio = views.isEmpty ? 3.0 : views.first.devicePixelRatio;
    return ratio.clamp(1.0, 4.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const w = LoomMetrics.width, b = LoomMetrics.border;
    const k = LoomMetrics.bigKnot;
    final n = gols.length;
    final height = LoomMetrics.height(n);
    final bottom = LoomMetrics.carpetBottom(n);
    final scale = _scale;
    // Snap the fell to whole pixels so the seam is sharp.
    final fell = (LoomMetrics.fell(n, woven) * scale).roundToDouble() / scale;
    final art = _RunnerArt.of(gols, scale);
    final paint = Paint()..filterQuality = FilterQuality.low;

    // Shadow the runner casts on the felt.
    _rect(
      canvas,
      4,
      0,
      w,
      bottom + LoomMetrics.band + 10,
      Colors.black.withValues(alpha: 0.2),
    );

    art.warp.draw(canvas, w, 0, fell, paint);
    art.woven.draw(canvas, w, fell, height, paint);

    // Ragged top edge of the woven part.
    final random = math.Random(11);
    for (var x = 0.0; x < w; x += k) {
      final teeth = random.nextInt(3);
      if (teeth > 0) {
        _rect(canvas, x, fell - teeth * k, k, teeth * k, LoomColors.madder);
      }
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

  @override
  bool shouldRepaint(LoomPainter old) => old.woven != woven || old.gols != gols;
}
