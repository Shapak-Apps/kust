import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/features/learn/lessons.dart';
import 'package:kust/l10n/app_locale.dart';

/// Colours of the garden the lessons are laid out in.
abstract final class GardenColors {
  static const Color ground = Color(0xFF2B5127);
  static const Color groundLight = Color(0xFF305829);
  static const Color gold = Color(0xFFFFBB00);
}

/// Where everything sits on the Learn map: the lessons are raised tiles in a
/// diagonal staircase up a chequered garden, three steps one way and three
/// back, with a gap where a new camp starts and a summit at the top.
class LearnMapLayout {
  LearnMapLayout({
    required this.width,
    required this.count,
    this.topInset = 0,
    this.footRoom = 160,
  });

  final double width;
  final int count;

  /// Room above the last tile, under the header.
  final double topInset;

  /// Room under the first tile (the up-next card and the tab bar sit there).
  final double footRoom;

  static const double tileW = 116;
  static const double tileH = 66;
  static const double depth = 18;
  static const double step = 74;
  static const double campGap = 118;
  static const double headRoom = 250;

  /// How far right each tile stands, in half tile widths.
  static const List<int> _run = [0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1, 0];

  double get height =>
      topInset +
      headRoom +
      (count - 1) * step +
      (kCamps.length - 1) * campGap +
      footRoom;

  double get _x0 => width / 2 - 1.5 * tileW / 2;

  /// The centre of the top face of tile [i].
  Offset tile(int i) {
    var y = height - footRoom - i * step;
    for (final camp in kCamps.skip(1)) {
      if (i >= camp.first) y -= campGap - step;
    }
    return Offset(_x0 + _run[i] * tileW / 2, y);
  }

  /// Halfway between the last tile of the camp before and [camp]'s first.
  double campY(Camp camp) =>
      (tile(camp.first).dy + tile(camp.first - 1).dy) / 2;

  Offset get summit => Offset(width / 2, tile(count - 1).dy - 150);

  /// How far above the bottom edge tile [i] is.
  double fromBottom(int i) => height - tile(i).dy;
}

/// The whole garden in one picture: the chequered ground, trees, bushes,
/// rocks, a pond, the statues' pedestals and the tiles, drawn back to front.
/// It never changes while the map is open, so it is drawn once and kept.
class LearnMapPainter extends CustomPainter {
  LearnMapPainter({
    required this.layout,
    required this.done,
    required this.next,
    required this.stars,
  });

  final LearnMapLayout layout;
  final Set<String> done;

  /// The index of the next lesson, or -1 when all are done.
  final int next;
  final Map<String, int> stars;

