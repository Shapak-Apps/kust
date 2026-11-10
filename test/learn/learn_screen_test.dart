import 'dart:io' as io;
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/features/learn/learn_screen.dart';
import 'package:kust/features/learn/lesson_screen.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/theme.dart';

const _shots =
    '/tmp/claude-1000/-home-merdan-projects-kust/760b9389-a422-43b3-b398-cd8c57ce1199/scratchpad';

Future<void> _drag(WidgetTester tester, String from, String to) async {
  final rect = tester.getRect(find.byType(PuzzleBoard));
  final cell = rect.width / 8;
  Offset at(String sq) {
    final file = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(sq[1]) - 1;
    return rect.topLeft + Offset((file + 0.5) * cell, (7 - rank + 0.5) * cell);
  }

  final g = await tester.startGesture(at(from));
  await tester.pump(const Duration(milliseconds: 20));
  await g.moveTo(at(from) + const Offset(0, -12));
  await tester.pump(const Duration(milliseconds: 20));
  await g.moveTo(at(to));
  await tester.pump(const Duration(milliseconds: 20));
  await g.up();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _shot(WidgetTester tester, String name) async {
  final boundary = tester.firstRenderObject(
    find.byKey(const ValueKey('shot')),
  ) as RenderRepaintBoundary;
  final image = await tester.runAsync(() => boundary.toImage());
  final bytes = await tester.runAsync(
    () => image!.toByteData(format: ImageByteFormat.png),
  );
  io.File('$_shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.soundEnabled = false;
    LearnProgress.instance.done.value = const {};
  });

  testWidgets('the Learn tab lists the lessons and marks the next one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const LearnScreen()),
        GoRoute(
          path: '/lesson/:id',
          builder: (_, s) => Text('lesson ${s.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('shot'),
        child: MaterialApp.router(theme: appDarkTheme, routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('The pawn'), findsWidgets);
    expect(find.text('Checkmate'), findsWidgets);
    expect(find.text('0 / 33'), findsOneWidget);
    expect(find.text('Learn how every piece moves'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await _shot(tester, 'learn');
    // With a few lessons done the trail turns gold up to the next stop.
    await LearnProgress.instance.complete('pawn', stars: 3);
    await LearnProgress.instance.complete('rook', stars: 2);
    await LearnProgress.instance.complete('bishop', stars: 3);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('8 / 33'), findsOneWidget);
    await _shot(tester, 'learn_done');
    LearnProgress.instance.done.value = const {};
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('The pawn').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('lesson pawn'), findsOneWidget);
  });

  testWidgets('a lesson runs from its introduction to its end', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const LessonScreen(lessonId: 'pawn'),
        ),
      ],
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('shot'),
        child: MaterialApp.router(theme: appDarkTheme, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start lesson'), findsOneWidget);
    await _shot(tester, 'lesson_intro');

    await tester.tap(find.text('Start lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Move the pawn to the star'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    await _shot(tester, 'lesson_task');

    // A move that is not the task: the pawn goes one square, the star stays.
    await _drag(tester, 'e2', 'e3');
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    await _drag(tester, 'e3', 'e4');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.text('Well done!'), findsOneWidget);
    await _shot(tester, 'lesson_solved');

    // Continue moves on to the next task.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Well done!'), findsNothing);
    expect(find.text('Move the pawn to the star'), findsOneWidget);
  });

  completeTests();
}

void completeTests() {
  testWidgets('a finished lesson shows its stars and saves them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const LessonScreen(lessonId: 'king'),
        ),
      ],
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('shot'),
        child: MaterialApp.router(theme: appDarkTheme, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await _shot(tester, 'lesson_intro');
    await tester.tap(find.text('Start lesson'));
    await tester.pumpAndSettle();
    for (final (a, b) in [('e1', 'e2'), ('e2', 'd3'), ('d3', 'c4')]) {
      await _drag(tester, a, b);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await _drag(tester, 'e1', 'e2');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Perfect lesson!'), findsOneWidget);
    expect(find.text('Next lesson'), findsOneWidget);
    expect(LearnProgress.instance.starsOf('king'), 3);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    await tester.pump(const Duration(seconds: 1));
    await _shot(tester, 'lesson_complete');
  });
}
