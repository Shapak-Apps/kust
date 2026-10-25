import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/board/board_squares_painter.dart';

void main() {
  group('square edges', () {
    for (final (side, dpr) in [(361.7, 2.75), (400.0, 3.0), (333.3, 1.0)]) {
      test('tile without gaps or overlaps ($side at ${dpr}x)', () {
        final size = Size(side, side);
        for (var row = 0; row < 8; row++) {
          for (var col = 0; col < 8; col++) {
            final rect = BoardSquaresPainter.squareRect(size, row, col, dpr);
            // Every edge lies on a whole device pixel.
            for (final v in [rect.left, rect.top, rect.right, rect.bottom]) {
              expect((v * dpr - (v * dpr).round()).abs(), lessThan(1e-6));
            }
            if (col < 7) {
              final next = BoardSquaresPainter.squareRect(
                size,
                row,
                col + 1,
                dpr,
              );
              expect(next.left, rect.right);
            }
            if (row < 7) {
              final below = BoardSquaresPainter.squareRect(
                size,
                row + 1,
                col,
                dpr,
              );
              expect(below.top, rect.bottom);
            }
          }
        }
        final last = BoardSquaresPainter.squareRect(size, 7, 7, dpr);
        expect((last.right - side).abs(), lessThanOrEqualTo(0.5 / dpr + 1e-9));
      });
    }
  });

  test('two equal squares side by side leave no line between them', () async {
    // A board of one colour at an awkward size: every pixel must come out
    // that colour, with no darker seam where squares meet.
    const colour = Color(0xFF769656);
    const side = 203.0, dpr = 1.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFF000000), BlendMode.src);
    BoardSquaresPainter(
      colors: List.filled(64, colour),
      devicePixelRatio: dpr,
    ).paint(canvas, const Size(side, side));
    final image = await recorder.endRecording().toImage(203, 203);
    final bytes = (await image.toByteData())!.buffer.asUint8List();
    for (var i = 0; i < bytes.length; i += 4) {
      expect(bytes[i], 0x76);
      expect(bytes[i + 1], 0x96);
      expect(bytes[i + 2], 0x56);
    }
  });

  test('repaints only when a colour or the pixel ratio changes', () {
    final a = BoardSquaresPainter(
      colors: List.filled(64, Colors.white),
      devicePixelRatio: 3,
    );
    expect(
      a.shouldRepaint(
        BoardSquaresPainter(
          colors: List.filled(64, Colors.white),
          devicePixelRatio: 3,
        ),
      ),
      isFalse,
    );
    final changed = List<Color>.filled(64, Colors.white)..[10] = Colors.red;
    expect(
      a.shouldRepaint(
        BoardSquaresPainter(colors: changed, devicePixelRatio: 3),
      ),
      isTrue,
    );
  });
}
