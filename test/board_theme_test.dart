import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/board_theme.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/theme.dart';
import 'package:kust/widgets/more_sheet.dart';

void main() {
  tearDown(() {
    AppSettings.instance.boardTheme.value = BoardTheme.defaultTheme;
  });

  group('themes', () {
    test('there are four, each with distinct light and dark squares', () {
      expect(BoardTheme.values.map((t) => t.label), [
        'Brown',
        'Green',
        'Dark Blue',
        'Wood',
      ]);
      for (final t in BoardTheme.values) {
        expect(t.light, isNot(t.dark), reason: t.label);
      }
      expect(BoardTheme.values.where((t) => t.grain), [BoardTheme.wood]);
    });

    test(
      'a saved name maps back to its theme, anything else to the default',
      () {
        for (final t in BoardTheme.values) {
          expect(BoardTheme.fromName(t.name), t);
        }
        expect(BoardTheme.fromName(null), BoardTheme.defaultTheme);
        expect(BoardTheme.fromName('neon'), BoardTheme.defaultTheme);
      },
    );

    test('the grain paints and only repaints when its square changes', () {
      const a = WoodGrainPainter(seed: 3, light: true);
      expect(
        a.shouldRepaint(const WoodGrainPainter(seed: 3, light: true)),
        isFalse,
      );
      expect(
        a.shouldRepaint(const WoodGrainPainter(seed: 4, light: true)),
        isTrue,
      );
      expect(
        a.shouldRepaint(const WoodGrainPainter(seed: 3, light: false)),
        isTrue,
      );
    });
  });

  group('settings', () {
    test('the choice is saved and loaded again', () async {
      SharedPreferences.setMockInitialValues({'board_theme': 'wood'});
      final s = AppSettings.instance;
      await s.load();
      expect(s.boardTheme.value, BoardTheme.wood);

      await s.setBoardTheme(BoardTheme.blue);
      expect(s.boardTheme.value, BoardTheme.blue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('board_theme'), 'blue');

      SharedPreferences.setMockInitialValues({});
      await s.load();
      expect(s.boardTheme.value, BoardTheme.defaultTheme);
    });

    testWidgets('the settings sheet lists the boards and picks one', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() => AppSettings.instance.load());
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showSettingsSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('BOARD'), findsOneWidget);
      for (final t in BoardTheme.values) {
        expect(find.text(t.label), findsOneWidget);
      }
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is BoardThemeSwatch &&
              w.selected &&
              w.theme == BoardTheme.brown,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Dark Blue'));
      await tester.pumpAndSettle();
      expect(AppSettings.instance.boardTheme.value, BoardTheme.blue);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is BoardThemeSwatch && w.selected && w.theme == BoardTheme.blue,
        ),
        findsOneWidget,
      );
    });
  });

  group('puzzle board', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: PuzzleBoard(
                  position: Chess.initial,
                  flipped: false,
                  interactive: false,
                  onMove: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    int count(WidgetTester tester, Color color) => tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color == color)
        .length;

    testWidgets('draws 32 squares of each colour, with a1 dark', (
      tester,
    ) async {
      await pump(tester);
      final theme = BoardTheme.defaultTheme;
      expect(count(tester, theme.light), 32);
      expect(count(tester, theme.dark), 32);

      // a1 is the bottom-left square.
      final bottomLeft = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.color == theme.dark || c.color == theme.light)
          .toList();
      final a1 = find.byWidget(
        bottomLeft.firstWhere((c) {
          final rect = tester.getRect(find.byWidget(c));
          return rect.left == 0 && rect.bottom == 600;
        }),
      );
      expect(tester.widget<Container>(a1).color, theme.dark);
    });

    testWidgets('changes colour when the setting changes', (tester) async {
      await pump(tester);
      AppSettings.instance.boardTheme.value = BoardTheme.green;
      await tester.pump();
      expect(count(tester, BoardTheme.green.light), 32);
      expect(count(tester, BoardTheme.green.dark), 32);
      expect(count(tester, BoardTheme.brown.dark), 0);
    });

    testWidgets('the wood theme draws a grain on every square', (tester) async {
      await pump(tester);
      AppSettings.instance.boardTheme.value = BoardTheme.wood;
      await tester.pump();
      final grains = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((p) => p.painter is WoodGrainPainter);
      expect(grains.length, 64);
    });
  });

  group('game board', () {
    testWidgets('a1 is dark and the colours follow the setting', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: appTheme,
            home: const Scaffold(body: Center(child: ChessBoard())),
          ),
        ),
      );
      await container
          .read(chessControllerProvider.notifier)
          .startGame(kInternationalBots.first, playerSide: Side.white);
      await tester.pumpAndSettle();

      Color background(Square s) => tester
          .widgetList<BoardSquareCell>(find.byType(BoardSquareCell))
          .firstWhere((c) => c.props.square == s)
          .props
          .background;

      var theme = BoardTheme.defaultTheme;
      expect(background(Square.a1), theme.dark);
      expect(background(Square.h1), theme.light);
      expect(background(Square.a8), theme.light);

      AppSettings.instance.boardTheme.value = BoardTheme.blue;
      await tester.pump();
      theme = BoardTheme.blue;
      expect(background(Square.a1), theme.dark);
      expect(background(Square.h1), theme.light);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
    });
  });
}
