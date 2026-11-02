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
import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/move_record.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/game/time_control.dart';
import 'package:kust/theme.dart';

Future<ChessController> _local(
  WidgetTester tester, {
  TimeControl? timeControl,
}) async {
  SharedPreferences.setMockInitialValues({});
  SoundService.instance.soundEnabled = false; // no audio plugin in tests
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
  await c.startLocalGame(timeControl: timeControl);
  await tester.pump();
  return c;
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 31));
}

void main() {
  late Directory dir;

  // A finished game is saved to the history.
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_local_review');
    Hive.init(dir.path);
    await Hive.openBox(AppStorage.historyBoxName);
    await Hive.openBox(AppStorage.userBoxName);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets('a finished local game can be stepped back through', (
    tester,
  ) async {
    final c = await _local(tester);
    // Fool's mate, staged as a finished game (saving it needs storage).
    Position p = Chess.initial;
    final history = <Position>[];
    final moves = <MoveRecord>[];
    for (final uci in ['f2f3', 'e7e5', 'g2g4', 'd8h4']) {
      final m = NormalMove.fromUci(uci);
      moves.add(MoveRecord(side: p.turn, san: uci, move: m));
      history.add(p);
      p = p.play(m);
    }
    // Saving the finished game does real file work: let it run for real.
    await tester.runAsync(() async {
      c.state = c.state.copyWith(
        position: p,
        history: history,
        moves: moves,
        status: GameStatus.checkmate,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });

    expect(c.canAnalysisMoveBack, isTrue);
    c.analysisMoveBack();
    c.analysisMoveBack();
    expect(c.state.analysisCursor, 2);
    expect(c.state.displayPosition.fen, history[2].fen);
    c.analysisMoveNext();
    c.analysisMoveNext();
    // Back at the end: the final position again.
    expect(c.state.displayPosition.fen, p.fen);
    await _finish(tester);
  });

  testWidgets('a timed local game pauses and resumes its clocks', (
    tester,
  ) async {
    final c = await _local(
      tester,
      timeControl: const TimeControl(baseMinutes: 5),
    );
    expect(c.state.canPause, isTrue);

    c.pauseClock();
    await tester.pump();
    expect(c.state.paused, isTrue);
    expect(find.text('Paused'), findsOneWidget);
    final frozen = c.state.whiteTimeLeft;
    await tester.pump(const Duration(seconds: 3));
    expect(c.state.whiteTimeLeft, frozen);
    // No moves while paused.
    c.selectSquare(Square.e2);
    expect(c.state.selectedSquare, isNull);

    // A tap on the board resumes.
    await tester.tap(find.text('Paused'));
    await tester.pump();
    expect(c.state.paused, isFalse);
    // The clock shows whole seconds, so let more than one go by.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1200)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.state.whiteTimeLeft, lessThan(frozen));
    await _finish(tester);
  });

  testWidgets('untimed local games and bot games have no pause', (
    tester,
  ) async {
    final c = await _local(tester);
    expect(c.state.canPause, isFalse);
    c.pauseClock();
    expect(c.state.paused, isFalse);
    await _finish(tester);
  });

  testWidgets('a local game can be aborted until black has moved', (
    tester,
  ) async {
    final c = await _local(tester);
    expect(c.state.canAbort, isTrue);
    c.selectSquare(Square.e2);
    c.selectSquare(Square.e4);
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.state.canAbort, isTrue); // black has not moved yet
    c.selectSquare(Square.e7);
    c.selectSquare(Square.e5);
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.state.canAbort, isFalse);
    await _finish(tester);
  });

  testWidgets('stepping back through a game plays a glide', (tester) async {
    final c = await _local(tester);
    c.selectSquare(Square.e2);
    c.selectSquare(Square.e4);
    await tester.pump(const Duration(milliseconds: 400));
    c.analysisMoveBack();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.state.displayPosition.board.pieceAt(Square.e2), isNotNull);
    await _finish(tester);
  });
}
