import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:Kust/features/game/chess/chess_controller.dart';
import 'package:Kust/features/game/chess/move_feedback.dart';
import 'package:Kust/features/game/move_feedback_badge.dart';

const Color kLightSquare = Color(0xFFF0E6D2);
const Color kDarkSquare = Color(0xFFB58863);
const Color kHighlight = Color(0x77FFBB00);
const Color kLastMoveHighlight = Color(0x40FFBB00);
const Color kHintHighlight = Color(0x552ECC71);

final Color kCheckSquareHighlight = Colors.red.withValues(alpha: 0.9);

Square _castlingDisplaySquare(Square target) {
  if (target == Square.h1) return Square.g1;
  if (target == Square.a1) return Square.c1;
  if (target == Square.h8) return Square.g8;
  if (target == Square.a8) return Square.c8;
  return target;
}

class _BoardView {
  const _BoardView({
    required this.position,
    required this.mode,
    required this.playerSide,
    required this.selected,
    required this.legal,
    required this.moveSquares,
    required this.hints,
    required this.blocked,
    required this.analysis,
    required this.wasUndo,
    required this.badgeFeedback,
    required this.badgeSquare,
  });

  factory _BoardView.from(GameState g) {
    MoveFeedback? feedback;
    Square? square;

    if (g.practiceMode &&
        g.moveFeedbackEnabled &&
        !g.isSelfAnalysisActive &&
        g.moves.isNotEmpty) {
      for (var i = g.moves.length - 1; i >= 0; i--) {
        final record = g.moves[i];
        if (record.feedback == null) continue;
        if (g.mode == GameMode.bot && record.side != g.playerSide) continue;
        feedback = record.feedback;
        square = _castlingDisplaySquare(record.move.to);
        break;
      }
    }

    return _BoardView(
      position: g.displayPosition,
      mode: g.mode,
      playerSide: g.playerSide,
      selected: g.displaySelectedSquare,
      legal: g.displayLegalDestinations,
      moveSquares: g.displayMoveSquares,
      hints: g.displayHintSquares,
      blocked:
          g.isBotThinking ||
          g.status != GameStatus.playing ||
          g.isSelfAnalysisActive,
      analysis: g.isSelfAnalysisActive,
      wasUndo: g.wasUndo,
      badgeFeedback: feedback,
      badgeSquare: square,
    );
  }

  final Position position;
  final GameMode mode;
  final Side playerSide;
  final Square? selected;
  final Set<Square> legal;
  final List<Square> moveSquares;
  final Set<Square> hints;
  final bool blocked;
  final bool analysis;
  final bool wasUndo;
  final MoveFeedback? badgeFeedback;
  final Square? badgeSquare;

  @override
  bool operator ==(Object other) {
    return other is _BoardView &&
        identical(position, other.position) &&
        mode == other.mode &&
        playerSide == other.playerSide &&
        selected == other.selected &&
        setEquals(legal, other.legal) &&
        listEquals(moveSquares, other.moveSquares) &&
        setEquals(hints, other.hints) &&
        blocked == other.blocked &&
        analysis == other.analysis &&
        wasUndo == other.wasUndo &&
        identical(badgeFeedback, other.badgeFeedback) &&
        badgeSquare == other.badgeSquare;
  }

