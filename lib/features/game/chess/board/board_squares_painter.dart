import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Paints the colour of all 64 squares in one pass.
///
/// Every edge is rounded to a whole device pixel and the squares are drawn
/// without anti-aliasing, so neighbours meet exactly: no square bleeds into
/// the next one and no thin line flickers between them. Squares painted one
/// by one at fractional sizes blend at their shared edges and show seams.
class BoardSquaresPainter extends CustomPainter {
  BoardSquaresPainter({required this.colors, required this.devicePixelRatio})
    : assert(colors.length == 64);

  /// One colour per square as shown on screen, row by row from the top left.
  final List<Color> colors;
  final double devicePixelRatio;

  /// The rectangle of the square at [row], [col] (as shown on screen) on a
  /// board of [size], with its edges on whole device pixels. Neighbouring
  /// squares share their edges exactly.
  static Rect squareRect(Size size, int row, int col, double devicePixelRatio) {
    double edge(double length, int i) =>
        (length * i / 8 * devicePixelRatio).roundToDouble() / devicePixelRatio;
    return Rect.fromLTRB(
      edge(size.width, col),
      edge(size.height, row),
      edge(size.width, col + 1),
      edge(size.height, row + 1),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        paint.color = colors[row * 8 + col];
        canvas.drawRect(squareRect(size, row, col, devicePixelRatio), paint);
      }
    }
  }

  @override
  bool shouldRepaint(BoardSquaresPainter old) =>
      old.devicePixelRatio != devicePixelRatio ||
      !listEquals(old.colors, colors);
}
