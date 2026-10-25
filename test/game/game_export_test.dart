import 'dart:ui' as ui;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/move_record.dart';
import 'package:kust/features/game/game_export.dart';
import 'package:kust/features/play/bots.dart';

GameState _game({
  GameStatus status = GameStatus.playing,
  Side player = Side.white,
  String? endReason,
}) {
  Position p = Chess.initial;
  final moves = <MoveRecord>[];
  for (final (uci, san) in [('e2e4', 'e4'), ('e7e5', 'e5'), ('g1f3', 'Nf3')]) {
    final m = NormalMove.fromUci(uci);
    moves.add(MoveRecord(side: p.turn, san: san, move: m));
    p = p.play(m);
  }
  return GameState(
    position: p,
    mode: GameMode.bot,
    bot: kInternationalBots.first,
    playerSide: player,
    moves: moves,
    status: status,
    endReason: endReason,
  );
}

void main() {
  test('the PGN of a game in progress lists the moves and ends in *', () {
    final pgn = livePgn(_game(), date: DateTime(2026, 10, 25));
    expect(pgn, contains('[Date "2026.10.25"]'));
    expect(pgn, contains('[White "Player"]'));
    expect(pgn, contains('[Black "${kInternationalBots.first.name}"]'));
    expect(pgn, contains('[Result "*"]'));
    expect(pgn.trim(), endsWith('1. e4 e5 2. Nf3 *'));
  });

  test('finished games carry their result', () {
    expect(gameResultToken(_game(status: GameStatus.draw)), '1/2-1/2');
    expect(gameResultToken(_game(status: GameStatus.resigned)), '0-1');
    expect(
      gameResultToken(_game(status: GameStatus.resigned, player: Side.black)),
      '1-0',
    );
    expect(
      gameResultToken(
        _game(status: GameStatus.timeout, endReason: 'You won on time.'),
      ),
      '1-0',
    );
  });

  testWidgets('the board image is a square PNG of the asked size', (
    tester,
  ) async {
    final png = await tester.runAsync(
      () => boardPng(Chess.initial, size: 256, highlight: [Square.e4]),
    );
    expect(png!.sublist(1, 4), [0x50, 0x4E, 0x47]); // "PNG"
    final image = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(png);
      return (await codec.getNextFrame()).image;
    });
    expect(image!.width, 256);
    expect(image.height, 256);
  });
}
