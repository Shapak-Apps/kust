import 'package:flutter/material.dart';

abstract final class BubbleMetrics {
  /// How far the tail sticks out to the left of the bubble's body.
  static const double tail = 12;
  static const double radius = 16;

  /// Half the height of the tail's base.
  static const double tailHalf = 9;
}

/// A flat speech bubble with a tail on its left, pointing at the speaker.
class SpeechBubblePainter extends CustomPainter {
  const SpeechBubblePainter({
    required this.fill,
    required this.border,
    this.tailAt = 0.5,
  });

  final Color fill;
  final Color border;

  /// Where the tail sits on the left edge, from 0 (top) to 1 (bottom).
  final double tailAt;

  /// The outline: a rounded body that starts after the tail, and a tail
  /// reaching the left edge at mid height.
  static Path shape(Size size, {double tailAt = 0.5}) {
    const tail = BubbleMetrics.tail;
    final body = RRect.fromLTRBR(
      tail,
      0,
      size.width,
      size.height,
      const Radius.circular(BubbleMetrics.radius),
    );
    // Keep the tail clear of the rounded corners.
    final margin = BubbleMetrics.radius + BubbleMetrics.tailHalf;
    final midY = (size.height * tailAt).clamp(
      margin,
      (size.height - margin).clamp(margin, double.infinity),
    );
    final path = Path()..addRRect(body);
    path.addPath(
      Path()
        ..moveTo(tail + 1, midY - BubbleMetrics.tailHalf)
        ..lineTo(0, midY)
        ..lineTo(tail + 1, midY + BubbleMetrics.tailHalf)
        ..close(),
      Offset.zero,
    );
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape(size, tailAt: tailAt);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(SpeechBubblePainter old) =>
      old.fill != fill || old.border != border || old.tailAt != tailAt;
}

/// The one look of every speech bubble in the app, whoever speaks: cream,
/// with dark words.
abstract final class BubbleColors {
  static const Color fill = Color(0xFFF4EDE0);

  /// The main words.
  static const Color ink = Color(0xFF1E2433);

  /// A second, quieter line.
  static const Color soft = Color(0xFF6B4A2F);

  /// Right and wrong, readable on [fill].
  static const Color good = Color(0xFF1F7A4D);
  static const Color bad = Color(0xFFB3261E);
}

/// A speech bubble in the app's one style, its tail on the left at
/// [tailAt] (0 top, 1 bottom), around [child].
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.child,
    this.tailAt = 0.5,
    this.padding = const EdgeInsets.fromLTRB(
      BubbleMetrics.tail + 14,
      12,
      14,
      12,
    ),
  });

  final Widget child;
  final double tailAt;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: SpeechBubblePainter(
      fill: BubbleColors.fill,
      border: BubbleColors.fill,
      tailAt: tailAt,
    ),
    child: Padding(padding: padding, child: child),
  );
}
