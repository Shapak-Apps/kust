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

  test('a near-best sacrifice that sets a trap is brilliant (Légal)', () {
    // 1.Nf3 d5 2.c4 dxc4 3.e3 Nf6 4.Bxc4 Bg4 5.Ne5: the queen is left to
    // Bxd1, which loses to Bxf7#.
    Position pos = Chess.initial;
    for (final san in ['Nf3', 'd5', 'c4', 'dxc4', 'e3', 'Nf6', 'Bxc4', 'Bg4']) {
      pos = pos.play(pos.parseSan(san)!);
    }
    final ne5 = pos.parseSan('Ne5')! as NormalMove;
    expect(
      classifyPlayedMove(
        before: pos,
        after: pos.play(ne5),
        move: ne5,
        bestCp: 90,
        playedCp: 50,
        secondBestCp: 60,
        isBest: false,
      ),
      MoveQuality.brilliant,
    );
  });
}
