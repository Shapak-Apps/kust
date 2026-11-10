import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/features/game/chess/chess_helpers.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/widgets/piece_image.dart';

/// Where everything sits on the mountain: the lessons wind up it in
/// switchbacks, the first at the foot and the last just under the summit.
class MountainLayout {
  MountainLayout({
    required this.width,
    required this.count,
    this.footRoom = 120,
    this.topInset = 0,
  });

  final double width;
  final int count;

  /// Room under the first lesson (the up-next card and the tab bar sit over
  /// it).
  final double footRoom;

  /// Sky above the mountain picture, under the header.
  final double topInset;

  static const double step = 132;
  static const double headRoom = 250;
  static const double nodeSize = 68;
  static const double currentSize = 84;

  double get height => topInset + headRoom + (count - 1) * step + footRoom;

  Offset node(int i) => Offset(
    width * (i.isEven ? 0.30 : 0.70) + (i % 3 - 1) * 6,
    height - footRoom - i * step,
  );

  Offset get base => Offset(width * 0.5, height - footRoom + 70);
  Offset get flag => Offset(width * 0.5, topInset + 38);

  /// How far above the bottom edge lesson [i] is.
  double fromBottom(int i) => footRoom + i * step;
}

/// The trail up the mountain, solid and gold where it has been climbed and
/// dashed above. The mountain itself is the picture under it.
class MountainPainter extends CustomPainter {
  const MountainPainter({required this.layout, required this.climbed});

  final MountainLayout layout;

  /// How many lessons, from the first, are done.
  final int climbed;

  static const Color gold = Color(0xFFFFBB00);

  @override
  void paint(Canvas canvas, Size size) {
    _trail(canvas);
    _flag(canvas);
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
    final base = layout.flag + const Offset(0, 34);
    final top = layout.flag - const Offset(0, 28);
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

/// The Learn map: the lessons as stops on a trail up a mountain, with a
/// sign where each camp starts. Done stops are gold with their stars, the
/// next one is green, bigger and calls "Start".
class MountainPath extends StatefulWidget {
  const MountainPath({
    super.key,
    required this.layout,
    required this.done,
    required this.starsOf,
    required this.onOpen,
  });

  final MountainLayout layout;
  final Set<String> done;
  final int Function(String id) starsOf;
  final void Function(Lesson lesson) onOpen;

  @override
  State<MountainPath> createState() => _MountainPathState();
}

class _MountainPathState extends State<MountainPath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

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
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF0B1222))),
          Positioned(
            left: 0,
            right: 0,
            top: layout.topInset,
            bottom: 0,
            child: SvgPicture.asset(
              'assets/images/learn_mountain.svg',
              fit: BoxFit.fill,
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: MountainPainter(layout: layout, climbed: climbed),
              ),
            ),
          ),
          for (final camp in kCamps.skip(1)) _campSign(context, camp),
          for (var i = 0; i < kLessons.length; i++) _stop(context, i, climbed),
        ],
      ),
    );
  }

  /// A sign on the trail where [camp] begins.
  Widget _campSign(BuildContext context, Camp camp) {
    final layout = widget.layout;
    final y = (layout.node(camp.first).dy + layout.node(camp.first - 1).dy) / 2;
    final t = context.t;
    return Positioned(
      left: 0,
      right: 0,
      top: y - 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xE60F4A33),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x803CB77C)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                camp.isSummit ? Icons.flag_rounded : Icons.cabin_rounded,
                size: 15,
                color: const Color(0xFF9EE7C1),
              ),
              const SizedBox(width: 6),
              Text(
                '${camp.label(t)} · ${camp.title(t)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFFBFF0D6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stop(BuildContext context, int i, int climbed) {
    final layout = widget.layout;
    final lesson = kLessons[i];
    final c = layout.node(i);
    final finished = widget.done.contains(lesson.id);
    final isNext = i == climbed;
    final onLeft = c.dx < layout.width / 2;
    final size = isNext ? MountainLayout.currentSize : MountainLayout.nodeSize;
    final t = context.t;
    final title = lesson.title(t);

    final label = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: layout.width * 0.42),
      child: DefaultTextStyle.merge(
        // No box behind the name: a soft shadow keeps it readable on the
        // mountain.
        style: const TextStyle(
          shadows: [
            Shadow(color: Color(0xE6000000), blurRadius: 8),
            Shadow(color: Color(0x99000000), blurRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: onLeft
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.lessonLabel(i + 1),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isNext
                    ? const Color(0xFF9EE7C1)
                    : finished
                    ? const Color(0xFFFFD466)
                    : const Color(0xFF7E879C),
              ),
            ),
            Text(
              title,
              textAlign: onLeft ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: finished || isNext
                    ? Colors.white
                    : const Color(0xFF9AA2B5),
              ),
            ),
          ],
        ),
      ),
    );

    return Positioned(
      left: 0,
      right: 0,
      top: c.dy - size / 2 - (isNext ? 52 : 0),
      height: size + (isNext ? 52 : 0) + 30,
      child: Semantics(
        button: true,
        label: '${i + 1}. $title, ${t.lessonTasks(lesson.tasks.length)}',
        onTap: () => widget.onOpen(lesson),
        excludeSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isNext)
              Positioned(
                left: c.dx - 60,
                width: 120,
                top: 0,
                child: _StartTip(pulse: _pulse),
              ),
            Positioned(
              left: c.dx - size / 2,
              top: isNext ? 52 : 0,
              child: Pressable(
                onTap: () => widget.onOpen(lesson),
                haptic: true,
                child: _Node(
                  lesson: lesson,
                  finished: finished,
                  isNext: isNext,
                  size: size,
                  pulse: _pulse,
                ),
              ),
            ),
            if (finished)
              Positioned(
                left: c.dx - 30,
                width: 60,
                top: size + 10,
                child: _Stars(count: widget.starsOf(lesson.id)),
              ),
            Positioned(
              left: onLeft ? c.dx + size / 2 + 14 : null,
              right: onLeft ? null : layout.width - c.dx + size / 2 + 14,
              top: (isNext ? 52 : 0) - 30,
              height: size + 60,
              child: GestureDetector(
                onTap: () => widget.onOpen(lesson),
                child: Center(child: label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The white "START" bubble over the next stop, bobbing gently.
class _StartTip extends StatelessWidget {
  const _StartTip({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -3 * math.sin(pulse.value * 2 * math.pi)),
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), blurRadius: 10),
              ],
            ),
            child: Text(
              context.t.learnStartTip,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: Color(0xFF20804F),
              ),
            ),
          ),
          CustomPaint(size: const Size(16, 8), painter: _TipTail()),
        ],
      ),
    );
  }
}

