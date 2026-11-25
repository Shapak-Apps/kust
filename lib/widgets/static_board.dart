import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/core/board_theme.dart';
import 'package:kust/core/piece_set.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/board/chess_board.dart'
    show kLastMoveHighlight;
import 'package:kust/widgets/piece_image.dart';

/// A board that only shows [position], in the colours and pieces from
/// settings, with [highlight] squares marked, seen from Black when
/// [flipped]. Square; it fills the width it is given.
class StaticBoard extends StatelessWidget {
  const StaticBoard({
    super.key,
    required this.position,
    this.flipped = false,
    this.highlight = const [],
    this.radius = 4,
    this.shadow = true,
  });

  final Position position;
  final bool flipped;
  final List<Square> highlight;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: shadow
                ? const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: ValueListenableBuilder<BoardTheme>(
              valueListenable: s.boardTheme,
              builder: (context, theme, _) => ValueListenableBuilder<PieceSet>(
                valueListenable: s.pieceSet,
                builder: (context, set, _) => _squares(theme, set),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _squares(BoardTheme theme, PieceSet set) {
    final board = position.board;
    return Column(
      children: [
        for (var row = 0; row < 8; row++)
          Expanded(
            child: Row(
              children: [
                for (var col = 0; col < 8; col++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final square = Square.fromCoords(
                          File(flipped ? 7 - col : col),
                          Rank(flipped ? row : 7 - row),
                        );
                        var colour = (col + row).isEven
                            ? theme.light
                            : theme.dark;
                        if (highlight.contains(square)) {
                          colour = Color.alphaBlend(kLastMoveHighlight, colour);
                        }
                        final piece = board.pieceAt(square);
                        return ColoredBox(
                          color: colour,
                          child: piece == null
                              ? const SizedBox.expand()
                              : PieceImage(
                                  set.asset(
                                    piece.color == Side.white ? 'w' : 'b',
                                    piece.role.uppercaseLetter,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
