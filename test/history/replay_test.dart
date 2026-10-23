import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/history/replay_screen.dart';

void main() {
  test('replays a legal game position by position', () {
    final replay = replayPositions(['e2e4', 'e7e5', 'g1f3']);
    expect(replay.positions.length, 4);
    expect(replay.moves.first, isNull);
    expect(
      replay.positions.last.fen,
      'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
    );
  });

  test('stops at the first move that cannot be played', () {
    final replay = replayPositions(['e2e4', 'e2e4', 'e7e5']);
    expect(replay.positions.length, 2);
  });

  test('empty and malformed move lists give just the start position', () {
    expect(replayPositions(const []).positions.length, 1);
    expect(replayPositions(['zz']).positions.length, 1);
  });
}
