import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:kust/widgets/piece_image.dart';
import 'package:kust/core/board_theme.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/board/board_geometry.dart';
import 'package:kust/features/game/chess/board/board_squares_painter.dart';
import 'package:kust/features/game/chess/board/chess_board.dart'
    show glideDuration;
import 'package:kust/features/game/chess/board/move_arrow.dart';
import 'package:kust/features/game/chess/chess_helpers.dart';

const Color _lastMoveColor = Color(0x66FFBB00);
const Color _selectedColor = Color(0x99FFBB00);
const Color _hintFromColor = Color(0x6622C55E);
const Color _targetDotColor = Color(0x33000000);

Square _displayCastleTarget(Square target) {
  if (target == Square.h1) return Square.g1;
  if (target == Square.a1) return Square.c1;
  if (target == Square.h8) return Square.g8;
  if (target == Square.a8) return Square.c8;
  return target;
}

/// The glide for stepping from [fromPly] to [toPly] through [positions] and
/// [moves] (as built by the replay and puzzle screens), or null when the
/// squares are not one move apart. Stepping back reverses the move, and
/// castling shows the king landing on its real square.
({Square from, Square to})? slideBetween(
  List<Position> positions,
  List<NormalMove?> moves,
  int fromPly,
  int toPly,
) {
  Square landing(NormalMove move, Position before) {
    final mover = before.board.pieceAt(move.from);
    final target = before.board.pieceAt(move.to);
    final castles =
        mover?.role == Role.king &&
        target != null &&
        target.color == mover?.color;
    if (!castles) return move.to;
    final kingSide = fileOf(move.to) > fileOf(move.from);
    return squareAt(kingSide ? 6 : 2, rankOf(move.to));
  }

  if (toPly == fromPly + 1) {
    final move = moves[toPly];
    if (move == null) return null;
    return (from: move.from, to: landing(move, positions[fromPly]));
  }
  if (toPly == fromPly - 1) {
    final move = moves[fromPly];
    if (move == null) return null;
    return (from: landing(move, positions[toPly]), to: move.from);
  }
  return null;
}

class PuzzleBoard extends StatefulWidget {
  const PuzzleBoard({
    super.key,
    required this.position,
    required this.flipped,
    required this.interactive,
    required this.onMove,
    this.lastMove,
    this.hintFrom,
    this.hintTo,
    this.slide,
    this.slideKey = 0,
  });

  final Position position;
  final bool flipped;
  final bool interactive;
  final ValueChanged<NormalMove> onMove;
  final NormalMove? lastMove;
  final Square? hintFrom;
  final Square? hintTo;

  /// Piece to glide into place: it now stands on [slide].to and travels from
  /// [slide].from. A new [slideKey] starts the animation, so stepping back
  /// can pass the reversed squares.
  final ({Square from, Square to})? slide;
  final int slideKey;

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl = AnimationController(
    vsync: this,
    duration: glideDuration(1),
  );
  ({Square from, Square to})? _sliding;
  Square? _selected;
  Map<Square, NormalMove> _targets = const {};

  /// Dragging: the piece, its square and where the finger is.
  Square? _dragFrom;
  Piece? _dragPiece;
  final ValueNotifier<Offset?> _dragAt = ValueNotifier(null);
  Square? _hover;
  double _cell = 0;

  /// A move made by dropping; its glide is skipped, the piece is there.
  ({Square from, Square to})? _dropped;

