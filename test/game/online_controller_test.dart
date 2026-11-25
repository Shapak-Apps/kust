import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/game/time_control.dart';
import 'package:kust/theme.dart';

void main() {
  testWidgets(
    "online: a premove queued in the friend's turn plays and is sent when "
    'their move arrives',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      SoundService.instance.soundEnabled = false;
      addTearDown(() => SoundService.instance.soundEnabled = true);
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
      final sent = <(String, int)>[];
      c.onOnlineMove = (move, ply) => sent.add((move.uci, ply));
      c.startOnlineGame(
        playerSide: Side.black,
        timeControl: const TimeControl(baseMinutes: 5),
      );
      await tester.pump();

      // White (the friend) to move: my e7-e5 is queued as a premove.
      c.selectSquare(Square.e7);
      c.selectSquare(Square.e5);
      expect(container.read(chessControllerProvider).premoves, isNotEmpty);
      expect(sent, isEmpty);

      c.applyOnlineMove('e2e4');
      await tester.pump(const Duration(milliseconds: 500));
      final s = container.read(chessControllerProvider);
      expect(s.moves.map((m) => m.san).toList(), ['e4', 'e5']);
      expect(s.premoves, isEmpty);
      expect(sent, [('e7e5', 1)]);

      // The server ends it: my resignation shows as a resign.
      c.endOnline(winner: Side.white, reason: 'resign');
      expect(
        container.read(chessControllerProvider).status,
        GameStatus.resigned,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
    },
  );
}