class _TipTail extends CustomPainter {
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
  bool shouldRepaint(_TipTail old) => false;
}

class _Stars extends StatelessWidget {
  const _Stars({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            Icons.star_rounded,
            size: 18,
            color: i < count ? MountainPainter.gold : const Color(0xFF4A4F5E),
            shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 3)],
          ),
      ],
    );
  }
}

/// A stop as a round 3D button: a darker rim under a lit face with a shine.
class _Node extends StatelessWidget {
  const _Node({
    required this.lesson,
    required this.finished,
    required this.isNext,
    required this.size,
    required this.pulse,
  });

  final Lesson lesson;
  final bool finished;
  final bool isNext;
  final double size;
  final Animation<double> pulse;

  static const double depth = 7;

  @override
  Widget build(BuildContext context) {
    final (face, rim) = finished
        ? (const Color(0xFFFFBB00), const Color(0xFFB98200))
        : isNext
        ? (const Color(0xFF3CB77C), const Color(0xFF20804F))
        : (const Color(0xFF2C3448), const Color(0xFF1B2132));
    final piece = lesson.piece;
    final glyphSize = size * 0.56;
    Widget glyph = piece == null
        ? Icon(
            lesson.icon,
            size: glyphSize * 0.82,
            color: finished
                ? const Color(0xFF3A2A00)
                : isNext
                ? Colors.white
                : const Color(0xFF6B7590),
          )
        : PieceImage(
            assetForPiece(
              Piece(color: finished ? Side.black : Side.white, role: piece),
            ),
            width: glyphSize,
            height: glyphSize,
          );
    if (!finished && !isNext) {
      glyph = Opacity(opacity: 0.45, child: glyph);
    }
    return SizedBox(
      width: size,
      height: size + depth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (isNext)
            Positioned(
              left: -24,
              top: -24,
              child: AnimatedBuilder(
                animation: pulse,
                builder: (context, _) {
                  final v = pulse.value;
                  return SizedBox(
                    width: size + 48,
                    height: size + 48,
                    child: Center(
                      child: Container(
                        width: size + 48 * v,
                        height: size + 48 * v,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3CB77C)
                              .withValues(alpha: 0.35 * (1 - v)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Positioned(
            top: depth,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: rim,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: face,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: finished || isNext ? 0.55 : 0.08,
                ),
                width: 2,
              ),
            ),
          ),
          Positioned(
            top: size * 0.1,
            child: Container(
              width: size * 0.6,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: finished || isNext ? 0.22 : 0.05,
                ),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: Center(child: glyph),
          ),
        ],
      ),
    );
  }
}
