import 'package:dartchess/dartchess.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:Kust/features/game/chess/chess_engine.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';

const String kStartFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

int skillLevelForElo(int elo) {
  const minElo = 800;
  const maxElo = 1400;

  final t = ((elo - minElo) / (maxElo - minElo)).clamp(0.0, 1.0);
  return (t * 20).round();
}

enum GameStatus { playing, checkmate, draw, resigned }

class GameState {
  const GameState({
    required this.position,
    required this.bot,
    required this.playerSide,
    this.selectedSquare,
    this.legalDestinations = const {},
    this.moveSquares = const [],
    this.status = GameStatus.playing,
    this.isBotThinking = false,
  });

  final Position position;
  final Bot bot;
  final Side playerSide;
  final Square? selectedSquare;
  final Set<Square> legalDestinations;
  final List<Square> moveSquares;
  final GameStatus status;
  final bool isBotThinking;

  bool get isPlayerTurn =>
      status == GameStatus.playing && position.turn == playerSide;

  GameState copyWith({
    Position? position,
    Square? selectedSquare,
    bool clearSelection = false,
    Set<Square>? legalDestinations,
    List<Square>? moveSquares,
    GameStatus? status,
    bool? isBotThinking,
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
      status: status ?? this.status,
      isBotThinking: isBotThinking ?? this.isBotThinking,
    );
  }
}

class ChessController extends Notifier<GameState> {
  @override
  GameState build() {
    ref.onDispose(_engine.stopThinking);

    return GameState(
      position: Chess.fromSetup(Setup.parseFen(kStartFen)),
      bot: const Bot(name: '-', elo: 0, imagePath: ''),
      playerSide: Side.white,
    );
  }

  ChessEngine get _engine => ref.read(chessEngineProvider);

  Future<void> startGame(Bot bot, {Side playerSide = Side.white}) async {
    await _engine.start();
    _engine.setSkillLevel(skillLevelForElo(bot.elo));

    state = GameState(
      position: Chess.fromSetup(Setup.parseFen(kStartFen)),
      bot: bot,
      playerSide: playerSide,
    );

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
      );
    } else {
      state = state.copyWith(clearSelection: true);
    }
  }

  void resign() {
    if (state.status != GameStatus.playing) return;
    _engine.stopThinking();
    state = state.copyWith(status: GameStatus.resigned);
  }

  Set<Square> _displayDestinationsFrom(Square square) {
    final piece = state.position.board.pieceAt(square);
    final raw = state.position.legalMovesOf(square).squares.toSet();

    if (piece?.role != Role.king) return raw;
    return raw.map(_castlingDisplaySquare).toSet();
  }

  void _playPlayerMove(Square from, Square to) {
    final target = _castlingMoveTarget(from, to);
    final promotion = _isPromotion(from, to) ? Role.queen : null;
    final move = NormalMove(from: from, to: target, promotion: promotion);

    if (!state.position.isLegal(move)) {
      state = state.copyWith(clearSelection: true);
      return;
    }

    final newPosition = state.position.play(move);

    state = state.copyWith(
      position: newPosition,
      clearSelection: true,
      moveSquares: [from, to],
      status: _statusFor(newPosition),
    );

    if (state.status == GameStatus.playing) {
      _requestBotMove();
    }
  }

  Future<void> _requestBotMove() async {
    if (state.status != GameStatus.playing) return;

    state = state.copyWith(isBotThinking: true);

    final skill = skillLevelForElo(state.bot.elo);
    final thinkTime = Duration(milliseconds: 300 + skill * 40);

    final uci = await _engine.bestMoveForFen(
      state.position.fen,
      thinkTime: thinkTime,
    );

    if (uci == '(none)') {
      state = state.copyWith(isBotThinking: false);
      return;
    }

    final move = _parseUciMove(uci);
    final newPosition = state.position.play(move);

    state = state.copyWith(
      position: newPosition,
      moveSquares: move.squares.toList(),
      status: _statusFor(newPosition),
      isBotThinking: false,
    );
  }

  Move _parseUciMove(String uci) {
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

  Square _castlingMoveTarget(Square from, Square to) {
    final piece = state.position.board.pieceAt(from);
    if (piece?.role != Role.king) return to;

    if (to == Square.g1) return Square.h1;
    if (to == Square.c1) return Square.a1;
    if (to == Square.g8) return Square.h8;
    if (to == Square.c8) return Square.a8;
    return to;
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
