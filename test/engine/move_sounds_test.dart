import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/move_sounds.dart';

String _sound(String fen, String uci) {
  final before = Chess.fromSetup(Setup.parseFen(fen));
  final move = Move.parse(uci)! as NormalMove;
  return moveSoundFor(before, move, before.play(move));
}

void main() {
  const start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  test('quiet move', () => expect(_sound(start, 'e2e4'), 'move.wav'));

  test('capture', () {
    expect(
      _sound(
        'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
        'e4d5',
      ),
      'capture.wav',
    );
  });

  test('en passant counts as a capture', () {
    expect(
      _sound(
        'rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3',
        'e5d6',
      ),
      'capture.wav',
    );
  });

  test('castling', () {
    expect(
      _sound('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1', 'e1h1'),
      'castle.wav',
    );
    expect(
      _sound('r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1', 'e8a8'),
      'castle.wav',
    );
  });

  test('promotion', () {
    expect(_sound('8/P6k/8/8/8/8/8/K7 w - - 0 1', 'a7a8q'), 'promote.wav');
  });

  test('check wins over capture and castling', () {
    expect(_sound('4k2r/8/8/8/8/8/8/4K2R w - - 0 1', 'h1h8'), 'check.wav');
    expect(_sound('4k3/8/8/8/8/8/8/4KR2 w - - 0 1', 'f1f8'), 'check.wav');
  });
}
