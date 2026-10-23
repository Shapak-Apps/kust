import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';
import 'package:kust/features/history/analysis_pacer.dart';
import 'package:kust/features/history/history_analysis.dart';

NormalMove _m(String uci) => Move.parse(uci)! as NormalMove;

void main() {
  group('AnalysisPacer', () {
    const pacer = AnalysisPacer();

    test('is fast to 50, slower to 60, medium to 80 and slow to the end', () {
      expect(AnalysisPacer.rateAt(0), greaterThan(AnalysisPacer.rateAt(50)));
      expect(AnalysisPacer.rateAt(50), greaterThan(AnalysisPacer.rateAt(60)));
      expect(AnalysisPacer.rateAt(60), greaterThan(AnalysisPacer.rateAt(80)));
      expect(AnalysisPacer.rateAt(80), 2); // about 2% a second at the end
      expect(AnalysisPacer.rateAt(99), 2);
    });

    double timeToReach(double from, double to) {
      var shown = from;
      var t = 0.0;
      while (shown < to && t < 100) {
        shown = pacer.step(current: shown, target: 100, seconds: 0.1);
        t += 0.1;
      }
      return t;
    }

    test('takes about the intended time through each stretch', () {
      expect(timeToReach(0, 50), closeTo(1.0, 0.2));
      expect(timeToReach(50, 60), closeTo(0.4, 0.2));
      expect(timeToReach(60, 80), closeTo(2.0, 0.3));
      expect(timeToReach(80, 98), closeTo(9.0, 0.5));
    });

    test('never runs ahead of the real progress or past 99', () {
      expect(pacer.step(current: 10, target: 15, seconds: 5), 15);
      expect(pacer.step(current: 98, target: 100, seconds: 60), 99);
      expect(
        pacer.step(current: 40, target: 20, seconds: 1),
        40,
      ); // no going back
    });
  });

  group('engineUci', () {
    test('plain, castling and promotion moves', () {
      final start = Chess.initial;
      expect(engineUci(_m('e2e4'), start), 'e2e4');

      final castle = Chess.fromSetup(
        Setup.parseFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'),
      );
      expect(engineUci(_m('e1h1'), castle), 'e1g1');
      expect(engineUci(_m('e1a1'), castle), 'e1c1');

      final promo = Chess.fromSetup(
        Setup.parseFen('8/P6k/8/8/8/8/8/K7 w - - 0 1'),
      );
      expect(engineUci(_m('a7a8q'), promo), 'a7a8q');
      expect(engineUci(_m('a7a8n'), promo), 'a7a8n');
    });
  });

  group('playerMoveJobs', () {
    final positions = <Position>[Chess.initial];
    final moves = <NormalMove>[];
    for (final uci in ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4']) {
      final move = _m(uci);
      moves.add(move);
      positions.add(positions.last.play(move));
    }

    test('picks only the player\'s moves for each side', () {
      final white = playerMoveJobs(
        positions: positions,
        moves: moves,
        playerIsWhite: true,
      );
      expect(white.map((j) => j.playedUci), ['e2e4', 'g1f3', 'f1c4']);

      final black = playerMoveJobs(
        positions: positions,
        moves: moves,
        playerIsWhite: false,
      );
      expect(black.map((j) => j.playedUci), ['e7e5', 'b8c6']);
    });

    test('the after position follows from the before position', () {
      final job = playerMoveJobs(
        positions: positions,
        moves: moves,
        playerIsWhite: true,
      ).first;
      expect(job.beforeFen, Chess.initial.fen);
      expect(job.afterFen, Chess.initial.play(_m('e2e4')).fen);
    });

    test('respects the cap', () {
      final jobs = playerMoveJobs(
        positions: positions,
        moves: moves,
        playerIsWhite: true,
        maxMoves: 2,
      );
      expect(jobs.length, 2);
    });
  });

  group('GameAnalyzer', () {
    final jobs = [
      for (var i = 0; i < 4; i++)
        AnalysisJob(beforeFen: 'b$i', playedUci: 'u$i', afterFen: 'a$i'),
    ];

    MoveAnalyzer fake(List<MoveAnalysis?> results) {
      var n = 0;
      return ({
        required beforeFen,
        required playedUci,
        required afterFen,
        required thinkTime,
        isStale,
      }) async => results[n++];
    }

    test('averages the move scores and reports progress', () async {
      final progress = <int>[];
      final analyzer = GameAnalyzer(
        analyze: fake(const [
          MoveAnalysis(bestUci: 'a', bestCp: 50, playedCp: 50),
          MoveAnalysis(bestUci: 'a', bestCp: 50, playedCp: 50),
          MoveAnalysis(bestUci: 'a', bestCp: 50, playedCp: 50),
          MoveAnalysis(bestUci: 'a', bestCp: 50, playedCp: 50),
        ]),
      );
      final value = await analyzer.accuracy(
        jobs,
        onProgress: (done, total) => progress.add(done * 100 ~/ total),
      );
      expect(value, closeTo(100, 0.01));
      expect(progress, [25, 50, 75, 100]);
    });

    test('skips moves the engine could not rate', () async {
      final analyzer = GameAnalyzer(
        analyze: fake(const [
          null,
          MoveAnalysis(bestUci: 'a', bestCp: 50, playedCp: 50),
          null,
          null,
        ]),
      );
      expect(await analyzer.accuracy(jobs), closeTo(100, 0.01));
    });

    test('returns null when nothing could be rated or it went stale', () async {
      expect(
        await GameAnalyzer(analyze: fake([null, null, null, null]))
            .accuracy(jobs),
        isNull,
      );
      expect(
        await GameAnalyzer(analyze: fake(const []))
            .accuracy(jobs, isStale: () => true),
        isNull,
      );
    });

    test('rethrows engine errors', () async {
      final analyzer = GameAnalyzer(
        analyze: ({
          required beforeFen,
          required playedUci,
          required afterFen,
          required thinkTime,
          isStale,
        }) async => throw const EngineUnavailableException('x'),
      );
      expect(
        analyzer.accuracy(jobs),
        throwsA(isA<EngineUnavailableException>()),
      );
    });
  });

  group('HistoryAnalysis', () {
    late Directory dir;
    late Box<dynamic> box;
    late GameHistoryStore store;

    GameRecord game({String id = 'g', int moves = 10, bool local = false}) =>
        GameRecord(
          id: id,
          playedAt: 1,
          isLocal: local,
          result: GameRecord.win,
          reason: '',
          playerIsWhite: true,
          uciMoves: const [
            'e2e4',
            'e7e5',
            'g1f3',
            'b8c6',
            'f1c4',
            'g8f6',
            'd2d3',
            'd7d6',
            'c1g5',
            'f8e7',
          ].take(moves).toList(),
          sanMoves: const [],
          botName: 'Karl',
          botElo: 1000,
        );

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('kust_analysis');
      Hive.init(dir.path);
      box = await Hive.openBox('h');
      store = GameHistoryStore.withBox(box);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    GameAnalyzer slowAnalyzer({
      Duration each = const Duration(milliseconds: 40),
    }) {
      return GameAnalyzer(
        analyze:
            ({
              required beforeFen,
              required playedUci,
              required afterFen,
              required thinkTime,
              isStale,
            }) async {
              await Future<void>.delayed(each);
              return const MoveAnalysis(bestUci: 'a', bestCp: 50, playedCp: 50);
            },
      );
    }

    test('canAnalyze needs a bot game with enough moves and no accuracy', () {
      expect(HistoryAnalysis.canAnalyze(game()), isTrue);
      expect(HistoryAnalysis.canAnalyze(game(local: true)), isFalse);
      expect(HistoryAnalysis.canAnalyze(game(moves: 4)), isFalse); // 2 moves
      final rated = GameRecord.tryFromMap({
        ...game().toMap(),
        'accuracy': 80.0,
      })!;
      expect(HistoryAnalysis.canAnalyze(rated), isFalse);
    });

    test('shows rising percentages, then stores the accuracy', () async {
      await store.add(game());
      final analysis = HistoryAnalysis(
        analyzer: slowAnalyzer(),
        store: store,
        tick: const Duration(milliseconds: 5),
        finishHold: const Duration(milliseconds: 10),
      );

      final seen = <int>[];
      analysis.stateFor('g').addListener(() {
        final state = analysis.stateFor('g').value;
        if (state != null) seen.add(state.percent);
      });

      final ok = await analysis.start(game());
      expect(ok, isTrue);

      // Never goes backwards, ends at 100, then the row is idle again.
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
      }
      expect(seen.last, 100);
      expect(seen.where((p) => p > 0 && p < 100), isNotEmpty);
      expect(analysis.stateFor('g').value, isNull);
      expect(store.byId('g')!.accuracy, closeTo(100, 0.01));
    });

    test('a second press while running does not start another run', () async {
      await store.add(game());
      var calls = 0;
      final analyzer = GameAnalyzer(
        analyze:
            ({
              required beforeFen,
              required playedUci,
              required afterFen,
              required thinkTime,
              isStale,
            }) async {
              calls++;
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return const MoveAnalysis(bestUci: 'a', bestCp: 50, playedCp: 50);
            },
      );
      final analysis = HistoryAnalysis(
        analyzer: analyzer,
        store: store,
        tick: const Duration(milliseconds: 5),
        finishHold: const Duration(milliseconds: 5),
      );
      final first = analysis.start(game());
      final second = analysis.start(game());
      await Future.wait([first, second]);
      expect(calls, 5); // one white move per pair: 5 of 10 plies
    });

    test('an engine failure shows as failed and can be retried', () async {
      await store.add(game());
      final failing = GameAnalyzer(
        analyze: ({
          required beforeFen,
          required playedUci,
          required afterFen,
          required thinkTime,
          isStale,
        }) async => throw const EngineUnavailableException('x'),
      );
      final analysis = HistoryAnalysis(
        analyzer: failing,
        store: store,
        tick: const Duration(milliseconds: 5),
      );
      expect(await analysis.start(game()), isFalse);
      expect(analysis.stateFor('g').value?.status, AnalysisStatus.failed);
      expect(store.byId('g')!.accuracy, isNull);

      // Pressing again tries again (and fails again here).
      expect(await analysis.start(game()), isFalse);
    });

    test('too short a game cannot be analyzed', () async {
      final analysis = HistoryAnalysis(analyzer: slowAnalyzer(), store: store);
      expect(await analysis.start(game(moves: 4)), isFalse);
      expect(analysis.stateFor('g').value?.status, AnalysisStatus.failed);
    });
  });
}
