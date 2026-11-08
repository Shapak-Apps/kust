import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  Offset get flag => Offset(width * 0.5, 38);

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
