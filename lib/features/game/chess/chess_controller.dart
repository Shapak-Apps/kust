import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:Kust/features/game/chess/chess_engine.dart';
import 'package:dartchess/dartchess.dart';

import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';
import 'package:Kust/features/game/chess/move_record.dart';
import 'package:Kust/features/game/chess/chess_helpers.dart';

const String kStartFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

int skillLevelForElo(int elo) {
  const minElo = 800;
  const maxElo = 1400;

  final t = ((elo - minElo) / (maxElo - minElo)).clamp(0.0, 1.0);
  return (t * 20).round();
}

enum GameStatus { loading, playing, checkmate, draw, resigned }

enum GameMode { bot, local }

class GameState {
  const GameState({
    required this.position,
    required this.mode,
    this.bot,
    required this.playerSide,
    this.selectedSquare,
    this.legalDestinations = const {},
    this.moveSquares = const [],
    this.hintSquares = const {},
    this.history = const [],
    this.moves = const [],
    this.status = GameStatus.loading,
    this.isBotThinking = false,
    this.isHintThinking = false,
    this.lastMove,
    this.capturedPiece,
    this.capturedSquare,
    this.wasUndo = false,
    this.endReason,
  });

  final Position position;
  final GameMode mode;
  final Bot? bot;
  final Side playerSide;
  final Square? selectedSquare;
  final Set<Square> legalDestinations;
  final List<Square> moveSquares;
  final Set<Square> hintSquares;
  final List<Position> history;
  final List<MoveRecord> moves;
  final GameStatus status;
  final bool isBotThinking;
  final bool isHintThinking;

  final NormalMove? lastMove;
  final Piece? capturedPiece;
  final Square? capturedSquare;
  final bool wasUndo;
  final String? endReason;

  bool get isPlayerTurn =>
      status == GameStatus.playing &&
      (mode == GameMode.local || position.turn == playerSide);

  bool get canUndo {
    if (status != GameStatus.playing) return false;
    if (history.isEmpty || isBotThinking) return false;

    if (mode == GameMode.local) return true;

    if (position.turn == playerSide) {
      return history.length >= 2;
    }

    return true;
  }

  GameState copyWith({
    Position? position,
    GameMode? mode,
    Bot? bot,
    Square? selectedSquare,
    bool clearSelection = false,
    Set<Square>? legalDestinations,
    List<Square>? moveSquares,
    Set<Square>? hintSquares,
    List<Position>? history,
    List<MoveRecord>? moves,
    GameStatus? status,
    bool? isBotThinking,
    bool? isHintThinking,
    NormalMove? lastMove,
    Piece? capturedPiece,
    Square? capturedSquare,
    bool? wasUndo,
    String? endReason,
    bool clearLastMove = false,
    bool clearCapture = false,
  }) {
    return GameState(
      position: position ?? this.position,
      mode: mode ?? this.mode,
      bot: bot ?? this.bot,
      playerSide: playerSide,
      selectedSquare: clearSelection
          ? null
          : (selectedSquare ?? this.selectedSquare),
      legalDestinations: clearSelection
          ? const {}
          : (legalDestinations ?? this.legalDestinations),
      moveSquares: moveSquares ?? this.moveSquares,
      hintSquares: hintSquares ?? this.hintSquares,
      history: history ?? this.history,
      moves: moves ?? this.moves,
      status: status ?? this.status,
      isBotThinking: isBotThinking ?? this.isBotThinking,
      isHintThinking: isHintThinking ?? this.isHintThinking,
      lastMove: clearLastMove ? null : (lastMove ?? this.lastMove),
      capturedPiece: clearCapture
          ? null
          : (capturedPiece ?? this.capturedPiece),
      capturedSquare: clearCapture
          ? null
          : (capturedSquare ?? this.capturedSquare),
      wasUndo: wasUndo ?? this.wasUndo,
      endReason: endReason ?? this.endReason,
    );
  }
}

class ChessController extends Notifier<GameState> {
  int _moveRequestId = 0;
  int _currentSkill = 0;

