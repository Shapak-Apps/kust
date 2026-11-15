import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/learn/garden_art.dart';
import 'package:kust/features/learn/garden_map.dart';
import 'package:kust/features/learn/lessons.dart';

void main() {
  test('every piece of scenery paints without throwing', () {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    const at = Offset(100, 200);
    GardenArt.tree(c, at, 1);
    GardenArt.tree(c, at, 0.7, fruit: false);
    GardenArt.pine(c, at, 1);
    GardenArt.bush(c, at, 1, berries: GardenArt.pinkBerries);
    GardenArt.rock(c, at, 1, moss: true);
    GardenArt.pond(c, at, 0.85);
    GardenArt.meadow(c, at, 6, 1);
    GardenArt.mushrooms(c, at, 1);
    GardenArt.log(c, at, 1);
    GardenArt.tent(c, at);
    GardenArt.campfire(c, at, 1);
    GardenArt.block(c, at, 76, 40, 24);
    GardenArt.groundDetail(c, const Size(400, 1200), 3);
    recorder.endRecording().dispose();
  });

  test('the whole map paints, at a phone pixel ratio, as cached bands', () {
    final layout = LearnMapLayout(width: 360, count: kLessons.length);
    final size = Size(360, layout.height);
    for (final next in [0, 4, -1]) {
      final recorder = ui.PictureRecorder();
      LearnMapPainter(
        layout: layout,
        done: {
          for (var i = 0; i < (next < 0 ? kLessons.length : next); i++)
            kLessons[i].id,
        },
        next: next,
        stars: const {},
        pixelRatio: 2.75,
      ).paint(Canvas(recorder), size);
      recorder.endRecording().dispose();
    }
  });
}
