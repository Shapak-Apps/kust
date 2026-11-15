import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/features/learn/learn_screen.dart';
import 'package:kust/features/learn/lesson_screen.dart';
import 'package:kust/features/review/review_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';

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
    botId: 'bahar',
    botName: 'Bahar',
    botElo: 400,
  );
}

Future<MoveAnalysis?> _fake({
  required String beforeFen,
  required String playedUci,
  required String afterFen,
  required Duration thinkTime,
  bool Function()? isStale,
}) async => playedUci == 'f3g5'
    ? const MoveAnalysis(
        bestUci: 'd2d3',
        bestCp: 40,
        playedCp: -400,
        secondBestCp: 20,
      )
    : MoveAnalysis(bestUci: playedUci, bestCp: 30, playedCp: 30);

/// The screens that carry the most text, in the languages with the longest
/// words, on a small phone and with large system fonts.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.soundEnabled = false;
    LearnProgress.instance.done.value = const {};
  });

  final screens = <String, Widget Function()>{
    'Learn': () => const LearnScreen(),
    'lesson': () => const LessonScreen(lessonId: 'pawn'),
    'review': () =>
        ReviewScreen(gameId: 'g1', record: _record(), analyzer: _fake),
  };

  for (final lang in ['ru', 'tk']) {
    for (final scale in [1.0, 1.3]) {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} fits 360 px in $lang at ${scale}x', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(360, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final router = GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => entry.value()),
              GoRoute(path: '/history/:id', builder: (_, _) => const Text('')),
            ],
          );
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: const Size(360, 740),
                textScaler: TextScaler.linear(scale),
              ),
              child: MaterialApp.router(
                theme: appDarkTheme,
                locale: Locale(lang),
                supportedLocales: kSupportedLocales,
                localizationsDelegates: kLocalizationDelegates,
                routerConfig: router,
              ),
            ),
          );
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));
          final ctx = tester.element(find.byType(Directionality).first);
          expect(MediaQuery.textScalerOf(ctx).scale(10), 10 * scale);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
