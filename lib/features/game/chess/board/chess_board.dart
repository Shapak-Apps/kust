import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:Kust/features/game/chess/chess_controller.dart';

const Color kLightSquare = Color(0xFFF0E6D2);
const Color kDarkSquare = Color(0xFFB58863);
const Color kHighlight = Color(0x77FFBB00);
const Color kLastMoveHighlight = Color(0x40FFBB00);

class ChessBoard extends ConsumerWidget {
  const ChessBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(chessControllerProvider);
    final flipped = gameState.playerSide == Side.black;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final squareSize = side / 8;

        final ranks = List.generate(8, (i) => flipped ? i : 7 - i);
        final files = List.generate(8, (i) => flipped ? 7 - i : i);

        return SizedBox(
          width: side,
          height: side,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final rank in ranks)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final file in files)
                      _BoardSquare(
                        square: squareAt(file, rank),
                        size: squareSize,
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BoardSquare extends ConsumerWidget {
  const _BoardSquare({required this.square, required this.size});

  final Square square;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(chessControllerProvider);
    final piece = gameState.position.board.pieceAt(square);

    final isLight = (fileOf(square) + rankOf(square)).isEven;
    final isSelected = gameState.selectedSquare == square;
    final isLegalTarget = gameState.legalDestinations.contains(square);
    final isLastMove = gameState.moveSquares.contains(square);

    var background = isLight ? kLightSquare : kDarkSquare;
    if (isLastMove) {
      background = Color.alphaBlend(kLastMoveHighlight, background);
    }
    if (isSelected) {
      background = Color.alphaBlend(kHighlight, background);
    }

    return GestureDetector(
      onTap: () =>
          ref.read(chessControllerProvider.notifier).selectSquare(square),
      child: Container(
        width: size,
        height: size,
        color: background,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (piece != null)
              Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: SvgPicture.asset(_assetForPiece(piece)),
              ),
            if (isLegalTarget && piece == null)
              Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            if (isLegalTarget && piece != null)
              Container(
                margin: EdgeInsets.all(size * 0.05),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.35),
                    width: size * 0.06,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _assetForPiece(Piece piece) {
  final color = piece.color == Side.white ? 'w' : 'b';
  final role = switch (piece.role) {
    Role.king => 'K',
    Role.queen => 'Q',
    Role.rook => 'R',
    Role.bishop => 'B',
    Role.knight => 'N',
    Role.pawn => 'P',
  };
  return 'assets/pieces/$color$role.svg';
}
