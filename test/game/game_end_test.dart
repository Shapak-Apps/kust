// The tests set the controller's state directly to stage a position.
// ignore_for_file: invalid_use_of_protected_member
import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/live_game_store.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/move_record.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/game/game_export.dart';
import 'package:kust/features/game/time_control.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/theme.dart';

import '../support/fake_engine.dart';

late ProviderContainer _container;
FakeEngine? _engine;

Future<ChessController> _start(
  WidgetTester tester, {
  bool local = true,
  bool practice = false,
  Side side = Side.white,
  List<String> replies = const [],
  TimeControl? timeControl,
}) async {
  SharedPreferences.setMockInitialValues({});
  SoundService.instance.soundEnabled = false;
  addTearDown(() => SoundService.instance.soundEnabled = true);
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _engine = FakeEngine(List.of(replies));
  _container = ProviderContainer(
    overrides: [chessEngineProvider.overrideWithValue(_engine!)],
  );
  addTearDown(_container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
      child: MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: Center(child: ChessBoard())),
      ),
    ),
  );
  final c = _container.read(chessControllerProvider.notifier);
  if (local) {
    // A clock needs a real timer to run in a test.
    await tester.runAsync(() => c.startLocalGame(timeControl: timeControl));
  } else {
    await tester.runAsync(
      () => c.startGame(
        kInternationalBots.first,
        playerSide: side,
        practiceMode: practice,
        timeControl: timeControl,
      ),
    );
  }
  await tester.pump();
  return c;
}

/// Plays [uci] by tapping its squares.
Future<void> _play(WidgetTester tester, ChessController c, String uci) async {
  c.selectSquare(Square.fromName(uci.substring(0, 2)));
  c.selectSquare(Square.fromName(uci.substring(2, 4)));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Plays the move that ends a game. Saving the game does real file work, so
/// the move and the wait for it run on the real event loop.
Future<void> _playLast(
  WidgetTester tester,
  ChessController c,
  String uci,
) async {
  await tester.runAsync(() async {
    c.selectSquare(Square.fromName(uci.substring(0, 2)));
    c.selectSquare(Square.fromName(uci.substring(2, 4)));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pump(const Duration(milliseconds: 400));
}

/// Lets the bot's pending reply land.
Future<void> _reply(WidgetTester tester) async {
  _engine!.release();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 50));
}

/// Sets the game up from [fen] with a move already on the record, so the
/// finished game is saved.
void _stage(ChessController c, String fen) {
  final start = Chess.fromSetup(Setup.parseFen(fen));
  c.state = c.state.copyWith(
    position: start,
    history: [Chess.initial],
    moves: [
      MoveRecord(side: Side.white, san: 'e4', move: NormalMove.fromUci('e2e4')),
    ],
  );
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 31));
  // Boxes close on the real event loop, not the test's fake one.
  await tester.runAsync(Hive.close);
}

GameRecord _saved() => GameHistoryStore.instance.all().single;

