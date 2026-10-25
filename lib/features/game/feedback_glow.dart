import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kust/features/game/chess/board/board_squares_painter.dart';

/// A glow in the colour of a move's rating on the square it landed on. It
/// flares up as the rating arrives, then settles to a soft tint.
///
/// It covers the whole board but paints only its square, with the same pixel
/// edges as [BoardSquaresPainter], and sits on its own layer: each frame
/// repaints one square and nothing else.
class FeedbackGlow extends StatefulWidget {
  const FeedbackGlow({
    super.key,
    required this.color,
    required this.row,
    required this.col,
  });

  final Color color;

  /// The square as shown on screen, counted from the top left.
  final int row;
  final int col;

  @override
  State<FeedbackGlow> createState() => _FeedbackGlowState();
}

class _FeedbackGlowState extends State<FeedbackGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  @override
  void didUpdateWidget(FeedbackGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color ||
        oldWidget.row != widget.row ||
        oldWidget.col != widget.col) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GlowPainter(
          color: widget.color,
          row: widget.row,
          col: widget.col,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          progress: reduceMotion ? kAlwaysCompleteAnimation : _controller,
        ),
      ),
    );
  }
}

/// How strong the glow is at time [t] (0 to 1): a quick flare, then it
/// settles to a little over half.
double feedbackGlowStrength(double t) {
  if (t < 0.3) return Curves.easeOutCubic.transform(t / 0.3);
  return 1 - 0.45 * Curves.easeInOut.transform((t - 0.3) / 0.7);
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({
    required this.color,
    required this.row,
    required this.col,
    required this.devicePixelRatio,
    required this.progress,
  }) : super(repaint: progress);

  final Color color;
  final int row;
  final int col;
  final double devicePixelRatio;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = BoardSquaresPainter.squareRect(
      size,
      row,
      col,
      devicePixelRatio,
    );
    final s = feedbackGlowStrength(progress.value);
    canvas.save();
    canvas.clipRect(rect, doAntiAlias: false);
    // A radial glow, brightest in the middle, still tinting the edges.
    canvas.drawRect(
      rect,
      Paint()
        ..isAntiAlias = false
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.62 * s),
            color.withValues(alpha: 0.30 * s),
          ],
        ).createShader(rect),
    );
    // A bright rim inside the square that fades as the glow settles.
    final rim = math.max(1.0, rect.width * 0.05);
    canvas.drawRect(
      rect.deflate(rim / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim
        ..color = color.withValues(alpha: 0.75 * s),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.color != color ||
      old.row != row ||
      old.col != col ||
      old.devicePixelRatio != devicePixelRatio ||
      old.progress != progress;
}
