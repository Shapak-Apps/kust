// The tests set the controller's state directly to stage a position.
// ignore_for_file: invalid_use_of_protected_member
import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/bot_policy.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/theme.dart';

/// An engine that answers each bot request with the next of [replies],
/// once [release] completes the pending one.
class _FakeEngine implements ChessEngine {
  _FakeEngine(this.replies);

  final List<String> replies;
  Completer<void>? _gate;

  /// Lets the bot's current search finish.
  void release() => _gate?.complete();

  @override
  Future<void> start() async {}

  @override
  void setSkillLevel(int level, {int? uciElo}) {}

  @override
  void stopThinking() {}

  @override
  Future<List<CandidateMove>> candidateMoves(
    String fen, {
    required int lines,
    required int depth,
    required Duration thinkTime,
  }) async {
    _gate = Completer<void>();
    await _gate!.future;
    return [CandidateMove(replies.removeAt(0), 0)];
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

Future<(ChessController, _FakeEngine)> _game(
  WidgetTester tester,
  List<String> replies,
) async {
  SharedPreferences.setMockInitialValues({});
  SoundService.instance.soundEnabled = false;
  addTearDown(() => SoundService.instance.soundEnabled = true);
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final engine = _FakeEngine(replies);
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
  await c.startGame(kInternationalBots.first, playerSide: Side.white);
  await tester.pump();
  return (c, engine);
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 31));
}

void main() {
  tearDown(() => AppSettings.instance.premoves.value = true);

  testWidgets('a premove is queued while the bot thinks and played after', (
    tester,
  ) async {
    final (c, engine) = await _game(tester, ['e7e5']);
    c.selectSquare(Square.e2);
    c.selectSquare(Square.e4);
    await tester.pump();
    expect(c.state.isBotThinking, isTrue);

    // Queue Nf3 while the bot thinks: nothing moves yet.
    c.selectSquare(Square.g1);
    expect(c.state.legalDestinations, containsAll([Square.f3, Square.h3]));
    c.selectSquare(Square.f3);
    expect(c.state.premove, (from: Square.g1, to: Square.f3));
    expect(c.state.position.board.pieceAt(Square.g1)?.role, Role.knight);

    engine.release();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(kPremoveDelay);
    await tester.pump(const Duration(milliseconds: 50));
    final board = c.state.position.board;
    expect(board.pieceAt(Square.e5)?.role, Role.pawn); // the bot's reply
    expect(board.pieceAt(Square.f3)?.role, Role.knight); // the premove
    expect(c.state.premove, isNull);
    expect(c.state.moves.map((m) => m.san), ['e4', 'e5', 'Nf3']);
    engine.release();
    await tester.pump(const Duration(milliseconds: 600));
    await _finish(tester);
  });

  testWidgets('a premove the bot made illegal is dropped', (tester) async {
    // e4-e5 is queued, then the bot plays ...e5 and blocks the pawn.
    final (c, engine) = await _game(tester, ['e7e5']);
    c.selectSquare(Square.e2);
    c.selectSquare(Square.e4);
    await tester.pump();
    c.selectSquare(Square.e4);
    c.selectSquare(Square.e5);
    expect(c.state.premove, (from: Square.e4, to: Square.e5));

    engine.release();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(kPremoveDelay);
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.state.premove, isNull);
    expect(c.state.moves.length, 2); // nothing played after ...e5
    expect(c.state.position.turn, Side.white);
    await _finish(tester);
  });

  testWidgets('a tap cancels a queued premove', (tester) async {
    final (c, engine) = await _game(tester, ['e7e5']);
    c.selectSquare(Square.e2);
    c.selectSquare(Square.e4);
    await tester.pump();
    c.selectSquare(Square.g1);
    c.selectSquare(Square.f3);
    expect(c.state.premove, isNotNull);
    c.selectSquare(Square.a5);
    expect(c.state.premove, isNull);

    engine.release();
    await tester.pump(const Duration(milliseconds: 700));
    expect(c.state.moves.length, 2);
    await _finish(tester);
  });

  testWidgets('with premoves off the board waits for the bot', (tester) async {
    AppSettings.instance.premoves.value = false;
    final (c, engine) = await _game(tester, ['e7e5']);
    c.selectSquare(Square.e2);
    c.selectSquare(Square.e4);
    await tester.pump();
    c.selectSquare(Square.g1);
    c.selectSquare(Square.f3);
    expect(c.state.premove, isNull);
    expect(c.state.selectedSquare, isNull);
    engine.release();
    await tester.pump(const Duration(milliseconds: 700));
    expect(c.state.moves.length, 2);
    await _finish(tester);
  });

  testWidgets('a premove can be queued by dragging too', (tester) async {
    final (c, engine) = await _game(tester, ['e7e5']);
    c.selectSquare(Square.e2);
    c.selectSquare(Square.e4);
    await tester.pump();
    expect(c.state.isBotThinking, isTrue);

    final board = tester.getRect(find.byType(ChessBoard));
    final cell = board.width / 8;
    Offset centre(int file, int rank) =>
        board.topLeft + Offset((file + 0.5) * cell, (7.5 - rank) * cell);
    final start = centre(6, 0); // g1
    final end = centre(5, 2) + Offset(0, cell * 0.3); // over f3
    final gesture = await tester.startGesture(start);
    for (var i = 1; i <= 6; i++) {
      await gesture.moveTo(Offset.lerp(start, end, i / 6)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();
    expect(c.state.premove, (from: Square.g1, to: Square.f3));
    engine.release();
    await tester.pump(const Duration(milliseconds: 700));
    expect(c.state.position.board.pieceAt(Square.f3)?.role, Role.knight);
    engine.release();
    await tester.pump(const Duration(milliseconds: 600));
    await _finish(tester);
  });

  test('the setting is saved, on by default', () async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    expect(AppSettings.instance.premoves.value, isTrue);
    await AppSettings.instance.setPremoves(false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('premoves_enabled'), isFalse);
  });
}
