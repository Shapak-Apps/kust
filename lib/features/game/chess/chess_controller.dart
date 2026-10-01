import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Kust/core/storage/app_storage.dart';
import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:Kust/features/game/chess/bot_policy.dart';
import 'package:Kust/features/game/chess/chess_engine.dart';
import 'package:Kust/features/game/chess/chess_helpers.dart';
import 'package:Kust/features/game/chess/move_feedback.dart';
import 'package:Kust/features/game/chess/move_record.dart';
import 'package:Kust/features/game/chess/sound_service.dart';
import 'package:Kust/features/game/time_control.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';

const String kStartFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

const Duration kBotMinMoveTime = Duration(milliseconds: 400);

const String kEvalBarPrefKey = 'eval_bar_enabled';
const String kMoveFeedbackPrefKey = 'move_feedback_enabled';

enum GameStatus { loading, playing, checkmate, draw, resigned, timeout }

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
    this.timeControl,
    this.whiteTimeLeft = Duration.zero,
    this.blackTimeLeft = Duration.zero,
    this.practiceMode = true,
    this.evaluationEnabled = false,
    this.evaluation,
    this.analysisIndex,
    this.moveFeedbackEnabled = true,
    this.feedbackAnalyzing = false,
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

  final TimeControl? timeControl;
  final Duration whiteTimeLeft;
  final Duration blackTimeLeft;

  final bool practiceMode;
  final bool evaluationEnabled;
  final EvalScore? evaluation;

  final int? analysisIndex;

  final bool moveFeedbackEnabled;

  final bool feedbackAnalyzing;

  bool get isPlayerTurn =>
      status == GameStatus.playing &&
      (mode == GameMode.local || position.turn == playerSide);

  bool get canUndo {
    if (status != GameStatus.playing) return false;
    if (history.isEmpty || isBotThinking) return false;
    if (!practiceMode) return false;

    if (mode == GameMode.local) return true;

    if (position.turn == playerSide) {
      return history.length >= 2;
    }

    return true;
  }

  bool get isSelfAnalysisActive {
    final index = analysisIndex;
    if (index == null) return false;
    if (moves.isEmpty) return false;
    return index >= 0 && index < moves.length;
  }

  int get analysisCursor {
    final index = analysisIndex;
    if (index == null) return moves.length;
    if (index < 0) return 0;
    if (index > moves.length) return moves.length;
    return index;
  }

  Position get displayPosition {
    if (!isSelfAnalysisActive) return position;
    final index = analysisIndex!;
    if (index < history.length) return history[index];
    return position;
  }

  List<Square> get displayMoveSquares {
    if (!isSelfAnalysisActive) return moveSquares;

    final index = analysisIndex!;
    if (index == 0) return const <Square>[];

    final move = moves[index - 1].move;
    return [move.from, move.to];
  }

  Set<Square> get displayHintSquares =>
      isSelfAnalysisActive ? const <Square>{} : hintSquares;

  Set<Square> get displayLegalDestinations =>
      isSelfAnalysisActive ? const <Square>{} : legalDestinations;

  Square? get displaySelectedSquare =>
      isSelfAnalysisActive ? null : selectedSquare;

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
    TimeControl? timeControl,
    Duration? whiteTimeLeft,
    Duration? blackTimeLeft,
    bool? practiceMode,
    bool? evaluationEnabled,
    EvalScore? evaluation,
    bool clearEvaluation = false,
    int? analysisIndex,
    bool clearAnalysis = false,
    bool? moveFeedbackEnabled,
    bool? feedbackAnalyzing,
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
      timeControl: timeControl ?? this.timeControl,
      whiteTimeLeft: whiteTimeLeft ?? this.whiteTimeLeft,
      blackTimeLeft: blackTimeLeft ?? this.blackTimeLeft,
      practiceMode: practiceMode ?? this.practiceMode,
      evaluationEnabled: evaluationEnabled ?? this.evaluationEnabled,
      evaluation: clearEvaluation ? null : (evaluation ?? this.evaluation),
      analysisIndex: clearAnalysis
          ? null
          : (analysisIndex ?? this.analysisIndex),
      moveFeedbackEnabled: moveFeedbackEnabled ?? this.moveFeedbackEnabled,
      feedbackAnalyzing: feedbackAnalyzing ?? this.feedbackAnalyzing,
    );
  }
}

