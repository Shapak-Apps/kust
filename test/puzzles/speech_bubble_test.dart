import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/puzzles/speech_bubble.dart';

void main() {
  const size = Size(300, 80);

  test('has a body that starts after the tail, and a tail on the left', () {
    final path = SpeechBubblePainter.shape(size);
    final bounds = path.getBounds();
    expect(bounds.left, 0); // the tail tip
    expect(bounds.right, size.width);
    expect(bounds.top, 0);
    expect(bounds.bottom, size.height);

    expect(path.contains(const Offset(BubbleMetrics.tail + 20, 40)), isTrue);
    // The tail sits at mid height and is narrow at its tip.
    expect(path.contains(const Offset(3, 40)), isTrue);
    expect(path.contains(const Offset(3, 10)), isFalse);
    expect(path.contains(const Offset(3, 70)), isFalse);
  });

  test('corners are rounded', () {
    final path = SpeechBubblePainter.shape(size);
    expect(path.contains(const Offset(BubbleMetrics.tail + 1, 1)), isFalse);
    expect(path.contains(const Offset(299, 1)), isFalse);
    expect(path.contains(const Offset(299, 79)), isFalse);
  });

  test('paints and only repaints when its colors change', () {
    const a = SpeechBubblePainter(fill: Colors.white, border: Colors.black);
    final recorder = ui.PictureRecorder();
    a.paint(Canvas(recorder), size);
    recorder.endRecording().dispose();

    expect(
      a.shouldRepaint(
        const SpeechBubblePainter(fill: Colors.white, border: Colors.black),
      ),
      isFalse,
    );
    expect(
      a.shouldRepaint(
        const SpeechBubblePainter(fill: Colors.red, border: Colors.black),
      ),
      isTrue,
    );
    expect(
      a.shouldRepaint(
        const SpeechBubblePainter(fill: Colors.white, border: Colors.red),
      ),
      isTrue,
    );
  });
}