  @override
  void paint(Canvas canvas, Size size) {
    _ground(canvas, size);
    final items = <(double, void Function())>[];
    _addDecor(canvas, items);
    for (var i = 0; i < layout.count; i++) {
      final c = layout.tile(i);
      items.add((c.dy, () => _tile(canvas, c, i)));
    }
    items.sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, draw) in items) {
      draw();
    }
  }

  void _ground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = GardenColors.ground);
    // A chessboard turned on its corner: rows of lighter diamonds.
    const w = 150.0, h = 86.0;
    final light = Paint()..color = GardenColors.groundLight;
    for (var y = 0.0; y < size.height + h; y += h) {
      for (var x = 0.0; x < size.width + w; x += w) {
        canvas.drawPath(
          Path()
            ..moveTo(x, y - h / 2)
            ..lineTo(x + w / 2, y)
            ..lineTo(x, y + h / 2)
            ..lineTo(x - w / 2, y)
            ..close(),
          light,
        );
      }
    }
  }

  // ---------------------------------------------------------------- tiles

  static Path _diamond(Offset c, double w, double h) {
    final side = w / math.sqrt2;
    final square = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: side, height: side),
          Radius.circular(side * 0.2),
        ),
      );
    final m = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(1, h / w, 1, 1)
      ..rotateZ(math.pi / 4);
    return square.transform(m.storage);
  }

  void _tile(Canvas canvas, Offset c, int i) {
    final lesson = kLessons[i];
    final finished = done.contains(lesson.id);
    final isNext = i == next;
    const w = LearnMapLayout.tileW, h = LearnMapLayout.tileH;
    const d = LearnMapLayout.depth;
    final (top, ring, rim, side, sideDark) = finished
        ? (
            const Color(0xFF7CC45B),
            const Color(0xFF6DB34E),
            const Color(0xFFA8DE8D),
            const Color(0xFF3F8130),
            const Color(0xFF2B5E21),
          )
        : isNext
        ? (
            const Color(0xFFF7C746),
            const Color(0xFFE8B02B),
            const Color(0xFFFFE394),
            const Color(0xFFB98A1C),
            const Color(0xFF86620F),
          )
        : (
            const Color(0xFF6F7F6A),
            const Color(0xFF64735F),
            const Color(0xFF93A08E),
            const Color(0xFF465341),
            const Color(0xFF333E2F),
          );

    // A soft shadow on the ground.
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(6, d + 10),
        width: w * 0.95,
        height: h * 0.7,
      ),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final face = _diamond(c, w, h);
    final bounds = face.getBounds();
    final sidePaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [side, sideDark],
          ).createShader(
            Rect.fromLTRB(bounds.left, c.dy, bounds.right, bounds.bottom + d),
          );
    canvas.drawPath(face.shift(const Offset(0, d)), sidePaint);
    canvas.drawRect(
      Rect.fromLTRB(bounds.left, c.dy, bounds.right, c.dy + d),
      sidePaint,
    );
    // Grass tufts along the bottom edge of a finished tile.
    if (finished) {
      final tuft = Paint()..color = sideDark;
      for (var x = bounds.left + 10; x < bounds.right - 8; x += 9) {
        final yEdge =
            c.dy + d + (h / 2) * (1 - ((x - c.dx).abs() / (w / 2))) - 2;
        canvas.drawCircle(Offset(x, yEdge), 3.2, tuft);
      }
    }

    canvas.drawPath(face, Paint()..color = top);
    for (final k in [0.74, 0.48]) {
      canvas.drawPath(
        _diamond(c, w * k, h * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = ring,
      );
    }
    canvas.drawPath(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = rim.withValues(alpha: 0.8),
    );

    if (finished) {
      // The tick a little above the middle and the stars under it, on the
      // face itself, so a lower tile never hides them.
      final check = Path()
        ..moveTo(c.dx - 16, c.dy - 8)
        ..lineTo(c.dx - 4, c.dy + 2)
        ..lineTo(c.dx + 18, c.dy - 18);
      Paint stroke(Color color, double width) => Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color;
      canvas.drawPath(
        check.shift(const Offset(0, 3)),
        stroke(const Color(0xFF3F8130), 8),
      );
      canvas.drawPath(check, stroke(Colors.white, 8));
      _stars(canvas, Offset(c.dx, c.dy + 15), stars[lesson.id] ?? 1);
    } else if (!isNext) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4C5948),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(1, 0.72);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  static Path _starPath(Offset c, double r) {
    final p = Path();
    for (var k = 0; k < 10; k++) {
      final a = -math.pi / 2 + k * math.pi / 5;
      final rr = k.isEven ? r : r * 0.45;
      final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  void _stars(Canvas canvas, Offset c, int count) {
    for (var k = 0; k < 3; k++) {
      final at = c + Offset((k - 1) * 13.0, k == 1 ? 1.5 : 0);
      final star = _starPath(at, 6.5);
      canvas.drawPath(
        star.shift(const Offset(0, 1.5)),
        Paint()..color = const Color(0x66000000),
      );
      canvas.drawPath(
        star,
        Paint()
          ..color = k < count ? GardenColors.gold : const Color(0xFF55604F),
      );
    }
  }

  // ---------------------------------------------------------------- decor

  /// Queues the trees, rocks and the rest to be drawn in depth order, and
  /// draws the flowers, which lie flat on the ground, straight away.
  void _addDecor(Canvas c, List<(double, void Function())> items) {
    final w = layout.width;
    double y(int i) => layout.tile(i).dy;
    void add(double at, void Function(Canvas) draw) =>
        items.add((at, () => draw(c)));

    final foot = y(0);
    add(foot + 92, (cv) => _tent(cv, Offset(w * 0.8, foot + 92)));
    add(foot + 82, (cv) => _bush(cv, Offset(w * 0.14, foot + 82), 1));
    _flowers(c, Offset(w * 0.58, foot + 66), 7, 1);
    add(foot + 8, (cv) => _tree(cv, Offset(w * 0.8, foot + 8), 1.05));
    _flowers(c, Offset(w * 0.66, foot - 40), 5, 2);

    add(y(1), (cv) => _rock(cv, Offset(w * 0.07, y(1) + 10), 0.9));
    add(y(2) + 20, (cv) => _bush(cv, Offset(w * 0.93, y(2) + 20), 0.9));
    add(y(3) + 30, (cv) => _pond(cv, Offset(w * 0.2, y(3) + 6), 0.85));
    add(y(4) + 6, (cv) => _rock(cv, Offset(w * 0.92, y(4) + 6), 0.75));
    add(y(5) + 4, (cv) => _tree(cv, Offset(w * 0.09, y(5) + 4), 0.8));
    _flowers(c, Offset(w * 0.9, y(5) - 20), 5, 3);

    final camp2 = layout.campY(kCamps[1]);
    add(camp2 + 26, (cv) => _pedestal(cv, Offset(w * 0.83, camp2 + 26)));
    add(y(6) + 16, (cv) => _tree(cv, Offset(w * 0.8, y(6) + 16), 1.1));
    add(y(7) + 14, (cv) => _bush(cv, Offset(w * 0.94, y(7) + 14), 0.8));
    _flowers(c, Offset(w * 0.1, y(7)), 6, 4);
    add(y(8) + 8, (cv) => _rock(cv, Offset(w * 0.08, y(8) + 8), 1));

    final camp3 = layout.campY(kCamps[2]);
    add(camp3 + 26, (cv) => _pedestal(cv, Offset(w * 0.17, camp3 + 26)));
    add(y(9) + 26, (cv) => _tree(cv, Offset(w * 0.14, y(9) + 26), 0.95));
    add(y(10) + 10, (cv) => _tree(cv, Offset(w * 0.06, y(10) + 10), 0.7));
    _flowers(c, Offset(w * 0.86, y(10) + 30), 6, 5);

    final top = layout.summit;
    add(top.dy + 40, (cv) => _podium(cv, top + const Offset(0, 40)));
    add(top.dy - 10, (cv) => _tree(cv, Offset(w * 0.12, top.dy - 10), 0.8));
    add(top.dy + 4, (cv) => _tree(cv, Offset(w * 0.9, top.dy + 4), 0.9));
  }

  static void _shadow(Canvas canvas, Offset base, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(center: base + Offset(w * 0.12, 0), width: w, height: h),
      Paint()
        ..color = const Color(0x38000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  static void _blob(
    Canvas canvas,
    Offset base,
    double s,
    List<(double, double, double)> circles,
    Color color,
  ) {
    final paint = Paint()..color = color;
    for (final (x, y, r) in circles) {
      canvas.drawCircle(base + Offset(x * s, y * s), r * s, paint);
    }
  }

  static void _tree(Canvas canvas, Offset base, double s) {
    _shadow(canvas, base, 86 * s, 24 * s);
    final trunk = Rect.fromLTWH(
      base.dx - 7 * s,
      base.dy - 46 * s,
      14 * s,
      48 * s,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(trunk, Radius.circular(4 * s)),
      Paint()..color = const Color(0xFF7A4B22),
    );
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 7 * s, base.dy - 46 * s, 6 * s, 48 * s),
      Paint()..color = const Color(0xFF94602F),
    );
    const shape = [
      (0.0, -80.0, 36.0),
      (-28.0, -64.0, 26.0),
      (28.0, -66.0, 27.0),
      (-12.0, -108.0, 28.0),
      (16.0, -104.0, 26.0),
    ];
    _blob(
      canvas,
      base + Offset(3 * s, 5 * s),
      s,
      shape,
      const Color(0xFF2F6A26),
    );
    _blob(canvas, base, s, shape, const Color(0xFF4E9A3A));
    _blob(canvas, base, s, const [
      (-10.0, -112.0, 18.0),
      (-30.0, -72.0, 15.0),
      (-6.0, -86.0, 20.0),
    ], const Color(0xFF68B54C));
    _blob(canvas, base, s, const [
      (-14.0, -118.0, 8.0),
      (-34.0, -78.0, 6.0),
    ], const Color(0xFF8ACB6A));
    final apple = Paint()..color = const Color(0xFFD94B3F);
    for (final (x, y) in const [
      (18.0, -84.0),
      (-20.0, -96.0),
      (6.0, -64.0),
      (30.0, -100.0),
    ]) {
      canvas.drawCircle(base + Offset(x * s, y * s), 3.2 * s, apple);
    }
  }

  static void _bush(Canvas canvas, Offset base, double s) {
    _shadow(canvas, base, 70 * s, 18 * s);
    const shape = [
      (-16.0, -14.0, 17.0),
      (12.0, -16.0, 19.0),
      (0.0, -28.0, 18.0),
    ];
    _blob(
      canvas,
      base + Offset(2 * s, 3 * s),
      s,
      shape,
      const Color(0xFF2F6A26),
    );
    _blob(canvas, base, s, shape, const Color(0xFF4E9A3A));
    _blob(canvas, base, s, const [
      (-6.0, -32.0, 10.0),
      (-20.0, -18.0, 8.0),
    ], const Color(0xFF68B54C));
  }

  static void _rock(Canvas canvas, Offset base, double s) {
    _shadow(canvas, base, 54 * s, 14 * s);
    final body = Path()
      ..moveTo(base.dx - 24 * s, base.dy)
      ..lineTo(base.dx - 18 * s, base.dy - 20 * s)
      ..lineTo(base.dx - 2 * s, base.dy - 28 * s)
      ..lineTo(base.dx + 18 * s, base.dy - 20 * s)
      ..lineTo(base.dx + 24 * s, base.dy - 2 * s)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFF9DA3AA));
    final lit = Path()
      ..moveTo(base.dx - 18 * s, base.dy - 20 * s)
      ..lineTo(base.dx - 2 * s, base.dy - 28 * s)
      ..lineTo(base.dx + 18 * s, base.dy - 20 * s)
      ..lineTo(base.dx + 2 * s, base.dy - 12 * s)
      ..close();
    canvas.drawPath(lit, Paint()..color = const Color(0xFFD3D7DC));
  }

  static void _flowers(Canvas canvas, Offset c, int n, int seed) {
    final r = math.Random(seed);
    for (var k = 0; k < n; k++) {
      final p = c + Offset(r.nextDouble() * 60 - 30, r.nextDouble() * 30 - 15);
      final petal = Paint()
        ..color = r.nextBool()
            ? const Color(0xFFF7F3E8)
            : const Color(0xFFFFD34D);
      for (var a = 0; a < 5; a++) {
        final ang = a * 2 * math.pi / 5;
        canvas.drawCircle(
          p + Offset(math.cos(ang) * 3, math.sin(ang) * 2.2),
          2.2,
          petal,
        );
      }
      canvas.drawCircle(p, 1.6, Paint()..color = const Color(0xFFE59A2E));
    }
  }

  static void _pond(Canvas canvas, Offset c, double s) {
    Path blob(double k) => Path()
      ..moveTo(c.dx - 70 * s * k, c.dy)
      ..cubicTo(
        c.dx - 72 * s * k,
        c.dy - 34 * s * k,
        c.dx - 10 * s * k,
        c.dy - 44 * s * k,
        c.dx + 30 * s * k,
        c.dy - 30 * s * k,
      )
      ..cubicTo(
        c.dx + 74 * s * k,
        c.dy - 18 * s * k,
        c.dx + 72 * s * k,
        c.dy + 28 * s * k,
        c.dx + 20 * s * k,
        c.dy + 34 * s * k,
      )
      ..cubicTo(
        c.dx - 30 * s * k,
        c.dy + 40 * s * k,
        c.dx - 68 * s * k,
        c.dy + 26 * s * k,
        c.dx - 70 * s * k,
        c.dy,
      )
      ..close();
    canvas.drawPath(blob(1.12), Paint()..color = const Color(0xFF3F7F33));
    canvas.drawPath(blob(1.0), Paint()..color = const Color(0xFF2C74C4));
    canvas.drawPath(blob(0.86), Paint()..color = const Color(0xFF3F92E3));
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x8CBFE3FF);
    canvas.drawArc(
      Rect.fromCenter(
        center: c + Offset(-20 * s, -8 * s),
        width: 24 * s,
        height: 8 * s,
      ),
      math.pi,
      math.pi * 0.8,
      false,
      wave,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: c + Offset(16 * s, 12 * s),
        width: 20 * s,
        height: 7 * s,
      ),
      math.pi,
      math.pi * 0.8,
      false,
      wave,
    );
    for (final (x, y, r) in const [
      (28.0, -10.0, 13.0),
      (-40.0, 10.0, 10.0),
      (4.0, 22.0, 8.0),
    ]) {
      final at = c + Offset(x * s, y * s);
      canvas.drawArc(
        Rect.fromCenter(center: at, width: r * 2 * s, height: r * 1.3 * s),
        0.5,
        2 * math.pi - 0.9,
        true,
        Paint()..color = const Color(0xFF58A848),
      );
    }
    final petal = Paint()..color = const Color(0xFFF06A8A);
    final at = c + Offset(30 * s, -14 * s);
    for (var a = 0; a < 6; a++) {
      final ang = a * math.pi / 3;
      canvas.drawCircle(
        at + Offset(math.cos(ang) * 4 * s, math.sin(ang) * 3 * s),
        3.2 * s,
        petal,
      );
    }
    canvas.drawCircle(at, 2.4 * s, Paint()..color = const Color(0xFFFFD34D));
    // Reeds along the back edge.
    final reed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF6DB34E);
    for (var k = 0; k < 7; k++) {
      final x = c.dx - 54 * s + k * 9 * s;
      final yb = c.dy - 30 * s + (k - 3).abs() * 3 * s;
      canvas.drawLine(
        Offset(x, yb),
        Offset(x - 3 + k % 3 * 3, yb - 16 * s - k % 2 * 6 * s),
        reed,
      );
    }
  }

  static void _tent(Canvas canvas, Offset base) {
    _shadow(canvas, base, 92, 22);
    final left = Path()
      ..moveTo(base.dx - 40, base.dy)
      ..lineTo(base.dx, base.dy - 56)
      ..lineTo(base.dx + 4, base.dy)
      ..close();
    final right = Path()
      ..moveTo(base.dx + 4, base.dy)
      ..lineTo(base.dx, base.dy - 56)
      ..lineTo(base.dx + 40, base.dy - 6)
      ..close();
    canvas.drawPath(left, Paint()..color = const Color(0xFFF08A3C));
    canvas.drawPath(right, Paint()..color = const Color(0xFFC9662A));
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 14, base.dy)
        ..lineTo(base.dx - 2, base.dy - 30)
        ..lineTo(base.dx + 2, base.dy)
        ..close(),
      Paint()..color = const Color(0xFF5A2E14),
    );
    canvas.drawLine(
      Offset(base.dx, base.dy - 56),
      Offset(base.dx, base.dy - 68),
      Paint()
        ..strokeWidth = 3
        ..color = const Color(0xFF6B4A2F),
    );
  }

  static void _box(
    Canvas canvas,
    Offset base,
    double w,
    double h,
    double tall,
    Color top,
    Color left,
    Color right,
  ) {
    final topFace = Path()
      ..moveTo(base.dx, base.dy - tall - h)
      ..lineTo(base.dx + w / 2, base.dy - tall - h / 2)
      ..lineTo(base.dx, base.dy - tall)
      ..lineTo(base.dx - w / 2, base.dy - tall - h / 2)
      ..close();
    final leftFace = Path()
      ..moveTo(base.dx - w / 2, base.dy - tall - h / 2)
      ..lineTo(base.dx, base.dy - tall)
      ..lineTo(base.dx, base.dy)
      ..lineTo(base.dx - w / 2, base.dy - h / 2)
      ..close();
    final rightFace = Path()
      ..moveTo(base.dx + w / 2, base.dy - tall - h / 2)
      ..lineTo(base.dx, base.dy - tall)
      ..lineTo(base.dx, base.dy)
      ..lineTo(base.dx + w / 2, base.dy - h / 2)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = left);
    canvas.drawPath(rightFace, Paint()..color = right);
    canvas.drawPath(topFace, Paint()..color = top);
  }

  /// A stone pedestal; its statue is drawn on top as a picture.
  static void _pedestal(Canvas canvas, Offset base) {
    _shadow(canvas, base, 96, 26);
    _box(
      canvas,
      base,
      76,
      40,
      24,
      const Color(0xFFE2DED5),
      const Color(0xFFBDB7AB),
      const Color(0xFF9C968A),
    );
  }

  /// The summit: a wide two-step podium with a flag.
  static void _podium(Canvas canvas, Offset base) {
    _shadow(canvas, base, 170, 40);
    _box(
      canvas,
      base,
      150,
      80,
      18,
      const Color(0xFFE2DED5),
      const Color(0xFFBDB7AB),
      const Color(0xFF9C968A),
    );
    _box(
      canvas,
      base - const Offset(0, 18),
      96,
      52,
      18,
      const Color(0xFFF0ECE4),
      const Color(0xFFCBC5B9),
      const Color(0xFFAAA498),
    );
    final pole = Offset(base.dx + 44, base.dy - 46);
    canvas.drawLine(
      pole,
      pole - const Offset(0, 74),
      Paint()
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFEDEDED),
    );
    canvas.drawPath(
      Path()
        ..moveTo(pole.dx + 1, pole.dy - 74)
        ..quadraticBezierTo(
          pole.dx + 22,
          pole.dy - 80,
          pole.dx + 42,
          pole.dy - 70,
        )
        ..lineTo(pole.dx + 42, pole.dy - 48)
        ..quadraticBezierTo(
          pole.dx + 22,
          pole.dy - 58,
          pole.dx + 1,
          pole.dy - 52,
        )
        ..close(),
      Paint()..color = const Color(0xFF1E8C4E),
    );
  }

  @override
  bool shouldRepaint(LearnMapPainter old) =>
      old.layout.width != layout.width ||
      old.layout.height != layout.height ||
      old.next != next ||
      old.done.length != done.length ||
      old.stars.toString() != stars.toString();
}