class ChessController extends Notifier<GameState> {
  int _moveRequestId = 0;
  int _evalRequestId = 0;
  BotPolicy _policy = BotPolicy(elo: 1400);
  bool _isDisposed = false;
  int _feedbackEpoch = 0;
  final Set<int> _feedbackPending = <int>{};
  final Map<String, int> _repCounts = <String, int>{};

  Timer? _clockTimer;
  DateTime? _lastTick;
  Duration _whiteClock = Duration.zero;
  Duration _blackClock = Duration.zero;

  @override
  GameState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      _stopClock();
    });

    final keepAliveLink = ref.keepAlive();
    Timer? keepAliveTimer;
    ref.onCancel(() {
      keepAliveTimer?.cancel();
      keepAliveTimer = Timer(const Duration(seconds: 30), keepAliveLink.close);
    });
    ref.onResume(() {
      keepAliveTimer?.cancel();
    });
    ref.onDispose(() {
      keepAliveTimer?.cancel();
    });

    return GameState(
      position: Chess.fromSetup(Setup.parseFen(kStartFen)),
      mode: GameMode.bot,
      bot: const Bot(id: '-', name: '-', elo: 0, imagePath: ''),
      playerSide: Side.white,
    );
  }

  ChessEngine get _engine => ref.read(chessEngineProvider);

  bool get _timed => state.timeControl != null;

  bool get canAnalysisMoveBack {
    if (state.status != GameStatus.playing) return false;
    if (state.isBotThinking) return false;
    if (state.moves.isEmpty) return false;

    return state.analysisCursor > 0;
  }

  bool get canAnalysisMoveNext {
    if (state.status != GameStatus.playing) return false;
    if (state.isBotThinking) return false;
    if (state.moves.isEmpty) return false;
    if (state.analysisIndex == null) return false;

    return state.analysisCursor < state.moves.length;
  }

  void _initClocks(TimeControl? timeControl) {
    _stopClock();

    if (timeControl == null) {
      _whiteClock = Duration.zero;
      _blackClock = Duration.zero;
      return;
    }

    _whiteClock = timeControl.base;
    _blackClock = timeControl.base;
    _lastTick = DateTime.now();
    _clockTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _onClockTick(),
    );
  }

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
    _lastTick = null;
  }

  void _onClockTick() {
    if (_isDisposed) return;
    if (state.status != GameStatus.playing || !_timed) {
      _stopClock();
      return;
    }
    _chargeElapsed();
  }

  bool _chargeElapsed({bool publish = true}) {
    if (!_timed || _lastTick == null) return true;

    final now = DateTime.now();
    final elapsed = now.difference(_lastTick!);
    _lastTick = now;

    if (elapsed > Duration.zero) {
      if (state.position.turn == Side.white) {
        _whiteClock -= elapsed;
        if (_whiteClock <= Duration.zero) {
          _whiteClock = Duration.zero;
          _publishClock();
          _flagFell(Side.white);
          return false;
        }
      } else {
        _blackClock -= elapsed;
        if (_blackClock <= Duration.zero) {
          _blackClock = Duration.zero;
          _publishClock();
          _flagFell(Side.black);
          return false;
        }
      }
    }

    if (publish) _publishClock();
    return true;
  }

  void _addIncrement(Side mover) {
    final increment = state.timeControl?.increment ?? Duration.zero;
    if (increment == Duration.zero) return;

    if (mover == Side.white) {
      _whiteClock += increment;
    } else {
      _blackClock += increment;
    }
    _publishClock();
  }

  void _publishClock() {
    if (!_timed || _isDisposed) return;

    final white = TimeControl.display(_whiteClock);
    final black = TimeControl.display(_blackClock);

    if (white == state.whiteTimeLeft && black == state.blackTimeLeft) return;

    state = state.copyWith(whiteTimeLeft: white, blackTimeLeft: black);
  }

  void _flagFell(Side fellSide) {
    if (_isDisposed) return;
    _stopClock();

    final String winner;
    if (state.mode == GameMode.local) {
      winner = fellSide == Side.white ? 'Black' : 'White';
    } else {
      winner = fellSide == state.playerSide ? state.bot!.name : 'You';
    }

    state = state.copyWith(
      status: GameStatus.timeout,
      isBotThinking: false,
      clearSelection: true,
      endReason: '$winner won on time.',
    );

    if (state.mode == GameMode.local || fellSide == state.playerSide) {
      SoundService.instance.playJingle('game-end.wav');
    } else {
      SoundService.instance.playJingle('game-win.wav');
      _recordBotWin();
    }
  }

  String _repKey(Position p) {
    final parts = p.fen.split(' ');
    return parts.length >= 4 ? parts.sublist(0, 4).join(' ') : p.fen;
  }

  int _registerPosition(Position p) {
    final key = _repKey(p);
    final count = (_repCounts[key] ?? 0) + 1;
    _repCounts[key] = count;
    return count;
  }

  void _rebuildRepetitions(List<Position> history, Position current) {
    _repCounts.clear();
    for (final p in history) {
      _registerPosition(p);
    }
    _registerPosition(current);
  }

  void _playSound(String asset) {
    if (_isDisposed) return;
    SoundService.instance.playSfx(asset);
  }

  void _playCheckSound() {
    _playSound('check.wav');
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
      sound = 'castle.wav';
    } else if (move.promotion != null) {
      sound = 'promote.wav';
    } else if (isCapture) {
      sound = 'capture.wav';
    } else {
      sound = isBot ? 'move-opponent.wav' : 'move.wav';
    }

    _playSound(sound);

    if (newPos.isCheck) {
      _playCheckSound();
    }

    if (isCapture || newPos.isCheck) {
      SoundService.instance.buzz(heavy: true);
    } else {
      SoundService.instance.buzz();
    }
  }

  void _playGameEndSound(Position position) {
    if (position.isCheckmate) {
      if (state.mode == GameMode.local) {
        SoundService.instance.playJingle('game-end.wav');
      } else if (position.turn == state.playerSide) {
        SoundService.instance.playJingle('game-end.wav');
      } else {
        SoundService.instance.playJingle('game-win.wav');
        _recordBotWin();
      }
    } else {
      SoundService.instance.playJingle('game-draw.wav');
    }
  }

  void _recordBotWin() {
    if (state.mode != GameMode.bot) return;
    final bot = state.bot;
    if (bot == null) return;
    if (state.practiceMode) return;
    unawaited(AppStorage.instance.markBotBeaten(bot.id));
  }

  Future<void> setMoveFeedbackEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kMoveFeedbackPrefKey, enabled);
    if (_isDisposed) return;
    state = state.copyWith(moveFeedbackEnabled: enabled);
    if (enabled) {
      _analyzeLastPlayerMove();
    }
  }

  int _evalToCp(EvalScore score) {
    if (score.mate != null) {
      // Treat mate as a very large advantage for the mating side.
      return score.mate! > 0 ? 100000 : -100000;
    }
    return score.cp ?? 0;
  }

  void _clearFeedbackAnalyzing() {
    if (_isDisposed) return;
    if (state.feedbackAnalyzing) {
      state = state.copyWith(feedbackAnalyzing: false);
    }
  }

  bool _isPlayerMove(MoveRecord played) {
    if (state.mode == GameMode.local) return true;
    return played.side == state.playerSide;
  }

  int _lastPlayerMoveIndex() {
    for (var i = state.moves.length - 1; i >= 0; i--) {
      if (_isPlayerMove(state.moves[i])) return i;
    }
    return -1;
  }

  void _analyzeLastPlayerMove() {
    final index = _lastPlayerMoveIndex();
    if (index >= 0) unawaited(_analyzeMoveAt(index));
  }

  void _resetFeedbackQueue() {
    _feedbackEpoch++;
    _feedbackPending.clear();
  }

  String _uciFor(NormalMove move, Position before) {
    final piece = before.board.pieceAt(move.from);
    final target = before.board.pieceAt(move.to);
    var to = move.to;
    if (piece != null &&
        piece.role == Role.king &&
        target != null &&
        target.color == piece.color) {
      to = _castlingDisplaySquare(to);
    }
    final promotion = move.promotion == null
        ? ''
        : _promotionChar(move.promotion!);
    return '${squareName(move.from)}${squareName(to)}$promotion';
  }

  Future<void> _analyzeMoveAt(int moveIndex) async {
    if (_isDisposed) return;
    if (!state.practiceMode || !state.moveFeedbackEnabled) return;
    if (moveIndex < 0 || moveIndex >= state.moves.length) return;
    if (moveIndex >= state.history.length) return;

    final played = state.moves[moveIndex];
    if (played.feedback != null) return;
    if (!_isPlayerMove(played)) return;
    if (!_feedbackPending.add(moveIndex)) return;

    final epoch = _feedbackEpoch;
    final beforePos = state.history[moveIndex];

    try {
      final afterPos = beforePos.play(played.move);
      final playedUci = _uciFor(played.move, beforePos);

      state = state.copyWith(feedbackAnalyzing: true);

      final analysis = await _engine.analyzeMove(
        beforeFen: beforePos.fen,
        playedUci: playedUci,
        afterFen: afterPos.fen,
        isStale: () => _isDisposed || epoch != _feedbackEpoch,
      );

      if (_isDisposed || epoch != _feedbackEpoch || analysis == null) return;
      if (moveIndex >= state.moves.length) return;
      if (state.moves[moveIndex].san != played.san) return;

      final bestMove = _parseUciMove(analysis.bestUci);
      if (!beforePos.isLegal(bestMove)) return;

      final bestSan = moveToSan(
        before: beforePos,
        move: bestMove,
        after: beforePos.play(bestMove),
        capturedSquare: _capturedSquareFor(beforePos, bestMove),
      );

      final lossCp = (analysis.bestCp - analysis.playedCp).clamp(0, 100000);
      final isBest = analysis.bestUci == playedUci || lossCp <= 10;
      final quality = isBest
          ? MoveQuality.best
          : classifyMoveLoss(lossCp, isBestMove: false);

      final feedback = MoveFeedback(
        quality: quality,
        bestSan: bestSan,
        playedSan: played.san,
        evalLossCp: lossCp,
      );

      final updated = List<MoveRecord>.of(state.moves);
      updated[moveIndex] = updated[moveIndex].copyWith(
        feedback: feedback,
        bestSan: bestSan,
      );
      state = state.copyWith(moves: updated);
    } catch (_) {
    } finally {
      if (epoch == _feedbackEpoch) _feedbackPending.remove(moveIndex);
      if (!_isDisposed && _feedbackPending.isEmpty && state.feedbackAnalyzing) {
        state = state.copyWith(feedbackAnalyzing: false);
      }
    }
  }

  String _promotionChar(Role role) {
    switch (role) {
      case Role.knight:
        return 'n';
      case Role.bishop:
        return 'b';
      case Role.rook:
        return 'r';
      case Role.queen:
      default:
        return 'q';
    }
  }

  Future<void> _loadEvalEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(kEvalBarPrefKey) ?? false;
    final feedback = prefs.getBool(kMoveFeedbackPrefKey) ?? true;
    if (_isDisposed) return;
    if (enabled != state.evaluationEnabled ||
        feedback != state.moveFeedbackEnabled) {
      state = state.copyWith(
        evaluationEnabled: enabled,
        moveFeedbackEnabled: feedback,
      );
    }
    if (enabled) _refreshEvaluation();
  }

  Future<void> startGame(
    Bot bot, {
    Side playerSide = Side.white,
    TimeControl? timeControl,
    bool practiceMode = false,
  }) async {
    _moveRequestId++;
    _evalRequestId++;
    _resetFeedbackQueue();
    _policy = BotPolicy(
      elo: bot.elo,
      seed: DateTime.now().microsecondsSinceEpoch,
    );
    _initClocks(timeControl);

    final base = timeControl?.base ?? Duration.zero;

    state = GameState(
      position: Chess.fromSetup(Setup.parseFen(kStartFen)),
      mode: GameMode.bot,
      bot: bot,
      playerSide: playerSide,
      moves: const [],
      timeControl: timeControl,
      whiteTimeLeft: base,
      blackTimeLeft: base,
      practiceMode: practiceMode,
      evaluationEnabled: state.evaluationEnabled,
      moveFeedbackEnabled: state.moveFeedbackEnabled,
      status: GameStatus.playing,
    );

    _rebuildRepetitions(const <Position>[], state.position);
    _playSound('game-start.wav');
    unawaited(_loadEvalEnabled());

    unawaited(
      _engine.start().then((_) {
        if (_isDisposed) return;
        _engine.setSkillLevel(_policy.skillLevel, uciElo: _policy.uciElo);
        if (state.position.turn != playerSide) {
          _requestBotMove();
        }
      }),
    );
  }

  Future<void> startLocalGame({TimeControl? timeControl}) async {
    _moveRequestId++;
    _evalRequestId++;
    _resetFeedbackQueue();
    _initClocks(timeControl);

    final base = timeControl?.base ?? Duration.zero;

    state = GameState(
      position: Chess.fromSetup(Setup.parseFen(kStartFen)),
      mode: GameMode.local,
      bot: null,
      playerSide: Side.white,
      moves: const [],
      status: GameStatus.playing,
      timeControl: timeControl,
      whiteTimeLeft: base,
      blackTimeLeft: base,
      practiceMode: true,
      evaluationEnabled: state.evaluationEnabled,
      moveFeedbackEnabled: state.moveFeedbackEnabled,
    );

    _rebuildRepetitions(const <Position>[], state.position);
    _playSound('game-start.wav');
    unawaited(_loadEvalEnabled());
  }

  Future<void> setEvaluationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kEvalBarPrefKey, enabled);

    if (_isDisposed) return;

    state = state.copyWith(
      evaluationEnabled: enabled,
      clearEvaluation: !enabled,
    );

    if (enabled) _refreshEvaluation();
  }

  Future<void> _refreshEvaluation() async {
    if (_isDisposed || !state.evaluationEnabled) return;
    if (state.status != GameStatus.playing &&
        state.status != GameStatus.checkmate &&
        state.status != GameStatus.draw) {
      return;
    }

    final id = ++_evalRequestId;
    final fen = state.position.fen;

    final score = await _engine.evaluateFen(
      fen,
      isStale: () => _isDisposed || id != _evalRequestId,
    );

    if (_isDisposed || id != _evalRequestId) return;
    if (state.position.fen != fen) return;

    state = state.copyWith(evaluation: score);
  }

  void selectSquare(Square square) {
    if (state.isSelfAnalysisActive) return;
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
    _stopClock();

    state = state.copyWith(
      status: GameStatus.resigned,
      isBotThinking: false,
      endReason: 'You resigned.',
    );

    SoundService.instance.playJingle('game-end.wav');
  }

  void undoLastMove() {
    if (!state.canUndo) return;

    if (!_chargeElapsed(publish: false)) return;

    _moveRequestId++;
    _evalRequestId++;
    _resetFeedbackQueue();
    if (state.isBotThinking) _engine.stopThinking();

    final oldHistory = state.history;
    final oldMoves = state.moves;

    final newHistory = List<Position>.from(oldHistory);
    final newMoves = List<MoveRecord>.from(oldMoves);

    var restored = newHistory.removeLast();

    if (state.mode != GameMode.local &&
        newHistory.isNotEmpty &&
        restored.turn != state.playerSide) {
      restored = newHistory.removeLast();
    }

    final removedCount = oldHistory.length - newHistory.length;
    final trimCount = removedCount.clamp(0, newMoves.length);
    if (trimCount > 0) {
      newMoves.removeRange(newMoves.length - trimCount, newMoves.length);
    }

    _rebuildRepetitions(newHistory, restored);

    NormalMove? undoMove;
    Square? capturedSquare;
    Piece? capturedPiece;

    if (oldMoves.isNotEmpty) {
      final lastUndone = oldMoves.last;
      undoMove = NormalMove(from: lastUndone.move.to, to: lastUndone.move.from);

      if (lastUndone.capturedPiece != null && oldHistory.isNotEmpty) {
        final posBeforeLastUndone = oldHistory[oldHistory.length - 1];
        final sq = _capturedSquareFor(posBeforeLastUndone, lastUndone.move);
        if (sq != null) {
          capturedSquare = sq;
          capturedPiece = lastUndone.capturedPiece;
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
      clearAnalysis: true,
      feedbackAnalyzing: false,
    );

    _refreshEvaluation();
  }

  void analysisMoveBack() {
    if (!canAnalysisMoveBack) return;

    final newIndex = state.analysisCursor - 1;
    if (newIndex < 0) return;

    state = state.copyWith(
      clearSelection: true,
      hintSquares: const <Square>{},
      analysisIndex: newIndex,
    );
  }

  void analysisMoveNext() {
    if (!canAnalysisMoveNext) return;

    final newIndex = state.analysisCursor + 1;

    if (newIndex >= state.moves.length) {
      state = state.copyWith(
        clearSelection: true,
        hintSquares: const <Square>{},
        clearAnalysis: true,
      );
      return;
    }

    state = state.copyWith(
      clearSelection: true,
      hintSquares: const <Square>{},
      analysisIndex: newIndex,
    );
  }

  void jumpToMove(int index) {
    if (state.status != GameStatus.playing) return;
    if (state.isBotThinking) return;
    if (index < 0 || index >= state.moves.length) return;

    final newIndex = index + 1;

    if (newIndex >= state.moves.length) {
      state = state.copyWith(
        clearSelection: true,
        hintSquares: const <Square>{},
        clearAnalysis: true,
      );
      return;
    }

    state = state.copyWith(
      clearSelection: true,
      hintSquares: const <Square>{},
      analysisIndex: newIndex,
    );
  }

  void stopEngineWork() {
    _engine.stopThinking();
  }

  Future<void> requestHint() async {
    if (!state.isPlayerTurn || state.isBotThinking) return;
    if (!state.practiceMode) return;
    if (state.mode == GameMode.local) return;

    final requestId = ++_moveRequestId;
    state = state.copyWith(isHintThinking: true);

    final uci = await _engine.evaluateBestHint(state.position.fen);

    if (_isDisposed || requestId != _moveRequestId) return;

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
    if (!_chargeElapsed(publish: false)) return;

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
      _playSound('illegal.wav');
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

    final repetitions = _registerPosition(newPosition);
    final gameStatus = _statusFor(newPosition, repetitions);
    final reason = _getEndReason(newPosition, repetitions, gameStatus);

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
      clearAnalysis: true,
    );

    if (state.status == GameStatus.playing) {
      _addIncrement(oldPosition.turn);
      if (state.mode == GameMode.bot) _requestBotMove();
      _refreshEvaluation();
      unawaited(_analyzeMoveAt(state.moves.length - 1));
    } else {
      _stopClock();
      _playGameEndSound(newPosition);
      _refreshEvaluation();
    }
  }

  Future<void> _requestBotMove() async {
    final requestId = ++_moveRequestId;
    state = state.copyWith(isBotThinking: true);

    final startedAt = DateTime.now();
    final policy = _policy;

    Move? move;
    if (policy.shouldBlunder()) {
      move = policy.randomLegalMove(state.position);
      if (move != null) {
        await Future.delayed(
          Duration(milliseconds: 250 + Random().nextInt(350)),
        );
      }
    }

    if (move == null) {
      final uci = await _engine.bestMoveForFen(
        state.position.fen,
        thinkTime: policy.thinkTime,
      );

      if (uci == '(none)' || uci.length < 4) {
        if (_isDisposed || requestId != _moveRequestId) return;
        state = state.copyWith(isBotThinking: false);
        return;
      }

      move = _parseUciMove(uci);
    }

    final remaining = kBotMinMoveTime - DateTime.now().difference(startedAt);
    if (remaining > Duration.zero) await Future.delayed(remaining);

    if (_isDisposed || requestId != _moveRequestId) return;

    if (state.status != GameStatus.playing) {
      state = state.copyWith(isBotThinking: false);
      return;
    }

    if (move is! NormalMove || !state.position.isLegal(move)) {
      state = state.copyWith(isBotThinking: false);
      return;
    }

    if (!_chargeElapsed(publish: false)) return;

    final normalMove = move;
    final beforeBotMove = state.position;
    final newPosition = beforeBotMove.play(move);

    final updatedHistory = [...state.history, beforeBotMove];

    final capturedSquare = _capturedSquareFor(beforeBotMove, normalMove);
    final capturedPiece = capturedSquare == null
        ? null
        : beforeBotMove.board.pieceAt(capturedSquare);

    final san = moveToSan(
      before: beforeBotMove,
      move: normalMove,
      after: newPosition,
      capturedSquare: capturedSquare,
    );

    final updatedMoves = [
      ...state.moves,
      MoveRecord(
        side: beforeBotMove.turn,
        san: san,
        move: normalMove,
        capturedPiece: capturedPiece,
      ),
    ];

    _playMoveSound(normalMove, beforeBotMove, newPosition, true);

    final repetitions = _registerPosition(newPosition);
    final gameStatus = _statusFor(newPosition, repetitions);
    final reason = _getEndReason(newPosition, repetitions, gameStatus);

    state = state.copyWith(
      position: newPosition,
      history: updatedHistory,
      moves: updatedMoves,
      moveSquares: [normalMove.from, normalMove.to],
      status: gameStatus,
      isBotThinking: false,
      lastMove: normalMove,
      capturedPiece: capturedPiece,
      capturedSquare: capturedSquare,
      clearCapture: capturedPiece == null,
      wasUndo: false,
      endReason: reason,
      clearAnalysis: true,
    );

    if (state.status != GameStatus.playing) {
      _stopClock();
      _playGameEndSound(newPosition);
    } else {
      _addIncrement(beforeBotMove.turn);
    }

    _refreshEvaluation();
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

  GameStatus _statusFor(Position position, int repetitions) {
    if (position.isCheckmate) return GameStatus.checkmate;
    if (position.isStalemate ||
        position.halfmoves >= 100 ||
        position.isInsufficientMaterial ||
        repetitions >= 3 ||
        position.isGameOver) {
      return GameStatus.draw;
    }
    return GameStatus.playing;
  }

  String? _getEndReason(Position position, int repetitions, GameStatus status) {
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
      if (repetitions >= 3) {
        return 'Game drawn by threefold repetition.';
      }
      return 'The game ended in a draw.';
    }

    return null;
  }
}

final chessControllerProvider =
    NotifierProvider.autoDispose<ChessController, GameState>(
      ChessController.new,
    );
