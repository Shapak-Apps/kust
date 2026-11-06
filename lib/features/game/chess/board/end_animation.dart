import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kust/features/game/chess/board/board_squares_painter.dart';

/// How the board shows the end of a game, before the result dialog.
///
/// Checkmate: the mated king's square turns red and the king tips over; the
/// winner's king turns green and hops. A draw (stalemate, 50 moves,
/// repetition, no material, ...): both king squares turn grey and an equals
/// badge pops up on each.

/// The pause after the last move, so its piece lands before this starts.
const Duration kEndFxDelay = Duration(milliseconds: 300);

/// How long the checkmate show runs.
const Duration kMateFxDuration = Duration(milliseconds: 1500);

/// How long the draw show runs.
const Duration kDrawFxDuration = Duration(milliseconds: 900);

/// A breath between the end of the show and the dialog.
const Duration kEndFxRest = Duration(milliseconds: 400);

const Color kEndRed = Color(0xFFE5484D);
const Color kEndGreen = Color(0xFF3CB77C);
const Color kEndGrey = Color(0xFF9A9A9A);

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
    final s = tintProgress(progress.value);
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
          ..color = cell.color.withValues(alpha: 0.62 * s),
      );
    }
  }

  @override
  bool shouldRepaint(_EndTintPainter old) =>
      old.progress != progress ||
      old.devicePixelRatio != devicePixelRatio ||
      old.cells.length != cells.length;
}

/// The mated king: it turns red and tips over, with a small rebound.
///
/// [towards] is +1 to fall to the right, -1 to the left. [child] is the
/// king, built once.
class TippingKing extends StatelessWidget {
  const TippingKing({
    super.key,
    required this.progress,
    required this.towards,
    required this.cell,
    required this.child,
  });

  final Animation<double> progress;
  final int towards;

  /// The size of a square.
  final double cell;
  final Widget child;

  /// How far over it has gone, in quarter turns: past the flat, then back.
  static double lean(double t) {
    if (t < 0.12) return 0;
    if (t < 0.58) {
      return 1.1 * Curves.easeInCubic.transform((t - 0.12) / 0.46);
    }
    if (t < 0.78) {
      return 1.1 - 0.1 * Curves.easeOut.transform((t - 0.58) / 0.2);
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final t = progress.value;
        final quarter = lean(t);
        // A little shake before it goes, so it looks hit.
        final shake = t < 0.12 ? math.sin(t / 0.12 * math.pi * 4) * 0.05 : 0.0;
        return Transform.translate(
          offset: Offset(0, cell * 0.03 * quarter.clamp(0.0, 1.0)),
          child: Transform.rotate(
            angle: towards * quarter * math.pi / 2 + shake,
            alignment: const Alignment(0, 0.3),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                kEndRed.withValues(alpha: 0.62 * tintProgress(t)),
                BlendMode.srcATop,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// The winner's king: it turns green and hops, tilting left and right.
class HoppingKing extends StatelessWidget {
  const HoppingKing({
    super.key,
    required this.progress,
    required this.cell,
    required this.child,
  });

  final Animation<double> progress;

  /// The size of a square.
  final double cell;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final t = progress.value;
        // Starts a moment after the colour, then settles.
        final q = ((t - 0.1) / 0.9).clamp(0.0, 1.0);
        final fade = 1 - 0.45 * q;
        final hop = math.sin(q * math.pi * 3).abs() * fade;
        final sway = math.sin(q * math.pi * 3 + math.pi / 2);
        final tilt = math.sin(q * math.pi * 3) * 0.30 * fade;
        return Transform.translate(
          offset: Offset(
            sway * cell * 0.10 * fade * (q > 0 ? 1 : 0),
            -cell * 0.38 * hop,
          ),
          child: Transform.rotate(
            angle: q >= 1 ? 0 : tilt,
            child: Transform.scale(
              scale: 1 + 0.12 * hop,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  kEndGreen.withValues(alpha: 0.55 * tintProgress(t)),
                  BlendMode.srcATop,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The equals badge of a draw, on the corner of a king's square like the
/// badge of a rated move. It pops in with a small overshoot.
class DrawBadge extends StatelessWidget {
  const DrawBadge({super.key, required this.progress, required this.size});

  final Animation<double> progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final pop = Curves.easeOutBack
            .transform(((progress.value - 0.15) / 0.4).clamp(0.0, 1.0))
            .clamp(0.0, 1.2);
        return Transform.scale(
          scale: pop,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB9B7B2), Color(0xFF8A8883)],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: size * 0.04,
              ),
              boxShadow: [
                BoxShadow(
                  color: kEndGrey.withValues(alpha: 0.5),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: _Equals(size: size * 0.52),
          ),
        );
      },
    );
  }
}

/// Two round bars: the equals sign.
class _Equals extends StatelessWidget {
  const _Equals({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(
      width: size,
      height: size * 0.24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(),
        SizedBox(height: size * 0.2),
        bar(),
      ],
    );
  }
}
