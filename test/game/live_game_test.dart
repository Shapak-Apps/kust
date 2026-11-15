import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/live_game_store.dart';
import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/game/time_control.dart';
import 'package:kust/theme.dart';

Future<ChessController> _local(
  WidgetTester tester, {
  TimeControl? timeControl,
}) async {
  SharedPreferences.setMockInitialValues({});
  SoundService.instance.soundEnabled = false;
  addTearDown(() => SoundService.instance.soundEnabled = true);
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
  final c = container.read(chessControllerProvider.notifier);
  await tester.runAsync(() => c.startLocalGame(timeControl: timeControl));
  await tester.pump();
  return c;
}

/// Plays [uci]; the saving of the game runs on the real event loop.
Future<void> _play(WidgetTester tester, ChessController c, String uci) async {
  await tester.runAsync(() async {
    c.selectSquare(Square.fromName(uci.substring(0, 2)));
    c.selectSquare(Square.fromName(uci.substring(2, 4)));
    await Future<void>.delayed(const Duration(milliseconds: 40));
  });
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 31));
  await tester.runAsync(Hive.close);
}

const _six = ['g1f3', 'g8f6', 'f3g1', 'f6g8', 'e2e4', 'e7e5'];

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_live');
    Hive.init(dir.path);
    await Hive.openBox(AppStorage.userBoxName);
    await Hive.openBox(AppStorage.historyBoxName);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets('a game in progress is saved and continues where it was', (
    tester,
  ) async {
    final first = await _local(tester);
    for (final m in _six) {
      await _play(tester, first, m);
    }
    final saved = LiveGameStore.instance.get();
    expect(saved, isNotNull);
    expect(saved!.uciMoves, _six);
    expect(saved.isLocal, isTrue);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final second = container.read(chessControllerProvider.notifier);
    final ok = await tester.runAsync(() => second.resumeGame(saved));
    expect(ok, isTrue);
    expect(second.state.position.fen, first.state.position.fen);
    expect(
      [for (final m in second.state.moves) m.san],
      [for (final m in first.state.moves) m.san],
    );
    expect(second.state.position.turn, Side.white);
    expect(second.state.status, GameStatus.playing);

    await _finish(tester);
  });

  testWidgets('finishing or aborting the game clears the saved one', (
    tester,
  ) async {
    final c = await _local(tester);
    for (final m in _six) {
      await _play(tester, c, m);
    }
    expect(LiveGameStore.instance.get(), isNotNull);
    await tester.runAsync(() async {
      c.resign();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    expect(LiveGameStore.instance.get(), isNull);
    await _finish(tester);
  });

  testWidgets('a timed game keeps its clocks and waits on return', (
    tester,
  ) async {
    final first = await _local(
      tester,
      timeControl: const TimeControl(baseMinutes: 5, incrementSeconds: 2),
    );
    for (final m in _six.take(2)) {
      await _play(tester, first, m);
    }
    final saved = LiveGameStore.instance.get()!;
    expect(saved.baseMinutes, 5);
    expect(saved.incrementSeconds, 2);
    expect(saved.whiteMs, greaterThan(0));

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final second = container.read(chessControllerProvider.notifier);
    await tester.runAsync(() => second.resumeGame(saved));
    expect(
      second.state.timeControl,
      const TimeControl(baseMinutes: 5, incrementSeconds: 2),
    );
    expect(second.state.paused, isTrue);
    await _finish(tester);
  });

  test(
    'damaged, old and impossible saves are not offered or replayed',
    () async {
      final box = Hive.box(AppStorage.userBoxName);
      final store = LiveGameStore.withBox(box);
      await box.put('live_game', {'v': 1, 'moves': 'oops'});
      expect(store.get(), isNull);
      await box.put('live_game', 'garbage');
      expect(store.get(), isNull);

      final old = LiveGame(
        isLocal: true,
        playerIsWhite: true,
        practice: true,
        uciMoves: const ['e2e4', 'e7e5'],
        savedAt: DateTime.now()
            .subtract(const Duration(days: 8))
            .millisecondsSinceEpoch,
      );
      await store.save(old);
      expect(store.get(), isNull);
      await store.save(
        LiveGame(
          isLocal: true,
          playerIsWhite: true,
          practice: true,
          uciMoves: const ['e2e4', 'e7e5'],
          savedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      expect(store.get(), isNotNull);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(chessControllerProvider.notifier);
      final illegal = LiveGame(
        isLocal: true,
        playerIsWhite: true,
        practice: true,
        uciMoves: const ['e2e5'],
        savedAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(await c.resumeGame(illegal), isFalse);
    },
  );
}