  @override
  GameState build() {
    ref.onDispose(() {
      _engine.stopThinking();
    });

    return GameState(
      position: Chess.fromSetup(Setup.parseFen(kStartFen)),
      mode: GameMode.bot,
      bot: const Bot(name: '-', elo: 0, imagePath: ''),
      playerSide: Side.white,
    );
  }

  ChessEngine get _engine => ref.read(chessEngineProvider);

  Future<void> _playSound(String asset) async {
    final player = AudioPlayer();
    await player.setPlayerMode(PlayerMode.lowLatency);

    player.onPlayerComplete.listen((_) {
      player.dispose();
    });

    await player.play(AssetSource('sounds/$asset'));
  }

  bool _isEnPassant(Position oldPos, NormalMove move) {
    final piece = oldPos.board.pieceAt(move.from);

    if (piece?.role != Role.pawn) return false;
    if (fileOf(move.from) == fileOf(move.to)) return false;

    return oldPos.board.pieceAt(move.to) == null;
  }

  Square? _capturedSquareFor(Position oldPos, NormalMove move) {
    final piece = oldPos.board.pieceAt(move.from);

    final isCastling =
        piece?.role == Role.king &&
        (move.from == Square.e1 || move.from == Square.e8) &&
        (move.to == Square.h1 ||
            move.to == Square.a1 ||
            move.to == Square.h8 ||
            move.to == Square.a8 ||
            move.to == Square.g1 ||
            move.to == Square.c1 ||
            move.to == Square.g8 ||
            move.to == Square.c8);

    if (isCastling) return null;

    if (oldPos.board.pieceAt(move.to) != null) {
      return move.to;
    }

    if (_isEnPassant(oldPos, move)) {
      return squareAt(fileOf(move.to), rankOf(move.from));
    }

    return null;
  }

  void _playMoveSound(
    NormalMove move,
    Position oldPos,
    Position newPos,
    bool isBot,
  ) {
    String sound;

    final isCastling =
        (move.from == Square.e1 || move.from == Square.e8) &&
        (move.to == Square.h1 ||
            move.to == Square.a1 ||
            move.to == Square.h8 ||
            move.to == Square.a8 ||
            move.to == Square.g1 ||
            move.to == Square.c1 ||
            move.to == Square.g8 ||
            move.to == Square.c8);

    final capturedSquare = _capturedSquareFor(oldPos, move);
    final isCapture = capturedSquare != null;

    if (isCastling) {
      sound = 'castle.mp3';
    } else if (move.promotion != null) {
      sound = 'promote.mp3';
    } else if (isCapture) {
      sound = 'capture.mp3';
    } else {
      sound = isBot ? 'move-opponent.mp3' : 'move.mp3';
    }

    _playSound(sound);

    if (newPos.isCheck) {
      _playSound('check.mp3');
    }
  }

  void _playGameEndSound(Position position) {
    if (position.isCheckmate) {
      if (state.mode == GameMode.local) {
        _playSound('game-end.mp3');
      } else if (position.turn == state.playerSide) {
        _playSound('game-end.mp3');
      } else {
        _playSound('game-win.mp3');
      }
    } else {
      _playSound('game-draw.mp3');
    }
  }

  Future<void> startGame(Bot bot, {Side playerSide = Side.white}) async {
    _moveRequestId++;
    _currentSkill = skillLevelForElo(bot.elo);

    state = GameState(
      position: Chess.fromSetup(Setup.parseFen(kStartFen)),
      mode: GameMode.bot,
      bot: bot,
      playerSide: playerSide,
      moves: const [],
    );

    await _engine.start();
    _engine.setSkillLevel(_currentSkill, elo: bot.elo);

    state = state.copyWith(status: GameStatus.playing);
    _playSound('game-start.mp3');

    if (state.position.turn != playerSide) {
      _requestBotMove();
    }
  }

  Future<void> startLocalGame() async {
    _moveRequestId++;
    _currentSkill = 0;

    state = GameState(
      position: Chess.fromSetup(Setup.parseFen(kStartFen)),
      mode: GameMode.local,
      bot: null,
      playerSide: Side.white,
      moves: const [],
      status: GameStatus.playing,
    );

    _playSound('game-start.mp3');
  }

