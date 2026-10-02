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

  bool get isBest => quality == MoveQuality.best || quality == MoveQuality.brilliant;

  String get bannerText {
    if (isBest) return '$playedSan · ${quality.shortLabel} move';
    return '$playedSan was ${quality.shortLabel} · $bestSan was best';
  }
}

MoveQuality classifyMoveLoss(int lossCp, {required bool isBestMove}) {
  if (isBestMove) return MoveQuality.best;
  if (lossCp <= 15) return MoveQuality.good;
  if (lossCp <= 60) return MoveQuality.inaccuracy;
  if (lossCp <= 150) return MoveQuality.mistake;
  return MoveQuality.blunder;
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
  if (piece.role == Role.king) return false;
  if (playedCp.abs() >= 100000 || bestCp.abs() >= 100000) {
    final mated = playedCp <= -100000;
    if (mated) return false;
  } else {
    if (playedCp < -150) return false;
    if (bestCp > 600) return false;
  }
  final destAttackers = after.board.attacksTo(move.to, opponent);
  final destHung = destAttackers.isNotEmpty;
  final captured = before.board.pieceAt(move.to);
  final sacValue = _sacPieceValue(piece.role);
  final isMinorPlus = sacValue >= 3;
  if (!isMinorPlus) return false;
  if (!destHung && captured == null) return false;
  if (destHung) return true;
  if (captured != null && _sacPieceValue(captured.role) >= 3) return true;
  return false;
}

