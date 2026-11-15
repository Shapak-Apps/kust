import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/play/bot_voice.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/theme.dart';

import '../support/fake_engine.dart';

/// A random source that always says yes.
class _Always extends Fake implements Random {
  @override
  double nextDouble() => 0;
}

Future<(ChessController, FakeEngine)> _game(
  WidgetTester tester, {
  required List<String> replies,
  required List<int> scores,
}) async {
  SharedPreferences.setMockInitialValues({});
  SoundService.instance.soundEnabled = false;
  addTearDown(() => SoundService.instance.soundEnabled = true);
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final engine = FakeEngine(replies, scores: scores);
  final container = ProviderContainer(
    overrides: [chessEngineProvider.overrideWithValue(engine)],
  );
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
  final c = container.read(chessControllerProvider.notifier)
    ..chatRandom = _Always();
  await c.startGame(kInternationalBots.first, playerSide: Side.white);
  await tester.pump();
  return (c, engine);
}

Future<void> _move(
  WidgetTester tester,
  ChessController c,
  FakeEngine engine,
  Square from,
  Square to,
) async {
  c.selectSquare(from);
  c.selectSquare(to);
  await tester.pump();
  engine.release();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 31));
}

void main() {
  testWidgets('a rated game: the bot sees your blunder in its own scores', (
    tester,
  ) async {
    final (c, engine) = await _game(
      tester,
      replies: ['e7e5', 'b8c6', 'g8f6'],
      scores: [50, 450, -100],
    );
    await _move(tester, c, engine, Square.e2, Square.e4);
    expect(c.state.botMomentSeq, 0); // nothing to compare with yet

    // Its score jumps from +50 to +450: your move was a blunder.
    await _move(tester, c, engine, Square.d2, Square.d3);
    expect(c.state.botMoment, BotMoment.blunder);
    expect(c.state.botMomentSeq, 1);

    // A strong move two plies on, within the cooldown: it stays quiet.
    await _move(tester, c, engine, Square.c1, Square.e3);
    expect(c.state.botMomentSeq, 1);
    await _end(tester);
  });

  testWidgets('a big drop in its own score is a strong move of yours', (
    tester,
  ) async {
    final (c, engine) = await _game(
      tester,
      replies: ['e7e5', 'b8c6'],
      scores: [300, -100],
    );
    await _move(tester, c, engine, Square.e2, Square.e4);
    await _move(tester, c, engine, Square.d2, Square.d4);
    expect(c.state.botMoment, BotMoment.brilliant);
    expect(c.state.botMomentSeq, 1);
    await _end(tester);
  });

  testWidgets('a small change and mate scores say nothing', (tester) async {
    final (c, engine) = await _game(
      tester,
      replies: ['e7e5', 'b8c6', 'g8f6'],
      scores: [50, 120, 100000],
    );
    await _move(tester, c, engine, Square.e2, Square.e4);
    await _move(tester, c, engine, Square.d2, Square.d3);
    await _move(tester, c, engine, Square.c1, Square.e3);
    expect(c.state.botMomentSeq, 0);
    await _end(tester);
  });
}
