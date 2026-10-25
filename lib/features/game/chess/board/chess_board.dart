import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart'
    show listEquals, setEquals, visibleForTesting;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kust/widgets/piece_image.dart';
import 'package:kust/core/board_theme.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/board/board_geometry.dart';
import 'package:kust/features/game/chess/board/board_squares_painter.dart';
import 'package:kust/features/game/chess/board/move_arrow.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/move_feedback.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/game/feedback_glow.dart';
import 'package:kust/features/game/move_feedback_badge.dart';

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

bool _isCornerSquare(Square s) {
  return s == Square.a1 || s == Square.h1 || s == Square.a8 || s == Square.h8;
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
    required this.badgeIndex,
    required this.pendingPromotion,
  });

  factory _BoardView.from(GameState g) {
    MoveFeedback? feedback;
    Square? square;
    int? index;

    if (g.practiceMode &&
        g.moveFeedbackEnabled &&
        !g.isSelfAnalysisActive &&
        g.moves.isNotEmpty) {
      int? lastPlayerIndex;
      for (var i = g.moves.length - 1; i >= 0; i--) {
        if (g.mode == GameMode.bot && g.moves[i].side != g.playerSide) {
          continue;
        }
        lastPlayerIndex = i;
        break;
      }
      if (lastPlayerIndex != null) {
        final record = g.moves[lastPlayerIndex];
        final landed = _castlingDisplaySquare(record.move.to);
        // Once the piece is taken the rating no longer belongs to the square.
        final stillThere =
            g.displayPosition.board.pieceAt(landed)?.color == record.side;
        if (record.feedback != null && stillThere) {
          feedback = record.feedback;
          square = _castlingDisplaySquare(record.move.to);
          index = lastPlayerIndex;
        }
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
      badgeIndex: index,
      pendingPromotion:
          !g.isSelfAnalysisActive && g.status == GameStatus.playing
          ? g.pendingPromotion
          : null,
    );
  }

  final Position position;
  final GameMode mode;
  final Side playerSide;
  final Square? selected;
  final Set<Square> legal;
  final List<Square> moveSquares;
  final Set<Square> hints;

  /// The hinted move as an arrow: the hint holds its squares in order,
  /// from first.
  ({Square from, Square to})? get hintArrow {
    if (hints.length != 2) return null;
    return (from: hints.first, to: hints.last);
  }

  final bool blocked;
  final bool analysis;
  final bool wasUndo;
  final MoveFeedback? badgeFeedback;
  final Square? badgeSquare;
  final int? badgeIndex;
  final ({Square from, Square to})? pendingPromotion;

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
        badgeSquare == other.badgeSquare &&
        badgeIndex == other.badgeIndex &&
        pendingPromotion == other.pendingPromotion;
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
    badgeIndex,
    pendingPromotion,
  );
}

class ChessBoard extends ConsumerStatefulWidget {
  const ChessBoard({super.key});

  @override
  ConsumerState<ChessBoard> createState() => _ChessBoardState();
}

/// How long a piece takes to glide [squares] squares: short hops are
/// quick, long slides a little longer, so every move feels the same speed.
Duration glideDuration(double squares) =>
    Duration(milliseconds: (150 + 28 * squares).clamp(170, 320).round());

const Duration _undoDuration = Duration(milliseconds: 120);

/// How long a dropped piece takes to fly back when the move was not legal.
const Duration _snapBackDuration = Duration(milliseconds: 170);

/// How far above the finger a dragged piece floats, in squares, so the
/// finger does not hide it.
const double _dragLift = 0.3;

