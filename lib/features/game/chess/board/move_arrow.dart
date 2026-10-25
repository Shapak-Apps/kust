import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The colour hint arrows are drawn in.
const Color kHintArrowColor = Color(0xFF2ECC71);

/// An arrow from one square to another, drawn over the board the way chess
/// sites show a suggested move: from the centre of one square to the centre
/// of the other, bent once for a knight. It grows from its start when it
/// appears.
///
/// It covers the whole board; squares are given as shown on screen, counted
/// from the top left.
class MoveArrow extends StatefulWidget {
  const MoveArrow({
    super.key,
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    this.color = kHintArrowColor,
  });

  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final Color color;

  @override
  State<MoveArrow> createState() => _MoveArrowState();
}

class _MoveArrowState extends State<MoveArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  @override
  void didUpdateWidget(MoveArrow old) {
    super.didUpdateWidget(old);
    if (old.fromRow != widget.fromRow ||
        old.fromCol != widget.fromCol ||
        old.toRow != widget.toRow ||
        old.toCol != widget.toCol) {
      _grow.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: MoveArrowPainter(
            from: (widget.fromRow, widget.fromCol),
            to: (widget.toRow, widget.toCol),
            color: widget.color,
            progress: reduceMotion
                ? kAlwaysCompleteAnimation
                : CurvedAnimation(parent: _grow, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }
}

class MoveArrowPainter extends CustomPainter {
  MoveArrowPainter({
    required this.from,
    required this.to,
    required this.color,
    required this.progress,
  }) : super(repaint: progress);

  /// (row, column) as shown on screen.
  final (int, int) from;
  final (int, int) to;
  final Color color;
  final Animation<double> progress;

  /// The corners the arrow passes through, in squares: start, maybe a bend,
  /// end. A knight's arrow goes along its long leg first, then turns.
  static List<Offset> route((int, int) from, (int, int) to) {
    Offset centre((int, int) s) => Offset(s.$2 + 0.5, s.$1 + 0.5);
    final dr = (to.$1 - from.$1).abs();
    final dc = (to.$2 - from.$2).abs();
    final isKnight = (dr == 1 && dc == 2) || (dr == 2 && dc == 1);
    if (!isKnight) return [centre(from), centre(to)];
    final bend = dr == 2 ? (to.$1, from.$2) : (from.$1, to.$2);
    return [centre(from), centre(bend), centre(to)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final square = size.width / 8;
    final points = [for (final p in route(from, to)) p * square];
    final shaft = square * 0.2;
    final headLength = square * 0.44;
    final headWidth = square * 0.56;

    // Walk the route up to the drawn length.
    final lengths = [
      for (var i = 1; i < points.length; i++)
        (points[i] - points[i - 1]).distance,
    ];
    final total = lengths.fold<double>(0, (a, b) => a + b);
    final drawnLength = total * progress.value.clamp(0.0, 1.0);
    var remaining = drawnLength;
    if (remaining <= 0) return;

    final drawn = <Offset>[points.first];
    for (var i = 0; i < lengths.length && remaining > 0; i++) {
      final step = math.min(remaining, lengths[i]);
      final direction = (points[i + 1] - points[i]) / lengths[i];
      drawn.add(points[i] + direction * step);
      remaining -= step;
    }
    final tip = drawn.last;
    final before = drawn[drawn.length - 2];
    final along = tip - before;
    if (along.distance == 0) return;
    final dir = along / along.distance;
    final normal = Offset(-dir.dy, dir.dx);
    // The shaft stops where the head begins, so they do not overlap.
    final headBase = tip - dir * math.min(headLength, drawnLength);

    final shape = Path()..moveTo(drawn.first.dx, drawn.first.dy);
    for (final p in drawn.sublist(1, drawn.length - 1)) {
      shape.lineTo(p.dx, p.dy);
    }
    shape.lineTo(headBase.dx, headBase.dy);

    // One layer at the arrow's opacity, so the joints are not darker.
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = shaft
        ..strokeJoin = StrokeJoin.miter
        ..strokeCap = ui.StrokeCap.butt,
    );
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        headBase.dx + normal.dx * headWidth / 2,
        headBase.dy + normal.dy * headWidth / 2,
      )
      ..lineTo(
        headBase.dx - normal.dx * headWidth / 2,
        headBase.dy - normal.dy * headWidth / 2,
      )
      ..close();
    canvas.drawPath(head, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(MoveArrowPainter old) =>
      old.from != from ||
      old.to != to ||
      old.color != color ||
      old.progress != progress;
}