  void selectSquare(Square square) {
    if (!state.isPlayerTurn) return;

    final piece = state.position.board.pieceAt(square);

    if (state.selectedSquare == null) {
      if (piece == null) return;
      if (state.mode != GameMode.local && piece.color != state.playerSide) {
        return;
      }
      if (state.mode == GameMode.local && piece.color != state.position.turn) {
        return;
      }

      state = state.copyWith(
        selectedSquare: square,
        legalDestinations: _displayDestinationsFrom(square),
        hintSquares: const {},
      );
      return;
    }

    if (square == state.selectedSquare) {
      state = state.copyWith(clearSelection: true);
      return;
    }

    if (state.legalDestinations.contains(square)) {
      _playPlayerMove(state.selectedSquare!, square);
      return;
    }

    final canSelectPiece =
        piece != null &&
        (state.mode == GameMode.local
            ? piece.color == state.position.turn
            : piece.color == state.playerSide);

    if (canSelectPiece) {
      state = state.copyWith(
        selectedSquare: square,
        legalDestinations: _displayDestinationsFrom(square),
        hintSquares: const {},
      );
    } else {
      state = state.copyWith(clearSelection: true);
    }
  }

  void resign() {
    if (state.status != GameStatus.playing) return;

    _moveRequestId++;
    _engine.stopThinking();

    state = state.copyWith(
      status: GameStatus.resigned,
      isBotThinking: false,
      endReason: 'You resigned.',
    );

    _playSound('game-end.mp3');
  }

  void undoLastMove() {
    if (!state.canUndo) return;

    _moveRequestId++;
    if (state.isBotThinking) _engine.stopThinking();

    final newHistory = List<Position>.from(state.history);
    final newMoves = List<MoveRecord>.from(state.moves);

    var restored = newHistory.removeLast();

    if (state.mode != GameMode.local &&
        newHistory.isNotEmpty &&
        restored.turn != state.playerSide) {
      restored = newHistory.removeLast();
    }

    final removedMoves = state.history.length - newHistory.length;

    if (removedMoves > 0 && newMoves.length >= removedMoves) {
      newMoves.removeRange(newMoves.length - removedMoves, newMoves.length);
    }

    final beforeLastMove = state.history.isNotEmpty ? state.history.last : null;

    NormalMove? undoMove;
    Square? capturedSquare;
    Piece? capturedPiece;

    if (state.moveSquares.length == 2) {
      final forwardFrom = state.moveSquares[0];
      final forwardTo = state.moveSquares[1];

      undoMove = NormalMove(from: forwardTo, to: forwardFrom);

      if (beforeLastMove != null) {
        final forwardMove = NormalMove(from: forwardFrom, to: forwardTo);
        final possibleCapturedSquare = _capturedSquareFor(
          beforeLastMove,
          forwardMove,
        );

        if (possibleCapturedSquare != null) {
          final restoredPiece = restored.board.pieceAt(possibleCapturedSquare);

          if (restoredPiece != null) {
            capturedSquare = possibleCapturedSquare;
            capturedPiece = restoredPiece;
          }
        }
      }
    }

    state = state.copyWith(
      position: restored,
      history: newHistory,
      moves: newMoves,
      clearSelection: true,
      moveSquares: const [],
      hintSquares: const {},
      status: GameStatus.playing,
      isBotThinking: false,
      lastMove: undoMove,
      clearLastMove: undoMove == null,
      capturedPiece: capturedPiece,
      capturedSquare: capturedSquare,
      clearCapture: capturedPiece == null,
      wasUndo: true,
    );
  }

  Future<void> requestHint() async {
    if (!state.isPlayerTurn || state.isBotThinking) return;
    if (state.mode == GameMode.local) return;

    final requestId = ++_moveRequestId;
    state = state.copyWith(isHintThinking: true);

    final uci = await _engine.evaluateBestHint(
      state.position.fen,
      currentSkill: _currentSkill,
      currentElo: state.bot?.elo ?? 0,
    );

    if (requestId != _moveRequestId) return;

    if (uci == '(none)') {
      state = state.copyWith(isHintThinking: false);
      return;
    }

    final from = squareAt(_fileFromChar(uci[0]), int.parse(uci[1]) - 1);
    final to = squareAt(_fileFromChar(uci[2]), int.parse(uci[3]) - 1);

    state = state.copyWith(hintSquares: {from, to}, isHintThinking: false);
  }

