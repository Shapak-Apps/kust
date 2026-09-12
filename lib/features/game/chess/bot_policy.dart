import 'dart:math';

import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:dartchess/dartchess.dart';

class BotPolicy {
  BotPolicy({required this.elo, int? seed}) : _random = Random(seed);

  final int elo;
  final Random _random;

  double get blunderChance => ((1400 - elo) / 1450).clamp(0.04, 0.60);

  int get skillLevel => (((elo - 600) / 800) * 20).round().clamp(0, 20);

  int? get uciElo => elo >= 1320 ? elo : null;

  Duration get thinkTime => Duration(milliseconds: 250 + skillLevel * 35);

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
