import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/features/learn/garden_art.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/ui/pressable.dart';
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
    this.pixelRatio = 1,
  });

  /// The screen's pixel ratio, for the cached image of the map.
  final double pixelRatio;

  final LearnMapLayout layout;
  final Set<String> done;

  /// The index of the next lesson, or -1 when all are done.
  final int next;
  final Map<String, int> stars;

  @override
  void paint(Canvas canvas, Size size) {
    final key =
        '${size.width}x${size.height}@$pixelRatio|$next|'
        '${(done.toList()..sort()).join(',')}|$stars';
    final art = _MapArt.of(key, size, pixelRatio, _paintAll);
    if (art == null) {
      _paintAll(canvas, size);
    } else {
      art.draw(canvas, size);
    }
  }

  void _paintAll(Canvas canvas, Size size) {
    _ground(canvas, size);
    _trail(canvas);
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
    GardenArt.groundDetail(canvas, size, 11);
  }

  // ---------------------------------------------------------------- trail

  /// Stepping stones from each lesson to the next: sandy where the way has
  /// been walked, grey moss ahead.
  void _trail(Canvas canvas) {
    const keep = LearnMapLayout.tileW * 0.5;
    for (var i = 0; i < layout.count - 1; i++) {
      final a = layout.tile(i) + const Offset(0, LearnMapLayout.depth / 2);
      final b = layout.tile(i + 1) + const Offset(0, LearnMapLayout.depth / 2);
      final walked = i < next || next < 0;
      final fill = walked ? const Color(0xFFE7D7A8) : const Color(0xFF6F806A);
      final edge = walked ? const Color(0xFFB7A271) : const Color(0xFF4E5D49);
      final length = (b - a).distance;
      final count = (length / 20).floor();
      for (var k = 1; k < count; k++) {
        final at = Offset.lerp(a, b, k / count)!;
        if ((at - a).distance < keep || (at - b).distance < keep) continue;
        // A little wobble, the same every time.
        final wobble = ((i * 7 + k * 13) % 5 - 2) * 1.2;
        final stone = Rect.fromCenter(
          center: at + Offset(wobble, 0),
          width: 15,
          height: 8,
        );
        canvas.drawOval(stone.shift(const Offset(0, 2)), Paint()..color = edge);
        canvas.drawOval(stone, Paint()..color = fill);
        canvas.drawOval(
          Rect.fromCenter(
            center: stone.center - const Offset(2, 1.2),
            width: 6,
            height: 2.4,
          ),
          Paint()..color = Colors.white.withValues(alpha: walked ? 0.55 : 0.2),
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

    if (isNext) {
      // A warm glow on the ground around the lesson to play next.
      final glow = Rect.fromCenter(
        center: c + const Offset(0, d * 0.7),
        width: w * 1.9,
        height: h * 1.9,
      );
      canvas.drawOval(
        glow,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x80FFD45C), Color(0x30FFD45C), Color(0x00FFD45C)],
            stops: [0, 0.5, 1],
          ).createShader(glow),
      );
    }

    // A soft shadow on the ground.
    GardenArt.shadow(
      canvas,
      c + Offset(-2, d + 8),
      w * 1.05,
      h * 0.8,
      opacity: 0.42,
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

    // Lit from the upper left, like the pieces standing on it.
    canvas.drawPath(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(top, Colors.white, 0.28)!,
            top,
            Color.lerp(top, Colors.black, 0.1)!,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(bounds),
    );
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
      _lock(canvas, c + Offset(tp.width / 2 + 9, 3));
    }
  }

  /// A small padlock beside a locked lesson's number.
  static void _lock(Canvas canvas, Offset c) {
    const color = Color(0xFF4C5948);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c + const Offset(0, 2), width: 11, height: 8),
        const Radius.circular(2),
      ),
      Paint()..color = color,
    );
    canvas.drawArc(
      Rect.fromCenter(center: c - const Offset(0, 1.6), width: 7, height: 8),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = color,
    );
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

    // The camp at the foot of the garden.
    final foot = y(0);
    add(foot + 96, (cv) => GardenArt.tent(cv, Offset(w * 0.79, foot + 96)));
    add(
      foot + 118,
      (cv) => GardenArt.campfire(cv, Offset(w * 0.55, foot + 118), 1),
    );
    add(
      foot + 112,
      (cv) => GardenArt.log(cv, Offset(w * 0.37, foot + 116), 0.8),
    );
    add(
      foot + 86,
      (cv) => GardenArt.bush(
        cv,
        Offset(w * 0.12, foot + 86),
        1,
        berries: GardenArt.pinkBerries,
      ),
    );
    GardenArt.meadow(c, Offset(w * 0.56, foot + 64), 7, 1);
    add(
      foot + 10,
      (cv) => GardenArt.tree(cv, Offset(w * 0.81, foot + 10), 1.05),
    );
    add(
      foot + 14,
      (cv) => GardenArt.mushrooms(cv, Offset(w * 0.64, foot + 18), 1),
    );
    GardenArt.meadow(c, Offset(w * 0.66, foot - 40), 5, 2);

    // Camp 1.
    add(
      y(1) + 10,
      (cv) => GardenArt.rock(cv, Offset(w * 0.07, y(1) + 10), 0.9, moss: true),
    );
    add(
      y(1) + 22,
      (cv) => GardenArt.rock(cv, Offset(w * 0.15, y(1) + 22), 0.5),
    );
    add(
      y(2) + 20,
      (cv) => GardenArt.bush(cv, Offset(w * 0.93, y(2) + 20), 0.9),
    );
    add(y(3) + 30, (cv) => GardenArt.pond(cv, Offset(w * 0.2, y(3) + 6), 0.85));
    add(
      y(4) + 6,
      (cv) => GardenArt.rock(cv, Offset(w * 0.92, y(4) + 6), 0.75, moss: true),
    );
    add(y(4) - 30, (cv) => GardenArt.pine(cv, Offset(w * 0.9, y(4) - 30), 0.8));
    add(
      y(5) + 4,
      (cv) => GardenArt.tree(cv, Offset(w * 0.09, y(5) + 4), 0.8, fruit: false),
    );
    GardenArt.meadow(c, Offset(w * 0.88, y(5) - 20), 5, 3, spread: 28);

    // Camp 2.
    final camp2 = layout.campY(kCamps[1]);
    add(camp2 + 26, (cv) => _pedestal(cv, Offset(w * 0.83, camp2 + 26)));
    add(
      camp2 + 40,
      (cv) => GardenArt.mushrooms(cv, Offset(w * 0.12, camp2 + 40), 0.9),
    );
    add(y(6) + 16, (cv) => GardenArt.tree(cv, Offset(w * 0.8, y(6) + 16), 1.1));
    add(
      y(7) + 14,
      (cv) => GardenArt.bush(
        cv,
        Offset(w * 0.94, y(7) + 14),
        0.8,
        berries: GardenArt.blueBerries,
      ),
    );
    GardenArt.meadow(c, Offset(w * 0.1, y(7)), 6, 4, spread: 30);
    add(
      y(8) + 8,
      (cv) => GardenArt.rock(cv, Offset(w * 0.08, y(8) + 8), 1, moss: true),
    );
    add(y(8) - 24, (cv) => GardenArt.pine(cv, Offset(w * 0.9, y(8) - 24), 0.9));

    // Camp 3 and the summit.
    final camp3 = layout.campY(kCamps[2]);
    add(camp3 + 26, (cv) => _pedestal(cv, Offset(w * 0.17, camp3 + 26)));
    add(
      camp3 + 34,
      (cv) => GardenArt.log(cv, Offset(w * 0.86, camp3 + 34), 0.8),
    );
    add(y(9) + 26, (cv) => GardenArt.pine(cv, Offset(w * 0.1, y(9) + 26), 1));
    add(
      y(10) + 10,
      (cv) => GardenArt.tree(cv, Offset(w * 0.06, y(10) + 10), 0.7),
    );
    GardenArt.meadow(c, Offset(w * 0.86, y(10) + 30), 6, 5, spread: 28);

    final top = layout.summit;
    add(top.dy + 40, (cv) => _podium(cv, top + const Offset(0, 40)));
    add(
      top.dy - 10,
      (cv) => GardenArt.pine(cv, Offset(w * 0.12, top.dy - 10), 0.9),
    );
    add(
      top.dy + 4,
      (cv) => GardenArt.tree(cv, Offset(w * 0.9, top.dy + 4), 0.9),
    );
    GardenArt.meadow(c, top + const Offset(0, 74), 8, 6, spread: 60);
  }

  /// A stone pedestal; its statue is drawn on top as a picture.
  static void _pedestal(Canvas canvas, Offset base) {
    GardenArt.shadow(canvas, base, 104, 30);
    GardenArt.block(canvas, base, 76, 40, 24);
  }

  /// The summit: a wide two-step podium with a flag.
  static void _podium(Canvas canvas, Offset base) {
    GardenArt.shadow(canvas, base, 180, 46);
    GardenArt.block(canvas, base, 150, 80, 18);
    GardenArt.block(canvas, base - const Offset(0, 18), 96, 52, 18);
    // On the lower step, clear of the king in the middle.
    final pole = Offset(base.dx + 58, base.dy - 52);
    canvas.drawLine(
      pole,
      pole - const Offset(0, 74),
      Paint()
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFEDEDED),
    );
    final flag = Path()
      ..moveTo(pole.dx + 1, pole.dy - 74)
      ..quadraticBezierTo(
        pole.dx + 22,
        pole.dy - 80,
        pole.dx + 42,
        pole.dy - 70,
      )
      ..lineTo(pole.dx + 42, pole.dy - 48)
      ..quadraticBezierTo(pole.dx + 22, pole.dy - 58, pole.dx + 1, pole.dy - 52)
      ..close();
    canvas.drawPath(
      flag,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF34B36A), Color(0xFF16703D)],
        ).createShader(flag.getBounds()),
    );
    final star = Path();
    final mid = Offset(pole.dx + 21, pole.dy - 65);
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 8.0 : 3.4;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = mid + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(star, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(LearnMapPainter old) =>
      old.layout.width != layout.width ||
      old.layout.height != layout.height ||
      old.next != next ||
      old.done.length != done.length ||
      old.stars.toString() != stars.toString() ||
      old.pixelRatio != pixelRatio;
}

