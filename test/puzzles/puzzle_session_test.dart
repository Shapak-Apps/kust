import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Kust/features/puzzles/puzzle_data.dart';
import 'package:Kust/features/puzzles/puzzle_session.dart';

NormalMove _m(String uci) => NormalMove.fromUci(uci);

// White: Ra1, Kg1. Black: Kg8 boxed in by own pawns.
const _mate1 = PuzzleEntry(
  id: 'm1',
  fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
  moves: ['a1a8'],
  rating: 800,
);

// Solver plays a1a8+, forced reply, then mates again: 3-ply line.
const _multi = PuzzleEntry(
  id: 'm2',
  fen: '7k/8/8/8/8/8/R7/1R4K1 w - - 0 1',
  moves: ['a2a7', 'h8g8', 'b1b8'],
  rating: 900,
);

// Two different first moves both mate.
const _twoLines = PuzzleEntry(
  id: 'm3',
  fen: '6k1/5ppp/8/8/8/8/5PPP/RR4K1 w - - 0 1',
  moves: ['a1a8'],
  alternatives: [
    ['b1b8'],
  ],
  rating: 800,
);

void main() {
  test('starts on the puzzle position with the solver to move', () {
    final s = PuzzleSession(_mate1);
    expect(s.solverSide, Side.white);
    expect(s.status, PuzzleStatus.inProgress);
    expect(s.expectedMove, _m('a1a8'));
  });

  test('wrong move is rejected, position untouched, can retry', () {
    final s = PuzzleSession(_mate1);
    final fen = s.position.fen;
    expect(s.submit(_m('a1a2')), PuzzleMoveResult.incorrect);
    expect(s.position.fen, fen);
    expect(s.mistakes, 1);
    expect(s.submit(_m('a1a8')), PuzzleMoveResult.solved);
    expect(s.status, PuzzleStatus.solved);
  });

  test('illegal move is treated as incorrect without changing state', () {
    final s = PuzzleSession(_mate1);
    final fen = s.position.fen;
    expect(s.submit(_m('a1b3')), PuzzleMoveResult.incorrect);
    expect(s.position.fen, fen);
  });

  test('progresses through solver moves and forced replies in order', () {
    final s = PuzzleSession(_multi);
    expect(s.submit(_m('a2a7')), PuzzleMoveResult.correct);
    expect(s.awaitingReply, isTrue);
    // Solver may not move while the reply is pending.
    expect(s.submit(_m('b1b8')), PuzzleMoveResult.ignored);
    expect(s.playReply(), _m('h8g8'));
    expect(s.awaitingReply, isFalse);
    expect(s.submit(_m('b1b8')), PuzzleMoveResult.solved);
  });

  test('either accepted line solves the puzzle', () {
    for (final uci in ['a1a8', 'b1b8']) {
      final s = PuzzleSession(_twoLines);
      expect(s.submit(_m(uci)), PuzzleMoveResult.solved, reason: uci);
    }
  });

  test('hints escalate and reset after a correct move', () {
    final s = PuzzleSession(_multi);
    expect(s.hintFrom, isNull);
    expect(s.useHint(), isTrue);
    expect(s.hintFrom, Square.a2);
    expect(s.hintTo, isNull);
    expect(s.useHint(), isTrue);
    expect(s.hintTo, Square.a7);
    expect(s.useHint(), isFalse);
    s.submit(_m('a2a7'));
    expect(s.hintLevel, 0);
  });

  test('reveal plays the remaining solution and marks revealed', () {
    final s = PuzzleSession(_multi);
    s.submit(_m('a2a7'));
    expect(s.remainingSolution, [_m('h8g8'), _m('b1b8')]);
    expect(s.revealNext(), _m('h8g8'));
    expect(s.revealNext(), _m('b1b8'));
    expect(s.revealNext(), isNull);
    expect(s.status, PuzzleStatus.revealed);
    expect(s.submit(_m('a1a8')), PuzzleMoveResult.ignored);
  });

  test('a revealed puzzle never counts as solved', () {
    final s = PuzzleSession(_mate1)..revealNext();
    expect(s.status, PuzzleStatus.revealed);
    expect(s.status, isNot(PuzzleStatus.solved));
  });

  test('retry restores the initial state', () {
    final s = PuzzleSession(_multi);
    final fen = s.position.fen;
    s.submit(_m('a1a1'));
    s.submit(_m('a2a7'));
    s.useHint();
    s.retry();
    expect(s.position.fen, fen);
    expect(s.positions.length, 1);
    expect(s.mistakes, 0);
    expect(s.hintLevel, 0);
    expect(s.step, 0);
    expect(s.status, PuzzleStatus.inProgress);
  });

  test('castling given as e1g1 is understood', () {
    const castle = PuzzleEntry(
      id: 'c',
      fen: 'r3k3/8/8/8/8/8/8/R3K2R w KQ - 0 1',
      moves: ['e1g1'],
      rating: 800,
    );
    expect(castle.isPlayable, isTrue);
    final s = PuzzleSession(castle);
    expect(s.submit(_m('e1h1')), PuzzleMoveResult.solved);
  });
}
