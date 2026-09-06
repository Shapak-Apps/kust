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
const Color kHintHighlight = Color(0x552ECC71);

class ChessBoard extends ConsumerStatefulWidget {
  const ChessBoard({super.key});

  @override
  ConsumerState<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends ConsumerState<ChessBoard>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _captureController;

  Square? _animFrom;
  Square? _animTo;
  Piece? _animPiece;

  Square? _capSquare;
  Piece? _capPiece;

  double _squareSize = 0;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(vsync: this);
    _captureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _captureController.dispose();
    super.dispose();
  }

  Offset _getSquareOffset(Square sq, double size) {
    final file = fileOf(sq);
    final rank = rankOf(sq);

    final dx = (_flipped ? 7 - file : file) * size;
    final dy = (_flipped ? rank : 7 - rank) * size;

    return Offset(dx, dy);
  }

  Square _castlingDisplaySquare(Square target) {
    if (target == Square.h1) return Square.g1;
    if (target == Square.a1) return Square.c1;
    if (target == Square.h8) return Square.g8;
    if (target == Square.a8) return Square.c8;
    return target;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(chessControllerProvider);
    _flipped = gameState.playerSide == Side.black;

    ref.listen<GameState>(chessControllerProvider, (previous, next) {
      if (previous == null) return;

      if (previous.position != next.position) {
        final move = next.lastMove;

        if (move != null) {
          Square visualFrom = move.from;
          Square visualTo = move.to;

          final isForwardCastling =
              (move.from == Square.e1 || move.from == Square.e8) &&
              (move.to == Square.h1 ||
                  move.to == Square.a1 ||
                  move.to == Square.h8 ||
                  move.to == Square.a8);

          final isReverseCastling =
              (move.to == Square.e1 || move.to == Square.e8) &&
              (move.from == Square.h1 ||
                  move.from == Square.a1 ||
                  move.from == Square.h8 ||
                  move.from == Square.a8);

          if (isForwardCastling) {
            visualTo = _castlingDisplaySquare(move.to);
          } else if (isReverseCastling) {
            visualFrom = _castlingDisplaySquare(move.from);
          }

          _animFrom = visualFrom;
          _animTo = visualTo;
          _animPiece =
              next.position.board.pieceAt(move.to) ??
              next.position.board.pieceAt(visualTo) ??
              previous.position.board.pieceAt(visualFrom);

          if (_animPiece != null) {
            final duration = next.wasUndo
                ? const Duration(milliseconds: 150)
                : const Duration(milliseconds: 200);

            _moveController.duration = duration;
            _moveController.reset();
            _moveController.forward();
          }

          if (next.capturedPiece != null && next.capturedSquare != null) {
            _capSquare = next.capturedSquare;
            _capPiece = next.capturedPiece;

            _captureController.reset();
            _captureController.forward();
          } else {
            _capSquare = null;
            _capPiece = null;
          }
        }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        _squareSize = side / 8;

        final ranks = List.generate(8, (i) => _flipped ? i : 7 - i);
        final files = List.generate(8, (i) => _flipped ? 7 - i : i);

        return SizedBox(
          width: side,
          height: side,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final rank in ranks)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final file in files)
                          _buildBoardSquare(squareAt(file, rank), gameState),
                      ],
                    ),
                ],
              ),

              if (_capPiece != null && _capSquare != null)
                Positioned(
                  left: _getSquareOffset(_capSquare!, _squareSize).dx,
                  top: _getSquareOffset(_capSquare!, _squareSize).dy,
                  width: _squareSize,
                  height: _squareSize,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _captureController,
                      builder: (context, child) {
                        final opacity = gameState.wasUndo
                            ? _captureController.value
                            : 1.0 - _captureController.value;

                        return Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(_squareSize * 0.02),
                        child: SvgPicture.asset(_assetForPiece(_capPiece!)),
                      ),
                    ),
                  ),
                ),

              if (_animPiece != null && _animFrom != null && _animTo != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _moveController,
                      builder: (context, child) {
                        final fromOffset = _getSquareOffset(
                          _animFrom!,
                          _squareSize,
                        );
                        final toOffset = _getSquareOffset(
                          _animTo!,
                          _squareSize,
                        );

                        final t = Curves.easeInOut.transform(
                          _moveController.value,
                        );

                        final currentOffset = Offset.lerp(
                          fromOffset,
                          toOffset,
                          t,
                        )!;

                        return Transform.translate(
                          offset: currentOffset,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width: _squareSize,
                              height: _squareSize,
                              child: Padding(
                                padding: EdgeInsets.all(_squareSize * 0.02),
                                child: SvgPicture.asset(
                                  _assetForPiece(_animPiece!),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoardSquare(Square square, GameState gameState) {
    final piece = gameState.position.board.pieceAt(square);

    final isLight = (fileOf(square) + rankOf(square)).isEven;
    final isSelected = gameState.selectedSquare == square;
    final isLegalTarget = gameState.legalDestinations.contains(square);
    final isLastMove = gameState.moveSquares.contains(square);
    final isHint = gameState.hintSquares.contains(square);

    var background = isLight ? kLightSquare : kDarkSquare;

    if (isLastMove) {
      background = Color.alphaBlend(kLastMoveHighlight, background);
    }

    if (isHint) {
      background = Color.alphaBlend(kHintHighlight, background);
    }

    if (isSelected) {
      background = Color.alphaBlend(kHighlight, background);
    }

    final coordinateColor = isLight ? kDarkSquare : kLightSquare;

    bool hidePiece = false;

    if (piece != null) {
      if (_animTo == square && _moveController.isAnimating) {
        hidePiece = true;
      }

      if (_capSquare == square && _captureController.isAnimating) {
        hidePiece = true;
      }
    }

    final showRankLabel = fileOf(square) == (_flipped ? 7 : 0);
    final showFileLabel = rankOf(square) == (_flipped ? 7 : 0);

    return GestureDetector(
      onTap: () =>
          ref.read(chessControllerProvider.notifier).selectSquare(square),
      child: Container(
        width: _squareSize,
        height: _squareSize,
        color: background,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (piece != null && !hidePiece)
              Padding(
                padding: EdgeInsets.all(_squareSize * 0.02),
                child: SvgPicture.asset(_assetForPiece(piece)),
              ),

            if (isLegalTarget && piece == null)
              Container(
                width: _squareSize * 0.28,
                height: _squareSize * 0.28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),

            if (isLegalTarget && piece != null)
              Container(
                margin: EdgeInsets.all(_squareSize * 0.05),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.35),
                    width: _squareSize * 0.06,
                  ),
                ),
              ),

            if (showRankLabel)
              Positioned(
                top: 2,
                left: 3,
                child: Text(
                  (rankOf(square) + 1).toString(),
                  style: TextStyle(
                    fontSize: _squareSize * 0.16,
                    fontWeight: FontWeight.w700,
                    color: coordinateColor,
                  ),
                ),
              ),

            if (showFileLabel)
              Positioned(
                bottom: 2,
                right: 3,
                child: Text(
                  String.fromCharCode('a'.codeUnitAt(0) + fileOf(square)),
                  style: TextStyle(
                    fontSize: _squareSize * 0.16,
                    fontWeight: FontWeight.w700,
                    color: coordinateColor,
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
