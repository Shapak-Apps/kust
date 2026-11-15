import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The scenery of the Learn garden: trees, bushes, rocks, the pond, flowers,
/// the camp. Everything is lit from the upper left and casts a soft shadow
/// to the lower right, and is shaded with gradients rather than blurs, so
/// the whole map can be recorded once and drawn cheaply.
///
/// Each painter takes the point where the thing meets the ground ([base])
/// and a scale [s] (1 is the size it was drawn at).
abstract final class GardenArt {
  // ------------------------------------------------------------------ paint

  static Paint _radial(
    Rect r,
    List<Color> colors, {
    Alignment center = const Alignment(-0.35, -0.45),
    double radius = 0.95,
    List<double>? stops,
  }) => Paint()
    ..shader = RadialGradient(
      center: center,
      radius: radius,
      colors: colors,
      stops: stops,
    ).createShader(r);

  static Paint _linear(
    Rect r,
    List<Color> colors, {
    Alignment begin = Alignment.centerLeft,
    Alignment end = Alignment.centerRight,
    List<double>? stops,
  }) => Paint()
    ..shader = LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
    ).createShader(r);

  static Paint _stroke(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color;

  static Path _poly(Offset base, double s, List<(double, double)> pts) {
    final p = Path()..moveTo(base.dx + pts[0].$1 * s, base.dy + pts[0].$2 * s);
    for (final (x, y) in pts.skip(1)) {
      p.lineTo(base.dx + x * s, base.dy + y * s);
    }
    return p..close();
  }

  /// A soft shadow on the grass, cast to the lower right.
  static void shadow(
    Canvas c,
    Offset base,
    double w,
    double h, {
    double opacity = 0.34,
  }) {
    final r = Rect.fromCenter(
      center: base + Offset(w * 0.14, h * 0.06),
      width: w,
      height: h,
    );
    c.drawOval(
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(8, 24, 6, opacity),
            Color.fromRGBO(8, 24, 6, opacity * 0.5),
            const Color.fromRGBO(8, 24, 6, 0),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(r),
    );
  }

  // ---------------------------------------------------------------- foliage

  static const Color _leafLight = Color(0xFFA6DE7C);
  static const Color _leaf = Color(0xFF5DAE48);
  static const Color _leafDark = Color(0xFF337A33);
  static const Color _leafDeep = Color(0xFF1E5124);

  /// A crown of leaves as a cluster of balls, each shaded on its own, the
  /// lower ones drawn over the upper ones so the crown looks bumpy and full.
  static void _foliage(
    Canvas c,
    Offset base,
    double s,
    List<(double, double, double)> balls, {
    Color light = _leafLight,
    Color mid = _leaf,
    Color dark = _leafDark,
    Color deep = _leafDeep,
  }) {
    final deepPaint = Paint()..color = deep;
    for (final (x, y, r) in balls) {
      c.drawCircle(base + Offset((x + 3) * s, (y + 4) * s), r * s, deepPaint);
    }
    final sorted = [...balls]..sort((a, b) => a.$2.compareTo(b.$2));
    final dab = Paint()..color = light.withValues(alpha: 0.5);
    final dent = Paint()..color = deep.withValues(alpha: 0.3);
    for (final (x, y, r) in sorted) {
      final at = base + Offset(x * s, y * s);
      final rect = Rect.fromCircle(center: at, radius: r * s);
      c.drawCircle(
        at,
        r * s,
        _radial(
          rect,
          [light, mid, dark],
          radius: 1.1,
          stops: const [0, 0.5, 1],
        ),
      );
      // Leaf texture: lit flecks up and left, dents down and right.
      for (final (dx, dy, k) in const [
        (-0.42, -0.38, 0.2),
        (-0.08, -0.56, 0.15),
        (-0.6, 0.0, 0.13),
      ]) {
        c.drawOval(
          Rect.fromCenter(
            center: at + Offset(dx * r * s, dy * r * s),
            width: k * r * s * 2.2,
            height: k * r * s * 1.4,
          ),
          dab,
        );
      }
      for (final (dx, dy, k) in const [
        (0.5, 0.3, 0.2),
        (0.16, 0.6, 0.17),
        (0.62, -0.12, 0.13),
      ]) {
        c.drawOval(
          Rect.fromCenter(
            center: at + Offset(dx * r * s, dy * r * s),
            width: k * r * s * 2.2,
            height: k * r * s * 1.5,
          ),
          dent,
        );
      }
    }
  }

  static void _fruit(Canvas c, Offset at, double r, List<Color> colors) {
    final rect = Rect.fromCircle(center: at, radius: r);
    c.drawCircle(
      at + Offset(r * 0.25, r * 0.35),
      r,
      Paint()..color = const Color(0x55102A0C),
    );
    c.drawCircle(at, r, _radial(rect, colors, stops: const [0, 0.55, 1]));
    c.drawCircle(
      at + Offset(-r * 0.35, -r * 0.38),
      r * 0.28,
      Paint()..color = const Color(0xCCFFFFFF),
    );
  }

  static const List<Color> _apple = [
    Color(0xFFFF9A86),
    Color(0xFFE2463A),
    Color(0xFF9B2219),
  ];

  // ------------------------------------------------------------------ trees

  /// A round, leafy fruit tree.
  static void tree(Canvas c, Offset base, double s, {bool fruit = true}) {
    shadow(c, base, 104 * s, 30 * s);
    final trunk = Path()
      ..moveTo(base.dx - 12 * s, base.dy + 1 * s)
      ..quadraticBezierTo(
        base.dx - 6 * s,
        base.dy - 5 * s,
        base.dx - 6 * s,
        base.dy - 20 * s,
      )
      ..lineTo(base.dx - 5 * s, base.dy - 56 * s)
      ..lineTo(base.dx + 5 * s, base.dy - 56 * s)
      ..lineTo(base.dx + 6 * s, base.dy - 20 * s)
      ..quadraticBezierTo(
        base.dx + 6 * s,
        base.dy - 5 * s,
        base.dx + 13 * s,
        base.dy + 1 * s,
      )
      ..quadraticBezierTo(
        base.dx,
        base.dy + 4 * s,
        base.dx - 12 * s,
        base.dy + 1 * s,
      )
      ..close();
    c.drawPath(
      trunk,
      _linear(
        trunk.getBounds(),
        const [Color(0xFFB8854C), Color(0xFF8A5A2D), Color(0xFF55351A)],
        stops: const [0, 0.45, 1],
      ),
    );
    final bark = _stroke(const Color(0x804A2D14), 1.3 * s);
    c.drawLine(
      base + Offset(1.5 * s, -8 * s),
      base + Offset(2 * s, -30 * s),
      bark,
    );
    c.drawLine(
      base + Offset(-1.5 * s, -24 * s),
      base + Offset(-2 * s, -44 * s),
      bark,
    );
    // Branches reaching into the crown.
    final branch = _stroke(const Color(0xFF6B4423), 4.2 * s);
    c.drawPath(
      Path()
        ..moveTo(base.dx - 2 * s, base.dy - 48 * s)
        ..quadraticBezierTo(
          base.dx - 8 * s,
          base.dy - 62 * s,
          base.dx - 20 * s,
          base.dy - 72 * s,
        ),
      branch,
    );
    c.drawPath(
      Path()
        ..moveTo(base.dx + 2 * s, base.dy - 50 * s)
        ..quadraticBezierTo(
          base.dx + 9 * s,
          base.dy - 64 * s,
          base.dx + 18 * s,
          base.dy - 76 * s,
        ),
      branch,
    );
    _foliage(c, base, s, const [
      (-30, -74, 24),
      (30, -76, 25),
      (0, -88, 32),
      (-20, -110, 26),
      (18, -112, 24),
      (-2, -130, 20),
    ]);
    if (fruit) {
      for (final (x, y) in const [
        (20.0, -86.0),
        (-24.0, -98.0),
        (6.0, -70.0),
        (32.0, -104.0),
        (-8.0, -120.0),
        (-36.0, -72.0),
      ]) {
        _fruit(c, base + Offset(x * s, y * s), 3.8 * s, _apple);
      }
    }
  }

  /// A tall, dark conifer, for contrast with the round trees.
  static void pine(Canvas c, Offset base, double s) {
    shadow(c, base, 66 * s, 20 * s);
    final trunk = Rect.fromLTRB(
      base.dx - 4 * s,
      base.dy - 18 * s,
      base.dx + 4 * s,
      base.dy + 1 * s,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(trunk, Radius.circular(2 * s)),
      _linear(trunk, const [Color(0xFF9C6A38), Color(0xFF4F3118)]),
    );
    const tiers = [
      (-12.0, 31.0, 46.0),
      (-36.0, 26.0, 42.0),
      (-58.0, 20.0, 38.0),
      (-78.0, 14.0, 32.0),
    ];
    for (final (bottom, half, tall) in tiers) {
      final apex = base + Offset(0, (bottom - tall) * s);
      final bl = base + Offset(-half * s, bottom * s);
      final br = base + Offset(half * s, bottom * s);
      final bc = base + Offset(0, (bottom + 5) * s);
      final left = Path()
        ..moveTo(apex.dx, apex.dy)
        ..quadraticBezierTo(
          apex.dx - half * 0.55 * s,
          apex.dy + tall * 0.55 * s,
          bl.dx,
          bl.dy,
        )
        ..quadraticBezierTo(bl.dx + half * 0.5 * s, bc.dy, bc.dx, bc.dy)
        ..close();
      final right = Path()
        ..moveTo(apex.dx, apex.dy)
        ..lineTo(bc.dx, bc.dy)
        ..quadraticBezierTo(br.dx - half * 0.5 * s, bc.dy, br.dx, br.dy)
        ..quadraticBezierTo(
          apex.dx + half * 0.55 * s,
          apex.dy + tall * 0.55 * s,
          apex.dx,
          apex.dy,
        )
        ..close();
      // The tier above shades the top of this one.
      c.drawPath(
        right,
        _linear(
          right.getBounds(),
          const [Color(0xFF2E6E48), Color(0xFF1C4B30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
      c.drawPath(
        left,
        _linear(
          left.getBounds(),
          const [Color(0xFF7CC68F), Color(0xFF3F8F5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
      c.drawPath(
        Path()
          ..moveTo(apex.dx - 1 * s, apex.dy + 4 * s)
          ..quadraticBezierTo(
            apex.dx - half * 0.5 * s,
            apex.dy + tall * 0.55 * s,
            bl.dx + 3 * s,
            bl.dy - 2 * s,
          ),
        _stroke(const Color(0x66E4FFD9), 1.4 * s),
      );
    }
  }

  // ----------------------------------------------------------------- bushes

  static void bush(Canvas c, Offset base, double s, {List<Color>? berries}) {
    shadow(c, base, 80 * s, 22 * s);
    _foliage(c, base, s, const [
      (-19, -13, 15),
      (17, -13, 16),
      (-3, -20, 19),
      (11, -31, 12),
      (-14, -30, 12),
    ]);
    if (berries != null) {
      for (final (x, y) in const [
        (-14.0, -26.0),
        (6.0, -30.0),
        (18.0, -16.0),
        (-6.0, -12.0),
        (-22.0, -12.0),
        (12.0, -36.0),
      ]) {
        _fruit(c, base + Offset(x * s, y * s), 2.6 * s, berries);
      }
    }
  }

  static const List<Color> pinkBerries = [
    Color(0xFFFFC2D8),
    Color(0xFFE5579A),
    Color(0xFF962660),
  ];

  static const List<Color> blueBerries = [
    Color(0xFFB7CCFF),
    Color(0xFF5577D9),
    Color(0xFF2B3E8C),
  ];

  // ------------------------------------------------------------------ rocks

  /// A faceted boulder, lit on top, with moss when [moss] is set.
  static void rock(Canvas c, Offset base, double s, {bool moss = false}) {
    shadow(c, base, 64 * s, 16 * s);
    final outline = _poly(base, s, const [
      (-27, 0),
      (-23, -16),
      (-9, -29),
      (10, -28),
      (25, -15),
      (28, -1),
      (11, 3),
      (-13, 3),
    ]);
    c.drawPath(outline, Paint()..color = const Color(0xFF6E7681));
    final top = _poly(base, s, const [
      (-23, -16),
      (-9, -29),
      (10, -28),
      (25, -15),
      (6, -12),
      (-10, -11),
    ]);
    c.drawPath(
      top,
      _linear(
        top.getBounds(),
        const [Color(0xFFF2F4F6), Color(0xFFC6CCD3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
    final left = _poly(base, s, const [
      (-27, 0),
      (-23, -16),
      (-10, -11),
      (-4, 2),
      (-13, 3),
    ]);
    c.drawPath(
      left,
      _linear(left.getBounds(), const [Color(0xFFC0C6CE), Color(0xFF9AA2AC)]),
    );
    final right = _poly(base, s, const [
      (6, -12),
      (25, -15),
      (28, -1),
      (11, 3),
      (-4, 2),
      (-10, -11),
    ]);
    c.drawPath(
      right,
      _linear(right.getBounds(), const [Color(0xFF959EA9), Color(0xFF656D78)]),
    );
    c.drawPath(
      Path()
        ..moveTo(base.dx - 23 * s, base.dy - 16 * s)
        ..lineTo(base.dx - 9 * s, base.dy - 29 * s)
        ..lineTo(base.dx + 10 * s, base.dy - 28 * s),
      _stroke(const Color(0xB3FFFFFF), 1.2 * s),
    );
    c.drawPath(
      Path()
        ..moveTo(base.dx + 14 * s, base.dy - 9 * s)
        ..lineTo(base.dx + 18 * s, base.dy - 3 * s),
      _stroke(const Color(0x66323840), 1.2 * s),
    );
    if (moss) {
      c.save();
      c.clipPath(top);
      final m = base + Offset(-6 * s, -24 * s);
      final rect = Rect.fromCenter(center: m, width: 34 * s, height: 16 * s);
      c.drawOval(
        rect,
        _radial(rect, const [Color(0xFFA8DC7E), Color(0xFF5DA746)]),
      );
      c.restore();
      for (final (x, y) in const [(-14.0, -16.0), (2.0, -20.0)]) {
        c.drawCircle(
          base + Offset(x * s, y * s),
          2 * s,
          Paint()..color = const Color(0xFF6CB651),
        );
      }
    }
  }

  // ------------------------------------------------------------------- pond

  static Path _pondShape(Offset c, double s, double k) => Path()
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

  /// A pond with a pebbled bank, deep water in the middle, lily pads with a
  /// lotus, and cattails at the back.
  static void pond(Canvas c, Offset center, double s) {
    final bank = _pondShape(center, s, 1.14);
    c.drawPath(
      bank.shift(Offset(4 * s, 5 * s)),
      Paint()..color = const Color(0x40102A0C),
    );
    c.drawPath(bank, Paint()..color = const Color(0xFFD2BE8C));
    final water = _pondShape(center, s, 1.0);
    final wb = water.getBounds();
    c.drawPath(
      water,
      _linear(
        wb,
        const [Color(0xFF14497F), Color(0xFF2A78C4), Color(0xFF63B8EE)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, 0.45, 1],
      ),
    );
    c.save();
    c.clipPath(water);
    // The far bank's shadow on the water, and the sky's shine on it.
    c.drawPath(
      Path.combine(
        PathOperation.difference,
        water,
        water.shift(Offset(0, 9 * s)),
      ),
      Paint()..color = const Color(0x55061B33),
    );
    final glow = Rect.fromCenter(
      center: center + Offset(-18 * s, -6 * s),
      width: 110 * s,
      height: 44 * s,
    );
    c.drawOval(
      glow,
      _radial(glow, const [
        Color(0x55FFFFFF),
        Color(0x00FFFFFF),
      ], center: Alignment.center),
    );
    final shine = _stroke(const Color(0x88E9F6FF), 2 * s);
    c.drawLine(
      center + Offset(-46 * s, -6 * s),
      center + Offset(-26 * s, -10 * s),
      shine,
    );
    c.drawLine(
      center + Offset(-20 * s, 18 * s),
      center + Offset(-6 * s, 16 * s),
      shine,
    );
    final ripple = _stroke(const Color(0x66CFEAFF), 1.3 * s);
    for (final k in [1.0, 1.7]) {
      c.drawOval(
        Rect.fromCenter(
          center: center + Offset(18 * s, 14 * s),
          width: 16 * s * k,
          height: 5 * s * k,
        ),
        ripple,
      );
    }
    c.restore();

    // Pebbles along the bank.
    final r = math.Random(7);
    for (final metric in _pondShape(center, s, 1.08).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 13 * s) {
        if (r.nextDouble() < 0.25) continue;
        final pos = metric.getTangentForOffset(d)!.position;
        final w = (7 + r.nextDouble() * 5) * s;
        final pebble = Rect.fromCenter(center: pos, width: w, height: w * 0.62);
        c.drawOval(
          pebble.shift(Offset(0.8 * s, 1.2 * s)),
          Paint()..color = const Color(0x55222A20),
        );
        c.drawOval(
          pebble,
          _linear(
            pebble,
            const [Color(0xFFEDEFF1), Color(0xFFA9B0B8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      }
    }

    for (final (x, y, rr, turn) in const [
      (26.0, -8.0, 13.0, 0.3),
      (-40.0, 10.0, 10.0, 2.4),
      (4.0, 22.0, 8.0, 4.6),
    ]) {
      _lilyPad(c, center + Offset(x * s, y * s), rr * s, turn);
    }
    _lotus(c, center + Offset(30 * s, -12 * s), s);

    // Cattails and reeds at the back.
    for (var k = 0; k < 6; k++) {
      final x = center.dx - 52 * s + k * 8 * s;
      final yb = center.dy - 31 * s + (k - 3).abs() * 2.5 * s;
      final lean = (k % 3 - 1) * 3 * s;
      final tall = (22 + (k % 2) * 8) * s;
      final tip = Offset(x + lean, yb - tall);
      c.drawLine(Offset(x, yb), tip, _stroke(const Color(0xFF4F9A3A), 2 * s));
      c.drawPath(
        Path()
          ..moveTo(x - 1 * s, yb)
          ..quadraticBezierTo(
            x - 6 * s,
            yb - tall * 0.5,
            x - 9 * s + lean,
            yb - tall * 0.75,
          ),
        _stroke(const Color(0xFF6DBF51), 1.8 * s),
      );
      if (k.isEven) {
        final head = Rect.fromCenter(
          center: tip + Offset(0, 6 * s),
          width: 5 * s,
          height: 11 * s,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(head, Radius.circular(2.5 * s)),
          _linear(head, const [Color(0xFFA36A3A), Color(0xFF5C3519)]),
        );
      }
    }
  }

  static void _lilyPad(Canvas c, Offset at, double r, double turn) {
    final rect = Rect.fromCenter(center: at, width: r * 2, height: r * 1.3);
    c.drawOval(
      rect.shift(Offset(r * 0.12, r * 0.18)),
      Paint()..color = const Color(0x55082440),
    );
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(1, 0.65);
    c.rotate(turn);
    final pad = Path()
      ..moveTo(0, 0)
      ..arcTo(
        Rect.fromCircle(center: Offset.zero, radius: r),
        0.22,
        2 * math.pi - 0.44,
        false,
      )
      ..close();
    c.drawPath(
      pad,
      _radial(Rect.fromCircle(center: Offset.zero, radius: r), const [
        Color(0xFF9CD978),
        Color(0xFF4E9B3D),
        Color(0xFF2F7030),
      ]),
    );
    final vein = _stroke(const Color(0x553A7A2C), r * 0.08);
    for (var k = 1; k < 6; k++) {
      final a = 0.22 + k * (2 * math.pi - 0.44) / 6;
      c.drawLine(
        Offset.zero,
        Offset(math.cos(a) * r * 0.8, math.sin(a) * r * 0.8),
        vein,
      );
    }
    c.restore();
  }

  static void _lotus(Canvas c, Offset at, double s) {
    void petal(double angle, double len, List<Color> colors) {
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(angle);
      final p = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-4.2 * s, -len * 0.55, 0, -len)
        ..quadraticBezierTo(4.2 * s, -len * 0.55, 0, 0)
        ..close();
      c.drawPath(
        p,
        _linear(
          p.getBounds(),
          colors,
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      );
      c.restore();
    }

    for (final a in [-1.5, -0.75, 0.0, 0.75, 1.5]) {
      petal(a, 10 * s, const [Color(0xFFD9558A), Color(0xFFF7A7C6)]);
    }
    for (final a in [-0.6, 0.0, 0.6]) {
      petal(a, 8 * s, const [Color(0xFFF07BA8), Color(0xFFFFE1EC)]);
    }
    c.drawCircle(at, 2.2 * s, Paint()..color = const Color(0xFFFFD34D));
  }

  // ----------------------------------------------------------------- meadow

  static const List<(Color, Color)> _petals = [
    (Color(0xFFFFFFFF), Color(0xFFE9E4D6)),
    (Color(0xFFFFE27A), Color(0xFFF2B829)),
    (Color(0xFFFFB8CF), Color(0xFFE5709A)),
    (Color(0xFFD6C6FF), Color(0xFF9479E0)),
  ];

  /// A few blades of grass.
  static void tuft(Canvas c, Offset at, double s, Color color) {
    final p = Paint()..color = color;
    for (final (lean, tall) in const [
      (-5.0, 9.0),
      (-1.0, 12.0),
      (3.0, 10.0),
      (6.0, 7.0),
    ]) {
      c.drawPath(
        Path()
          ..moveTo(at.dx - 1.6 * s, at.dy)
          ..quadraticBezierTo(
            at.dx + lean * 0.3 * s,
            at.dy - tall * 0.6 * s,
            at.dx + lean * s,
            at.dy - tall * s,
          )
          ..quadraticBezierTo(
            at.dx + lean * 0.2 * s + 1 * s,
            at.dy - tall * 0.5 * s,
            at.dx + 1.6 * s,
            at.dy,
          )
          ..close(),
        p,
      );
    }
  }

  static void _flower(Canvas c, Offset at, double s, (Color, Color) colors) {
    c.drawLine(
      at + Offset(0, 7 * s),
      at,
      _stroke(const Color(0xFF3F8A33), 1.1 * s),
    );
    c.drawOval(
      Rect.fromCenter(
        center: at + Offset(1 * s, 7.5 * s),
        width: 6 * s,
        height: 2 * s,
      ),
      Paint()..color = const Color(0x40102A0C),
    );
    final paint = _radial(Rect.fromCircle(center: at, radius: 4.5 * s), [
      colors.$1,
      colors.$2,
    ], center: Alignment.center);
    for (var a = 0; a < 5; a++) {
      final ang = -math.pi / 2 + a * 2 * math.pi / 5;
      c.drawOval(
        Rect.fromCenter(
          center: at + Offset(math.cos(ang) * 2.8 * s, math.sin(ang) * 2.1 * s),
          width: 3.6 * s,
          height: 3 * s,
        ),
        paint,
      );
    }
    c.drawCircle(at, 1.4 * s, Paint()..color = const Color(0xFFE38A1E));
  }

  /// A patch of grass and flowers around [center].
  static void meadow(
    Canvas c,
    Offset center,
    int flowers,
    int seed, {
    double spread = 36,
  }) {
    final r = math.Random(seed);
    for (var k = 0; k < flowers + 3; k++) {
      final p =
          center +
          Offset(
            (r.nextDouble() * 2 - 1) * spread,
            (r.nextDouble() * 2 - 1) * spread * 0.45,
          );
      tuft(c, p + const Offset(3, 6), 0.9, const Color(0xFF4C9A3B));
    }
    final spots = <Offset>[
      for (var k = 0; k < flowers; k++)
        center +
            Offset(
              (r.nextDouble() * 2 - 1) * spread,
              (r.nextDouble() * 2 - 1) * spread * 0.45,
            ),
    ]..sort((a, b) => a.dy.compareTo(b.dy));
    for (final p in spots) {
      _flower(c, p, 1, _petals[r.nextInt(_petals.length)]);
    }
  }

  /// Two spotted mushrooms.
  static void mushrooms(Canvas c, Offset base, double s) {
    for (final (dx, k) in const [(-6.0, 1.0), (7.0, 0.72)]) {
      final at = base + Offset(dx * s, 0);
      final sk = s * k;
      shadow(c, at, 18 * sk, 6 * sk, opacity: 0.3);
      final stem = Rect.fromLTRB(
        at.dx - 3 * sk,
        at.dy - 11 * sk,
        at.dx + 3 * sk,
        at.dy,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(stem, Radius.circular(2 * sk)),
        _linear(stem, const [Color(0xFFFFFBF0), Color(0xFFD7CDB6)]),
      );
      final cap = Rect.fromCenter(
        center: at - Offset(0, 11 * sk),
        width: 20 * sk,
        height: 16 * sk,
      );
      final capPath = Path()
        ..addArc(cap, math.pi, math.pi)
        ..quadraticBezierTo(
          cap.center.dx,
          cap.center.dy + 3 * sk,
          cap.left,
          cap.center.dy,
        );
      c.drawPath(
        capPath,
        _radial(cap, const [
          Color(0xFFFF8D7A),
          Color(0xFFDD3B2F),
          Color(0xFF8E1D16),
        ]),
      );
      final dot = Paint()..color = const Color(0xF2FFFFFF);
      for (final (x, y, rr) in const [
        (-4.0, -4.5, 1.6),
        (3.0, -5.5, 1.3),
        (-0.5, -1.5, 1.1),
        (6.0, -2.0, 1.0),
      ]) {
        c.drawCircle(cap.center + Offset(x * sk, y * sk), rr * sk, dot);
      }
    }
  }

  /// A cut log lying on the grass.
  static void log(Canvas c, Offset base, double s) {
    shadow(c, base, 64 * s, 14 * s);
    final body = Rect.fromLTRB(
      base.dx - 26 * s,
      base.dy - 13 * s,
      base.dx + 22 * s,
      base.dy,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(6.5 * s)),
      _linear(
        body,
        const [Color(0xFFB27A44), Color(0xFF7B4E26), Color(0xFF4E3018)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
    final bark = _stroke(const Color(0x664A2D14), 1.1 * s);
    c.drawLine(
      Offset(body.left + 8 * s, body.top + 4 * s),
      Offset(body.right - 12 * s, body.top + 4.5 * s),
      bark,
    );
    c.drawLine(
      Offset(body.left + 14 * s, body.top + 8.5 * s),
      Offset(body.right - 6 * s, body.top + 9 * s),
      bark,
    );
    final end = Rect.fromCenter(
      center: Offset(body.right, body.center.dy),
      width: 10 * s,
      height: 13 * s,
    );
    c.drawOval(
      end,
      _radial(end, const [
        Color(0xFFF2D19C),
        Color(0xFFD29A5A),
      ], center: Alignment.center),
    );
    c.drawOval(end.deflate(2.4 * s), _stroke(const Color(0x88A8693A), 0.9 * s));
  }

  // ------------------------------------------------------------------- camp

  /// A ridge tent seen from the front left, with its door open.
  static void tent(Canvas c, Offset base) {
    shadow(c, base + const Offset(10, 0), 124, 30, opacity: 0.4);
    const apex = Offset(-4, -62);
    const back = Offset(26, -74);
    // Guy ropes and pegs.
    final rope = _stroke(const Color(0xAAE9DFC8), 1);
    c.drawLine(base + apex, base + const Offset(-60, 6), rope);
    c.drawLine(base + back, base + const Offset(78, -8), rope);
    for (final p in const [Offset(-60, 6), Offset(78, -8)]) {
      c.drawLine(
        base + p,
        base + p + const Offset(0, -5),
        _stroke(const Color(0xFF6B4A2F), 2),
      );
    }
    // The far side, in shade.
    final side = _poly(base, 1, const [
      (-4, -62),
      (26, -74),
      (64, -10),
      (36, 2),
    ]);
    c.drawPath(
      side,
      _linear(side.getBounds(), const [Color(0xFFC75E24), Color(0xFF8E3C14)]),
    );
    // The front, in light.
    final front = _poly(base, 1, const [(-46, 2), (-4, -62), (36, 2)]);
    c.drawPath(
      front,
      _linear(
        front.getBounds(),
        const [Color(0xFFFFB066), Color(0xFFF07F34), Color(0xFFD9652A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
    // Hem and ridge seams.
    c.drawLine(
      base + const Offset(-44, -2),
      base + const Offset(34, -2),
      _stroke(const Color(0x66FFFFFF), 1.4),
    );
    c.drawLine(base + apex, base + back, _stroke(const Color(0xCCFFD2A6), 1.6));
    // The open door, its flaps tied back.
    final door = _poly(base, 1, const [(-16, 2), (-4, -40), (10, 2)]);
    c.drawPath(
      door,
      _linear(
        door.getBounds(),
        const [Color(0xFF3B1A0A), Color(0xFF140703)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
    c.drawPath(
      _poly(base, 1, const [(-16, 2), (-4, -40), (-24, 2)]),
      Paint()..color = const Color(0xFFFFC68E),
    );
    c.drawPath(
      _poly(base, 1, const [(10, 2), (-4, -40), (16, 2)]),
      Paint()..color = const Color(0xFFE3742F),
    );
    // Pole tips.
    final pole = _stroke(const Color(0xFF5A3A22), 2.4);
    c.drawLine(base + apex, base + apex + const Offset(-1, -8), pole);
    c.drawLine(base + back, base + back + const Offset(0, -7), pole);
  }

  /// A small fire in a ring of stones, with its glow on the grass.
  static void campfire(Canvas c, Offset base, double s) {
    final glow = Rect.fromCenter(center: base, width: 110 * s, height: 46 * s);
    c.drawOval(
      glow,
      _radial(
        glow,
        const [Color(0x66FFB347), Color(0x22FFB347), Color(0x00FFB347)],
        center: Alignment.center,
        stops: const [0, 0.5, 1],
      ),
    );
    void stones(bool front) {
      for (var k = 0; k < 9; k++) {
        final a = k * 2 * math.pi / 9;
        final isFront = math.sin(a) > 0;
        if (isFront != front) continue;
        final at = base + Offset(math.cos(a) * 17 * s, math.sin(a) * 7 * s);
        final r = Rect.fromCenter(center: at, width: 9 * s, height: 6 * s);
        c.drawOval(
          r,
          _linear(
            r,
            const [Color(0xFFE6E8EA), Color(0xFF8C939C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      }
    }

    stones(false);
    // Crossed logs.
    for (final turn in [-0.42, 0.42]) {
      c.save();
      c.translate(base.dx, base.dy - 3 * s);
      c.rotate(turn);
      final logRect = Rect.fromCenter(
        center: Offset.zero,
        width: 26 * s,
        height: 6 * s,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(logRect, Radius.circular(3 * s)),
        _linear(
          logRect,
          const [Color(0xFF9A6534), Color(0xFF4A2C14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      );
      c.restore();
    }
    // Flames, outer to inner.
    Path flame(double w, double h) => Path()
      ..moveTo(base.dx - w * s, base.dy - 4 * s)
      ..quadraticBezierTo(
        base.dx - w * 1.1 * s,
        base.dy - h * 0.5 * s,
        base.dx - 1 * s,
        base.dy - h * s,
      )
      ..quadraticBezierTo(
        base.dx + w * 0.4 * s,
        base.dy - h * 0.62 * s,
        base.dx + w * 0.55 * s,
        base.dy - h * 0.72 * s,
      )
      ..quadraticBezierTo(
        base.dx + w * 1.2 * s,
        base.dy - h * 0.35 * s,
        base.dx + w * s,
        base.dy - 4 * s,
      )
      ..close();
    final outer = flame(10, 30);
    c.drawPath(
      outer,
      _linear(
        outer.getBounds(),
        const [Color(0xFFFFB13B), Color(0xFFF0462A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
    final midFlame = flame(6.5, 21);
    c.drawPath(
      midFlame,
      _linear(
        midFlame.getBounds(),
        const [Color(0xFFFFE07A), Color(0xFFFF8A2B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
    c.drawPath(flame(3.4, 12), Paint()..color = const Color(0xFFFFF6D6));
    final spark = Paint()..color = const Color(0xCCFFD36B);
    for (final (x, y) in const [(-7.0, -36.0), (6.0, -42.0), (1.0, -50.0)]) {
      c.drawCircle(base + Offset(x * s, y * s), 1.2 * s, spark);
    }
    stones(true);
  }

  // ------------------------------------------------------------------ stone

  /// A block of pale stone, its faces lit from the upper left and its top
  /// edges caught by the light.
  static void block(Canvas c, Offset base, double w, double h, double tall) {
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
    c.drawPath(
      leftFace,
      _linear(
        leftFace.getBounds(),
        const [Color(0xFFD4CEC2), Color(0xFFB2AB9E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
    c.drawPath(
      rightFace,
      _linear(
        rightFace.getBounds(),
        const [Color(0xFFA59E91), Color(0xFF857E72)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
    c.drawPath(
      topFace,
      _linear(
        topFace.getBounds(),
        const [Color(0xFFFFFDF8), Color(0xFFE2DCD0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
    final edge = _stroke(const Color(0xCCFFFFFF), 1.2);
    c.drawLine(
      Offset(base.dx - w / 2, base.dy - tall - h / 2),
      Offset(base.dx, base.dy - tall),
      edge,
    );
    c.drawLine(
      Offset(base.dx, base.dy - tall),
      Offset(base.dx + w / 2, base.dy - tall - h / 2),
      _stroke(const Color(0x66FFFFFF), 1),
    );
  }

  // ----------------------------------------------------------------- ground

  /// Dappled light and scattered grass over the chequered ground.
  static void groundDetail(Canvas c, Size size, int seed) {
    final r = math.Random(seed);
    for (var y = 60.0; y < size.height; y += 210) {
      final at = Offset(r.nextDouble() * size.width, y + r.nextDouble() * 120);
      c.save();
      c.translate(at.dx, at.dy);
      c.scale(1, 0.46);
      final patch = Rect.fromCircle(center: Offset.zero, radius: 130);
      c.drawCircle(
        Offset.zero,
        130,
        _radial(
          patch,
          const [Color(0x22CFF5A8), Color(0x00CFF5A8)],
          center: Alignment.center,
          radius: 0.5,
        ),
      );
      c.restore();
    }
    for (var k = 0; k < size.height / 26; k++) {
      final at = Offset(
        r.nextDouble() * size.width,
        r.nextDouble() * size.height,
      );
      tuft(
        c,
        at,
        0.55 + r.nextDouble() * 0.4,
        r.nextBool() ? const Color(0x5544892F) : const Color(0x4072B656),
      );
    }
  }
}
