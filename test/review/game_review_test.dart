import 'dart:io' as io;
import 'dart:ui' show ImageByteFormat;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/move_feedback.dart';
import 'package:kust/features/review/game_review.dart';
import 'package:kust/features/review/review_screen.dart';
import 'package:kust/theme.dart';

const _uci = [
  'e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'f3g5', 'd7d5', //
  'e4d5', 'f6d5', 'g5f7', 'e8f7', 'd1f3', 'f7e6',
];

GameRecord _record({bool local = false}) {
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
    isLocal: local,
    result: local ? GameRecord.whiteWon : GameRecord.win,
    reason: 'checkmate',
    playerIsWhite: true,
    uciMoves: _uci,
    sanMoves: san,
    botId: 'bahar',
    botName: 'Bahar',
    botElo: 400,
  );
}

/// Every move is fine except ply 3 (White's Ng5?, a blunder) and ply 8 (Black's
/// ...d5, best by far).
Future<MoveAnalysis?> _fake({
  required String beforeFen,
  required String playedUci,
  required String afterFen,
  required Duration thinkTime,
  bool Function()? isStale,
}) async {
  if (playedUci == 'f3g5') {
    return MoveAnalysis(
      bestUci: 'd2d3',
      bestCp: 40,
      playedCp: -400,
      secondBestCp: 20,
    );
  }
  return MoveAnalysis(
    bestUci: playedUci,
    bestCp: 30,
    playedCp: 30,
    secondBestCp: 10,
  );
}

void main() {
  test('rates both sides and finds the worst moves', () async {
    final progress = <int>[];
    final data = await reviewGame(
      _record(),
      analyze: _fake,
      onProgress: (d, t) => progress.add(d),
    );
    expect(data, isNotNull);
    expect(data!.moves.length, _uci.length);
    expect(progress.last, _uci.length);
    expect(data.by(Side.white).length, 7);
    expect(data.by(Side.black).length, 7);

    final blunder = data.moves.firstWhere((m) => m.ply == 7);
    expect(blunder.quality, MoveQuality.blunder);
    expect(blunder.bestSan, 'd3');
    expect(blunder.side, Side.white);
    expect(blunder.lossPercent, greaterThan(20));
    // Black stands better after it, so White's chance is below 50.
    expect(blunder.whiteWin, lessThan(50));

    expect(data.worst(Side.white).map((m) => m.ply), [7]);
    expect(data.worst(Side.black), isEmpty);
    expect(data.accuracy(Side.white)!, lessThan(data.accuracy(Side.black)!));
    expect(data.counts(Side.white)[MoveQuality.blunder], 1);
  });

  test('stops quietly when stale', () async {
    var calls = 0;
    final data = await reviewGame(
      _record(),
      analyze: _fake,
      isStale: () => ++calls > 3,
    );
    expect(data, isNull);
  });

  testWidgets('the screen shows accuracy, counts and the key moment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              ReviewScreen(gameId: 'g1', record: _record(), analyzer: _fake),
        ),
        GoRoute(
          path: '/history/:id',
          builder: (_, s) => Text('replay ${s.uri.queryParameters['ply']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('shot'),
        child: MaterialApp.router(theme: appDarkTheme, routerConfig: router),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Game review'), findsOneWidget);
    expect(find.text('You'), findsWidgets);
    expect(find.text('Bahar'), findsWidgets);
    expect(find.text('Blunder'), findsWidgets);
    expect(find.textContaining('Best was d3'), findsOneWidget);
    expect(find.text('Open replay'), findsOneWidget);

    final shot = tester.firstRenderObject(
      find.byKey(const ValueKey('shot')),
    ) as RenderRepaintBoundary;
    final image = await tester.runAsync(() => shot.toImage());
    final bytes = await tester.runAsync(
      () => image!.toByteData(format: ImageByteFormat.png),
    );
    io.File(
      '/tmp/claude-1000/-home-merdan-projects-kust/760b9389-a422-43b3-b398-cd8c57ce1199/scratchpad/review.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());

    await tester.tap(find.textContaining('Best was d3'));
    await tester.pumpAndSettle();
    expect(find.text('replay 7'), findsOneWidget);
  });
}