  Set<Square> _displayDestinationsFrom(Square square) {
    final piece = state.position.board.pieceAt(square);
    if (piece == null) return {};

    final rawDestinations = state.position.legalMovesOf(square).squares.toSet();
    final displaySquares = <Square>{};

    for (final dest in rawDestinations) {
      final isCastling =
          piece.role == Role.king &&
          (square == Square.e1 || square == Square.e8) &&
          (dest == Square.h1 ||
              dest == Square.a1 ||
              dest == Square.h8 ||
              dest == Square.a8);

      if (isCastling) {
        displaySquares.add(_castlingDisplaySquare(dest));
      } else {
        displaySquares.add(dest);
      }
    }

    return displaySquares;
  }

  void _playPlayerMove(Square from, Square to) {
    Square target = to;
    final piece = state.position.board.pieceAt(from);

    if (piece?.role == Role.king) {
      if (from == Square.e1) {
        if (to == Square.g1) target = Square.h1;
        if (to == Square.c1) target = Square.a1;
      } else if (from == Square.e8) {
        if (to == Square.g8) target = Square.h8;
        if (to == Square.c8) target = Square.a8;
      }
    }

    final promotion = _isPromotion(from, target) ? Role.queen : null;
    final move = NormalMove(from: from, to: target, promotion: promotion);

    if (!state.position.isLegal(move)) {
      _playSound('illegal.mp3');
      state = state.copyWith(clearSelection: true);
      return;
    }

    final oldPosition = state.position;
    final newPosition = oldPosition.play(move);

    final updatedHistory = [...state.history, oldPosition];

    final capturedSquare = _capturedSquareFor(oldPosition, move);
    final capturedPiece = capturedSquare == null
        ? null
        : oldPosition.board.pieceAt(capturedSquare);

    final san = moveToSan(
      before: oldPosition,
      move: move,
      after: newPosition,
      capturedSquare: capturedSquare,
    );

    final updatedMoves = [
      ...state.moves,
      MoveRecord(
        side: oldPosition.turn,
        san: san,
        move: move,
        capturedPiece: capturedPiece,
      ),
    ];

    _playMoveSound(move, oldPosition, newPosition, false);

    final gameStatus = _statusFor(newPosition, updatedHistory);
    final reason = _getEndReason(newPosition, updatedHistory, gameStatus);

    state = state.copyWith(
      position: newPosition,
      history: updatedHistory,
      moves: updatedMoves,
      clearSelection: true,
      moveSquares: [move.from, move.to],
      hintSquares: const {},
      status: gameStatus,
      lastMove: move,
      capturedPiece: capturedPiece,
      capturedSquare: capturedSquare,
      clearCapture: capturedPiece == null,
      wasUndo: false,
      endReason: reason,
    );

    if (state.status == GameStatus.playing) {
      if (state.mode == GameMode.bot) _requestBotMove();
    } else {
      _playGameEndSound(newPosition);
    }
  }

  Future<void> _requestBotMove() async {
    final requestId = ++_moveRequestId;
    state = state.copyWith(isBotThinking: true);

    final thinkTime = Duration(milliseconds: 300 + _currentSkill * 40);
    final uci = await _engine.bestMoveForFen(
      state.position.fen,
      thinkTime: thinkTime,
    );

    if (requestId != _moveRequestId) return;

    if (state.status != GameStatus.playing) {
      state = state.copyWith(isBotThinking: false);
      return;
    }

    if (uci == '(none)') {
      state = state.copyWith(isBotThinking: false);
      return;
    }

    final move = _parseUciMove(uci);
    final beforeBotMove = state.position;
    final newPosition = beforeBotMove.play(move);

    final updatedHistory = [...state.history, beforeBotMove];

    final capturedSquare = _capturedSquareFor(beforeBotMove, move);
    final capturedPiece = capturedSquare == null
        ? null
        : beforeBotMove.board.pieceAt(capturedSquare);

    final san = moveToSan(
      before: beforeBotMove,
      move: move,
      after: newPosition,
      capturedSquare: capturedSquare,
    );

    final updatedMoves = [
      ...state.moves,
      MoveRecord(
        side: beforeBotMove.turn,
        san: san,
        move: move,
        capturedPiece: capturedPiece,
      ),
    ];

    _playMoveSound(move, beforeBotMove, newPosition, true);

    final gameStatus = _statusFor(newPosition, updatedHistory);
    final reason = _getEndReason(newPosition, updatedHistory, gameStatus);

    state = state.copyWith(
      position: newPosition,
      history: updatedHistory,
      moves: updatedMoves,
      moveSquares: [move.from, move.to],
      status: gameStatus,
      isBotThinking: false,
      lastMove: move,
      capturedPiece: capturedPiece,
      capturedSquare: capturedSquare,
      clearCapture: capturedPiece == null,
      wasUndo: false,
      endReason: reason,
    );

    if (state.status != GameStatus.playing) {
      _playGameEndSound(newPosition);
    }
  }

