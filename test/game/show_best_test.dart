import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/bot_policy.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/theme.dart';

/// An engine that gives a best move for each position the player is asked
/// about, and lets the bot's search finish when told to.
class _Engine implements ChessEngine {
  _Engine({required this.hints, required this.botMoves});

  final List<String> hints;
  final List<String> botMoves;
  final List<String> asked = [];
  Completer<void>? _gate;

  void release() => _gate?.complete();

  @override
  Future<void> start() async {}

  @override
  void setSkillLevel(int level, {int? uciElo}) {}

  @override
  void stopThinking() {}

  @override
  Future<String> evaluateBestHint(String fen) async {
    asked.add(fen);
    return hints.removeAt(0);
  }

  @override
  Future<List<CandidateMove>> candidateMoves(
    String fen, {
    required int lines,
    required int depth,
    required Duration thinkTime,
  }) async {
    _gate = Completer<void>();
    await _gate!.future;
    return [CandidateMove(botMoves.removeAt(0), 0)];
  }

  @override
  Future<EvalScore?> evaluateFen(
    String fen, {
    Duration thinkTime = const Duration(milliseconds: 250),
    bool Function()? isStale,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Show best follows the position: shown on your turn, gone when '
      'you move, back after the bot replies, off with the switch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.soundEnabled = false;
    addTearDown(() => SoundService.instance.soundEnabled = true);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final engine = _Engine(hints: ['d2d4', 'c2c4'], botMoves: ['d7d5']);
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
    final c = container.read(chessControllerProvider.notifier);
    await c.startGame(
      kInternationalBots.first,
      playerSide: Side.white,
      practiceMode: true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // At the start it is your move: the engine's best move is shown.
    expect(c.state.suggestSquares, {Square.d2, Square.d4});

    // You play a different move: the arrow goes at once.
    c.selectSquare(Square.e2);
    c.selectSquare(Square.e4);
    await tester.pump();
    expect(c.state.suggestSquares, isEmpty);
    expect(c.state.isBotThinking, isTrue);

    // The bot replies: a new arrow for the new position.
    engine.release();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.state.suggestSquares, {Square.c2, Square.c4});
    expect(engine.asked, hasLength(2));

    // Switched off: the arrow goes and stays away.
    await c.setShowBestEnabled(false);
    await tester.pump();
    expect(c.state.suggestSquares, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 31));
  });
}
