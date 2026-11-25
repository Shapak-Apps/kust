import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kust/features/game/chess/board/board_geometry.dart';
import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/board/move_arrow.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/move_feedback.dart';

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

/// The board of puzzles, lessons and replays: the very board games use
/// (the same pieces, glides, captures, coordinates, dragging and promotion),
/// run by its screen instead of a game. The screen gives the position and
/// what to mark; the player's moves come back through [onMove].
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
    this.arrow,
    this.arrows = const [],
    this.badge,
  });

  final Position position;
  final bool flipped;
  final bool interactive;
  final ValueChanged<NormalMove> onMove;
  final NormalMove? lastMove;
  final Square? hintFrom;
  final Square? hintTo;

  /// Piece to glide into place: it now stands on [slide].to and travels from
  /// [slide].from. Stepping back passes the reversed squares.
  final ({Square from, Square to})? slide;
  final int slideKey;

  /// An arrow to draw, e.g. the best move in a replay.
  final ({Square from, Square to})? arrow;

  /// More arrows, each in its own colour, e.g. the lines of a tactic.
  final List<({Square from, Square to, Color color})> arrows;

  /// A move rating to pin on a square's corner, as in a game.
  final ({Square square, MoveQuality quality})? badge;

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard> {
  /// Its own: the board needs nothing from the app's providers.
  final ProviderContainer _container = ProviderContainer();

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  late final NotifierProvider<ChessController, GameState> _board =
      NotifierProvider.autoDispose<ChessController, GameState>(
        () =>
            ScreenBoardController(_state(null))
              ..onBoardMove = (move) => widget.onMove(move),
      );

  /// What the board shows, from the screen's props; [before] is the
  /// position shown until now, to see what a glide captures.
  GameState _state(Position? before) {
    final w = widget;
    final slide = w.slide;
    final last = w.lastMove;
    Piece? captured;
    if (slide != null && before != null) {
      final mover = before.board.pieceAt(slide.from);
      final taken = before.board.pieceAt(slide.to);
      if (mover != null && taken != null && taken.color != mover.color) {
        captured = taken;
      }
    }
    return GameState(
      position: w.position,
      mode: GameMode.bot,
      // The side to move is the player's, so its pieces can be picked up.
      playerSide: w.position.turn,
      status: w.interactive ? GameStatus.playing : GameStatus.loading,
      lastMove: slide == null
          ? null
          : NormalMove(from: slide.from, to: slide.to),
      moveSquares: last == null ? const [] : [last.from, last.to],
      hintSquares: {?w.hintFrom, ?w.hintTo},
      capturedPiece: captured,
      capturedSquare: captured == null ? null : slide!.to,
      practiceMode: false,
    );
  }

  @override
  void didUpdateWidget(covariant PuzzleBoard old) {
    super.didUpdateWidget(old);
    // Not while the tree builds: the board takes it straight after.
    scheduleMicrotask(() {
      if (!mounted) return;
      final c = _container.read(_board.notifier) as ScreenBoardController;
      c.show(_state(_container.read(_board).position));
    });
  }

  @override
  Widget build(BuildContext context) {
    final arrow = widget.arrow;
    return UncontrolledProviderScope(
      container: _container,
      child: ChessBoard(
        controller: _board,
        flipped: widget.flipped,
        badge: widget.badge,
        arrows: [
          if (arrow != null)
            (from: arrow.from, to: arrow.to, color: kHintArrowColor),
          ...widget.arrows,
        ],
      ),
    );
  }
}