  /// After an illegal drop the piece flies back to its square.
  late final AnimationController _snapCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
  );
  Square? _snapSquare;
  Piece? _snapPiece;
  Offset _snapStart = Offset.zero;

  /// How far above the finger a dragged piece floats, in squares.
  static const double _dragLift = 0.3;

  void _onBoardTheme() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    AppSettings.instance.boardTheme.addListener(_onBoardTheme);
    AppSettings.instance.pieceSet.addListener(_onBoardTheme);
    // Rebuild once the glide ends so the real piece is drawn again.
    _slideCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() {});
    });
    _snapCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _snapPiece = null;
          _snapSquare = null;
        });
      }
    });
  }

  @override
  void didUpdateWidget(PuzzleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slideKey != oldWidget.slideKey) {
      final slide = widget.slide;
      final dropped = _dropped;
      _dropped = null;
      // A piece dropped on its square is already there: no glide.
      final wasDropped =
          slide != null &&
          dropped != null &&
          slide.from == dropped.from &&
          slide.to == dropped.to;
      _sliding = wasDropped ? null : slide;
      if (_sliding != null) {
        final s = _sliding!;
        final distance = math.sqrt(
          math.pow(fileOf(s.to) - fileOf(s.from), 2) +
              math.pow(rankOf(s.to) - rankOf(s.from), 2),
        );
        _slideCtrl.duration = glideDuration(distance.toDouble());
        _slideCtrl.forward(from: 0);
      } else {
        _slideCtrl.value = 1;
      }
    }
    if (oldWidget.position.fen != widget.position.fen) {
      _selected = null;
      _targets = const {};
    }
  }

  @override
  void dispose() {
    AppSettings.instance.boardTheme.removeListener(_onBoardTheme);
    AppSettings.instance.pieceSet.removeListener(_onBoardTheme);
    _slideCtrl.dispose();
    _snapCtrl.dispose();
    _dragAt.dispose();
    super.dispose();
  }

  bool get _isSliding => _sliding != null && _slideCtrl.isAnimating;

  Map<Square, NormalMove> _destinationsFrom(Square from) {
    final position = widget.position;
    final piece = position.board.pieceAt(from);
    final isPawn = piece?.role == Role.pawn;
    final targets = <Square, NormalMove>{};

    for (final to in position.legalMovesOf(from).squares) {
      final target = position.board.pieceAt(to);
      final isCastle =
          piece?.role == Role.king &&
          target != null &&
          target.color == piece?.color;
      final promotes = isPawn && (rankOf(to) == 0 || rankOf(to) == 7);
      final move = NormalMove(
        from: from,
        to: to,
        promotion: promotes ? Role.queen : null,
      );
      if (isCastle) {
        targets[_displayCastleTarget(to)] = move;
        // The rook itself is a target too when castling on the rook is on.
        if (AppSettings.instance.castleOnRook.value) targets[to] = move;
      } else {
        targets[to] = move;
      }
    }
    return targets;
  }

  void _handleTap(Square square) {
    if (!widget.interactive) return;
    final position = widget.position;

    if (_selected != null) {
      final move = _targets[square];
      if (move != null) {
        setState(() {
          _selected = null;
          _targets = const {};
        });
        widget.onMove(move);
        return;
      }
    }

    final piece = position.board.pieceAt(square);
    if (piece != null && piece.color == position.turn) {
      setState(() {
        _selected = square;
        _targets = _destinationsFrom(square);
      });
      return;
    }

    setState(() {
      _selected = null;
      _targets = const {};
    });
  }

  Offset _pieceCentre(Offset finger) => finger - Offset(0, _cell * _dragLift);

  Square? _squareUnder(Offset local) {
    if (_cell <= 0) return null;
    final col = (local.dx / _cell).floor();
    final row = (local.dy / _cell).floor();
    if (col < 0 || col > 7 || row < 0 || row > 7) return null;
    return _squareAt(local, _cell);
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.interactive) return;
    final square = _squareUnder(details.localPosition);
    if (square == null) return;
    final piece = widget.position.board.pieceAt(square);
    if (piece == null || piece.color != widget.position.turn) return;
    _snapCtrl.stop();
    setState(() {
      _selected = square;
      _targets = _destinationsFrom(square);
      _dragFrom = square;
      _dragPiece = piece;
      _hover = square;
      _snapPiece = null;
    });
    _dragAt.value = details.localPosition;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dragFrom == null) return;
    _dragAt.value = details.localPosition;
    final over = _squareUnder(_pieceCentre(details.localPosition));
    if (over != _hover) setState(() => _hover = over);
  }

  void _onDragEnd([DragEndDetails? _]) {
    final from = _dragFrom;
    final piece = _dragPiece;
    final at = _dragAt.value;
    if (from == null || piece == null || at == null) return;
    final target = _squareUnder(_pieceCentre(at));
    final move = target == null || target == from ? null : _targets[target];
    setState(() {
      _dragFrom = null;
      _dragPiece = null;
      _hover = null;
      if (move != null) {
        _selected = null;
        _targets = const {};
      } else {
        _snapSquare = from;
        _snapPiece = piece;
        _snapStart = _pieceCentre(at) - Offset(_cell / 2, _cell / 2);
      }
    });
    _dragAt.value = null;
    if (move != null) {
      _dropped = (from: from, to: target!);
      widget.onMove(move);
    } else {
      _snapCtrl.forward(from: 0);
    }
  }

  Square _squareAt(Offset local, double cell) {
    final col = math.min(7, math.max(0, (local.dx / cell).floor()));
    final row = math.min(7, math.max(0, (local.dy / cell).floor()));
    final file = widget.flipped ? 7 - col : col;
    final rank = widget.flipped ? row : 7 - row;
    return squareAt(file, rank);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;
        final cell = boardSize / 8;
        _cell = cell;
        final hintFrom = widget.hintFrom;
        final hintTo = widget.hintTo;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            _handleTap(_squareAt(details.localPosition, cell));
          },
          // Pick up the piece where the finger first touched, not where the
          // drag was recognised a few pixels later.
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: _onDragStart,
          onPanUpdate: _onDragUpdate,
          onPanEnd: _onDragEnd,
          onPanCancel: _onDragEnd,
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              children: [
                // Square colours in one pass on whole pixels; the cells
                // above are transparent and only hold pieces and markers.
                Positioned.fill(
                  child: CustomPaint(
                    painter: BoardSquaresPainter(
                      colors: [for (var i = 0; i < 64; i++) _cellColor(i)],
                      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                    ),
                  ),
                ),
                for (var index = 0; index < 64; index++)
                  _buildCell(index, cell),
                _buildSlidingPiece(cell),
                if (hintFrom != null && hintTo != null)
                  Positioned.fill(
                    child: MoveArrow(
                      fromRow: _rowOf(hintFrom),
                      fromCol: _colOf(hintFrom),
                      toRow: _rowOf(hintTo),
                      toCol: _colOf(hintTo),
                    ),
                  ),
                if (_dragPiece != null && _hover != null)
                  Positioned(
                    left: _colOf(_hover!) * cell,
                    top: _rowOf(_hover!) * cell,
                    width: cell,
                    height: cell,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.75),
                            width: cell * 0.06,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_dragPiece != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ValueListenableBuilder<Offset?>(
                        valueListenable: _dragAt,
                        child: RepaintBoundary(
                          child: SizedBox(
                            width: cell,
                            height: cell,
                            child: PieceImage(assetForPiece(_dragPiece!)),
                          ),
                        ),
                        builder: (context, at, child) {
                          if (at == null) return const SizedBox.shrink();
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Transform.translate(
                              offset:
                                  _pieceCentre(at) - Offset(cell / 2, cell / 2),
                              child: Transform.scale(scale: 1.18, child: child),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (_snapPiece != null && _snapSquare != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _snapCtrl,
                        child: RepaintBoundary(
                          child: SizedBox(
                            width: cell,
                            height: cell,
                            child: Padding(
                              padding: EdgeInsets.all(cell * 0.02),
                              child: PieceImage(assetForPiece(_snapPiece!)),
                            ),
                          ),
                        ),
                        builder: (context, child) {
                          final t = Curves.easeOutCubic.transform(
                            _snapCtrl.value,
                          );
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Transform.translate(
                              offset: Offset.lerp(
                                _snapStart,
                                _cellOrigin(_snapSquare!, cell),
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
              ],
            ),
          ),
        );
      },
    );
  }

  /// The square shown at [index], counted row by row from the top left.
  Square _squareOf(int index) {
    final row = index ~/ 8;
    final col = index % 8;
    final file = widget.flipped ? 7 - col : col;
    final rank = widget.flipped ? row : 7 - row;
    return squareAt(file, rank);
  }

  /// The colour of the square shown at [index], with any highlight on top.
  Color _cellColor(int index) {
    final square = _squareOf(index);
    final isLight = (fileOf(square) + rankOf(square)).isOdd;
    final lastMove = widget.lastMove;
    final theme = AppSettings.instance.boardTheme.value;
    var background = isLight ? theme.light : theme.dark;
    if (lastMove != null &&
        (square == lastMove.from || square == lastMove.to)) {
      background = Color.alphaBlend(_lastMoveColor, background);
    }
    if (widget.hintFrom == square) {
      background = Color.alphaBlend(_hintFromColor, background);
    }
    // The hinted move itself is drawn as an arrow.
    if (_selected == square) {
      background = Color.alphaBlend(_selectedColor, background);
    }
    return background;
  }

  Widget _buildCell(int index, double cell) {
    final row = index ~/ 8;
    final col = index % 8;
    final square = _squareOf(index);
    final hideForSlide =
        (_isSliding && _sliding!.to == square) ||
        _dragFrom == square ||
        _snapSquare == square;
    final piece = hideForSlide ? null : widget.position.board.pieceAt(square);
    final isLight = (fileOf(square) + rankOf(square)).isOdd;
    final isTarget = _targets.containsKey(square);
    final theme = AppSettings.instance.boardTheme.value;

    return Positioned(
      left: col * cell,
      top: row * cell,
      width: cell,
      height: cell,
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (theme.grain)
              Positioned.fill(
                child: CustomPaint(
                  painter: WoodGrainPainter(seed: square, light: isLight),
                ),
              ),
            if (piece != null)
              Padding(
                padding: EdgeInsets.all(cell * 0.02),
                child: PieceImage(assetForPiece(piece)),
              ),
            if (isTarget)
              Container(
                width: cell * (piece == null ? 0.3 : 0.9),
                height: cell * (piece == null ? 0.3 : 0.9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: piece == null ? _targetDotColor : null,
                  border: piece != null
                      ? Border.all(color: _targetDotColor, width: cell * 0.08)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _colOf(Square square) =>
      widget.flipped ? 7 - fileOf(square) : fileOf(square);
  int _rowOf(Square square) =>
      widget.flipped ? rankOf(square) : 7 - rankOf(square);

  Offset _cellOrigin(Square square, double cell) {
    final file = fileOf(square);
    final rank = rankOf(square);
    final col = widget.flipped ? 7 - file : file;
    final row = widget.flipped ? rank : 7 - rank;
    return Offset(col * cell, row * cell);
  }

  Widget _buildSlidingPiece(double cell) {
    final sliding = _sliding;
    if (sliding == null) return const SizedBox.shrink();
    final piece = widget.position.board.pieceAt(sliding.to);
    if (piece == null) return const SizedBox.shrink();

    final from = _cellOrigin(sliding.from, cell);
    final to = _cellOrigin(sliding.to, cell);
    // The piece is built once and sits on its own layer; each frame only
    // moves it, so gliding costs no widget rebuilds or SVG work.
    return AnimatedBuilder(
      animation: _slideCtrl,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Padding(
            padding: EdgeInsets.all(cell * 0.02),
            child: PieceImage(assetForPiece(piece)),
          ),
        ),
      ),
      builder: (context, child) {
        if (!_slideCtrl.isAnimating) return const SizedBox.shrink();
        final t = Curves.easeOutCubic.transform(_slideCtrl.value);
        final at = Offset.lerp(from, to, t)!;
        return Positioned(
          left: at.dx,
          top: at.dy,
          width: cell,
          height: cell,
          child: child!,
        );
      },
    );
  }
}
