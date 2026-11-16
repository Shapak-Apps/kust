// The tests read the controller's state directly.
// ignore_for_file: invalid_use_of_protected_member

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/train/train_openings.dart';
import 'package:kust/theme.dart';

import '../support/fake_engine.dart';

void main() {
  testWidgets('a line is built from move one: wrong moves are refused', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.soundEnabled = false;
    addTearDown(() => SoundService.instance.soundEnabled = true);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final engine = FakeEngine(const []);
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
    final italian = kTrainOpenings.firstWhere((o) => o.id == 'italian');
    final line = italian.lines.first;
    final c = container.read(chessControllerProvider.notifier);
    await c.startGame(
      kInternationalBots.first,
      practiceMode: true,
      line: line.uci,
    );
    await tester.pump();
    expect(c.state.lineLength, line.san.length);
    expect(c.state.moves, isEmpty);

    // Show best stays off while the line is built.
    await c.setShowBestEnabled(true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.state.suggestSquares, isEmpty);

    // 1.d4 is not the line: refused, and 1.e4 is named and shown.
    c.selectSquare(Square.d2);
    c.selectSquare(Square.d4);
    await tester.pump();
    expect(c.state.moves, isEmpty);
    expect(c.state.lineExpected, 'e4');
    expect(c.state.hintSquares, {Square.e2, Square.e4});

    // 1.e4 is: played, and the bot answers with the line's 1...e5.
    c.selectSquare(Square.e2);
    c.selectSquare(Square.e4);
    await tester.pump();
    expect(c.state.lineExpected, isNull);
    await tester.pump(const Duration(seconds: 1));
    expect(c.state.moves.map((m) => m.san), ['e4', 'e5']);
    expect(c.state.inLine, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 31));
  });
}
