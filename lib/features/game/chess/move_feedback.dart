import 'package:flutter/material.dart';

/// Move feedback colors (also used for badge circles).
/// FFDD00 inaccuracy, 00FF8C brilliant, DB0000 blunder,
/// 00B138 best, 4CD23E good, 6385ED flawless.
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

  /// SVG glyph from assets/icons/moves (white shape, drawn on colored circle).
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
}

/// Feedback attached to a single played move.
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

  /// Line shown under the moves history bar.
  /// e.g. "Nf3 · best move" or "a4 was inaccuracy · Nc3 was best".
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
