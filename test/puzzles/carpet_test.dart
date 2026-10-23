import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/puzzles/carpet.dart';
import 'package:kust/features/puzzles/puzzles_screen.dart';
import 'package:kust/theme.dart';

void _paint(CustomPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  group('shapes', () {
    test('an octagon is as wide as two apothems and has 8 sides', () {
      final bounds = octagonPath(Offset.zero, 40).getBounds();
      final apothem = 40 * math.cos(math.pi / 8);
      expect(bounds.width, closeTo(2 * apothem, 0.001));
      expect(bounds.height, closeTo(2 * apothem, 0.001));
    });

    test('a diamond spans its radius in both directions', () {
      final bounds = diamondPath(const Offset(10, 20), 5).getBounds();
      expect(bounds, const Rect.fromLTRB(5, 15, 15, 25));
    });
  });

  group('speech bubble', () {
    test('has a body with a tail sticking out on the left', () {
      const size = Size(300, 80);
      final path = SpeechBubblePainter.shape(size);
      final bounds = path.getBounds();
      expect(bounds.left, 0); // the tail tip
      expect(bounds.right, size.width);
      expect(bounds.top, 0);
      expect(bounds.bottom, size.height);

      // The body starts after the tail; the tail is only low on the left.
      expect(path.contains(const Offset(BubbleMetrics.tail + 20, 40)), isTrue);
      expect(path.contains(const Offset(2, 80 - 22 + 4)), isTrue); // tail
      expect(path.contains(const Offset(2, 8)), isFalse); // above the tail
    });

    test('corners are rounded', () {
      final path = SpeechBubblePainter.shape(const Size(300, 80));
      expect(path.contains(const Offset(BubbleMetrics.tail + 1, 1)), isFalse);
      expect(path.contains(const Offset(299, 1)), isFalse);
    });

    test('paints and only repaints when colors change', () {
      const a = SpeechBubblePainter(fill: Colors.white, border: Colors.grey);
      _paint(a, const Size(300, 80));
      expect(
        a.shouldRepaint(
          const SpeechBubblePainter(fill: Colors.white, border: Colors.grey),
        ),
        isFalse,
      );
      expect(
        a.shouldRepaint(
          const SpeechBubblePainter(fill: Colors.black, border: Colors.grey),
        ),
        isTrue,
      );
    });
  });

  group('painters', () {
    test('the carpet paints in both themes at path size', () {
      for (final colors in [CarpetColors.light, CarpetColors.dark]) {
        _paint(CarpetPatternPainter(colors: colors), const Size(400, 4400));
      }
    });

    test('the carpet only repaints when its colors change', () {
      const a = CarpetPatternPainter(colors: CarpetColors.light);
      expect(
        a.shouldRepaint(const CarpetPatternPainter(colors: CarpetColors.light)),
        isFalse,
      );
      expect(
        a.shouldRepaint(const CarpetPatternPainter(colors: CarpetColors.dark)),
        isTrue,
      );
    });

    test('medallions paint, with and without the halo', () {
      _paint(
        const OctagonPainter(fill: Colors.amber, ring: Colors.black),
        const Size(68, 68),
      );
      _paint(
        const OctagonPainter(
          fill: Colors.amber,
          ring: Colors.black,
          halo: Colors.red,
        ),
        const Size(68, 68),
      );
    });

    test(
      'the thread paints done and dotted segments and handles edge cases',
      () {
        final centers = [
          const Offset(100, 400),
          const Offset(50, 300),
          const Offset(100, 200),
          const Offset(100, 200), // zero-length segment
        ];
        for (final reached in [0, 1, 3]) {
          _paint(
            ThreadPainter(
              centers: centers,
              reachedIndex: reached,
              done: Colors.amber,
              todo: Colors.grey,
            ),
            const Size(200, 500),
          );
        }
        _paint(
          const ThreadPainter(
            centers: [Offset(1, 1)],
            reachedIndex: 0,
            done: Colors.amber,
            todo: Colors.grey,
          ),
          const Size(10, 10),
        );
      },
    );
  });

  group('puzzle screen', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('kust_carpet_ui');
      Hive.init(dir.path);
      await Hive.openBox(AppStorage.userBoxName);
      await Hive.openBox(AppStorage.puzzleBoxName);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    Future<void> pumpScreen(WidgetTester tester, ThemeData theme) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: PuzzlesScreen()),
        ),
      );
      for (var i = 0; i < 50; i++) {
        if (find.textContaining('Next:').evaluate().isNotEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    for (final entry in {'light': appTheme, 'dark': appDarkTheme}.entries) {
      testWidgets('shows the coach, carpet and medallions (${entry.key})', (
        tester,
      ) async {
        await pumpScreen(tester, entry.value);

        expect(find.textContaining('Next: Mate in 1'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is CarpetPatternPainter,
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is ThreadPainter,
          ),
          findsOneWidget,
        );
        // At least the first medallion is in view and reads as available.
        expect(
          find.bySemanticsLabel(RegExp('Puzzle 1, available')),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is OctagonPainter,
          ),
          findsWidgets,
        );
        // The coach is a speech bubble floating over the carpet, in the same
        // stack as the scrolling path, not a block above it.
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is SpeechBubblePainter,
          ),
          findsOneWidget,
        );
        final coach = tester.getRect(find.textContaining('Next: Mate in 1'));
        final path = tester.getRect(find.byType(SingleChildScrollView));
        expect(path.overlaps(coach), isTrue);
        expect(
          find
              .ancestor(
                of: find.textContaining('Next: Mate in 1'),
                matching: find.byType(Stack),
              )
              .evaluate()
              .any(
                (e) => find
                    .descendant(
                      of: find.byWidget(e.widget),
                      matching: find.byType(SingleChildScrollView),
                    )
                    .evaluate()
                    .isNotEmpty,
              ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