class _ChessBoardState extends ConsumerState<ChessBoard>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _captureController;

  Square? _animFrom;
  Square? _animTo;
  Piece? _animPiece;

  Square? _capSquare;
  Piece? _capPiece;

  /// Whether the captured piece goes at once (the mover was dropped there)
  /// rather than as the mover arrives.
  bool _capAtOnce = false;

  /// The rook sliding along with the king while castling.
  Square? _rookFrom;
  Square? _rookTo;
  Piece? _rookPiece;

  /// The piece being dragged, where it came from and where the finger is.
  Square? _dragFrom;
  Piece? _dragPiece;
  final ValueNotifier<Offset?> _dragAt = ValueNotifier(null);

  /// The square the dragged piece is over, ringed.
  Square? _hover;

  /// A move made by dropping: it is already in place, so it does not glide.
  ({Square from, Square to})? _dropped;

  /// A dropped piece flying back to [_snapSquare] after an illegal drop.
  late AnimationController _snapController;
  Square? _snapSquare;
  Piece? _snapPiece;
  Offset _snapStart = Offset.zero;

  double _squareSize = 0;
  bool _flipped = false;
  final Map<Square, ({BoardSquareProps props, Widget widget})> _cells = {};

  void _onBoardTheme() {
    if (mounted) setState(() {});
  }

  /// The cached squares hold the old pieces, so they are built again.
  void _onPieceSet() {
    if (!mounted) return;
    setState(_cells.clear);
  }

  @override
  void initState() {
    super.initState();
    AppSettings.instance.boardTheme.addListener(_onBoardTheme);
    AppSettings.instance.pieceSet.addListener(_onPieceSet);

    _moveController = AnimationController(
      vsync: this,
      duration: glideDuration(1),
    );
    _captureController = AnimationController(
      vsync: this,
      duration: glideDuration(1),
    );
    _snapController = AnimationController(
      vsync: this,
      duration: _snapBackDuration,
    );
    _snapController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _snapPiece != null) {
        setState(() {
          _snapPiece = null;
          _snapSquare = null;
        });
      }
    });

    _moveController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          (_animPiece != null || _rookPiece != null)) {
        setState(() {
          _animPiece = null;
          _rookPiece = null;
          _rookFrom = null;
          _rookTo = null;
        });
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
    AppSettings.instance.boardTheme.removeListener(_onBoardTheme);
    AppSettings.instance.pieceSet.removeListener(_onPieceSet);
    _moveController.dispose();
    _captureController.dispose();
    _snapController.dispose();
    _dragAt.dispose();
    super.dispose();
  }

  Offset _getSquareOffset(Square sq, double size) {
    final file = fileOf(sq);
    final rank = rankOf(sq);

    final dx = (_flipped ? 7 - file : file) * size;
    final dy = (_flipped ? rank : 7 - rank) * size;

    return Offset(dx, dy);
  }

  /// The square at [local] on the board, or null off the board.
  Square? _squareAtOffset(Offset local) {
    if (_squareSize <= 0) return null;
    final col = (local.dx / _squareSize).floor();
    final row = (local.dy / _squareSize).floor();
    if (col < 0 || col > 7 || row < 0 || row > 7) return null;
    final file = _flipped ? 7 - col : col;
    final rank = _flipped ? row : 7 - row;
    return squareAt(file, rank);
  }

  void _handleTap(Offset local) {
    final square = _squareAtOffset(local);
    if (square == null) return;
    ref.read(chessControllerProvider.notifier).selectSquare(square);
  }

  /// Where the dragged piece's centre is for a finger at [finger].
  Offset _pieceCentre(Offset finger) =>
      finger - Offset(0, _squareSize * _dragLift);

  void _onDragStart(DragStartDetails details) {
    final square = _squareAtOffset(details.localPosition);
    if (square == null) return;
    final controller = ref.read(chessControllerProvider.notifier);
    if (!controller.pickUp(square)) return;
    final piece = ref
        .read(chessControllerProvider)
        .position
        .board
        .pieceAt(square);
    if (piece == null) return;
    SoundService.instance.buzz();
    _snapController.stop();
    setState(() {
      _dragFrom = square;
      _dragPiece = piece;
      _snapPiece = null;
      _hover = square;
    });
    _dragAt.value = details.localPosition;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dragFrom == null) return;
    _dragAt.value = details.localPosition;
    final over = _squareAtOffset(_pieceCentre(details.localPosition));
    if (over != _hover) setState(() => _hover = over);
  }

  void _onDragEnd([DragEndDetails? _]) {
    final from = _dragFrom;
    final piece = _dragPiece;
    final at = _dragAt.value;
    if (from == null || piece == null || at == null) return;
    final target = _squareAtOffset(_pieceCentre(at));

    var played = false;
    if (target != null && target != from) {
      _dropped = (from: from, to: target);
      played = ref.read(chessControllerProvider.notifier).dropOn(target);
      if (!played) _dropped = null;
    }

    setState(() {
      _dragFrom = null;
      _dragPiece = null;
      _hover = null;
      if (!played) {
        // Fly back to where it came from.
        _snapSquare = from;
        _snapPiece = piece;
        _snapStart =
            _pieceCentre(at) - Offset(_squareSize / 2, _squareSize / 2);
      }
    });
    _dragAt.value = null;
    if (!played) _snapController.forward(from: 0);
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
    final Widget svg = PieceImage(_assetForPiece(piece));

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

          final fromHome = move.from == Square.e1 || move.from == Square.e8;
          final toHome = move.to == Square.e1 || move.to == Square.e8;

          final isForwardCastling =
              !next.wasUndo &&
              fromHome &&
              _isCornerSquare(move.to) &&
              previous.position.board.pieceAt(move.from)?.role == Role.king;

          final isReverseCastling =
              next.wasUndo &&
              toHome &&
              _isCornerSquare(move.from) &&
              next.position.board.pieceAt(move.to)?.role == Role.king;

          // The rook slides beside the king: from its corner to the square
          // the king crossed, or back again when undoing.
          _rookPiece = null;
          if (isForwardCastling) {
            visualTo = _castlingDisplaySquare(move.to);
            _rookFrom = move.to;
            _rookTo = _rookCastledSquare(move.to);
            _rookPiece = next.position.board.pieceAt(_rookTo!);
          } else if (isReverseCastling) {
            visualFrom = _castlingDisplaySquare(move.from);
            _rookFrom = _rookCastledSquare(move.from);
            _rookTo = move.from;
            _rookPiece = next.position.board.pieceAt(_rookTo!);
          }

          // A dropped piece is already where it belongs: no glide.
          final dropped = _dropped;
          _dropped = null;
          final wasDropped =
              dropped != null &&
              dropped.from == move.from &&
              (dropped.to == move.to || dropped.to == visualTo);

          _animFrom = visualFrom;
          _animTo = visualTo;
          _animPiece = wasDropped
              ? null
              : next.position.board.pieceAt(move.to) ??
                    next.position.board.pieceAt(visualTo) ??
                    previous.position.board.pieceAt(visualFrom);

          final distance = math.sqrt(
            math.pow(fileOf(visualTo) - fileOf(visualFrom), 2) +
                math.pow(rankOf(visualTo) - rankOf(visualFrom), 2),
          );
          final duration = next.wasUndo
              ? _undoDuration
              : glideDuration(distance.toDouble());
          if (_animPiece != null || _rookPiece != null) {
            _moveController.duration = duration;
            _moveController.forward(from: 0);
          }

          if (next.capturedPiece != null && next.capturedSquare != null) {
            _capSquare = next.capturedSquare;
            _capPiece = next.capturedPiece;
            _capAtOnce = wasDropped || next.wasUndo;
            _captureController.duration = wasDropped
                ? const Duration(milliseconds: 140)
                : duration;
            _captureController.forward(from: 0);
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
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final colors = [
          for (final rank in ranks)
            for (final file in files)
              _squareColor(squareAt(file, rank), view, checkedKing),
        ];
        final badgeSquare = view.badgeSquare;
        final badgeFeedback = view.badgeFeedback;

        return AbsorbPointer(
          absorbing: view.blocked,
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              children: [
                // Every child of this stack is keyed: pieces in flight come
                // and go above the grid, and without keys the layers after
                // them would be rebuilt, replaying the feedback animations.

                // Square colours in one pass on whole pixels; the squares
                // above are transparent and only hold pieces and markers.
                Positioned.fill(
                  key: const ValueKey('board_colours'),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: BoardSquaresPainter(
                        colors: colors,
                        devicePixelRatio: dpr,
                      ),
                    ),
                  ),
                ),

                if (badgeFeedback != null && badgeSquare != null)
                  Positioned.fill(
                    key: const ValueKey('feedback_glow'),
                    child: IgnorePointer(
                      child: FeedbackGlow(
                        key: ValueKey('glow_${view.badgeIndex}'),
                        color: badgeFeedback.quality.color,
                        row: ranks.indexOf(rankOf(badgeSquare)),
                        col: files.indexOf(fileOf(badgeSquare)),
                      ),
                    ),
                  ),

                GestureDetector(
                  key: const ValueKey('board_grid'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleTap(details.localPosition),
                  // Pick up the piece where the finger first touched, not
                  // where the drag was recognised a few pixels later.
                  dragStartBehavior: DragStartBehavior.down,
                  onPanStart: _onDragStart,
                  onPanUpdate: _onDragUpdate,
                  onPanEnd: _onDragEnd,
                  onPanCancel: _onDragEnd,
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
                    key: const ValueKey('captured_piece'),
                    left: _getSquareOffset(_capSquare!, _squareSize).dx,
                    top: _getSquareOffset(_capSquare!, _squareSize).dy,
                    width: _squareSize,
                    height: _squareSize,
                    child: IgnorePointer(
                      // The piece is built once; each frame only changes
                      // its opacity and scale on its own layer.
                      child: AnimatedBuilder(
                        animation: _captureController,
                        child: RepaintBoundary(
                          child: Padding(
                            padding: EdgeInsets.all(_squareSize * 0.02),
                            child: _buildRotatedPiece(_capPiece!, view),
                          ),
                        ),
                        builder: (context, child) {
                          // Taken as the mover arrives, not before.
                          final t =
                              (_capAtOnce
                                      ? Curves.easeIn
                                      : const Interval(
                                          0.55,
                                          1,
                                          curve: Curves.easeIn,
                                        ))
                                  .transform(_captureController.value);
                          final visible = view.wasUndo ? t : 1.0 - t;
                          return Opacity(
                            opacity: visible.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.6 + 0.4 * visible.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                if (!view.analysis &&
                    _animPiece != null &&
                    _animFrom != null &&
                    _animTo != null)
                  Positioned.fill(
                    key: const ValueKey('moving_piece'),
                    child: IgnorePointer(
                      // The piece is built once and lives on its own layer,
                      // so every frame only moves that layer: no widget
                      // rebuilds and no SVG work while it glides.
                      child: AnimatedBuilder(
                        animation: _moveController,
                        child: RepaintBoundary(
                          child: SizedBox(
                            width: _squareSize,
                            height: _squareSize,
                            child: Padding(
                              padding: EdgeInsets.all(_squareSize * 0.02),
                              child: _buildRotatedPiece(_animPiece!, view),
                            ),
                          ),
                        ),
                        builder: (context, child) {
                          final from = _getSquareOffset(
                            _animFrom!,
                            _squareSize,
                          );
                          final to = _getSquareOffset(_animTo!, _squareSize);
                          final progress = _moveController.value;
                          final t =
                              (view.wasUndo
                                      ? Curves.easeOut
                                      : Curves.easeOutCubic)
                                  .transform(progress);
                          // A slight lift mid-flight, none when undoing.
                          final lift = view.wasUndo
                              ? 1.0
                              : 1.0 + 0.06 * math.sin(math.pi * progress);

                          return Align(
                            alignment: Alignment.topLeft,
                            child: Transform.translate(
                              offset: Offset.lerp(from, to, t)!,
                              child: Transform.scale(scale: lift, child: child),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                if (!view.analysis &&
                    _rookPiece != null &&
                    _rookFrom != null &&
                    _rookTo != null)
                  Positioned.fill(
                    key: const ValueKey('moving_rook'),
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _moveController,
                        child: RepaintBoundary(
                          child: SizedBox(
                            width: _squareSize,
                            height: _squareSize,
                            child: Padding(
                              padding: EdgeInsets.all(_squareSize * 0.02),
                              child: _buildRotatedPiece(_rookPiece!, view),
                            ),
                          ),
                        ),
                        builder: (context, child) {
                          final t = Curves.easeOutCubic.transform(
                            _moveController.value,
                          );
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Transform.translate(
                              offset: Offset.lerp(
                                _getSquareOffset(_rookFrom!, _squareSize),
                                _getSquareOffset(_rookTo!, _squareSize),
                                t,
                              )!,
                              child: child,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                if (view.hintArrow != null)
                  Positioned.fill(
                    key: const ValueKey('hint_arrow'),
                    child: MoveArrow(
                      fromRow: ranks.indexOf(rankOf(view.hintArrow!.from)),
                      fromCol: files.indexOf(fileOf(view.hintArrow!.from)),
                      toRow: ranks.indexOf(rankOf(view.hintArrow!.to)),
                      toCol: files.indexOf(fileOf(view.hintArrow!.to)),
                    ),
                  ),

                if (_dragPiece != null && _hover != null)
                  Positioned(
                    key: const ValueKey('drag_hover'),
                    left: _getSquareOffset(_hover!, _squareSize).dx,
                    top: _getSquareOffset(_hover!, _squareSize).dy,
                    width: _squareSize,
                    height: _squareSize,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.75),
                            width: _squareSize * 0.06,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_dragPiece != null)
                  Positioned.fill(
                    key: const ValueKey('dragged_piece'),
                    child: IgnorePointer(
                      // Built once; each finger move only shifts its layer.
                      child: ValueListenableBuilder<Offset?>(
                        valueListenable: _dragAt,
                        child: RepaintBoundary(
                          child: SizedBox(
                            width: _squareSize,
                            height: _squareSize,
                            child: _buildRotatedPiece(_dragPiece!, view),
                          ),
                        ),
                        builder: (context, at, child) {
                          if (at == null) return const SizedBox.shrink();
                          final centre = _pieceCentre(at);
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Transform.translate(
                              offset:
                                  centre -
                                  Offset(_squareSize / 2, _squareSize / 2),
                              child: Transform.scale(scale: 1.18, child: child),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                if (_snapPiece != null && _snapSquare != null)
                  Positioned.fill(
                    key: const ValueKey('snapping_piece'),
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _snapController,
                        child: RepaintBoundary(
                          child: SizedBox(
                            width: _squareSize,
                            height: _squareSize,
                            child: Padding(
                              padding: EdgeInsets.all(_squareSize * 0.02),
                              child: _buildRotatedPiece(_snapPiece!, view),
                            ),
                          ),
                        ),
                        builder: (context, child) {
                          final t = Curves.easeOutCubic.transform(
                            _snapController.value,
                          );
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Transform.translate(
                              offset: Offset.lerp(
                                _snapStart,
                                _getSquareOffset(_snapSquare!, _squareSize),
                                t,
                              )!,
                              child: Transform.scale(
                                scale: 1.18 - 0.18 * t,
                                child: child,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                if (view.pendingPromotion != null)
                  Positioned.fill(
                    key: const ValueKey('promotion'),
                    child: _PromotionPicker(
                      color: displayPosition.turn,
                      rotated:
                          view.mode == GameMode.local &&
                          displayPosition.turn == Side.black,
                      squareSize: _squareSize,
                      onPick: (role) => ref
                          .read(chessControllerProvider.notifier)
                          .completePromotion(role),
                      onCancel: () => ref
                          .read(chessControllerProvider.notifier)
                          .cancelPromotion(),
                    ),
                  ),

                if (view.badgeFeedback != null && view.badgeSquare != null)
                  Positioned(
                    key: const ValueKey('feedback_badge'),
                    left: _getSquareOffset(view.badgeSquare!, _squareSize).dx,
                    top: _getSquareOffset(view.badgeSquare!, _squareSize).dy,
                    width: _squareSize,
                    height: _squareSize,
                    child: IgnorePointer(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            // On the rightmost column the badge would run off
                            // the screen, so it sits on the left corner there.
                            right: _onRightEdge(view.badgeSquare!)
                                ? null
                                : -_squareSize * 0.22,
                            left: _onRightEdge(view.badgeSquare!)
                                ? -_squareSize * 0.22
                                : null,
                            top: -_squareSize * 0.22,
                            child: MoveFeedbackBadge(
                              feedback: view.badgeFeedback!,
                              size: _squareSize * 0.52,
                              key: ValueKey(
                                '${view.badgeIndex}_${view.badgeFeedback!.playedSan}_${view.badgeFeedback!.quality}',
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

  /// Where the rook from [corner] stands once castled: beside the king.
  Square _rookCastledSquare(Square corner) =>
      squareAt(fileOf(corner) == 7 ? 5 : 3, rankOf(corner));

  /// Whether [square] is shown in the rightmost column.
  bool _onRightEdge(Square square) => fileOf(square) == (_flipped ? 0 : 7);

  /// The colour of [square]: its own, with any highlight on top.
  Color _squareColor(Square square, _BoardView view, Square? checkedKing) {
    // a1 is a dark square, so light squares have an odd file + rank sum.
    final isLight = (fileOf(square) + rankOf(square)).isOdd;
    final theme = AppSettings.instance.boardTheme.value;
    var background = isLight ? theme.light : theme.dark;
    if (view.moveSquares.contains(square)) {
      background = Color.alphaBlend(kLastMoveHighlight, background);
    }
    if (checkedKing == square) {
      background = Color.alphaBlend(kCheckSquareHighlight, background);
    }
    if (view.selected == square) {
      background = Color.alphaBlend(kHighlight, background);
    }
    return background;
  }

  Widget _buildBoardSquare(
    Square square,
    _BoardView view,
    Square? checkedKing,
  ) {
    final piece = view.position.board.pieceAt(square);
    final isLight = (fileOf(square) + rankOf(square)).isOdd;
    final isLegalTarget = view.legal.contains(square);
    final theme = AppSettings.instance.boardTheme.value;
    final background = _squareColor(square, view, checkedKing);

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

      if (_rookTo == square && _rookPiece != null && !view.analysis) {
        hidePiece = true;
      }

      // Lifted by the finger, or flying back after an illegal drop.
      if (_dragFrom == square || _snapSquare == square) hidePiece = true;
    }

    final props = BoardSquareProps(
      square: square,
      size: _squareSize,
      background: background,
      coordinateColor: isLight ? theme.dark : theme.light,
      grain: theme.grain,
      piece: hidePiece ? null : piece,
      hasPieceUnderneath: piece != null,
      isLegalTarget: isLegalTarget,
      rotatePiece:
          view.mode == GameMode.local && view.position.turn == Side.black,
      showRankLabel: fileOf(square) == (_flipped ? 7 : 0),
      showFileLabel: rankOf(square) == (_flipped ? 7 : 0),
    );

    // Reuse the very same widget when a square looks the same as before.
    // Flutter skips rebuilding an identical widget, so a move only rebuilds
    // the squares that changed instead of all 64.
    final cached = _cells[square];
    if (cached != null && cached.props == props) return cached.widget;
    final widget = BoardSquareCell(props: props);
    _cells[square] = (props: props, widget: widget);
    return widget;
  }
}

/// Everything that decides how one square looks. Compared by value.
@immutable
class BoardSquareProps {
  const BoardSquareProps({
    required this.square,
    required this.size,
    required this.background,
    required this.coordinateColor,
    required this.grain,
    required this.piece,
    required this.hasPieceUnderneath,
    required this.isLegalTarget,
    required this.rotatePiece,
    required this.showRankLabel,
    required this.showFileLabel,
  });

  final Square square;
  final double size;
  final Color background;
  final Color coordinateColor;

  /// Whether the square carries a wood grain (see [BoardTheme.grain]).
  final bool grain;

  /// The piece to draw, or null for an empty square or one hidden while a
  /// moving copy is in flight.
  final Piece? piece;

  /// Whether a piece stands here at all (changes the legal-move marker).
  final bool hasPieceUnderneath;
  final bool isLegalTarget;
  final bool rotatePiece;
  final bool showRankLabel;
  final bool showFileLabel;

  @override
  bool operator ==(Object other) =>
      other is BoardSquareProps &&
      other.square == square &&
      other.size == size &&
      other.background == background &&
      other.coordinateColor == coordinateColor &&
      other.grain == grain &&
      other.piece == piece &&
      other.hasPieceUnderneath == hasPieceUnderneath &&
      other.isLegalTarget == isLegalTarget &&
      other.rotatePiece == rotatePiece &&
      other.showRankLabel == showRankLabel &&
      other.showFileLabel == showFileLabel;

  @override
  int get hashCode => Object.hash(
    square,
    size,
    background,
    coordinateColor,
    grain,
    piece,
    hasPieceUnderneath,
    isLegalTarget,
    rotatePiece,
    showRankLabel,
    showFileLabel,
  );
}

/// One square of the board, drawn from [BoardSquareProps].
class BoardSquareCell extends StatelessWidget {
  const BoardSquareCell({super.key, required this.props});

  final BoardSquareProps props;

  /// Counts builds so tests can check that unchanged squares are skipped.
  @visibleForTesting
  static int debugBuildCount = 0;

  @override
  Widget build(BuildContext context) {
    assert(() {
      debugBuildCount++;
      return true;
    }());

    final size = props.size;
    final piece = props.piece;

    final labelStyle = TextStyle(
      fontSize: size * 0.16,
      fontWeight: FontWeight.w700,
      color: props.coordinateColor,
    );

    Widget? pieceWidget;
    if (piece != null) {
      final svg = PieceImage(_assetForPiece(piece));
      pieceWidget = Padding(
        padding: EdgeInsets.all(size * 0.02),
        child: props.rotatePiece
            ? RotatedBox(quarterTurns: 2, child: svg)
            : svg,
      );
    }

    // The colour itself is painted under the grid by [BoardSquaresPainter].
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (props.grain)
            Positioned.fill(
              child: CustomPaint(
                painter: WoodGrainPainter(
                  seed: props.square,
                  light: (fileOf(props.square) + rankOf(props.square)).isOdd,
                ),
              ),
            ),
          ?pieceWidget,

          if (props.isLegalTarget && !props.hasPieceUnderneath)
            Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),

          if (props.isLegalTarget && props.hasPieceUnderneath)
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

          if (props.showRankLabel)
            Positioned(
              top: 2,
              left: 3,
              child: Text(
                (rankOf(props.square) + 1).toString(),
                style: labelStyle,
              ),
            ),

          if (props.showFileLabel)
            Positioned(
              bottom: 2,
              right: 3,
              child: Text(
                String.fromCharCode('a'.codeUnitAt(0) + fileOf(props.square)),
                style: labelStyle,
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

  return AppSettings.instance.pieceSet.value.asset(color, role);
}

class _PromotionPicker extends StatelessWidget {
  const _PromotionPicker({
    required this.color,
    required this.rotated,
    required this.squareSize,
    required this.onPick,
    required this.onCancel,
  });

  final Side color;
  final bool rotated;
  final double squareSize;
  final ValueChanged<Role> onPick;
  final VoidCallback onCancel;

  static const List<Role> _roles = [
    Role.queen,
    Role.rook,
    Role.bishop,
    Role.knight,
  ];

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: EdgeInsets.all(squareSize * 0.15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(squareSize * 0.3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final role in _roles)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(role),
              child: SizedBox(
                width: squareSize * 1.1,
                height: squareSize * 1.1,
                child: Padding(
                  padding: EdgeInsets.all(squareSize * 0.05),
                  child: PieceImage(
                    _assetForPiece(Piece(color: color, role: role)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onCancel,
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: rotated ? RotatedBox(quarterTurns: 2, child: card) : card,
      ),
    );
  }
}
