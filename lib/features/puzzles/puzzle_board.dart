import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:Kust/features/game/chess/chess_helpers.dart';

const Color _lightSquare = Color(0xFFF0E6D2);
const Color _darkSquare = Color(0xFFB58863);
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
  });

  final Position position;
  final bool flipped;
  final bool interactive;
  final ValueChanged<NormalMove> onMove;
  final NormalMove? lastMove;
  final Square? hintFrom;
  final Square? hintTo;

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard> {
  Square? _selected;
  Map<Square, NormalMove> _targets = const {};

  @override
  void didUpdateWidget(PuzzleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position.fen != widget.position.fen) {
      _selected = null;
      _targets = const {};
    }
  }

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
    final piece = widget.position.board.pieceAt(square);
    final isLight = (file + rank).isOdd;

    final lastMove = widget.lastMove;
    final isLast =
        lastMove != null &&
        (square == lastMove.from || square == lastMove.to);
    final isSelected = _selected == square;
    final isTarget = _targets.containsKey(square);
    final isHintFrom = widget.hintFrom == square;
    final isHintTo = widget.hintTo == square;

    var background = isLight ? _lightSquare : _darkSquare;
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
            if (piece != null)
              Padding(
                padding: EdgeInsets.all(cell * 0.04),
                child: SvgPicture.asset(assetForPiece(piece)),
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
}
