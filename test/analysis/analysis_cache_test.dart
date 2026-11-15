import 'dart:async';
import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/analysis_cache.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';
import 'package:kust/features/history/replay_positions.dart';
import 'package:kust/features/review/game_review.dart';

final _startFen = Chess.initial.fen;
const _uci = ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'f3g5', 'd7d5'];

GameRecord _record() {
  Position p = Chess.initial;
  final san = <String>[];
  for (final u in _uci) {
    final m = NormalMove.fromUci(u);
    san.add(p.makeSan(m).$2);
    p = p.play(m);
  }
  return GameRecord(
    id: 'g1',
    playedAt: 0,
    isLocal: false,
    result: GameRecord.win,
    reason: 'checkmate',
    playerIsWhite: true,
    uciMoves: _uci,
    sanMoves: san,
  );
}

void main() {
  late Directory dir;
  late Box<dynamic> box;
  late AnalysisCache cache;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_analysis');
    Hive.init(dir.path);
    box = await Hive.openBox('analysis');
    cache = AnalysisCache.withBox(box, maxEntries: 8);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  /// An engine whose answer depends on how long it may think, like a real
  /// one: the longer, the better the played move looks.
  MoveAnalyzer engine(List<Duration> asked) =>
      ({
        required String beforeFen,
        required String playedUci,
        required String afterFen,
        required Duration thinkTime,
        bool Function()? isStale,
      }) async {
        asked.add(thinkTime);
        return MoveAnalysis(
          bestUci: 'd2d4',
          bestCp: 60,
          playedCp: 60 - 300000 ~/ (thinkTime.inMilliseconds + 100),
          secondBestCp: 20,
        );
      };

  Future<MoveAnalysis?> rate(MoveAnalyzer a, String uci, [int ms = 250]) => a(
    beforeFen: _startFen,
    playedUci: uci,
    afterFen: _startFen,
    thinkTime: Duration(milliseconds: ms),
  );

  test(
    'a move is searched once, with the same think time for everyone',
    () async {
      final asked = <Duration>[];
      final a = cache.wrap(engine(asked));
      final first = await rate(a, 'e2e4', 100);
      final second = await rate(a, 'e2e4', 900);
      expect(asked, [kAnalysisThinkTime]);
      expect(second!.playedCp, first!.playedCp);
    },
  );

  test('a failed rating is not remembered', () async {
    var calls = 0;
    final a = cache.wrap(({
      required beforeFen,
      required playedUci,
      required afterFen,
      required thinkTime,
      isStale,
    }) async {
      calls++;
      return null;
    });
    await rate(a, 'e2e4');
    await rate(a, 'e2e4');
    expect(calls, 2);
  });

  test('two askers of the same move share one search', () async {
    final gate = Completer<void>();
    var calls = 0;
    final a = cache.wrap(({
      required beforeFen,
      required playedUci,
      required afterFen,
      required thinkTime,
      isStale,
    }) async {
      calls++;
      await gate.future;
      return const MoveAnalysis(bestUci: 'e2e4', bestCp: 10, playedCp: 10);
    });
    final one = rate(a, 'e2e4');
    final two = rate(a, 'e2e4');
    gate.complete();
    expect(await one, isNotNull);
    expect(await two, isNotNull);
    expect(calls, 1);
  });

  test('ratings are still there after the app restarts', () async {
    await rate(cache.wrap(engine([])), 'e2e4');
    await Hive.close();
    Hive.init(dir.path);
    final reopened = AnalysisCache.withBox(await Hive.openBox('analysis'));
    final asked = <Duration>[];
    final back = await rate(reopened.wrap(engine(asked)), 'e2e4');
    expect(back, isNotNull);
    expect(asked, isEmpty);
  });

  test('the oldest ratings go when there are too many', () async {
    final a = cache.wrap(engine([]));
    for (final u in ['a2a3', 'b2b3', 'c2c3', 'd2d3', 'e2e3', 'f2f3', 'g2g3']) {
      await rate(a, u);
    }
    await rate(a, 'h2h3');
    await rate(a, 'a2a4'); // the ninth: over the limit
    expect(box.length, lessThanOrEqualTo(8));
    expect(cache.get(AnalysisCache.keyFor(_startFen, 'a2a4')), isNotNull);
    expect(cache.get(AnalysisCache.keyFor(_startFen, 'a2a3')), isNull);
  });

  test('the result sheet and Review give the same accuracy', () async {
    final a = cache.wrap(engine([]));
    final game = _record();

    final data = await reviewGame(
      game,
      analyze: a,
      thinkTime: kAnalysisThinkTime,
    );

    final replay = replayPositions(game.uciMoves);
    final jobs = playerMoveJobs(
      positions: replay.positions,
      moves: [for (final m in replay.moves.skip(1)) m!],
      playerIsWhite: true,
    );
    // The result sheet asks with its own, different think time.
    final sheet = await GameAnalyzer(
      analyze: a,
      thinkTime: const Duration(milliseconds: 250),
    ).accuracy(jobs);

    expect(sheet, isNotNull);
    expect(sheet, closeTo(data!.accuracy(Side.white)!, 1e-9));
  });
}
