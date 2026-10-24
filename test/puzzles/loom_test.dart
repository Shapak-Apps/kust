import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/loom.dart';
import 'package:kust/features/puzzles/puzzles_screen.dart';
import 'package:kust/theme.dart';

void _paint(CustomPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  group('göls', () {
    for (final kind in GolKind.values) {
      test('${kind.name} is symmetric and has a saffron heart', () {
        final chart = GolChart.of(kind);
        var knots = 0;
        var saffron = false;
        for (var j = -golRows; j <= golRows; j++) {
          for (var i = -golCols; i <= golCols; i++) {
            final knot = golKnot(kind, i, j);
            if (knot == null) continue;
            knots++;
            saffron |= knot == Knot.saffron;
            // The outline mirrors both ways; colours (diagonal quarter pairs,
            // S-hooks) repeat when turned half a circle.
            expect(golKnot(kind, -i, j), isNotNull, reason: '($i, $j)');
            expect(golKnot(kind, i, -j), isNotNull, reason: '($i, $j)');
            expect(golKnot(kind, -i, -j), knot, reason: '($i, $j)');
          }
        }
        expect(saffron, isTrue);
        expect(knots, greaterThan(600));
        // Nothing is cut off by the chart's edge.
        for (final row in [chart.knots.first, chart.knots.last]) {
          expect(row.every((k) => k == null), isTrue);
        }
        for (final row in chart.knots) {
          expect(row.first, isNull);
          expect(row.last, isNull);
        }
      });
    }

    test('charts are cached and outlines sit on the edge', () {
      final chart = GolChart.of(GolKind.teke);
      expect(identical(chart, GolChart.of(GolKind.teke)), isTrue);
      final middle = chart.rows ~/ 2;
      final firstKnot = chart.knots[middle].indexWhere((k) => k != null);
      expect(chart.outline[middle][firstKnot], isTrue);
      expect(chart.outline[middle][chart.cols ~/ 2], isFalse);
    });

    test('every göl fits inside the runner between its borders', () {
      const width = (2 * golCols + 1) * LoomMetrics.knot;
      expect(width, lessThanOrEqualTo(LoomMetrics.width - LoomMetrics.border));
      expect(
        (2 * golRows + 1) * LoomMetrics.knot,
        lessThanOrEqualTo(LoomMetrics.slot),
      );
    });
  });

  group('loom', () {
    test('the fell climbs as levels are woven', () {
      const n = 5;
      final start = LoomMetrics.fell(n, 0);
      final half = LoomMetrics.fell(n, 0.5);
      final done = LoomMetrics.fell(n, 1);
      expect(start, LoomMetrics.golBottom(n, 0));
      expect(half, lessThan(start));
      expect(half, greaterThan(LoomMetrics.golTop(n, 0)));
      expect(done, LoomMetrics.golBottom(n, 1));
      // Beyond the last level it stays on the top göl.
      expect(
        LoomMetrics.fell(n, 9),
        closeTo(LoomMetrics.golTop(n, n - 1), 1e-9),
      );
    });

    test('paints at every stage and repaints only when it moves', () {
      final gols = GolKind.values.toList();
      final size = Size(LoomMetrics.width, LoomMetrics.height(gols.length));
      for (final woven in [0.0, 0.3, 0.99, 1.0, 2.5, 5.0]) {
        _paint(
          LoomPainter(gols: gols, woven: woven, current: woven.floor()),
          size,
        );
      }
      final a = LoomPainter(gols: gols, woven: 0.2, current: 0);
      expect(
        a.shouldRepaint(LoomPainter(gols: gols, woven: 0.2, current: 0)),
        isFalse,
      );
      expect(
        a.shouldRepaint(LoomPainter(gols: gols, woven: 0.3, current: 0)),
        isTrue,
      );
    });
  });

  group('puzzle screen', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('kust_loom_ui');
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
      testWidgets('shows the carpet, five göls and the next puzzle '
          '(${entry.key})', (tester) async {
        await pumpScreen(tester, entry.value);

        expect(find.textContaining('Next: Mate in 1'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is LoomPainter,
          ),
          findsOneWidget,
        );
        for (final level in kLoomLevels) {
          expect(find.text(level.theme), findsOneWidget);
          expect(find.text(level.tribe.toUpperCase()), findsNothing);
        }
        expect(find.textContaining('0 of 36 knots'), findsOneWidget);
        expect(find.text('Coming soon'), findsNWidgets(4));
        expect(find.text('Continue · Mate in 1'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Mate in 1, 0 of 36 knots')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