/// The painted map turned into images, in bands short enough for any GPU,
/// so scrolling the map only copies pixels instead of drawing every tree,
/// pebble and flower again on each frame.
class _MapArt {
  _MapArt._(this._key, this._bands);

  final String _key;
  final List<(double top, double height, ui.Image image)> _bands;

  double _ratio = 1;

  static _MapArt? _current;

  /// Highest pixel ratio the images are made at, to keep memory in check.
  static const double _maxRatio = 2.5;
  static const double _band = 1024;

  static _MapArt? of(
    String key,
    Size size,
    double pixelRatio,
    void Function(Canvas, Size) paint,
  ) {
    final current = _current;
    if (current != null && current._key == key) return current;
    final ratio = pixelRatio.clamp(1.0, _maxRatio);
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final bands = <(double, double, ui.Image)>[];
    try {
      for (var top = 0.0; top < size.height; top += _band) {
        final height = math.min(_band, size.height - top);
        // A few rows more than drawn, so smoothing never samples past the
        // edge and no seam shows between bands.
        final padded = math.min(height + 4, size.height - top);
        final bandRecorder = ui.PictureRecorder();
        Canvas(bandRecorder)
          ..scale(ratio)
          ..translate(0, -top)
          ..drawPicture(picture);
        final bandPicture = bandRecorder.endRecording();
        bands.add((
          top,
          height,
          bandPicture.toImageSync(
            (size.width * ratio).ceil(),
            (padded * ratio).ceil(),
          ),
        ));
        bandPicture.dispose();
      }
    } catch (_) {
      for (final (_, _, image) in bands) {
        image.dispose();
      }
      picture.dispose();
      return null;
    }
    picture.dispose();
    current?._dispose();
    return _current = _MapArt._(key, bands).._ratio = ratio;
  }

