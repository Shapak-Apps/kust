import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/evaluation_bar.dart';
import 'package:kust/features/history/replay_screen.dart';
import 'package:kust/theme.dart';
import 'package:kust/ui/kust_controls.dart';

const _game = GameRecord(
  id: 'g',
  playedAt: 0,
  isLocal: false,
  result: GameRecord.win,
  reason: '',
  playerIsWhite: true,
  uciMoves: ['e2e4', 'e7e5', 'g1f3', 'b8c6'],
  sanMoves: ['e4', 'e5', 'Nf3', 'Nc6'],
  botName: 'Karl',
  botElo: 1000,
);

Widget _app({ReplayEvaluator? evaluator}) => MaterialApp(
  theme: appTheme,
  home: ReplayScreen(gameId: 'g', record: _game, evaluator: evaluator),
);

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.tune_rounded));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the move text and steps through the game', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('Start position'), findsOneWidget);
    expect(find.text('Move 0 of 4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Move 1 of 4'), findsOneWidget);
    expect(find.text('1. e4'), findsWidgets);

    await tester.tap(find.text('2. Nf3'));
    await tester.pumpAndSettle();
    expect(find.text('Move 3 of 4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Move 2 of 4'), findsOneWidget);
  });

  testWidgets('has no play button, speed control or copy button up top', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
    expect(find.textContaining('Speed'), findsNothing);
    expect(find.byIcon(Icons.copy_rounded), findsNothing);
  });

  testWidgets('the focused move is gold text, not a bubble', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('1. e4'));
    await tester.pumpAndSettle();

    final focused = tester.widget<Text>(find.text('1. e4').first);
    final other = tester.widget<Text>(find.text('2. Nf3'));
    expect(focused.style!.color, isNot(other.style!.color));
    expect(focused.style!.fontWeight, FontWeight.w800);
    // Plain text only: the strip has no decorated containers around moves.
    expect(
      find.ancestor(
        of: find.text('1. e4').first,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border != null,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('settings sheet copies the PGN', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_app());
    await _openSettings(tester);
    expect(find.text('Evaluation bar'), findsOneWidget);
    await tester.tap(find.text('Copy PGN'));
    await tester.pumpAndSettle();

    expect(copied, contains('[Result "1-0"]'));
    expect(copied, contains('1. e4 e5 2. Nf3 Nc6'));
    expect(find.text('PGN copied'), findsOneWidget);
  });

  testWidgets('evaluation bar appears from settings and follows the move', (
    tester,
  ) async {
    final asked = <String>[];
    await tester.pumpWidget(
      _app(
        evaluator: (fen) async {
          asked.add(fen);
          return const EvalScore(cp: 120);
        },
      ),
    );
    expect(find.byType(EvaluationBar), findsNothing);

    await _openSettings(tester);
    await tester.tap(find.byType(KustSwitch));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 20)); // close the sheet
    await tester.pumpAndSettle();

    expect(find.byType(EvaluationBar), findsOneWidget);
    expect(asked.length, 1);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(asked.length, 2);

    // Going back to a position already evaluated does not ask again.
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(asked.length, 2);
  });

  testWidgets('a failing evaluator shows a message instead of crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(evaluator: (_) async => throw StateError('x')),
    );
    await _openSettings(tester);
    await tester.tap(find.byType(KustSwitch));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();

    expect(find.byType(EvaluationBar), findsNothing);
    expect(find.text('Evaluation is unavailable right now'), findsOneWidget);
  });
}
