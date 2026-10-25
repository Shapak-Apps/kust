import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:dartchess/dartchess.dart';

import 'package:kust/features/game/chess/accuracy.dart';

const Color kMoveBrilliant = Color(0xFF1BADA6);
const Color kMoveGreat = Color(0xFF5C8BB0);
const Color kMoveBest = Color(0xFF81B64C);
const Color kMoveExcellent = Color(0xFF96BC4B);
const Color kMoveGood = Color(0xFF95AF8A);
const Color kMoveInaccuracy = Color(0xFFF7C631);
const Color kMoveMistake = Color(0xFFFFA459);
const Color kMoveMiss = Color(0xFFFF7769);
const Color kMoveBlunder = Color(0xFFFA412D);

const int _kingExchangeValue = 100;

/// A sacrifice gives up at least this much material (in pawns) net.
const int _brilliantMinNetLoss = 2;

/// Still at least this well off after the sacrifice (centipawns).
const int _brilliantLosingCp = -150;

/// Already this far ahead, a sacrifice is just good technique, not
/// brilliant (the way chess.com rates it too).
const int _brilliantWinningCp = 400;

/// How a move compares with the engine's choice, from best to worst.
enum MoveQuality {
  brilliant,
  great,
  best,
  excellent,
  good,
  inaccuracy,
  mistake,
  miss,
  blunder,
}

extension MoveQualityStyle on MoveQuality {
  String get label => switch (this) {
    MoveQuality.brilliant => 'Brilliant',
    MoveQuality.great => 'Great',
    MoveQuality.best => 'Best move',
    MoveQuality.excellent => 'Excellent',
    MoveQuality.good => 'Good',
    MoveQuality.inaccuracy => 'Inaccuracy',
    MoveQuality.mistake => 'Mistake',
    MoveQuality.miss => 'Miss',
    MoveQuality.blunder => 'Blunder',
  };

  String get shortLabel => switch (this) {
    MoveQuality.brilliant => 'brilliant',
    MoveQuality.great => 'great',
    MoveQuality.best => 'best',
    MoveQuality.excellent => 'excellent',
    MoveQuality.good => 'good',
    MoveQuality.inaccuracy => 'an inaccuracy',
    MoveQuality.mistake => 'a mistake',
    MoveQuality.miss => 'a miss',
    MoveQuality.blunder => 'a blunder',
  };

  String get asset => switch (this) {
    MoveQuality.brilliant => 'assets/icons/moves/brilliant.svg',
    MoveQuality.great => 'assets/icons/moves/flawless.svg',
    MoveQuality.best => 'assets/icons/moves/best.svg',
    MoveQuality.excellent => 'assets/icons/moves/good.svg',
    MoveQuality.good => 'assets/icons/moves/check.svg',
    MoveQuality.inaccuracy => 'assets/icons/moves/inaccuracy.svg',
    MoveQuality.mistake => 'assets/icons/moves/mistake.svg',
    MoveQuality.miss => 'assets/icons/moves/miss.svg',
    MoveQuality.blunder => 'assets/icons/moves/blunder.svg',
  };

  Color get color => switch (this) {
    MoveQuality.brilliant => kMoveBrilliant,
    MoveQuality.great => kMoveGreat,
    MoveQuality.best => kMoveBest,
    MoveQuality.excellent => kMoveExcellent,
    MoveQuality.good => kMoveGood,
    MoveQuality.inaccuracy => kMoveInaccuracy,
    MoveQuality.mistake => kMoveMistake,
    MoveQuality.miss => kMoveMiss,
    MoveQuality.blunder => kMoveBlunder,
  };

  double get iconScale => switch (this) {
    MoveQuality.best => 0.72,
    _ => 0.66,
  };

  /// Worth a second, deeper look before it is shown: the labels that stand
  /// out, so a shallow search must not hand them out by mistake.
  bool get needsCheck =>
      this == MoveQuality.brilliant ||
      this == MoveQuality.great ||
      this == MoveQuality.mistake ||
      this == MoveQuality.miss ||
      this == MoveQuality.blunder;
}

class MoveFeedback {
  const MoveFeedback({
    required this.quality,
    required this.bestSan,
    required this.playedSan,
    this.evalLossCp = 0,
  });

  final MoveQuality quality;
  final String bestSan;
  final String playedSan;
  final int evalLossCp;

  bool get isBest =>
      quality == MoveQuality.best ||
      quality == MoveQuality.brilliant ||
      quality == MoveQuality.great;

  String get bannerText {
    if (isBest) return '$playedSan · ${quality.shortLabel} move';
    return '$playedSan was ${quality.shortLabel} · $bestSan was best';
  }
}

/// The share of the game a score is worth to the side it belongs to, 0..1:
/// the same curve as the accuracy figure (lichess's), so a move's label and
/// its accuracy always agree.
double expectedPointsFromCp(int cp) => winPercent(cp) / 100;

/// How much of the game, 0..1, playing [playedCp] instead of [bestCp] gave
/// away.
double expectedPointsLost({required int bestCp, required int playedCp}) =>
    (expectedPointsFromCp(bestCp) - expectedPointsFromCp(playedCp)).clamp(
      0.0,
      1.0,
    );

/// Smaller losses than this are search noise: the move counts as best.
const double _bestTolerance = 0.003;

/// The label of a move that is not one of the engine's best, by how much of
/// the game it gave away. The same limits as chess.com, for every player
/// and every opponent.
MoveQuality classifyByLoss(double lost) {
  if (lost <= _bestTolerance) return MoveQuality.best;
  if (lost <= 0.02) return MoveQuality.excellent;
  if (lost <= 0.05) return MoveQuality.good;
  if (lost <= 0.10) return MoveQuality.inaccuracy;
  if (lost <= 0.20) return MoveQuality.mistake;
  return MoveQuality.blunder;
}

