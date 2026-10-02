import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:dartchess/dartchess.dart';

const Color kMoveInaccuracy = Color(0xFFFFDD00);
const Color kMoveBrilliant = Color(0xFF00FF8C);
const Color kMoveBlunder = Color(0xFFDB0000);
const Color kMoveBest = Color(0xFF00B138);
const Color kMoveGood = Color(0xFF4CD23E);
const Color kMoveFlawless = Color(0xFF6385ED);

enum MoveQuality {
  brilliant,
  best,
  good,
  flawless,
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
      case MoveQuality.flawless:
        return 'Flawless';
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
      case MoveQuality.flawless:
        return 'flawless';
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
      case MoveQuality.flawless:
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
      case MoveQuality.flawless:
        return kMoveFlawless;
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
      quality == MoveQuality.flawless;

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

({int good, int inaccuracy, int mistake}) lossThresholdsFor(int rating) {
  if (rating < 600) return (good: 35, inaccuracy: 110, mistake: 250);
  if (rating < 1000) return (good: 25, inaccuracy: 85, mistake: 200);
  if (rating < 1500) return (good: 18, inaccuracy: 65, mistake: 160);
  return (good: 12, inaccuracy: 50, mistake: 120);
}

MoveQuality classifyMoveLossCp(
  int lossCp, {
  required bool isBestMove,
  int rating = 800,
}) {
  if (isBestMove) return MoveQuality.best;
  final t = lossThresholdsFor(rating);
  if (lossCp <= t.good) return MoveQuality.good;
  if (lossCp <= t.inaccuracy) return MoveQuality.inaccuracy;
  if (lossCp <= t.mistake) return MoveQuality.mistake;
  return MoveQuality.blunder;
}

MoveQuality classifyMoveLoss(int lossCp, {required bool isBestMove}) {
  return classifyMoveLossCp(lossCp, isBestMove: isBestMove);
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
  if (lost <= 0.02 * softness) return MoveQuality.good;
  if (lost <= 0.05 * softness) return MoveQuality.good;
  if (lost <= 0.10 * softness) return MoveQuality.inaccuracy;
  if (lost <= 0.20 * softness) return MoveQuality.mistake;
  return MoveQuality.blunder;
}

bool isFlawlessSequence({
  required int bestCp,
  required int playedCp,
  required bool isBest,
  required int streak,
}) {
  if (!isBest) return false;
  if (playedCp.abs() >= 100000) return false;
  if (playedCp < -80) return false;
  if (bestCp > 500) return false;
  return streak >= 3;
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
      return 0;
  }
}

bool isBrilliantSacrifice({
  required Position before,
  required Position after,
  required NormalMove move,
  required int bestCp,
  required int playedCp,
  required bool isBest,
}) {
  if (!isBest) return false;
  final mover = before.turn;
  final opponent = mover.opposite;
  final piece = before.board.pieceAt(move.from);
  if (piece == null) return false;
  if (piece.role == Role.king || piece.role == Role.pawn) return false;
  final moverMatBefore = _sideMaterial(before, mover);
  final moverMatAfter = _sideMaterial(after, mover);
  final staticLoss = moverMatBefore - moverMatAfter;
  final captured = before.board.pieceAt(move.to);
  final takesEqualOrBigger =
      captured != null && _sacPieceValue(captured.role) >= 2;
  if (staticLoss < 3 && !takesEqualOrBigger) return false;
  final destAttackers = after.board.attacksTo(move.to, opponent);
  if (destAttackers.isEmpty) {
    final givesCheck = after.isCheck;
    final attacksQueen = _attacksEnemyQueen(after, mover, opponent);
    if (!givesCheck && !attacksQueen) return false;
  }
  final defenders = after.board.attacksTo(move.to, mover);
  final hanging = defenders.isEmpty && destAttackers.isNotEmpty;
  final enPrise =
      hanging && _sacPieceValue(piece.role) >= 3 && staticLoss >= 3;
  final givesCheck = after.isCheck;
  if (!enPrise && !givesCheck && destAttackers.isEmpty) return false;
  if (playedCp.abs() >= 100000 || bestCp.abs() >= 100000) {
    if (playedCp <= -100000) return false;
    if (playedCp < 0) return false;
    return true;
  }
  if (playedCp < -120) return false;
  if (bestCp > 400) return false;
  if (bestCp < -300) return false;
  final delta = (playedCp - bestCp).clamp(-100000, 100000);
  if (delta < -30) return false;
  return true;
}

int _sideMaterial(Position position, Side side) {
  var total = 0;
  for (final square in Square.values) {
    final piece = position.board.pieceAt(square);
    if (piece == null) continue;
    if (piece.color != side) continue;
    total += _sacPieceValue(piece.role);
  }
  return total;
}

bool _attacksEnemyQueen(Position after, Side mover, Side opponent) {
  for (final square in Square.values) {
    final piece = after.board.pieceAt(square);
    if (piece == null) continue;
    if (piece.color != opponent) continue;
    if (piece.role != Role.queen) continue;
    if (after.board.attacksTo(square, mover).isNotEmpty) return true;
  }
  return false;
}

