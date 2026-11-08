import 'package:dartchess/dartchess.dart';

/// What a task asks for.
enum TaskKind {
  /// Move your piece onto the stars; other moves are free.
  collect,

  /// Capture the marked pieces; other moves are free.
  capture,

  /// Capture the one marked piece; any other move is wrong.
  bestCapture,

  /// Give check.
  check,

  /// Give checkmate in one move.
  mate,

  /// Get out of check: any legal move does.
  escape,

  /// Get out of check by capturing the marked attacker.
  escapeCapture,
  castleKing,
  castleQueen,

  /// Capture the marked square with a pawn that moves diagonally onto an
  /// empty square.
  enPassant,
  promote,
}

/// One exercise on the board, always played by White from [fen].
class LessonTask {
  const LessonTask({
    required this.fen,
    required this.kind,
    this.targets = const {},
    this.piece,
  });

  final String fen;
  final TaskKind kind;

  /// The stars to reach, or the squares of the pieces to capture.
  final Set<Square> targets;

  /// The piece to move, for the prompt of [TaskKind.collect].
  final Role? piece;

  /// Whether the targets are drawn as stars (empty squares) rather than
  /// marks on pieces.
  bool get starred => kind == TaskKind.collect || kind == TaskKind.enPassant;
}

/// How the board answered a move.
enum TaskStep {
  /// A legal move that does not finish the task: carry on.
  progress,

  /// The task is done.
  done,

  /// Not what was asked: the move is taken back.
  wrong,

  /// The move left the other side stalemated, when mate was asked.
  stalemate,
}

/// Plays a [LessonTask]: White moves, Black stands still, and the board is
/// turned back to White after every move that keeps the task going.
class TaskRunner {
  TaskRunner(this.task)
    : position = _parse(task.fen),
      _remaining = {...task.targets};

  final LessonTask task;
  Position position;
  final Set<Square> _remaining;

  /// The stars or marked pieces still to take.
  Set<Square> get remaining => Set.unmodifiable(_remaining);

  static Position _parse(String fen) =>
      Chess.fromSetup(Setup.parseFen(fen), ignoreImpossibleCheck: true);

  /// The same position with White to move again and no en passant.
  static Position? whiteToMove(Position p) {
    final parts = p.fen.split(' ');
    parts[1] = 'w';
    parts[3] = '-';
    try {
      return _parse(parts.join(' '));
    } on PositionSetupException {
      // Black is in check with White to move: not a position.
      return null;
    }
  }

  /// Where [move] ends: castling, written as the king taking its rook, lands
  /// on the king's real square.
  static Square landing(NormalMove move, Position before) {
    final mover = before.board.pieceAt(move.from);
    final target = before.board.pieceAt(move.to);
    final castles =
        mover?.role == Role.king &&
        target != null &&
        target.color == mover?.color;
    if (!castles) return move.to;
    final kingSide = move.to.file > move.from.file;
    return Square.fromCoords(kingSide ? File.g : File.c, move.to.rank);
  }

  /// Plays [move]. On [TaskStep.progress] and [TaskStep.done] the position
  /// moves on; on the others it stays as it was.
  TaskStep apply(NormalMove move) {
    final before = position;
    if (!before.isLegal(move)) return TaskStep.wrong;
    final after = before.play(move);
    final to = landing(move, before);
    final mover = before.board.pieceAt(move.from);

    // Moves on to [after] with White to move again; false when that is not
    // a position (the free move checked Black).
    bool advance({bool force = false}) {
      final over = after.isCheckmate || after.isStalemate;
      final next = over ? after : whiteToMove(after);
      if (next == null && !force) return false;
      position = next ?? after;
      return true;
    }

    // The task is over, so the board may stay with Black to move.
    TaskStep finish(TaskStep step) {
      advance(force: true);
      return step;
    }

    switch (task.kind) {
      case TaskKind.collect:
      case TaskKind.capture:
        if (!advance()) return TaskStep.wrong;
        _remaining.remove(to);
        return _remaining.isEmpty ? TaskStep.done : TaskStep.progress;
      case TaskKind.bestCapture:
      case TaskKind.escapeCapture:
      case TaskKind.enPassant:
        if (!task.targets.contains(to)) return TaskStep.wrong;
        if (task.kind == TaskKind.enPassant &&
            (mover?.role != Role.pawn || before.board.pieceAt(to) != null)) {
          return TaskStep.wrong;
        }
        return finish(TaskStep.done);
      case TaskKind.check:
        return after.isCheck ? finish(TaskStep.done) : TaskStep.wrong;
      case TaskKind.mate:
        if (after.isCheckmate) return finish(TaskStep.done);
        return after.isStalemate ? TaskStep.stalemate : TaskStep.wrong;
      case TaskKind.escape:
        return finish(TaskStep.done);
      case TaskKind.castleKing:
        return mover?.role == Role.king && to.file == File.g
            ? finish(TaskStep.done)
            : TaskStep.wrong;
      case TaskKind.castleQueen:
        return mover?.role == Role.king && to.file == File.c
            ? finish(TaskStep.done)
            : TaskStep.wrong;
      case TaskKind.promote:
        return move.promotion != null ? finish(TaskStep.done) : TaskStep.wrong;
    }
  }

  /// A move that makes progress, for the hint: the first legal move that is
  /// not [TaskStep.wrong], preferring one that finishes the task.
  NormalMove? hint() {
    NormalMove? fallback;
    NormalMove? closest;
    var closestDistance = 99;
    for (final entry in position.legalMoves.entries) {
      for (final to in entry.value.squares) {
        var move = NormalMove(from: entry.key, to: to);
        final piece = position.board.pieceAt(entry.key);
        final last = piece?.role == Role.pawn && (to.rank == Rank.eighth);
        if (last) {
          move = NormalMove(from: entry.key, to: to, promotion: Role.queen);
        }
        final probe = TaskRunner(task)
          ..position = position
          .._remaining.clear()
          .._remaining.addAll(_remaining);
        final step = probe.apply(move);
        if (step == TaskStep.done) return move;
        if (step != TaskStep.progress) continue;
        // A free move helps when it lands on a star or a mark, or else gets
        // the piece nearer to one.
        final land = landing(move, position);
        if (_remaining.contains(land)) {
          fallback ??= move;
        } else if (task.kind == TaskKind.collect &&
            position.board.pieceAt(entry.key)?.role == task.piece) {
          for (final star in _remaining) {
            final d = _distance(land, star);
            if (d < closestDistance) {
              closestDistance = d;
              closest = move;
            }
          }
        }
      }
    }
    return fallback ?? closest;
  }

  static int _distance(Square a, Square b) {
    final df = (a.file - b.file).abs();
    final dr = (a.rank - b.rank).abs();
    return df > dr ? df : dr;
  }
}
