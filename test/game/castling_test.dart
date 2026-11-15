import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/castling.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';

void main() {
  test('a rook corner shows as where the king lands, anything else stays', () {
    expect(castlingDisplaySquare(Square.h1), Square.g1);
    expect(castlingDisplaySquare(Square.a1), Square.c1);
    expect(castlingDisplaySquare(Square.h8), Square.g8);
    expect(castlingDisplaySquare(Square.a8), Square.c8);
    expect(castlingDisplaySquare(Square.e4), Square.e4);
    expect(castlingDisplaySquare(Square.g1), Square.g1);
  });

  test('all four castles are written as the engine does', () {
    final cases = {
      // White and black, each side.
      'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1': {
        'e1h1': 'e1g1',
        'e1a1': 'e1c1',
      },
      'r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R b KQkq - 0 1': {
        'e8h8': 'e8g8',
        'e8a8': 'e8c8',
      },
    };
    for (final entry in cases.entries) {
      final position = Chess.fromSetup(Setup.parseFen(entry.key));
      for (final castle in entry.value.entries) {
        final move = NormalMove.fromUci(castle.key);
        expect(position.isLegal(move), isTrue, reason: castle.key);
        expect(engineUci(move, position), castle.value);
      }
    }
  });

  test('a plain king step is not a castle', () {
    final position = Chess.fromSetup(
      Setup.parseFen('4k3/8/8/8/8/8/8/R3K2R w - - 0 1'),
    );
    expect(engineUci(NormalMove.fromUci('e1f1'), position), 'e1f1');
    expect(engineUci(NormalMove.fromUci('h1h5'), position), 'h1h5');
  });
}