/// Rates a played move. [bestCp], [playedCp] and [secondBestCp] are from
/// the mover's point of view, from searches of [before].
MoveQuality classifyPlayedMove({
  required Position before,
  required Position after,
  required NormalMove move,
  required int bestCp,
  required int playedCp,
  required int? secondBestCp,
  required bool isBest,
}) {
  final lost = expectedPointsLost(bestCp: bestCp, playedCp: playedCp);
  if (!isBest && lost > _bestTolerance) {
    final quality = classifyByLoss(lost);
    final costly =
        quality == MoveQuality.mistake || quality == MoveQuality.blunder;
    if (costly && isMiss(bestCp: bestCp, playedCp: playedCp)) {
      return MoveQuality.miss;
    }
    return quality;
  }
  if (isBrilliantSacrifice(
    before: before,
    after: after,
    move: move,
    playedCp: playedCp,
    isBest: true,
  )) {
    return MoveQuality.brilliant;
  }
  if (isGreatMove(bestCp: bestCp, secondBestCp: secondBestCp)) {
    return MoveQuality.great;
  }
  return MoveQuality.best;
}

/// A missed chance rather than a plain error: the best move would have left
/// the player clearly winning, the move played let that go, yet the game
/// is not lost by it. Typically: not punishing the opponent's mistake.
bool isMiss({required int bestCp, required int playedCp}) =>
    expectedPointsFromCp(bestCp) >= 0.75 &&
    expectedPointsFromCp(playedCp) >= 0.4;

/// The only good move: it keeps the game (at least) balanced while the next
/// best would lose a good share of it.
bool isGreatMove({required int bestCp, required int? secondBestCp}) {
  if (secondBestCp == null) return false;
  final best = expectedPointsFromCp(bestCp);
  final second = expectedPointsFromCp(secondBestCp);
  return best >= 0.5 && second < 0.5 && best - second >= 0.2;
}

int _sacPieceValue(Role role) => switch (role) {
  Role.pawn => 1,
  Role.knight => 3,
  Role.bishop => 3,
  Role.rook => 5,
  Role.queen => 9,
  Role.king => _kingExchangeValue,
};

/// A best move that gives material away: after it, the opponent can win
/// at least two pawns' worth more than the move itself took, while the
/// mover stays fine but not already far ahead. The material given up can
/// be the piece that moved or another one it leaves hanging.
bool isBrilliantSacrifice({
  required Position before,
  required Position after,
  required NormalMove move,
  required int playedCp,
  required bool isBest,
}) {
  if (!isBest) return false;
  if (playedCp < _brilliantLosingCp) return false;
  if (playedCp > _brilliantWinningCp) return false;

  final mover = before.turn;
  final piece = before.board.pieceAt(move.from);
  if (piece == null) return false;
  final target = before.board.pieceAt(move.to);
  if (target != null && target.color == mover) return false; // castling
  final captured = target == null ? 0 : _sacPieceValue(target.role);

  // How much more each of the mover's pieces now hangs than it did before
  // (the moved piece compared with where it came from): what the move
  // gives away, not what was already loose.
  final hangingAfter = _hanging(after, mover);
  final hangingBefore = _hanging(
    before.copyWith(turn: mover.opposite, epSquare: null),
    mover,
  );
  var added = 0;
  hangingAfter.forEach((square, gain) {
    final origin = square == move.to ? move.from : square;
    added = math.max(added, gain - (hangingBefore[origin] ?? 0));
  });
  return captured - added <= -_brilliantMinNetLoss && added > 1;
}

/// For each of [side]'s pieces (not the king) the opponent can win
/// something from in [position] (with the opponent to move): how much,
/// exchanges on that square played out. Only captures the opponent can
/// legally make count: a pinned attacker takes nothing.
Map<Square, int> _hanging(Position position, Side side) {
  final result = <Square, int>{};
  for (final square in position.board.bySide(side).squares) {
    final piece = position.board.pieceAt(square);
    if (piece == null || piece.role == Role.king) continue;
    final attackers = _legalCapturerValues(position, square);
    if (attackers.isEmpty) continue;
    final defenders = _attackerValues(position, square, side);
    final gain = _exchangeGain(
      _sacPieceValue(piece.role),
      attackers,
      defenders,
    );
    if (gain > 0) result[square] = gain;
  }
  return result;
}

/// The values of the pieces of the side to move in [position] that can
/// legally capture on [square], cheapest first.
List<int> _legalCapturerValues(Position position, Square square) {
  final values = <int>[];
  for (final from in position.board.bySide(position.turn).squares) {
    if (!position.legalMovesOf(from).has(square)) continue;
    final attacker = position.board.pieceAt(from);
    if (attacker != null) values.add(_sacPieceValue(attacker.role));
  }
  values.sort();
  return values;
}

List<int> _attackerValues(Position position, Square square, Side side) {
  final attackers = position.board.attacksTo(square, side);
  final values = <int>[];
  for (final from in attackers.squares) {
    final attacker = position.board.pieceAt(from);
    if (attacker == null) continue;
    values.add(_sacPieceValue(attacker.role));
  }
  values.sort();
  return values;
}

int _exchangeGain(int target, List<int> attackers, List<int> defenders) {
  if (attackers.isEmpty) return 0;
  final cheapest = attackers.first;
  final remaining = attackers.sublist(1);
  final recapture = _exchangeGain(cheapest, defenders, remaining);
  return math.max(0, target - recapture);
}