/// The Learn map: the garden picture, the statues, the piece standing on the
/// next tile with the coach bobbing over it, a sign where each camp starts,
/// and a tap target on every tile.
class LearnMap extends StatelessWidget {
  const LearnMap({
    super.key,
    required this.layout,
    required this.done,
    required this.stars,
    required this.onOpen,
    required this.coachImage,
  });

  final LearnMapLayout layout;
  final Set<String> done;
  final Map<String, int> stars;
  final void Function(Lesson lesson) onOpen;
  final String coachImage;

  @override
  Widget build(BuildContext context) {
    final next = kLessons.indexWhere((l) => !done.contains(l.id));
    final t = context.t;
    // A statue stands on its pedestal: [base] is the pedestal's bottom point.
    Widget statue(Offset base, Role role, double height) => Positioned(
      left: base.dx - height * 100 / 135 / 2,
      top: base.dy - 42 - height + 14,
      child: LearnPiece(role, height: height),
    );
    final w = layout.width;
    return SizedBox(
      width: w,
      height: layout.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Everything that never moves, kept as one picture.
          Positioned.fill(
            child: RepaintBoundary(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      isComplex: true,
                      painter: LearnMapPainter(
                        layout: layout,
                        done: done,
                        next: next,
                        stars: stars,
                      ),
                    ),
                  ),
                  statue(
                    Offset(w * 0.83, layout.campY(kCamps[1]) + 26),
                    Role.rook,
                    62,
                  ),
                  statue(
                    Offset(w * 0.17, layout.campY(kCamps[2]) + 26),
                    Role.queen,
                    66,
                  ),
                  statue(layout.summit + const Offset(-10, 28), Role.king, 128),
                  for (final camp in kCamps.skip(1)) _sign(context, camp, t),
                  if (next >= 0) _piece(next),
                ],
              ),
            ),
          ),
          if (next >= 0) _marker(next),
          for (var i = 0; i < kLessons.length; i++) _hit(i),
        ],
      ),
    );
  }

  Widget _piece(int i) {
    final c = layout.tile(i);
    final lesson = kLessons[i];
    const height = 104.0;
    final role = lesson.piece;
    return Positioned(
      left: c.dx - height * 100 / 135 / 2,
      top: c.dy - height + 22,
      child: role == null
          ? SizedBox(
              width: 70,
              height: height,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Icon(lesson.icon, size: 44, color: Colors.white),
              ),
            )
          : LearnPiece(role, height: height),
    );
  }

  Widget _marker(int i) {
    final c = layout.tile(i);
    return Positioned(
      left: c.dx - 32,
      top: c.dy - 176,
      width: 64,
      height: 78,
      child: RepaintBoundary(child: _Marker(image: coachImage)),
    );
  }

  Widget _sign(BuildContext context, Camp camp, AppL10n t) {
    final y = layout.campY(camp);
    return Positioned(
      left: 0,
      right: 0,
      top: y - 18,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF7A4E26),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF5A3618), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), offset: Offset(0, 4)),
            ],
          ),
          child: Text(
            '${camp.label(t)} · ${camp.title(t)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Color(0xFFFFEBC7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hit(int i) {
    final c = layout.tile(i);
    final lesson = kLessons[i];
    return Positioned(
      left: c.dx - LearnMapLayout.tileW / 2,
      top: c.dy - LearnMapLayout.tileH / 2 - 20,
      width: LearnMapLayout.tileW,
      height: LearnMapLayout.tileH + LearnMapLayout.depth + 20,
      child: Semantics(
        button: true,
        label: '${i + 1}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onOpen(lesson),
        ),
      ),
    );
  }
}

/// The coach's portrait in a white card with a tail, bobbing over the next
/// tile, the way Chess.com shows you on its map.
class _Marker extends StatefulWidget {
  const _Marker({required this.image});

  final String image;

  @override
  State<_Marker> createState() => _MarkerState();
}

class _MarkerState extends State<_Marker> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: ColoredBox(
              color: const Color(0xFF2B7553),
              child: Image.asset(
                widget.image,
                fit: BoxFit.cover,
                cacheWidth: 180,
              ),
            ),
          ),
        ),
        CustomPaint(size: const Size(16, 9), painter: _Tail()),
      ],
    );
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -4 * math.sin(_bob.value * 2 * math.pi)),
        child: child,
      ),
      child: card,
    );
  }
}

class _Tail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_Tail old) => false;
}
