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
import 'package:kust/ui/kust_dialog.dart';

/// A controller that just holds a fixed state.
class _FixedController extends ChessController {
  _FixedController(this.fixed);

  final GameState fixed;

  @override
  GameState build() => fixed;
}

GameState _state({int? ratingChange, double? accuracy, bool pending = false}) {
  return GameState(
    position: Chess.initial,
    mode: GameMode.bot,
    bot: kInternationalBots.first,
    playerSide: Side.white,
    status: GameStatus.resigned,
    ratingChange: ratingChange,
    accuracy: accuracy,
    accuracyPending: pending,
  );
}

Future<void> _open(
  WidgetTester tester,
  GameState state, {
  VoidCallback? onRematch,
  VoidCallback? onLobby,
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
                onPressed: () => showKustDialog<void>(
                  context,
                  builder: (_) => GameResultContent(
                    title: 'Game over',
                    message: 'You resigned.',
                    onRematch: onRematch ?? () {},
                    onLobby: onLobby ?? () {},
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

  testWidgets('is a modal in the middle of the screen, not a bottom sheet', (
    tester,
  ) async {
    await _open(tester, _state(ratingChange: 9, accuracy: 87.7));

    final card = tester.getRect(find.byKey(const ValueKey('kustDialogCard')));
    expect(card.center.dx, closeTo(200, 1));
    expect(card.center.dy, closeTo(400, 40));
    // Floats above the bottom edge instead of being attached to it.
    expect(card.bottom, lessThan(800 - 24));
    expect(card.top, greaterThan(24));
  });

  testWidgets('everything inside is centered', (tester) async {
    await _open(tester, _state(ratingChange: 9, accuracy: 87.7));

    for (final text in ['Game over', 'You resigned.', 'Rating 1209 (+9)']) {
      expect(
        tester.getCenter(find.text(text)).dx,
        closeTo(200, 1),
        reason: text,
      );
    }
    expect(tester.getCenter(find.text('Accuracy 87.7%')).dx, closeTo(200, 20));
  });

  testWidgets('has two buttons in one row that call their callbacks', (
    tester,
  ) async {
    var rematch = 0;
    var lobby = 0;
    await _open(
      tester,
      _state(),
      onRematch: () => rematch++,
      onLobby: () => lobby++,
    );

    final a = tester.getCenter(find.text('Lobby'));
    final b = tester.getCenter(find.text('Rematch'));
    expect(a.dy, closeTo(b.dy, 1)); // same row
    expect(a.dx, lessThan(b.dx));

    await tester.tap(find.text('Rematch'));
    await tester.tap(find.text('Lobby'));
    expect(rematch, 1);
    expect(lobby, 1);
  });

  testWidgets('says it is analyzing while the accuracy is worked out', (
    tester,
  ) async {
    await _open(tester, _state(pending: true));
    expect(find.text('Analyzing your moves…'), findsOneWidget);
    expect(find.textContaining('Accuracy'), findsNothing);
  });

  testWidgets('shows no accuracy line when there is nothing to show', (
    tester,
  ) async {
    await _open(tester, _state());
    expect(find.textContaining('Accuracy'), findsNothing);
    expect(find.textContaining('Analyzing'), findsNothing);
  });

  testWidgets('tapping outside closes it', (tester) async {
    await _open(tester, _state());
    await tester.tapAt(const Offset(200, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Game over'), findsNothing);
  });
}
