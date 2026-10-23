import 'package:dartchess/dartchess.dart';

import 'package:kust/features/puzzles/puzzle_data.dart';

enum PuzzleStatus { inProgress, solved, revealed }

enum PuzzleMoveResult {
  /// The move was accepted; an opponent reply may be pending.
  correct,

  /// The move was accepted and completed the puzzle.
  solved,

  /// The move was rejected; the position is unchanged.
  incorrect,

  /// The session was not accepting moves (finished, or a reply is pending).
  ignored,
}

/// Puzzle progression and solution checking, independent of any UI.
///
/// Even steps of a solution line are the solver's moves, odd steps are forced
/// opponent replies. Moves are checked against the stored lines only; no
/// engine is involved.
class PuzzleSession {
  PuzzleSession(this.puzzle) {
    _reset();
  }

  static const int maxHintLevel = 2;

  final PuzzleEntry puzzle;

  /// Positions reached so far; index 0 is the starting position.
  final List<Position> positions = [];

  /// Move that led to each entry of [positions] (null for the start).
  final List<NormalMove?> lastMoves = [];

  PuzzleStatus status = PuzzleStatus.inProgress;
  int mistakes = 0;
  int hintLevel = 0;
  int _step = 0;
  late List<List<String>> _candidates;

  Position get position => positions.last;
  Position get startPosition => positions.first;
  Side get solverSide => startPosition.turn;
  int get step => _step;
  bool get isFinished => status != PuzzleStatus.inProgress;

  /// Whether the next move in the line belongs to the opponent.
  bool get awaitingReply => !isFinished && _step < _lineLength && _step.isOdd;

  int get _lineLength => _candidates.first.length;

  /// The solver's next expected move, or null if it is not their turn.
  NormalMove? get expectedMove {
    if (isFinished || _step.isOdd || _step >= _lineLength) return null;
    return parsePuzzleUci(_candidates.first[_step], position);
  }

  /// The opponent's forced reply, or null if none is pending.
  NormalMove? get pendingReply {
    if (!awaitingReply) return null;
    return parsePuzzleUci(_candidates.first[_step], position);
  }

  /// Moves still to be played in the main remaining line.
  List<NormalMove> get remainingSolution {
    final result = <NormalMove>[];
    var pos = position;
    for (var i = _step; i < _lineLength; i++) {
      final move = parsePuzzleUci(_candidates.first[i], pos);
      if (move == null || !pos.isLegal(move)) break;
      result.add(move);
      pos = pos.play(move);
    }
    return result;
  }

  /// Square to highlight for the current hint, if any.
  Square? get hintFrom => hintLevel >= 1 ? expectedMove?.from : null;
  Square? get hintTo => hintLevel >= 2 ? expectedMove?.to : null;

  /// Submits a solver move. Illegal or wrong moves leave the state untouched.
  PuzzleMoveResult submit(NormalMove move) {
    if (isFinished || _step.isOdd) return PuzzleMoveResult.ignored;

    final matching = _candidates.where((line) {
      if (_step >= line.length) return false;
      final expected = parsePuzzleUci(line[_step], position);
      return expected != null && _sameMove(expected, move);
    }).toList();

    if (matching.isEmpty || !position.isLegal(move)) {
      mistakes++;
      return PuzzleMoveResult.incorrect;
    }

    _candidates = matching;
    _push(move);
    hintLevel = 0;
    _step++;

    if (_step >= _lineLength) {
      status = PuzzleStatus.solved;
      return PuzzleMoveResult.solved;
    }
    return PuzzleMoveResult.correct;
  }

  /// Plays the opponent's forced reply. Returns it, or null if none pending.
  /// May finish the puzzle when the reply is the last move of the line.
  NormalMove? playReply() {
    final reply = pendingReply;
    if (reply == null || !position.isLegal(reply)) return null;
    _push(reply);
    _step++;
    if (_step >= _lineLength) status = PuzzleStatus.solved;
    return reply;
  }

  /// Advances the hint. Returns false when no further hint is available.
  bool useHint() {
    if (isFinished || _step.isOdd || hintLevel >= maxHintLevel) return false;
    hintLevel++;
    return true;
  }

  /// Plays the next move of the solution on the solver's behalf, whichever
  /// side it belongs to. The puzzle is marked revealed once the line ends,
  /// never solved. Returns null when nothing is left to play.
  NormalMove? revealNext() {
    if (status == PuzzleStatus.solved) return null;
    status = PuzzleStatus.revealed;
    if (_step >= _lineLength) return null;
    final move = parsePuzzleUci(_candidates.first[_step], position);
    if (move == null || !position.isLegal(move)) return null;
    _push(move);
    _step++;
    hintLevel = 0;
    return move;
  }

  /// Restores the starting position and clears all attempt state.
  void retry() => _reset();

  void _reset() {
    positions
      ..clear()
      ..add(Chess.fromSetup(Setup.parseFen(puzzle.fen)));
    lastMoves
      ..clear()
      ..add(null);
    status = PuzzleStatus.inProgress;
    mistakes = 0;
    hintLevel = 0;
    _step = 0;
    _candidates = puzzle.lines;
  }

  void _push(NormalMove move) {
    positions.add(position.play(move));
    lastMoves.add(move);
  }

  bool _sameMove(NormalMove expected, NormalMove played) {
    if (expected.from != played.from || expected.to != played.to) return false;
    return expected.promotion == null || expected.promotion == played.promotion;
  }
}
