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
  const SpeechBubblePainter({required this.fill, required this.border});

  final Color fill;
  final Color border;

  /// The outline: a rounded body that starts after the tail, and a tail
  /// reaching the left edge at mid height.
  static Path shape(Size size) {
    const tail = BubbleMetrics.tail;
    final body = RRect.fromLTRBR(
      tail,
      0,
      size.width,
      size.height,
      const Radius.circular(BubbleMetrics.radius),
    );
    final midY = size.height / 2;
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
    final path = shape(size);
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
      old.fill != fill || old.border != border;
}
