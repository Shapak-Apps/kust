import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/gol_charts.dart';
import 'package:kust/features/puzzles/loom.dart';
import 'package:kust/features/puzzles/coach_bubble.dart';
import 'package:kust/features/puzzles/puzzles_screen.dart';
import 'package:kust/features/puzzles/speech_bubble.dart';
import 'package:kust/theme.dart';

void _paint(CustomPainter painter, Size size) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  group('göls', () {
    final letters = RegExp(r'^[.rywgk]+$');

    for (final kind in GolKind.values) {
      test('${kind.name} is a full chart of the flag göl', () {
        final rows = kGolChartRows[kind.name]!;
        expect(rows.length.isOdd, isTrue);
        expect(rows.length, inInclusiveRange(51, 75));
        for (final row in rows) {
          expect(row.length, golChartWidth);
          expect(row, matches(letters));
        }
        var knots = 0;
        final used = <Knot>{};
        for (var j = -golRows; j <= golRows; j++) {
          for (var i = -golCols; i <= golCols; i++) {
            final knot = golKnot(kind, i, j);
            if (knot == null) continue;
            knots++;
            used.add(knot);
          }
        }
        expect(knots, greaterThan(2500));
        expect(used, containsAll([Knot.saffron, Knot.ivory, Knot.indigo]));

        // The chart sits inside the grid with a margin on every side.
        final chart = GolChart.of(kind);
        for (final row in [chart.knots.first, chart.knots.last]) {
          expect(row.every((k) => k == null), isTrue);
        }
        for (final row in chart.knots) {
          expect(row.first, isNull);
          expect(row.last, isNull);
        }
        // Lines of the design exist, and the edge is part of them.
        var contour = 0;
        for (var r = 0; r < chart.rows; r++) {
          for (var c = 0; c < chart.cols; c++) {
            if (chart.outline[r][c]) expect(chart.contour[r][c], isTrue);
            if (chart.contour[r][c]) contour++;
          }
        }
        expect(contour, greaterThan(300));
      });
    }

    double similarity(GolKind kind, bool Function(int, int) mirrored) {
      final rows = kGolChartRows[kind.name]!;
      final h = rows.length, w = golChartWidth;
      var same = 0;
      for (var r = 0; r < h; r++) {
        for (var c = 0; c < w; c++) {
          final other = mirrored(r, c)
              ? rows[h - 1 - r][w - 1 - c]
              : rows[r][w - 1 - c];
          if (rows[r][c] == other) same++;
        }
      }
      return same / (h * w);
    }

    test('the göls have the symmetry of the real designs', () {
      // The Teke göl turns into itself after half a turn.
      expect(similarity(GolKind.teke, (_, _) => true), greaterThan(0.9));
      // The others are mirror images left to right.
      for (final kind in [GolKind.yomut, GolKind.arsary, GolKind.cowdur]) {
        expect(
          similarity(kind, (_, _) => false),
          greaterThan(0.9),
          reason: kind.name,
        );
      }
    });

    test('the five göls are different from each other', () {
      final seen = <String>{};
      for (final kind in GolKind.values) {
        expect(seen.add(kGolChartRows[kind.name]!.join()), isTrue);
      }
    });

    test('only known flag letters make knots', () {
      expect(knotOfLetter('y'), Knot.saffron);
      expect(knotOfLetter('w'), Knot.ivory);
      expect(knotOfLetter('g'), Knot.indigo);
      expect(knotOfLetter('k'), Knot.deep);
      expect(knotOfLetter('r'), Knot.rust);
      expect(knotOfLetter('.'), isNull);
      expect(knotOfLetter('?'), isNull);
    });

    test('knots outside the chart are empty', () {
      expect(golKnot(GolKind.teke, 60, 0), isNull);
      expect(golKnot(GolKind.teke, 0, -60), isNull);
      expect(golKnot(GolKind.teke, 0, 0), isNotNull);
    });

    test('charts are cached and outlines sit on the edge', () {
      final chart = GolChart.of(GolKind.teke);
      expect(identical(chart, GolChart.of(GolKind.teke)), isTrue);
      final middle = chart.rows ~/ 2;
      final firstKnot = chart.knots[middle].indexWhere((k) => k != null);
      expect(chart.outline[middle][firstKnot], isTrue);
      expect(chart.outline[middle][chart.cols ~/ 2], isFalse);
    });

    test('the border is one repeat of the flag strip that tiles', () {
      expect(kBorderRows.length, greaterThan(50));
      final width = kBorderRows.first.length;
      expect(width, lessThanOrEqualTo(10));
      for (final row in kBorderRows) {
        expect(row.length, width);
        expect(row, matches(letters));
      }
      // It has a pattern, and its last row leads into its first.
      expect(kBorderRows.join().contains('y'), isTrue);
      var same = 0;
      for (var c = 0; c < width; c++) {
        if (kBorderRows.last[c] == kBorderRows.first[c]) same++;
      }
      expect(same, greaterThanOrEqualTo(width ~/ 2));
      // The tile and its guard line fit in the border of the runner.
      expect(
        width * LoomMetrics.knot + LoomMetrics.knot,
        lessThanOrEqualTo(LoomMetrics.border),
      );
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
        _paint(LoomPainter(gols: gols, woven: woven), size);
      }
      final a = LoomPainter(gols: gols, woven: 0.2);
      expect(a.shouldRepaint(LoomPainter(gols: gols, woven: 0.2)), isFalse);
      expect(a.shouldRepaint(LoomPainter(gols: gols, woven: 0.3)), isTrue);
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
        // Levels 2 to 5 have puzzles but wait for level 1 to be woven.
        expect(find.text('Not started'), findsNWidgets(4));
        expect(find.text('Continue · Mate in 1'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Mate in 1, 0 of 36 knots')),
          findsOneWidget,
        );
        // The coach is a speech bubble floating over the carpet, in the same
        // stack as the scrolling path, and the carpet starts below it.
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is SpeechBubblePainter,
          ),
          findsOneWidget,
        );
        final coach = tester.getRect(find.byType(CoachBubble));
        final path = tester.getRect(find.byType(SingleChildScrollView));
        expect(path.overlaps(coach), isTrue);
        expect(
          find
              .ancestor(
                of: find.byType(CoachBubble),
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
        expect(find.textContaining('Next: Mate in 1'), findsOneWidget);
        // The scrolling content has padding so the carpet starts below the
        // coach's face.
        final scroll = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(
          (scroll.padding! as EdgeInsets).top,
          greaterThanOrEqualTo(coach.height - 10),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
