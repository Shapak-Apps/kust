import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:Kust/features/game/chess/chess_engine.dart';
import 'package:dartchess/dartchess.dart';

import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';

const String kStartFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

int skillLevelForElo(int elo) {
  const minElo = 800;
  const maxElo = 1400;

  final t = ((elo - minElo) / (maxElo - minElo)).clamp(0.0, 1.0);
  return (t * 20).round();
}

enum GameStatus { loading, playing, checkmate, draw, resigned }

class GameState {
  const GameState({
    required this.position,
    required this.bot,
    required this.playerSide,
    this.selectedSquare,
    this.legalDestinations = const {},
    this.moveSquares = const [],
    this.hintSquares = const {},
    this.history = const [],
    this.status = GameStatus.loading,
    this.isBotThinking = false,
    this.isHintThinking = false,
  });

  final Position position;
  final Bot bot;
  final Side playerSide;
  final Square? selectedSquare;
  final Set<Square> legalDestinations;
  final List<Square> moveSquares;
  final Set<Square> hintSquares;
  final List<Position> history;
  final GameStatus status;
  final bool isBotThinking;
  final bool isHintThinking;

  bool get isPlayerTurn =>
      status == GameStatus.playing && position.turn == playerSide;

  bool get canUndo => history.isNotEmpty && !isBotThinking;

  GameState copyWith({
    Position? position,
    Square? selectedSquare,
    bool clearSelection = false,
    Set<Square>? legalDestinations,
    List<Square>? moveSquares,
    Set<Square>? hintSquares,
    List<Position>? history,
    GameStatus? status,
    bool? isBotThinking,
    bool? isHintThinking,
  }) {
    return GameState(
      position: position ?? this.position,
      bot: bot,
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
      status: status ?? this.status,
      isBotThinking: isBotThinking ?? this.isBotThinking,
      isHintThinking: isHintThinking ?? this.isHintThinking,
    );
  }
}

class ChessController extends Notifier<GameState> {
  int _moveRequestId = 0;
  int _currentSkill = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  GameState build() {
    ref.onDispose(() {
      _engine.stopThinking();
      _audioPlayer.dispose();
    });

    return GameState(
      position: Chess.fromSetup(Setup.parseFen(kStartFen)),
      bot: const Bot(name: '-', elo: 0, imagePath: ''),
      playerSide: Side.white,
    );
  }

  ChessEngine get _engine => ref.read(chessEngineProvider);

  void _playSound(String asset) {
    _audioPlayer.play(AssetSource('sounds/$asset'));
  }

  void _playMoveSound(NormalMove move, Position newPos, bool isBot) {
    String sound;

    final isCastling =
        (move.from == Square.e1 || move.from == Square.e8) &&
        (move.to == Square.h1 ||
            move.to == Square.a1 ||
            move.to == Square.h8 ||
            move.to == Square.a8);

    if (isCastling) {
      sound = 'castle.mp3';
    } else if (move.promotion != null) {
      sound = 'promote.mp3';
    } else if (state.position.board.pieceAt(move.to) != null) {
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
      if (position.turn == state.playerSide) {
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
      bot: bot,
      playerSide: playerSide,
    );

    await _engine.start();
    _engine.setSkillLevel(_currentSkill);

    state = state.copyWith(status: GameStatus.playing);
    _playSound('game-start.mp3');

    if (state.position.turn != playerSide) {
      _requestBotMove();
    }
  }

  void selectSquare(Square square) {
    if (!state.isPlayerTurn) return;

    final piece = state.position.board.pieceAt(square);

    if (state.selectedSquare == null) {
      if (piece == null || piece.color != state.playerSide) return;
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

    if (piece != null && piece.color == state.playerSide) {
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
    state = state.copyWith(status: GameStatus.resigned, isBotThinking: false);
    _playSound('game-end.mp3');
  }

  void undoLastMove() {
    if (state.history.isEmpty) return;

    _moveRequestId++;
    if (state.isBotThinking) _engine.stopThinking();

    final newHistory = List<Position>.from(state.history);
    var restored = newHistory.removeLast();

    if (newHistory.isNotEmpty && restored.turn != state.playerSide) {
      restored = newHistory.removeLast();
    }

    state = state.copyWith(
      position: restored,
      history: newHistory,
      clearSelection: true,
      moveSquares: const [],
      hintSquares: const {},
      status: GameStatus.playing,
      isBotThinking: false,
    );
  }

  Future<void> requestHint() async {
    if (!state.isPlayerTurn || state.isBotThinking) return;

    final requestId = ++_moveRequestId;
    state = state.copyWith(isHintThinking: true);

    _engine.setSkillLevel(20);
    final uci = await _engine.bestMoveForFen(
      state.position.fen,
      thinkTime: const Duration(milliseconds: 500),
    );
    _engine.setSkillLevel(_currentSkill);

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
      if (to == Square.g1)
        target = Square.h1;
      else if (to == Square.c1)
        target = Square.a1;
      else if (to == Square.g8)
        target = Square.h8;
      else if (to == Square.c8)
        target = Square.a8;
    }

    final promotion = _isPromotion(from, target) ? Role.queen : null;
    final move = NormalMove(from: from, to: target, promotion: promotion);

    if (!state.position.isLegal(move)) {
      _playSound('illegal.mp3');
      state = state.copyWith(clearSelection: true);
      return;
    }

    final newPosition = state.position.play(move);
    _playMoveSound(move, newPosition, false);

    state = state.copyWith(
      position: newPosition,
      history: [...state.history, state.position],
      clearSelection: true,
      moveSquares: [move.from, move.to],
      hintSquares: const {},
      status: _statusFor(newPosition),
    );

    if (state.status == GameStatus.playing) {
      _requestBotMove();
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

    _playMoveSound(move, newPosition, true);

    state = state.copyWith(
      position: newPosition,
      history: [...state.history, beforeBotMove],
      moveSquares: [move.from, move.to],
      status: _statusFor(newPosition),
      isBotThinking: false,
    );

    if (state.status != GameStatus.playing) {
      _playGameEndSound(newPosition);
    }
  }

  NormalMove _parseUciMove(String uci) {
    final from = squareAt(_fileFromChar(uci[0]), int.parse(uci[1]) - 1);
    final to = squareAt(_fileFromChar(uci[2]), int.parse(uci[3]) - 1);
    final promotion = uci.length > 4 ? _roleFromChar(uci[4]) : null;
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

  GameStatus _statusFor(Position position) {
    if (position.isCheckmate) return GameStatus.checkmate;
    if (position.outcome != null) return GameStatus.draw;
    if (position.isGameOver) return GameStatus.draw;
    return GameStatus.playing;
  }
}

final chessControllerProvider = NotifierProvider<ChessController, GameState>(
  ChessController.new,
);
