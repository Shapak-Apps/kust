import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:dartchess/dartchess.dart';

const Color kMoveInaccuracy = Color(0xFFFFDD00);
const Color kMoveBrilliant = Color(0xFF00FF8C);
const Color kMoveBlunder = Color(0xFFDB0000);
const Color kMoveBest = Color(0xFF00B138);
const Color kMoveGood = Color(0xFF4CD23E);
const Color kMoveGreat = Color(0xFF6385ED);

const int _kingExchangeValue = 100;
const int _brilliantMinNetLoss = 2;
const int _brilliantLosingCp = -150;

enum MoveQuality {
  brilliant,
  best,
  good,
  great,
  inaccuracy,
  mistake,
  blunder,
}

extension MoveQualityStyle on MoveQuality {
  String get label {
    switch (this) {
      case MoveQuality.brilliant:
        return 'Brilliant';
      case MoveQuality.best:
        return 'Best move';
      case MoveQuality.good:
        return 'Good';
      case MoveQuality.great:
        return 'Great';
      case MoveQuality.inaccuracy:
        return 'Inaccuracy';
      case MoveQuality.mistake:
        return 'Mistake';
      case MoveQuality.blunder:
        return 'Blunder';
    }
  }

  String get shortLabel {
    switch (this) {
      case MoveQuality.brilliant:
        return 'brilliant';
      case MoveQuality.best:
        return 'best';
      case MoveQuality.good:
        return 'good';
      case MoveQuality.great:
        return 'great';
      case MoveQuality.inaccuracy:
        return 'inaccuracy';
      case MoveQuality.mistake:
        return 'mistake';
      case MoveQuality.blunder:
        return 'blunder';
    }
  }

  String get asset {
    switch (this) {
      case MoveQuality.brilliant:
        return 'assets/icons/moves/brilliant.svg';
      case MoveQuality.best:
        return 'assets/icons/moves/best.svg';
      case MoveQuality.good:
        return 'assets/icons/moves/good.svg';
      case MoveQuality.great:
        return 'assets/icons/moves/flawless.svg';
      case MoveQuality.inaccuracy:
        return 'assets/icons/moves/iA.svg';
      case MoveQuality.mistake:
      case MoveQuality.blunder:
        return 'assets/icons/moves/mistake.svg';
    }
  }

  Color get color {
    switch (this) {
      case MoveQuality.brilliant:
        return kMoveBrilliant;
      case MoveQuality.best:
        return kMoveBest;
      case MoveQuality.good:
        return kMoveGood;
      case MoveQuality.great:
        return kMoveGreat;
      case MoveQuality.inaccuracy:
        return kMoveInaccuracy;
      case MoveQuality.mistake:
      case MoveQuality.blunder:
        return kMoveBlunder;
    }
  }

  double get iconScale {
    switch (this) {
      case MoveQuality.best:
        return 0.72;
      default:
        return 0.66;
    }
  }
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

double expectedPointsFromCp(int cp) {
  if (cp >= 100000) return 1.0;
  if (cp <= -100000) return 0.0;
  return 1.0 / (1.0 + math.exp(-cp / 300.0));
}

int ratingForFeedback({int? botElo, Side? playerSide}) {
  if (botElo != null && botElo > 0) return botElo;
  return 800;
}

MoveQuality classifyPlayedMove({
  required Position before,
  required Position after,
  required NormalMove move,
  required int bestCp,
  required int playedCp,
  required int? secondBestCp,
  required bool isBest,
  int rating = 800,
}) {
  if (!isBest) {
    return classifyByExpectedPoints(
      bestCp: bestCp,
      playedCp: playedCp,
      isBestMove: false,
      rating: rating,
    );
  }
  if (isBrilliantSacrifice(
    before: before,
    after: after,
    move: move,
    playedCp: playedCp,
    isBest: isBest,
  )) {
    return MoveQuality.brilliant;
  }
  if (isGreatMove(bestCp: bestCp, secondBestCp: secondBestCp)) {
    return MoveQuality.great;
  }
  return MoveQuality.best;
}

MoveQuality classifyByExpectedPoints({
  required int bestCp,
  required int playedCp,
  required bool isBestMove,
  int rating = 800,
}) {
  if (isBestMove) return MoveQuality.best;
  final lost =
      (expectedPointsFromCp(bestCp) - expectedPointsFromCp(playedCp)).clamp(
        0.0,
        1.0,
      );
  final softness = rating < 600
      ? 1.6
      : rating < 1000
      ? 1.3
      : rating < 1500
      ? 1.0
      : 0.85;
  if (lost <= 0.05 * softness) return MoveQuality.good;
  if (lost <= 0.10 * softness) return MoveQuality.inaccuracy;
  if (lost <= 0.20 * softness) return MoveQuality.mistake;
  return MoveQuality.blunder;
}

bool isGreatMove({required int bestCp, required int? secondBestCp}) {
  if (secondBestCp == null) return false;
  final best = expectedPointsFromCp(bestCp);
  final second = expectedPointsFromCp(secondBestCp);
  return best >= 0.5 && second < 0.5 && best - second >= 0.2;
}

int _sacPieceValue(Role role) {
  switch (role) {
    case Role.pawn:
      return 1;
    case Role.knight:
      return 3;
    case Role.bishop:
      return 3;
    case Role.rook:
      return 5;
    case Role.queen:
      return 9;
    case Role.king:
      return _kingExchangeValue;
  }
}

bool isBrilliantSacrifice({
  required Position before,
  required Position after,
  required NormalMove move,
  required int playedCp,
  required bool isBest,
}) {
  if (!isBest) return false;
  if (playedCp < _brilliantLosingCp) return false;

  final mover = before.turn;
  final opponent = mover.opposite;

  final piece = before.board.pieceAt(move.from);
  if (piece == null) return false;
  if (piece.role == Role.king || piece.role == Role.pawn) return false;

  final target = before.board.pieceAt(move.to);
  if (target != null && target.color == mover) return false;

  final capturedValue = target == null ? 0 : _sacPieceValue(target.role);
  final movedValue = _sacPieceValue(piece.role);

  final opponentAttackers = _attackerValues(after, move.to, opponent);
  if (opponentAttackers.isEmpty) return false;

  final moverDefenders = _attackerValues(after, move.to, mover);
  final opponentGain = _exchangeGain(
    movedValue,
    opponentAttackers,
    moverDefenders,
  );

  final netForMover = capturedValue - opponentGain;
  return netForMover <= -_brilliantMinNetLoss;
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