  void draw(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.medium;
    for (final (top, height, image) in _bands) {
      // Each band reaches a pixel into the next one, so their soft edges
      // overlap the same picture instead of letting the ground show through.
      final drawn = math.min(height + 1, image.height / _ratio);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), drawn * _ratio),
        Rect.fromLTWH(0, top, size.width, drawn),
        paint,
      );
    }
  }

  void _dispose() {
    for (final (_, _, image) in _bands) {
      image.dispose();
    }
  }
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
                        pixelRatio: MediaQuery.devicePixelRatioOf(context),
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
                  statue(layout.summit + const Offset(0, 28), Role.king, 128),
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
      child: _Marker(image: coachImage),
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
      child: Builder(
        builder: (context) => Semantics(
          button: true,
          label: '${context.t.lessonLabel(i + 1)}, ${lesson.title(context.t)}',
          excludeSemantics: true,
          child: Pressable(
            scale: 0.96,
            haptic: true,
            onTap: () => onOpen(lesson),
            child: const SizedBox.expand(),
          ),
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
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Still when the system asks for less motion.
    if (MediaQuery.disableAnimationsOf(context)) {
      _bob.stop();
      _bob.value = 0;
    } else if (!_bob.isAnimating) {
      _bob.repeat();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Painted once: the bob only moves this layer.
    final card = RepaintBoundary(
      child: Column(
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
      ),
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
