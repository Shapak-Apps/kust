import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/features/game/chess/chess_helpers.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/piece_image.dart';

/// Where everything sits on the mountain: the lessons wind up it in
/// switchbacks, the first at the foot and the last just under the summit.
class MountainLayout {
  MountainLayout({
    required this.width,
    required this.count,
    this.footRoom = 120,
  });

  final double width;
  final int count;

  /// Room under the first lesson (the tab bar sits over it).
  final double footRoom;

  static const double step = 128;
  static const double headRoom = 250;
  static const double nodeSize = 68;

  double get height => headRoom + (count - 1) * step + footRoom;

  Offset node(int i) => Offset(
    width * (i.isEven ? 0.30 : 0.70) + (i % 3 - 1) * 6,
    height - footRoom - i * step,
  );

  Offset get base => Offset(width * 0.5, height - footRoom + 70);
  Offset get summit => Offset(width * 0.5, 64);
  Offset get flag => Offset(width * 0.5, 138);

  /// How far above the bottom edge lesson [i] is.
  double fromBottom(int i) => footRoom + i * step;
}

/// The mountain scene and the trail: sky, ranges, snow, trees and clouds,
/// then the path, solid and gold where it has been climbed, dashed above.
class MountainPainter extends CustomPainter {
  const MountainPainter({required this.layout, required this.climbed});

  final MountainLayout layout;

  /// How many lessons, from the first, are done.
  final int climbed;

  static const Color sky1 = Color(0xFF111826);
  static const Color sky2 = Color(0xFF2B2622);
  static const Color far = Color(0xFF2A3140);
  static const Color mid = Color(0xFF353E50);
  static const Color near = Color(0xFF414B5F);
  static const Color snow = Color(0xFFEDF1F7);
  static const Color snowShade = Color(0xFFC3CCDA);
  static const Color pine = Color(0xFF2C5A43);
  static const Color gold = Color(0xFFFFBB00);

