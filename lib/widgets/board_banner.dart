import 'package:flutter/material.dart';

import 'package:kust/core/board_theme.dart';
import 'package:kust/core/piece_set.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/piece_image.dart';

/// A corner of the board, in big squares five across, in the theme and
/// pieces picked in settings, fading into the page at the bottom. With
/// [pieces], the bottom two ranks hold the white pawns and R Q K B N.
class BoardBanner extends StatelessWidget {
  const BoardBanner({
    super.key,
    required this.height,
    this.pieces = true,
    this.dim = 0.15,
    this.fadeFrom = 0.7,
  });

  final double height;
  final bool pieces;

  /// How much of the page colour lies over the top of the board, 0..1.
  final double dim;

  /// Where, from the top (0..1), the board starts fading into the page.
  final double fadeFrom;

  /// Squares across: few, so the pieces are big.
  static const files = 5;
  static const _backRank = ['R', 'Q', 'K', 'B', 'N'];

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    final bg = context.k.bg;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: ValueListenableBuilder<BoardTheme>(
          valueListenable: s.boardTheme,
          builder: (context, board, _) => ValueListenableBuilder<PieceSet>(
            valueListenable: s.pieceSet,
            builder: (context, set, _) => LayoutBuilder(
              builder: (context, box) {
                final sq = box.maxWidth / files;
                final ranks = (height / sq).ceil().clamp(1, 8);
                // From the top down to rank 1; the top one is cut when the
                // box is not a whole number of squares tall.
                Widget square(int file, int rank) {
                  final light = (file + rank).isEven;
                  final role = !pieces || rank > 2
                      ? null
                      : rank == 1
                      ? _backRank[file]
                      : 'P';
                  return Container(
                    width: sq,
                    height: sq,
                    color: light ? board.light : board.dark,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (board.grain)
                          CustomPaint(
                            painter: WoodGrainPainter(
                              seed: rank * 8 + file,
                              light: light,
                            ),
                          ),
                        if (role != null)
                          Padding(
                            padding: EdgeInsets.all(sq * 0.06),
                            child: PieceImage(set.asset('w', role)),
                          ),
                      ],
                    ),
                  );
                }

                return ClipRect(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Column(
                          children: [
                            for (var rank = ranks; rank >= 1; rank--)
                              Row(
                                children: [
                                  for (var f = 0; f < files; f++)
                                    square(f, rank),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                bg.withValues(alpha: dim),
                                bg.withValues(alpha: dim),
                                bg,
                              ],
                              stops: [0, fadeFrom, 1],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
