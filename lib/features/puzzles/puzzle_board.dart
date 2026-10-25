import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/widgets/piece_image.dart';
import 'package:kust/core/board_theme.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/board/board_geometry.dart';
import 'package:kust/features/game/chess/chess_helpers.dart';

const Color _lastMoveColor = Color(0x66FFBB00);
const Color _selectedColor = Color(0x99FFBB00);
const Color _hintFromColor = Color(0x6622C55E);
const Color _hintToColor = Color(0x9922C55E);
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  ({Square from, Square to})? _sliding;
  Square? _selected;
  Map<Square, NormalMove> _targets = const {};

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
  }

  @override
  void didUpdateWidget(PuzzleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slideKey != oldWidget.slideKey) {
      _sliding = widget.slide;
      if (_sliding != null) {
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
      targets[isCastle ? _displayCastleTarget(to) : to] = move;
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

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            _handleTap(_squareAt(details.localPosition, cell));
          },
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              children: [
                for (var index = 0; index < 64; index++)
                  _buildCell(index, cell),
                _buildSlidingPiece(cell),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int index, double cell) {
    final row = index ~/ 8;
    final col = index % 8;
    final file = widget.flipped ? 7 - col : col;
    final rank = widget.flipped ? row : 7 - row;
    final square = squareAt(file, rank);
    final hideForSlide = _isSliding && _sliding!.to == square;
    final piece = hideForSlide ? null : widget.position.board.pieceAt(square);
    final isLight = (file + rank).isOdd;

    final lastMove = widget.lastMove;
    final isLast =
        lastMove != null && (square == lastMove.from || square == lastMove.to);
    final isSelected = _selected == square;
    final isTarget = _targets.containsKey(square);
    final isHintFrom = widget.hintFrom == square;
    final isHintTo = widget.hintTo == square;

    final theme = AppSettings.instance.boardTheme.value;
    var background = isLight ? theme.light : theme.dark;
    if (isLast) background = Color.alphaBlend(_lastMoveColor, background);
    if (isHintFrom) {
      background = Color.alphaBlend(_hintFromColor, background);
    }
    if (isHintTo) background = Color.alphaBlend(_hintToColor, background);
    if (isSelected) {
      background = Color.alphaBlend(_selectedColor, background);
    }

    return Positioned(
      left: col * cell,
      top: row * cell,
      width: cell,
      height: cell,
      child: Container(
        color: background,
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
