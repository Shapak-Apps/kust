import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/feedback_glow.dart';

void main() {
  test('the glow flares up, then settles to a soft tint', () {
    expect(feedbackGlowStrength(0), 0);
    expect(feedbackGlowStrength(0.3), closeTo(1, 1e-9));
    expect(feedbackGlowStrength(1), closeTo(0.55, 1e-9));
    for (var t = 0.0; t < 0.3; t += 0.05) {
      expect(
        feedbackGlowStrength(t + 0.05),
        greaterThan(feedbackGlowStrength(t)),
      );
    }
  });

  testWidgets('paints its own square only, on its own layer', (tester) async {
    const key = GlobalObjectKey('board');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: SizedBox.square(
              dimension: 400,
              child: FeedbackGlow(color: Color(0xFF00FF00), row: 2, col: 5),
            ),
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(FeedbackGlow),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 200));
    final image = await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return boundary.toImage();
    });
    final bytes = (await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!.buffer.asUint8List();
    int alphaAt(int x, int y) => bytes[(y * 400 + x) * 4 + 3];
    // Square row 2, column 5 spans x 250..300, y 100..150.
    expect(alphaAt(275, 125), greaterThan(0));
    expect(alphaAt(251, 101), greaterThan(0));
    // Its neighbours stay untouched: no glow bleeds over the edge.
    expect(alphaAt(249, 125), 0);
    expect(alphaAt(300, 125), 0);
    expect(alphaAt(275, 99), 0);
    expect(alphaAt(275, 150), 0);
    await tester.pump(const Duration(seconds: 1));
  });

  test('the engine rates a move with a depth cap and searchmoves last', () {
    expect(
      ChessEngine.goCommand(const Duration(milliseconds: 400), depth: 12),
      'go depth 12 movetime 400',
    );
    expect(
      ChessEngine.goCommand(
        const Duration(milliseconds: 400),
        depth: 12,
        searchMove: 'e2e4',
      ),
      'go depth 12 movetime 400 searchmoves e2e4',
    );
    expect(
      ChessEngine.goCommand(const Duration(milliseconds: 250)),
      'go movetime 250',
    );
  });
}