  @override
  void paint(Canvas canvas, Size size) {
    final w = layout.width, h = layout.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky1, sky2],
        ).createShader(Offset.zero & size),
    );
    _stars(canvas, w, h);
    _cloud(canvas, Offset(w * 0.18, h * 0.30), 1.0);
    _cloud(canvas, Offset(w * 0.86, h * 0.47), 0.8);
    _cloud(canvas, Offset(w * 0.14, h * 0.66), 0.9);

    // Far ranges.
    _peak(canvas, Offset(w * 0.10, h * 0.34), w * 0.30, h, far);
    _peak(canvas, Offset(w * 0.92, h * 0.42), w * 0.34, h, far);
    _peak(canvas, Offset(w * 0.80, h * 0.62), w * 0.40, h, mid);
    _peak(canvas, Offset(w * 0.06, h * 0.70), w * 0.40, h, mid);

    // The great mountain, with a snow cap.
    final peak = layout.summit;
    final body = Path()
      ..moveTo(-12, h)
      ..lineTo(-12, h * 0.66)
      ..lineTo(w * 0.12, h * 0.50)
      ..lineTo(w * 0.20, h * 0.53)
      ..lineTo(w * 0.34, h * 0.30)
      ..lineTo(w * 0.42, h * 0.24)
      ..lineTo(peak.dx - 8, peak.dy + 24)
      ..lineTo(peak.dx, peak.dy)
      ..lineTo(peak.dx + 12, peak.dy + 20)
      ..lineTo(w * 0.60, h * 0.22)
      ..lineTo(w * 0.70, h * 0.32)
      ..lineTo(w * 0.80, h * 0.46)
      ..lineTo(w * 0.90, h * 0.50)
      ..lineTo(w + 12, h * 0.60)
      ..lineTo(w + 12, h)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [near, Color(0xFF2E3544)],
        ).createShader(Offset.zero & size),
    );
    // The shaded side of the mountain.
    final shade = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(peak.dx + 12, peak.dy + 20)
      ..lineTo(w * 0.60, h * 0.22)
      ..lineTo(w * 0.70, h * 0.32)
      ..lineTo(w * 0.80, h * 0.46)
      ..lineTo(w * 0.90, h * 0.50)
      ..lineTo(w + 12, h * 0.60)
      ..lineTo(w + 12, h)
      ..lineTo(w * 0.66, h)
      ..lineTo(w * 0.58, h * 0.52)
      ..lineTo(w * 0.52, h * 0.30)
      ..close();
    canvas.drawPath(shade, Paint()..color = const Color(0x22000000));
    _cap(canvas, peak);

    _trees(canvas, w, h);
    _trail(canvas);
    _flag(canvas);
  }

  void _stars(Canvas canvas, double w, double h) {
    final paint = Paint()..color = const Color(0x55FFFFFF);
    final random = math.Random(7);
    for (var i = 0; i < 36; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * w, random.nextDouble() * h * 0.22),
        random.nextDouble() * 1.2 + 0.4,
        paint,
      );
    }
  }

  void _cloud(Canvas canvas, Offset c, double scale) {
    final paint = Paint()..color = const Color(0x16FFFFFF);
    for (final (dx, dy, r) in const [
      (-34.0, 4.0, 18.0),
      (-12.0, -8.0, 24.0),
      (14.0, -2.0, 21.0),
      (36.0, 6.0, 15.0),
    ]) {
      canvas.drawCircle(c + Offset(dx, dy) * scale, r * scale, paint);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: c + Offset(0, 14 * scale),
          width: 96 * scale,
          height: 14 * scale,
        ),
        Radius.circular(8 * scale),
      ),
      paint,
    );
  }

  /// A triangular summit at [tip] reaching down to [bottom].
  void _peak(
    Canvas canvas,
    Offset tip,
    double halfBase,
    double bottom,
    Color c,
  ) {
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx - halfBase, bottom)
        ..lineTo(tip.dx - halfBase * 0.22, tip.dy + (bottom - tip.dy) * 0.18)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + halfBase * 0.3, tip.dy + (bottom - tip.dy) * 0.2)
        ..lineTo(tip.dx + halfBase, bottom)
        ..close(),
      Paint()..color = c,
    );
  }

  void _cap(Canvas canvas, Offset peak) {
    final path = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(peak.dx + 12, peak.dy + 20)
      ..lineTo(peak.dx + 56, peak.dy + 118)
      ..lineTo(peak.dx + 34, peak.dy + 104)
      ..lineTo(peak.dx + 22, peak.dy + 128)
      ..lineTo(peak.dx + 4, peak.dy + 100)
      ..lineTo(peak.dx - 14, peak.dy + 130)
      ..lineTo(peak.dx - 30, peak.dy + 100)
      ..lineTo(peak.dx - 52, peak.dy + 116)
      ..lineTo(peak.dx - 8, peak.dy + 24)
      ..close();
    canvas.drawPath(path, Paint()..color = snow);
    canvas.drawPath(
      Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(peak.dx + 12, peak.dy + 20)
        ..lineTo(peak.dx + 56, peak.dy + 118)
        ..lineTo(peak.dx + 34, peak.dy + 104)
        ..lineTo(peak.dx + 22, peak.dy + 128)
        ..lineTo(peak.dx + 4, peak.dy + 100)
        ..close(),
      Paint()..color = snowShade,
    );
  }

  void _trees(Canvas canvas, double w, double h) {
    for (final (fx, dy, s) in const [
      (0.07, 54.0, 1.0),
      (0.16, 24.0, 0.8),
      (0.90, 60.0, 1.1),
      (0.80, 20.0, 0.8),
      (0.97, 28.0, 0.7),
      (0.05, 150.0, 0.7),
      (0.93, 168.0, 0.8),
    ]) {
      final base = Offset(w * fx, h - dy);
      for (var tier = 0; tier < 3; tier++) {
        final tw = (30 - tier * 7) * s;
        final top = base.dy - (16 + tier * 14) * s;
        canvas.drawPath(
          Path()
            ..moveTo(base.dx - tw, top + 22 * s)
            ..lineTo(base.dx, top - 4 * s)
            ..lineTo(base.dx + tw, top + 22 * s)
            ..close(),
          Paint()..color = pine,
        );
      }
      canvas.drawRect(
        Rect.fromCenter(
          center: base + Offset(0, 6 * s),
          width: 5 * s,
          height: 10 * s,
        ),
        Paint()..color = const Color(0xFF4A3A2C),
      );
    }
  }

  /// The points the trail goes through: the foot, each lesson, the summit.
  List<Offset> get _points => [
    layout.base,
    for (var i = 0; i < layout.count; i++) layout.node(i),
    layout.flag + const Offset(0, 40),
  ];

  Path _segment(Offset a, Offset b) {
    final mid = (a.dy + b.dy) / 2;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, mid, b.dx, mid, b.dx, b.dy);
  }

  void _trail(Canvas canvas) {
    final pts = _points;
    for (var k = 0; k < pts.length - 1; k++) {
      final seg = _segment(pts[k], pts[k + 1]);
      canvas.drawPath(
        seg,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x40000000),
      );
      if (k < climbed) {
        canvas.drawPath(
          seg,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round
            ..color = gold,
        );
      } else {
        _dashed(canvas, seg);
      }
    }
  }

  void _dashed(Canvas canvas, Path path) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x88DDE4F0);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 20) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 9, metric.length)),
          paint,
        );
      }
    }
  }

  void _flag(Canvas canvas) {
    final base = layout.flag + const Offset(0, 30);
    final top = layout.flag - const Offset(0, 30);
    canvas.drawLine(
      base,
      top,
      Paint()
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE9EDF4),
    );
    final done = climbed >= layout.count;
    canvas.drawPath(
      Path()
        ..moveTo(top.dx + 2, top.dy)
        ..lineTo(top.dx + 40, top.dy + 12)
        ..lineTo(top.dx + 2, top.dy + 26)
        ..close(),
      Paint()..color = done ? gold : const Color(0xFF8A94A6),
    );
  }

  @override
  bool shouldRepaint(MountainPainter old) =>
      old.climbed != climbed ||
      old.layout.width != layout.width ||
      old.layout.height != layout.height;
}

