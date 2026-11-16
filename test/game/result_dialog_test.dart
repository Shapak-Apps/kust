import 'dart:io';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/game_result_dialog.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/theme.dart';
import 'package:kust/features/game/chess/move_feedback.dart';

/// A controller that just holds a fixed state.
class _FixedController extends ChessController {
  _FixedController(this.fixed);

  final GameState fixed;

  @override
  GameState build() => fixed;
}

GameState _state({
  int? ratingChange,
  double? accuracy,
  bool pending = false,
  Map<MoveQuality, int>? counts,
}) {
  return GameState(
    position: Chess.initial,
    mode: GameMode.bot,
    bot: kInternationalBots.first,
    playerSide: Side.white,
    status: GameStatus.resigned,
    ratingChange: ratingChange,
    accuracy: accuracy,
    accuracyPending: pending,
    moveCounts: counts,
  );
}

Future<void> _open(
  WidgetTester tester,
  GameState state, {
  VoidCallback? onRematch,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chessControllerProvider.overrideWith(() => _FixedController(state)),
      ],
      child: MaterialApp(
        theme: appTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showGameResult(
                  context,
                  builder: (dialogContext) => GameResultScreen(
                    title: 'Game over',
                    message: 'You resigned.',
                    onRematch: onRematch ?? () {},
                    onClose: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // Not pumpAndSettle: the analyzing spinner never stops animating.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_result_ui');
    Hive.init(dir.path);
    final user = await Hive.openBox(AppStorage.userBoxName);
    await user.put('player_rating', 1209);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets('covers the whole screen and shows the result', (tester) async {
    await _open(tester, _state(ratingChange: 9, accuracy: 87.7));
    expect(
      tester.getRect(find.byType(GameResultScreen)).size,
      const Size(400, 800),
    );
    expect(find.text('Game over'), findsOneWidget);
    expect(find.text('You resigned.'), findsOneWidget);
    expect(find.text('1209'), findsOneWidget);
    expect(find.text('+9'), findsOneWidget);
    expect(find.text('Accuracy 87.7%'), findsOneWidget);
  });

  testWidgets('the X closes it and leaves the game behind', (tester) async {
    await _open(tester, _state());
    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Game over'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('has Rematch and no Lobby or new-game button', (tester) async {
    var rematch = 0;
    await _open(tester, _state(), onRematch: () => rematch++);
    expect(find.text('Lobby'), findsNothing);
    await tester.tap(find.text('Rematch'));
    expect(rematch, 1);
  });

  testWidgets('rates moves best first, errors after, skipping zeros', (
    tester,
  ) async {
    await _open(
      tester,
      _state(
        counts: {
          MoveQuality.blunder: 1,
          MoveQuality.best: 12,
          MoveQuality.brilliant: 1,
          MoveQuality.book: 4,
          MoveQuality.inaccuracy: 2,
        },
      ),
    );
    final labels = ['Brilliant', 'Best move', 'Inaccuracy', 'Blunder'];
    for (final l in labels) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
    expect(find.text('Book'), findsNothing);
    expect(find.text('Great'), findsNothing);
    final xs = [
      for (final l in labels.take(3)) tester.getCenter(find.text(l)).dx,
    ];
    expect(xs[0], lessThan(xs[1]));
    expect(xs[1], lessThan(xs[2]));
    // The fourth wraps to the next row.
    expect(
      tester.getCenter(find.text('Blunder')).dy,
      greaterThan(tester.getCenter(find.text('Brilliant')).dy),
    );
  });

  testWidgets('says it is analyzing while the moves are rated', (tester) async {
    await _open(tester, _state(pending: true));
    expect(find.text('Analyzing your moves…'), findsOneWidget);
    expect(find.textContaining('Accuracy'), findsNothing);
  });

  testWidgets('shows no accuracy when there is nothing to show', (
    tester,
  ) async {
    await _open(tester, _state());
    expect(find.textContaining('Accuracy'), findsNothing);
    expect(find.textContaining('Analyzing'), findsNothing);
  });
}
