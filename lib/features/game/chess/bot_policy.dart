import 'dart:math';

import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:dartchess/dartchess.dart';

class BotPolicy {
  BotPolicy({required this.elo, int? seed}) : _random = Random(seed);

  final int elo;
  final Random _random;

  static const int _engineEloFloor = 1320;
  static const int _engineEloCeiling = 3190;

  int get skillLevel => 20;

  int get uciElo => elo.clamp(_engineEloFloor, _engineEloCeiling);

  double get blunderChance {
    if (elo >= _engineEloFloor) return 0.02;
    final gap = _engineEloFloor - elo;
    return 0.03 + gap / 920 * 0.32;
  }

  Duration get thinkTime {
    if (elo < _engineEloFloor) {
      final fastRange = (elo - 400).clamp(0, 920);
      return Duration(milliseconds: 120 + (fastRange / 920 * 200).round());
    }

    final strongRange = (elo - _engineEloFloor).clamp(0, 680);
    return Duration(milliseconds: 400 + (strongRange / 680 * 800).round());
  }

  bool shouldBlunder() => _random.nextDouble() < blunderChance;

  Move? randomLegalMove(Position position) {
    final allMoves = <Move>[];
    for (final from in position.legalMoves.keys) {
      final destinations = position.legalMoves[from];
      if (destinations == null) continue;
      final piece = position.board.pieceAt(from);
      for (final to in destinations.squares) {
        final isPromotion =
            piece?.role == Role.pawn && (rankOf(to) == 0 || rankOf(to) == 7);
        allMoves.add(
          NormalMove(
            from: from,
            to: to,
            promotion: isPromotion ? Role.queen : null,
          ),
        );
      }
    }
    if (allMoves.isEmpty) return null;
    return allMoves[_random.nextInt(allMoves.length)];
  }
}
