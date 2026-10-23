import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Drawing helpers for the Turkmen-carpet look of the puzzle screen: a quiet
/// repeating "gül" pattern, octagon medallions for puzzles and a thread that
/// links them. Everything is flat shapes, so it stays cheap to paint.

/// Regular octagon with a flat top, [radius] being the distance to a vertex.
Path octagonPath(Offset center, double radius) {
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final angle = math.pi / 8 + i * math.pi / 4;
    final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path..close();
}

/// Square turned 45 degrees, [radius] being the distance to a corner.
Path diamondPath(Offset center, double radius) {
  return Path()
    ..moveTo(center.dx, center.dy - radius)
    ..lineTo(center.dx + radius, center.dy)
    ..lineTo(center.dx, center.dy + radius)
    ..lineTo(center.dx - radius, center.dy)
    ..close();
}

/// Carpet red and gold, tuned for each theme so the pattern stays a whisper
/// behind the puzzles.
class CarpetColors {
  const CarpetColors._(this.red, this.gold);

  final Color red;
  final Color gold;

  static const light = CarpetColors._(Color(0xFF9B2D20), Color(0xFFB07A00));
  static const dark = CarpetColors._(Color(0xFFD9604C), Color(0xFFFFBB00));

  static CarpetColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Background pattern: staggered gül medallions with small diamonds in the
/// gaps, and a zig-zag band down both edges.
class CarpetPatternPainter extends CustomPainter {
  const CarpetPatternPainter({required this.colors});

  final CarpetColors colors;

  static const double tile = 104;
  static const double band = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = colors.red.withValues(alpha: 0.10);
    final softFill = Paint()
      ..style = PaintingStyle.fill
      ..color = colors.red.withValues(alpha: 0.05);
    final goldLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colors.gold.withValues(alpha: 0.14);
    final goldFill = Paint()
      ..style = PaintingStyle.fill
      ..color = colors.gold.withValues(alpha: 0.12);

    final rows = (size.height / (tile / 2)).ceil() + 1;
    final cols = (size.width / tile).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      final y = row * tile / 2;
      final shift = row.isOdd ? tile / 2 : 0.0;
      for (var col = -1; col < cols; col++) {
        final c = Offset(col * tile + shift, y);

        canvas.drawPath(octagonPath(c, 34), line);
        canvas.drawPath(octagonPath(c, 24), softFill);
        canvas.drawPath(diamondPath(c, 13), goldLine);
        canvas.drawCircle(c, 2.5, goldFill);

        // Small diamonds in the gaps between medallions.
        canvas.drawPath(
          diamondPath(c + const Offset(tile / 2, 0), 4.5),
          goldFill,
        );
        canvas.drawPath(
          diamondPath(c + const Offset(0, tile / 2), 4.5),
          goldFill,
        );
      }
    }

    _paintBand(canvas, size, left: true);
    _paintBand(canvas, size, left: false);
  }

  void _paintBand(Canvas canvas, Size size, {required bool left}) {
    final edge = left ? 0.0 : size.width;
    final dir = left ? 1.0 : -1.0;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colors.red.withValues(alpha: 0.16);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = colors.red.withValues(alpha: 0.08);

    canvas.drawLine(
      Offset(edge + dir * band, 0),
      Offset(edge + dir * band, size.height),
      stroke,
    );

    final zig = Path()..moveTo(edge, 0);
    const step = 14.0;
    var down = true;
    for (double y = 0; y < size.height + step; y += step) {
      final x = edge + dir * (down ? band - 2 : 2);
      zig.lineTo(x, y + step / 2);
      down = !down;
    }
    canvas.drawPath(zig, stroke);

    for (double y = 0; y < size.height; y += step * 2) {
      canvas.drawPath(
        Path()
          ..moveTo(edge, y)
          ..lineTo(edge + dir * (band - 2), y + step / 2)
          ..lineTo(edge, y + step)
          ..close(),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(CarpetPatternPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

/// Octagon medallion behind a puzzle number or icon.
class OctagonPainter extends CustomPainter {
  const OctagonPainter({required this.fill, required this.ring, this.halo});

  /// Body color.
  final Color fill;

  /// Thin inner outline and the outer edge.
  final Color ring;

  /// Extra outer outline marking the puzzle to play next.
  final Color? halo;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // A flat-topped octagon reaches its flat sides at radius * cos(22.5 deg).
    final radius = size.width / 2 / math.cos(math.pi / 8);

    canvas.drawPath(octagonPath(center, radius), Paint()..color = fill);
    canvas.drawPath(
      octagonPath(center, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );
    canvas.drawPath(
      octagonPath(center, radius * 0.8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ring.withValues(alpha: 0.6),
    );
    if (halo != null) {
      canvas.drawPath(
        octagonPath(center, radius * 1.16),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = halo!,
      );
    }
  }

  @override
  bool shouldRepaint(OctagonPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.ring != ring ||
      oldDelegate.halo != halo;
}

/// The thread linking the puzzles: solid gold up to the next puzzle and a
/// dotted line beyond it.
class ThreadPainter extends CustomPainter {
  const ThreadPainter({
    required this.centers,
    required this.reachedIndex,
    required this.done,
    required this.todo,
  });

  final List<Offset> centers;

  /// Index of the next puzzle; segments before it are drawn as done.
  final int reachedIndex;
  final Color done;
  final Color todo;

  @override
  void paint(Canvas canvas, Size size) {
    final donePaint = Paint()
      ..color = done
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = todo;

    for (var i = 0; i < centers.length - 1; i++) {
      final a = centers[i];
      final b = centers[i + 1];
      if (i < reachedIndex) {
        canvas.drawLine(a, b, donePaint);
        continue;
      }
      final length = (b - a).distance;
      if (length == 0) continue;
      final dir = (b - a) / length;
      for (double d = 0; d <= length; d += 16) {
        canvas.drawCircle(a + dir * d, 2.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(ThreadPainter oldDelegate) =>
      oldDelegate.centers != centers ||
      oldDelegate.reachedIndex != reachedIndex ||
      oldDelegate.done != done ||
      oldDelegate.todo != todo;
}

/// Sizes shared by the speech bubble and the content padded inside it.
class BubbleMetrics {
  BubbleMetrics._();

  /// Width of the tail sticking out on the left.
  static const double tail = 10;
  static const double radius = 18;
}

/// A message bubble: a rounded body with a small tail on the lower left,
/// pointing at the speaker. Fill and outline are one shape, so the tail joins
/// the body without a seam.
class SpeechBubblePainter extends CustomPainter {
  const SpeechBubblePainter({required this.fill, required this.border});

  final Color fill;
  final Color border;

  /// The outline for a bubble of [size].
  static Path shape(Size size) {
    const tail = BubbleMetrics.tail;
    final body = Path()
      ..addRRect(
        RRect.fromLTRBR(
          tail,
          0,
          size.width,
          size.height,
          const Radius.circular(BubbleMetrics.radius),
        ),
      );
    final y = size.height - 22;
    final pointer = Path()
      ..moveTo(tail + 1, y - 8)
      ..lineTo(0, y + 4)
      ..lineTo(tail + 1, y + 12)
      ..close();
    return Path.combine(PathOperation.union, body, pointer);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape(size);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(SpeechBubblePainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.border != border;
}
