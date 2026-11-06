import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/features/game/chess/board/board_squares_painter.dart';

/// How the board shows the end of a game, before the result dialog.
///
/// Checkmate: the winner's king square fades to green and the mated king's to
/// red; the pieces stay as they are. A draw (stalemate, 50 moves, repetition,
/// no material, ...): both king squares fade to grey and an equals badge, made
/// like the badge of a rated move, pops up on each.

/// The pause after the last move, so its piece lands before this starts.
const Duration kEndFxDelay = Duration(milliseconds: 300);

/// How long the checkmate show runs.
const Duration kMateFxDuration = Duration(milliseconds: 800);

/// How long the draw show runs.
const Duration kDrawFxDuration = Duration(milliseconds: 900);

/// A breath between the end of the show and the dialog.
const Duration kEndFxRest = Duration(milliseconds: 400);

// Strong, nearly solid colours, so the square reads the same on a light or a
// dark square and a white or a black king stands out on it.
const Color kEndRed = Color(0xFFD93F45);
const Color kEndGreen = Color(0xFF2E9E66);
const Color kEndGrey = Color(0xFF77756F);

/// Fades [Curves.easeOut] over the first [share] of the show: how far the
/// colours have come.
double tintProgress(double t, [double share = 0.25]) =>
    Curves.easeOut.transform((t / share).clamp(0.0, 1.0));

/// Squares washed with a colour that comes in as the show starts. Painted in
/// one layer, so each frame redraws only these few squares.
class EndTintLayer extends StatelessWidget {
  const EndTintLayer({
    super.key,
    required this.progress,
    required this.cells,
    required this.devicePixelRatio,
  });

  final Animation<double> progress;

  /// Each tinted square: its place on screen (counted from the top left) and
  /// its colour.
  final List<({int row, int col, Color color})> cells;
  final double devicePixelRatio;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _EndTintPainter(
          progress: progress,
          cells: cells,
          devicePixelRatio: devicePixelRatio,
        ),
      ),
    );
  }
}

class _EndTintPainter extends CustomPainter {
  _EndTintPainter({
    required this.progress,
    required this.cells,
    required this.devicePixelRatio,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final List<({int row, int col, Color color})> cells;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final s = tintProgress(progress.value, 0.5);
    if (s <= 0) return;
    for (final cell in cells) {
      final rect = BoardSquaresPainter.squareRect(
        size,
        cell.row,
        cell.col,
        devicePixelRatio,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..isAntiAlias = false
          ..color = cell.color.withValues(alpha: 0.94 * s),
      );
    }
  }

  @override
  bool shouldRepaint(_EndTintPainter old) =>
      old.progress != progress ||
      old.devicePixelRatio != devicePixelRatio ||
      old.cells.length != cells.length;
}

/// The equals badge of a draw, on the corner of a king's square. Made like
/// [MoveFeedbackBadge]: a flat coloured circle with a soft glow that pops in
/// with a small overshoot, then the white sign fades in.
class DrawBadge extends StatelessWidget {
  const DrawBadge({super.key, required this.progress, required this.size});

  final Animation<double> progress;
  final double size;

  static const Color color = Color(0xFF98968F);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        // The badge's own 450 ms: the circle in the first half, the sign
        // after it, as on a rated move.
        final t = (progress.value * 2).clamp(0.0, 1.0);
        final circle = const Interval(
          0.0,
          0.55,
          curve: Curves.easeOutBack,
        ).transform(t);
        final sign = const Interval(
          0.45,
          1.0,
          curve: Curves.easeIn,
        ).transform(t);
        return Transform.scale(
          scale: circle.clamp(0.01, 1.2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: sign,
              child: SvgPicture.asset(
                'assets/icons/moves/draw.svg',
                width: size * 0.62,
                height: size * 0.62,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
