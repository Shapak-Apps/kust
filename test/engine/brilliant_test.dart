import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/move_feedback.dart';

void main() {
  // White to move: Rxf7 gives up the rook for a pawn, and Stockfish rates it
  // best (+6.3 at depth 24). White is already far ahead here.
  final before = Chess.fromSetup(
    Setup.parseFen(
      'rnnqk2r/5pb1/1p4pp/p1BPp3/2P4N/3P2P1/PP4BP/R2Q1RK1 w kq - 0 16',
    ),
  );
  final move = NormalMove.fromUci('f1f7');
  final after = before.play(move);

  bool brilliant(int playedCp) => isBrilliantSacrifice(
    before: before,
    after: after,
    move: move,
    playedCp: playedCp,
    isBest: true,
  );

  test('a sound sacrifice in a balanced game is brilliant', () {
    expect(brilliant(80), isTrue);
  });

  test('the same sacrifice when already winning is only the best move', () {
    expect(brilliant(631), isFalse);
    expect(
      classifyPlayedMove(
        before: before,
        after: after,
        move: move,
        bestCp: 631,
        playedCp: 631,
        secondBestCp: 502,
        isBest: true,
      ),
      MoveQuality.best,
    );
  });

  test('a sacrifice that leaves you lost is never brilliant', () {
    expect(brilliant(-300), isFalse);
  });
}
