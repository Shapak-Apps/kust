import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/evaluation_bar.dart';
import 'package:kust/features/history/replay_screen.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
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

Widget _app({
  ReplayEvaluator? evaluator,
  GameRecord record = _game,
  void Function(String)? playSound,
}) => MaterialApp(
  theme: appTheme,
  home: ReplayScreen(
    gameId: 'g',
    record: record,
    evaluator: evaluator,
    playSound: playSound ?? (_) {},
  ),
);

String _fen(WidgetTester tester) =>
    tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).position.fen;

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.tune_rounded));
  await tester.pumpAndSettle();
}

void main() {
  _layoutTests();
  testWidgets('steps through the game and the strip jumps to a move', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final start = _fen(tester);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(_fen(tester), isNot(start));

    await tester.tap(find.text('2. Nf3'));
    await tester.pumpAndSettle();
    expect(_fen(tester), contains('5N2'));

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(_fen(tester), isNot(contains('5N2')));

    await tester.tap(find.byIcon(Icons.first_page_rounded));
    await tester.pumpAndSettle();
    expect(_fen(tester), start);
  });

  testWidgets('hides the move title and counter block', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('2. Nf3'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Move '), findsNothing);
    expect(find.text('Start position'), findsNothing);
    // The only place a move reads "2. Nf3" is the strip.
    expect(find.text('2. Nf3'), findsOneWidget);
  });

  testWidgets('plays move, capture, castle and check sounds when stepping', (
    tester,
  ) async {
    final played = <String>[];
    const record = GameRecord(
      id: 'g2',
      playedAt: 0,
      isLocal: true,
      result: GameRecord.whiteWon,
      reason: '',
      playerIsWhite: true,
      // 1.e4 d5 2.exd5 Qxd5 3.Nc3 Qa5 4.Nf3 e6 5.Bc4 Nf6 6.O-O Bb4 7.Bxe6 fxe6
      uciMoves: [
        'e2e4',
        'd7d5',
        'e4d5',
        'd8d5',
        'b1c3',
        'd5a5',
        'g1f3',
        'e7e6',
        'f1c4',
        'g8f6',
        'e1h1',
        'f8b4',
        'c4e6',
        'f7e6',
      ],
      sanMoves: [
        'e4',
        'd5',
        'exd5',
        'Qxd5',
        'Nc3',
        'Qa5',
        'Nf3',
        'e6',
        'Bc4',
        'Nf6',
        'O-O',
        'Bb4',
        'Bxe6',
        'fxe6',
      ],
    );
    await tester.pumpWidget(_app(record: record, playSound: played.add));

    final next = find.byIcon(Icons.chevron_right_rounded);
    for (var i = 0; i < 14; i++) {
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(played.first, 'move.wav'); // 1. e4
    expect(played[2], 'capture.wav'); // 2. exd5
    expect(played[10], 'castle.wav'); // 6. O-O
    expect(played[12], 'capture.wav'); // 7. Bxe6
    expect(played.length, 14);

    // Stepping back is a plain move sound; jumping is silent.
    played.clear();
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(played, ['move.wav']);
    played.clear();
    await tester.tap(find.byIcon(Icons.first_page_rounded));
    await tester.pumpAndSettle();
    expect(played, isEmpty);
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

void _layoutTests() {
  testWidgets('the current move is centered in the strip', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    for (final label in ['1. e4', '2. Nf3', 'Nc6']) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      final center = tester.getCenter(find.text(label).first);
      expect(center.dx, closeTo(200, 2), reason: label);
    }
  });

  testWidgets('the board uses the full width', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    final board = tester.getRect(find.byType(PuzzleBoard));
    expect(board.left, 0);
    expect(board.width, 400);
  });
}