void main() {
  late Directory dir;

  setUp(() async {
    LiveGameStore.enabled = false;
    dir = await Directory.systemTemp.createTemp('kust_game_end');
    Hive.init(dir.path);
    await Hive.openBox(AppStorage.historyBoxName);
    await Hive.openBox(AppStorage.userBoxName);
    await Hive.openBox(AppStorage.botProgressBoxName);
    await Hive.openBox(AppStorage.puzzleBoxName);
  });

  tearDown(() async {
    LiveGameStore.enabled = true;
    await Hive.close();
    await dir.delete(recursive: true);
  });

  const kingRookVsKing = '4k3/8/8/8/8/4K3/4R3/8 w - - 0 1';

  testWidgets('a threefold repetition is a draw', (tester) async {
    final c = await _start(tester);
    final shuffle = ['g1f3', 'g8f6', 'f3g1', 'f6g8'];
    for (final m in [...shuffle, ...shuffle.take(3)]) {
      await _play(tester, c, m);
    }
    await _playLast(tester, c, shuffle.last);
    expect(c.state.status, GameStatus.draw);
    expect(c.state.endReason, EndReason.repetition);
    expect(gameResultToken(c.state), '1/2-1/2');
    expect(_saved().result, GameRecord.draw);
    expect(_saved().reason, 'repetition');
    await _finish(tester);
  });

  testWidgets('the fiftieth move without progress is a draw', (tester) async {
    final c = await _start(tester);
    _stage(c, '4k3/8/8/8/8/4K3/4R3/8 w - - 99 80');
    await _playLast(tester, c, 'e2a2');
    expect(c.state.status, GameStatus.draw);
    expect(c.state.endReason, EndReason.fiftyMove);
    expect(_saved().reason, 'fiftyMove');
    await _finish(tester);
  });

  testWidgets('king and bishop against a king is a draw', (tester) async {
    final c = await _start(tester);
    _stage(c, '4k3/8/4p3/8/2B5/8/8/4K3 w - - 0 1');
    await _playLast(tester, c, 'c4e6');
    expect(c.state.status, GameStatus.draw);
    expect(c.state.endReason, EndReason.insufficientMaterial);
    expect(_saved().reason, 'insufficientMaterial');
    await _finish(tester);
  });

  testWidgets('no legal move and no check is a stalemate', (tester) async {
    final c = await _start(tester);
    _stage(c, '7k/8/5K2/8/8/8/6Q1/8 w - - 0 1');
    await _playLast(tester, c, 'g2g6');
    expect(c.state.status, GameStatus.draw);
    expect(c.state.endReason, EndReason.stalemate);
    expect(_saved().reason, 'stalemate');
    await _finish(tester);
  });

  testWidgets('a flag that falls loses on time, and the PGN says so', (
    tester,
  ) async {
    final c = await _start(
      tester,
      timeControl: const TimeControl(baseMinutes: 5),
    );
    _stage(c, kStartFen);
    await tester.runAsync(() async {
      c.debugSetClocks(white: const Duration(milliseconds: 30));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.state.status, GameStatus.timeout);
    expect(c.state.flagFell, Side.white);
    expect(gameResultToken(c.state), '0-1');
    expect(_saved().result, GameRecord.blackWon);
    await _finish(tester);
  });

  testWidgets('a flag that falls against a lone king is a draw', (
    tester,
  ) async {
    final c = await _start(
      tester,
      timeControl: const TimeControl(baseMinutes: 5),
    );
    _stage(c, kingRookVsKing);
    // White to move holds the rook: it is black, with a lone king, who
    // cannot be mated... so white's flag falls against a king that cannot
    // win, and the game is drawn.
    await tester.runAsync(() async {
      c.debugSetClocks(white: const Duration(milliseconds: 30));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.state.status, GameStatus.draw);
    expect(c.state.endReason, EndReason.timeNoMate);
    expect(_saved().result, GameRecord.draw);
    await _finish(tester);
  });

  group('timed games against a bot', () {
    const clock = TimeControl(baseMinutes: 5);

    Future<void> flag(
      WidgetTester tester,
      ChessController c, {
      Duration? white,
      Duration? black,
    }) async {
      await tester.runAsync(() async {
        c.debugSetClocks(white: white, black: black);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('your flag falling loses the game and costs rating', (
      tester,
    ) async {
      final c = await _start(tester, local: false, timeControl: clock);
      _stage(c, kStartFen);
      final before = PlayerRatingStore.instance.rating;
      await flag(tester, c, white: const Duration(milliseconds: 30));
      expect(c.state.status, GameStatus.timeout);
      expect(c.state.flagFell, Side.white);
      expect(_saved().result, GameRecord.loss);
      expect(PlayerRatingStore.instance.rating, lessThan(before));
      await _finish(tester);
    });

    testWidgets('the bot flagging wins the game and beats the bot', (
      tester,
    ) async {
      final c = await _start(tester, local: false, timeControl: clock);
      _stage(c, 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1');
      await flag(tester, c, black: const Duration(milliseconds: 30));
      expect(c.state.status, GameStatus.timeout);
      expect(c.state.flagFell, Side.black);
      expect(c.state.isBotThinking, isFalse);
      expect(_saved().result, GameRecord.win);
      expect(
        AppStorage.instance.isBotBeaten(kInternationalBots.first.id),
        isTrue,
      );
      await _finish(tester);
    });

    testWidgets('running out of time against a lone king is a draw', (
      tester,
    ) async {
      final c = await _start(tester, local: false, timeControl: clock);
      _stage(c, kingRookVsKing);
      await flag(tester, c, white: const Duration(milliseconds: 30));
      expect(c.state.endReason, EndReason.timeNoMate);
      expect(_saved().result, GameRecord.draw);
      await _finish(tester);
    });
  });

  testWidgets('resigning a bot game loses it and costs rating', (tester) async {
    final c = await _start(tester, local: false);
    _stage(c, kStartFen);
    final before = PlayerRatingStore.instance.rating;
    await tester.runAsync(() async {
      c.resign();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    expect(c.state.status, GameStatus.resigned);
    expect(_saved().result, GameRecord.loss);
    expect(PlayerRatingStore.instance.rating, lessThan(before));
    expect(_saved().ratingChange, PlayerRatingStore.instance.rating - before);
    await _finish(tester);
  });

  for (final practice in [false, true]) {
    testWidgets(
      practice
          ? 'mating a bot in practice does not count as beating it'
          : 'mating a bot beats it and moves the rating',
      (tester) async {
        final c = await _start(
          tester,
          local: false,
          practice: practice,
          replies: ['e7e5', 'b8c6', 'g8f6'],
        );
        await _play(tester, c, 'e2e4');
        await _reply(tester);
        await _play(tester, c, 'd1h5');
        await _reply(tester);
        await _play(tester, c, 'f1c4');
        await _reply(tester);
        await _playLast(tester, c, 'h5f7');
        expect(c.state.status, GameStatus.checkmate);
        expect(
          AppStorage.instance.isBotBeaten(kInternationalBots.first.id),
          !practice,
        );
        expect(_saved().result, GameRecord.win);
        expect(_saved().ratingChange != null, !practice);
        await _finish(tester);
      },
    );
  }

  testWidgets('undo takes back both plies and the repetitions with them', (
    tester,
  ) async {
    final c = await _start(
      tester,
      local: false,
      practice: true,
      replies: ['g8f6', 'f6g8', 'f6g8'],
    );
    // 1.Nf3 Nf6 2.Ng1 Ng8: the start position is on the board a second time.
    for (final m in ['g1f3', 'f3g1']) {
      await _play(tester, c, m);
      await _reply(tester);
    }
    expect(c.state.moves.length, 4);

    c.undoLastMove();
    expect(c.state.moves.length, 2);
    expect(c.state.position.fen, contains('rnbqkb1r/pppppppp/5n2'));

    // Back to the start position again. Had the undone visit still counted,
    // this would already be the third time.
    await _play(tester, c, 'f3g1');
    await _reply(tester);
    expect(c.state.moves.length, 4);
    expect(c.state.status, GameStatus.playing);
    await _finish(tester);
  });

  testWidgets('the game is saved even if the screen is left at once', (
    tester,
  ) async {
    final c = await _start(tester, local: false);
    _stage(c, kStartFen);
    final before = PlayerRatingStore.instance.rating;
    await tester.runAsync(() async {
      c.resign();
      await Future<void>.delayed(Duration.zero);
      _container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    expect(GameHistoryStore.instance.all(), hasLength(1));
    expect(PlayerRatingStore.instance.rating, lessThan(before));
    await _finish(tester);
  });
}