  NormalMove _parseUciMove(String uci) {
    var from = squareAt(_fileFromChar(uci[0]), int.parse(uci[1]) - 1);
    var to = squareAt(_fileFromChar(uci[2]), int.parse(uci[3]) - 1);

    final promotion = uci.length > 4 ? _roleFromChar(uci[4]) : null;

    if (from == Square.e1 && to == Square.g1) {
      to = Square.h1;
    } else if (from == Square.e1 && to == Square.c1) {
      to = Square.a1;
    } else if (from == Square.e8 && to == Square.g8) {
      to = Square.h8;
    } else if (from == Square.e8 && to == Square.c8) {
      to = Square.a8;
    }

    return NormalMove(from: from, to: to, promotion: promotion);
  }

  int _fileFromChar(String c) => c.codeUnitAt(0) - 'a'.codeUnitAt(0);

  Role _roleFromChar(String c) {
    switch (c) {
      case 'r':
        return Role.rook;
      case 'b':
        return Role.bishop;
      case 'n':
        return Role.knight;
      default:
        return Role.queen;
    }
  }

  bool _isPromotion(Square from, Square to) {
    final piece = state.position.board.pieceAt(from);
    if (piece?.role != Role.pawn) return false;

    final rank = rankOf(to);
    return rank == 0 || rank == 7;
  }

  Square _castlingDisplaySquare(Square target) {
    if (target == Square.h1) return Square.g1;
    if (target == Square.a1) return Square.c1;
    if (target == Square.h8) return Square.g8;
    if (target == Square.a8) return Square.c8;
    return target;
  }

  bool _isThreefoldRepetition(Position current, List<Position> history) {
    int count = 1;
    for (final pastPosition in history) {
      if (pastPosition.fen == current.fen) {
        count++;
        if (count >= 3) return true;
      }
    }
    return false;
  }

  GameStatus _statusFor(Position position, List<Position> history) {
    if (position.isCheckmate) return GameStatus.checkmate;
    if (position.isStalemate ||
        position.halfmoves >= 100 ||
        position.isInsufficientMaterial ||
        _isThreefoldRepetition(position, history) ||
        position.isGameOver) {
      return GameStatus.draw;
    }
    return GameStatus.playing;
  }

  String? _getEndReason(
    Position position,
    List<Position> history,
    GameStatus status,
  ) {
    if (status == GameStatus.checkmate) {
      if (state.mode == GameMode.local) {
        final winner = position.turn == Side.white ? 'Black' : 'White';
        return '$winner won by checkmate.';
      }

      final winner = position.turn == state.playerSide
          ? state.bot!.name
          : 'You';
      return '$winner won by checkmate.';
    }

    if (status == GameStatus.draw) {
      if (position.isStalemate) {
        return 'Game drawn by stalemate.';
      }
      if (position.halfmoves >= 100) {
        return 'Game drawn by 50-move rule.';
      }
      if (position.isInsufficientMaterial) {
        return 'Game drawn due to insufficient material.';
      }
      if (_isThreefoldRepetition(position, history)) {
        return 'Game drawn by threefold repetition.';
      }
      return 'The game ended in a draw.';
    }

    return null;
  }
}

final chessControllerProvider = NotifierProvider<ChessController, GameState>(
  ChessController.new,
);