/// The Learn map: the lessons as stops on a trail up a mountain. Done stops
/// are green, the next one is gold with the climber on it.
class MountainPath extends StatefulWidget {
  const MountainPath({
    super.key,
    required this.layout,
    required this.done,
    required this.onOpen,
  });

  final MountainLayout layout;
  final Set<String> done;
  final void Function(Lesson lesson) onOpen;

  @override
  State<MountainPath> createState() => _MountainPathState();
}

class _MountainPathState extends State<MountainPath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int get _climbed {
    var n = 0;
    while (n < kLessons.length && widget.done.contains(kLessons[n].id)) {
      n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final climbed = _climbed;
    return SizedBox(
      width: layout.width,
      height: layout.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: MountainPainter(layout: layout, climbed: climbed),
              ),
            ),
          ),
          for (var i = 0; i < kLessons.length; i++) _stop(context, i, climbed),
        ],
      ),
    );
  }

  Widget _stop(BuildContext context, int i, int climbed) {
    final layout = widget.layout;
    final lesson = kLessons[i];
    final c = layout.node(i);
    final finished = widget.done.contains(lesson.id);
    final isNext = i == climbed;
    final onLeft = i.isEven;
    const size = MountainLayout.nodeSize;
    final k = context.k;
    final t = context.t;
    final title = lesson.title(t);

    final node = _Node(
      lesson: lesson,
      finished: finished,
      isNext: isNext,
      pulse: _pulse,
    );
    final label = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: layout.width * 0.4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xB3141210),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: onLeft
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${i + 1}',
              style: k.caption.copyWith(
                color: isNext ? MountainPainter.gold : k.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              textAlign: onLeft ? TextAlign.left : TextAlign.right,
              style: k.body.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                height: 1.15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    return Positioned(
      left: 0,
      right: 0,
      top: c.dy - size / 2,
      height: size,
      child: Semantics(
        button: true,
        label: '${i + 1}. $title, ${t.lessonTasks(lesson.tasks.length)}',
        onTap: () => widget.onOpen(lesson),
        excludeSemantics: true,
        child: Pressable(
          onTap: () => widget.onOpen(lesson),
          haptic: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(left: c.dx - size / 2, top: 0, child: node),
              Positioned(
                left: onLeft ? c.dx + size / 2 + 10 : null,
                right: onLeft ? null : layout.width - c.dx + size / 2 + 10,
                top: 0,
                bottom: 0,
                child: Center(child: label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.lesson,
    required this.finished,
    required this.isNext,
    required this.pulse,
  });

  final Lesson lesson;
  final bool finished;
  final bool isNext;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    const size = MountainLayout.nodeSize;
    final fill = finished
        ? k.success
        : isNext
        ? MountainPainter.gold
        : const Color(0xFF232B3A);
    final piece = lesson.piece;
    final Widget glyph = piece == null
        ? Icon(
            lesson.icon,
            size: 32,
            color: isNext || finished ? Colors.white : const Color(0xFFB9C2D2),
          )
        : PieceImage(
            assetForPiece(Piece(color: Side.white, role: piece)),
            width: 42,
            height: 42,
          );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isNext)
            AnimatedBuilder(
              animation: pulse,
              builder: (context, _) => Container(
                width: size + 18 * pulse.value,
                height: size + 18 * pulse.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MountainPainter.gold.withValues(
                    alpha: 0.28 * (1 - pulse.value),
                  ),
                ),
              ),
            ),
          Container(
            width: size - 6,
            height: size - 6,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(
                color: finished || isNext
                    ? Colors.white
                    : const Color(0xFF5A6678),
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: glyph,
          ),
          if (finished)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: k.success, width: 2),
                ),
                child: Icon(Icons.check_rounded, size: 16, color: k.success),
              ),
            ),
        ],
      ),
    );
  }
}
