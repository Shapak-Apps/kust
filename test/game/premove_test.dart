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
import 'package:kust/features/game/chess/premoves.dart';
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

/// Plays 1.e4 so the bot is thinking about its reply.
Future<void> _afterE4(WidgetTester tester, ChessController c) async {
  c.selectSquare(Square.e2);
  c.selectSquare(Square.e4);
  await tester.pump();
  expect(c.state.isBotThinking, isTrue);
}

/// Lets the bot's reply land and any premove follow.
Future<void> _reply(WidgetTester tester, _FakeEngine engine) async {
  engine.release();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 50));
}

Premove _p(Square from, Square to) => (from: from, to: to);

void main() {
  tearDown(() {
    AppSettings.instance.premoves.value = true;
    AppSettings.instance.castleOnRook.value = false;
  });

  testWidgets('a premove is queued while the bot thinks and played after', (
    tester,
  ) async {
    final (c, engine) = await _game(tester, ['e7e5', 'a7a6']);
    await _afterE4(tester, c);

    c.selectSquare(Square.g1);
    expect(c.state.legalDestinations, containsAll([Square.f3, Square.h3]));
    c.selectSquare(Square.f3);
    expect(c.state.premoves, [_p(Square.g1, Square.f3)]);
    // The board shows it made already; the real game has not moved.
    expect(c.state.boardPosition.board.pieceAt(Square.f3)?.role, Role.knight);
    expect(c.state.position.board.pieceAt(Square.g1)?.role, Role.knight);

    await _reply(tester, engine);
    expect(c.state.moves.map((m) => m.san), ['e4', 'e5', 'Nf3']);
    expect(c.state.premoves, isEmpty);
    expect(c.state.lastMoveInstant, isTrue);
    await _reply(tester, engine);
    await _finish(tester);
  });

  testWidgets('several premoves play one after each bot move', (tester) async {
    final (c, engine) = await _game(tester, ['e7e5', 'b8c6', 'g8f6', 'a7a6']);
    await _afterE4(tester, c);

    c.selectSquare(Square.g1);
    c.selectSquare(Square.f3);
    c.selectSquare(Square.f1);
    c.selectSquare(Square.c4);
    // With the knight and bishop gone (as drawn), the king may castle.
    c.selectSquare(Square.e1);
    expect(c.state.legalDestinations, contains(Square.g1));
    c.selectSquare(Square.g1);
    expect(c.state.premoves, [
      _p(Square.g1, Square.f3),
      _p(Square.f1, Square.c4),
      _p(Square.e1, Square.g1),
    ]);
    final shown = c.state.boardPosition.board;
    expect(shown.pieceAt(Square.g1)?.role, Role.king);
    expect(shown.pieceAt(Square.f1)?.role, Role.rook);

    await _reply(tester, engine);
    await _reply(tester, engine);
    await _reply(tester, engine);
    expect(c.state.moves.map((m) => m.san), [
      'e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Nf6', 'O-O', //
    ]);
    expect(c.state.premoves, isEmpty);
    await _reply(tester, engine);
    await _finish(tester);
  });

  testWidgets('if the bot makes a premove illegal, every premove goes', (
    tester,
  ) async {
    final (c, engine) = await _game(tester, ['e7e5', 'a7a6']);
    await _afterE4(tester, c);
    c.selectSquare(Square.e4);
    c.selectSquare(Square.e5);
    c.selectSquare(Square.g1);
    c.selectSquare(Square.f3);
    expect(c.state.premoves.length, 2);

    await _reply(tester, engine); // ...e5 blocks the pawn
    expect(c.state.premoves, isEmpty);
    expect(c.state.moves.length, 2);
    expect(c.state.position.turn, Side.white);
    await _finish(tester);
  });

  testWidgets('a premove recapture onto your own piece, by dragging', (
    tester,
  ) async {
    final (c, engine) = await _game(tester, ['f6e4', 'g8h8']);
    // The bot, black, is about to take e4; Nc3 is ready to take back.
    c.state = c.state.copyWith(
      position: Chess.fromSetup(
        Setup.parseFen('6k1/8/5n2/8/4P3/2N5/8/3Q2K1 b - - 0 1'),
      ),
      status: GameStatus.playing,
      engineFailed: true,
    );
    await c.retryEngine();
    await tester.pump();
    expect(c.state.isBotThinking, isTrue);

    expect(c.pickUp(Square.c3), isTrue);
    expect(c.state.legalDestinations, contains(Square.e4));
    expect(c.dropOn(Square.e4), isTrue);
    expect(c.state.premoves, [_p(Square.c3, Square.e4)]);

    await _reply(tester, engine);
    expect(c.state.moves.map((m) => m.san), ['Nxe4', 'Nxe4']);
    await _reply(tester, engine);
    await _finish(tester);
  });

  testWidgets('premove captures by tap: a bot piece, and taking back', (
    tester,
  ) async {
    final (c, engine) = await _game(tester, ['f6e4', 'g8h8']);
    c.state = c.state.copyWith(
      position: Chess.fromSetup(
        Setup.parseFen('6k1/8/5n2/8/4P3/2N5/8/3Q2K1 b - - 0 1'),
      ),
      status: GameStatus.playing,
      engineFailed: true,
    );
    await c.retryEngine();
    await tester.pump();
    // Tap the knight, then your own pawn on e4: Nxe4 back is queued.
    c.selectSquare(Square.c3);
    c.selectSquare(Square.e4);
    expect(c.state.premoves, [_p(Square.c3, Square.e4)]);
    // And a capture of a bot piece: Qxd8 is fine to queue too.
    c.selectSquare(Square.d1);
    expect(c.state.legalDestinations, contains(Square.d8));
    await _reply(tester, engine);
    expect(c.state.moves.map((m) => m.san), ['Nxe4', 'Nxe4']);
    await _reply(tester, engine);
    await _finish(tester);
  });

  testWidgets('tapping your own piece picks it; anything else cancels all', (
    tester,
  ) async {
    final (c, engine) = await _game(tester, ['e7e5']);
    await _afterE4(tester, c);
    c.selectSquare(Square.g1);
    c.selectSquare(Square.f3);
    // With nothing selected, a tap on one of your pieces selects it.
    c.selectSquare(Square.d2);
    expect(c.state.selectedSquare, Square.d2);
    expect(c.state.premoves.length, 1);
    c.selectSquare(Square.d2);
    // An empty square that is no destination cancels everything.
    c.selectSquare(Square.a5);
    expect(c.state.premoves, isEmpty);

    await _reply(tester, engine);
    expect(c.state.moves.length, 2);
    await _finish(tester);
  });

  testWidgets('a premove appears in place while the bot\'s piece glides', (
    tester,
  ) async {
    final (c, engine) = await _game(tester, ['e7e5', 'a7a6']);
    await _afterE4(tester, c);
    c.selectSquare(Square.g1);
    c.selectSquare(Square.f3);

    engine.release();
    // Past the bot's 0.4 s minimum, into its glide.
    await tester.pump(const Duration(milliseconds: 420));
    await tester.pump(const Duration(milliseconds: 16));
    expect(c.state.moves.length, 3);
    // The bot's pawn is still on its way; the knight did not restart it.
    expect(find.byKey(const ValueKey('moving_piece')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await _reply(tester, engine);
    await _finish(tester);
  });

  testWidgets('with premoves off the board waits for the bot', (tester) async {
    AppSettings.instance.premoves.value = false;
    final (c, engine) = await _game(tester, ['e7e5']);
    await _afterE4(tester, c);
    c.selectSquare(Square.g1);
    c.selectSquare(Square.f3);
    expect(c.state.premoves, isEmpty);
    expect(c.state.selectedSquare, isNull);
    await _reply(tester, engine);
    expect(c.state.moves.length, 2);
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

  group('premove rules', () {
    final start = Chess.initial;
    Set<Square> from(Position p, Square s, {Side side = Side.white}) =>
        premoveDestinations(p.board, s, side, castles: p.castles);

    test('pieces go by how they move, ignoring what is in the way', () {
      // The rook on a1 behind its pawn may still premove up the file.
      expect(from(start, Square.a1), containsAll([Square.a2, Square.a8]));
      expect(from(start, Square.a1), contains(Square.h1));
      // Pawns: one or two ahead, and either diagonal, empty or not.
      expect(from(start, Square.e2), {
        Square.e3, Square.e4, Square.d3, Square.f3, //
      });
      expect(from(start, Square.g1), {Square.e2, Square.f3, Square.h3});
      // Not the opponent's pieces.
      expect(from(start, Square.e7), isEmpty);
      expect(from(start, Square.e7, side: Side.black), contains(Square.e5));
    });

    test('the king castles only with rights and its rook in place', () {
      expect(from(start, Square.e1), containsAll([Square.g1, Square.c1]));
      final noRights = start.copyWith(castles: Castles.empty);
      expect(from(noRights, Square.e1), isNot(contains(Square.g1)));
      expect(
        premoveDestinations(
          start.board,
          Square.e1,
          Side.white,
          castles: start.castles,
          castleOnRook: true,
        ),
        containsAll([Square.h1, Square.a1]),
      );
    });

    test('a premoved castle moves the rook too; a pawn queens', () {
      final castled = applyPremove(
        start.board.removePieceAt(Square.f1).removePieceAt(Square.g1),
        _p(Square.e1, Square.g1),
        Side.white,
      );
      expect(castled.pieceAt(Square.g1)?.role, Role.king);
      expect(castled.pieceAt(Square.f1)?.role, Role.rook);
      expect(castled.pieceAt(Square.h1), isNull);

      final pawn = Board.empty.setPieceAt(
        Square.a7,
        const Piece(color: Side.white, role: Role.pawn),
      );
      expect(
        applyPremove(
          pawn,
          _p(Square.a7, Square.a8),
          Side.white,
        ).pieceAt(Square.a8)?.role,
        Role.queen,
      );
    });

    test('a queue stops where a premoved piece is no longer there', () {
      final queue = [_p(Square.g1, Square.f3), _p(Square.f3, Square.g5)];
      expect(premoveBoard(start.board, Side.white, queue).valid, 2);
      final taken = start.board.removePieceAt(Square.g1);
      expect(premoveBoard(taken, Side.white, queue).valid, 0);
    });
  });
}