  @override
  int get hashCode => Object.hash(
    position,
    mode,
    playerSide,
    selected,
    legal.length,
    moveSquares.length,
    hints.length,
    blocked,
    analysis,
    wasUndo,
    badgeFeedback,
    badgeSquare,
  );
}

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

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _captureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _moveController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _animPiece != null) {
        setState(() => _animPiece = null);
      }
    });
    _captureController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _capPiece != null) {
        setState(() {
          _capPiece = null;
          _capSquare = null;
        });
      }
    });
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

  void _handleTap(Offset local) {
    if (_squareSize <= 0) return;
    final col = (local.dx ~/ _squareSize).clamp(0, 7).toInt();
    final row = (local.dy ~/ _squareSize).clamp(0, 7).toInt();
    final file = _flipped ? 7 - col : col;
    final rank = _flipped ? row : 7 - row;
    ref.read(chessControllerProvider.notifier).selectSquare(
      squareAt(file, rank),
    );
  }

  Square? _checkedKingSquare(Position position) {
    if (!position.isCheck) return null;
    for (final square in Square.values) {
      final piece = position.board.pieceAt(square);
      if (piece != null &&
          piece.role == Role.king &&
          piece.color == position.turn) {
        return square;
      }
    }
    return null;
  }

  Widget _buildRotatedPiece(Piece piece, _BoardView view) {
    final Widget svg = SvgPicture.asset(_assetForPiece(piece));

    if (view.mode == GameMode.local && view.position.turn == Side.black) {
      return RotatedBox(quarterTurns: 2, child: svg);
    }

    return svg;
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(chessControllerProvider.select(_BoardView.from));
    final displayPosition = view.position;

    _flipped = view.mode == GameMode.local
        ? false
        : view.playerSide == Side.black;

    ref.listen<GameState>(chessControllerProvider, (previous, next) {
      if (previous == null) return;

      if (previous.isSelfAnalysisActive || next.isSelfAnalysisActive) return;

      if (!identical(previous.position, next.position)) {
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
                ? const Duration(milliseconds: 120)
                : const Duration(milliseconds: 200);

            _moveController.duration = duration;
            _captureController.duration = duration;
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
        } else {
          if (_animPiece != null || _capPiece != null) {
            setState(() {
              _animPiece = null;
              _capPiece = null;
              _capSquare = null;
            });
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
        final checkedKing = _checkedKingSquare(displayPosition);

        return AbsorbPointer(
          absorbing: view.blocked,
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleTap(details.localPosition),
                  child: RepaintBoundary(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final rank in ranks)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final file in files)
                                _buildBoardSquare(
                                  squareAt(file, rank),
                                  view,
                                  checkedKing,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                if (!view.analysis && _capPiece != null && _capSquare != null)
                  Positioned(
                    left: _getSquareOffset(_capSquare!, _squareSize).dx,
                    top: _getSquareOffset(_capSquare!, _squareSize).dy,
                    width: _squareSize,
                    height: _squareSize,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _captureController,
                        builder: (context, child) {
                          final opacity = view.wasUndo
                              ? _captureController.value
                              : 1.0 - _captureController.value;

                          return Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: child,
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(_squareSize * 0.02),
                          child: _buildRotatedPiece(_capPiece!, view),
                        ),
                      ),
                    ),
                  ),

                if (!view.analysis &&
                    _animPiece != null &&
                    _animFrom != null &&
                    _animTo != null)
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

                          final curve = view.wasUndo
                              ? Curves.easeOut
                              : Curves.easeInOut;

                          final t = curve.transform(_moveController.value);

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
                                  child: _buildRotatedPiece(_animPiece!, view),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                if (view.badgeFeedback != null && view.badgeSquare != null)
                  Positioned(
                    left: _getSquareOffset(view.badgeSquare!, _squareSize).dx,
                    top: _getSquareOffset(view.badgeSquare!, _squareSize).dy,
                    width: _squareSize,
                    height: _squareSize,
                    child: IgnorePointer(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            right: -_squareSize * 0.22,
                            top: -_squareSize * 0.22,
                            child: MoveFeedbackBadge(
                              feedback: view.badgeFeedback!,
                              size: _squareSize * 0.52,
                              key: ValueKey(
                                '${view.badgeFeedback!.playedSan}_${view.badgeFeedback!.quality}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoardSquare(
    Square square,
    _BoardView view,
    Square? checkedKing,
  ) {
    final piece = view.position.board.pieceAt(square);

    final isLight = (fileOf(square) + rankOf(square)).isEven;
    final isSelected = view.selected == square;
    final isLegalTarget = view.legal.contains(square);
    final isLastMove = view.moveSquares.contains(square);
    final isHint = view.hints.contains(square);
    final isCheckSquare = checkedKing == square;

    var background = isLight ? kLightSquare : kDarkSquare;

    if (isLastMove) {
      background = Color.alphaBlend(kLastMoveHighlight, background);
    }

    if (isHint) {
      background = Color.alphaBlend(kHintHighlight, background);
    }

    if (isCheckSquare) {
      background = Color.alphaBlend(kCheckSquareHighlight, background);
    }

    if (isSelected) {
      background = Color.alphaBlend(kHighlight, background);
    }

    final coordinateColor = isLight ? kDarkSquare : kLightSquare;

    bool hidePiece = false;

    if (piece != null) {
      if (_animTo == square && _moveController.isAnimating && !view.analysis) {
        hidePiece = true;
      }

      if (_capSquare == square &&
          _captureController.isAnimating &&
          !view.analysis) {
        hidePiece = true;
      }
    }

    final showRankLabel = fileOf(square) == (_flipped ? 7 : 0);
    final showFileLabel = rankOf(square) == (_flipped ? 7 : 0);

    return Container(
      width: _squareSize,
      height: _squareSize,
      color: background,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (piece != null && !hidePiece)
            Padding(
              padding: EdgeInsets.all(_squareSize * 0.02),
              child: _buildRotatedPiece(piece, view),
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
