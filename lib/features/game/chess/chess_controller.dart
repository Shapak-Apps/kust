import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kust/core/settings.dart';
import 'package:kust/features/achievements/achievement_tracker.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/game/chess/board/board_geometry.dart';
import 'package:kust/features/game/chess/bot_policy.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/chess_helpers.dart';
import 'package:kust/features/game/chess/move_feedback.dart';
import 'package:kust/features/game/chess/premoves.dart';
import 'package:kust/features/game/chess/move_record.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/game/time_control.dart';
import 'package:kust/features/play/pick_opponent_modal.dart';

const String kStartFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

const String kEvalBarPrefKey = 'eval_bar_enabled';
const String kMoveFeedbackPrefKey = 'move_feedback_enabled';
const String kShowBestPrefKey = 'show_best_enabled';

/// How deep, and at most how long, a standout move rating is checked again.
const int kFeedbackCheckDepth = 16;
const Duration kFeedbackCheckTime = Duration(milliseconds: 800);

/// Why a game ended in a draw, or on time without a winner.
enum EndReason {
  stalemate,
  fiftyMove,
  insufficientMaterial,
  repetition,
  drawn,
  timeNoMate,
}

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
    this.suggestSquares = const {},
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
    this.flagFell,
    this.resignedSide,
    this.timeControl,
    this.whiteTimeLeft = Duration.zero,
    this.blackTimeLeft = Duration.zero,
    this.practiceMode = true,
    this.evaluationEnabled = false,
    this.evaluation,
    this.analysisIndex,
    this.moveFeedbackEnabled = false,
    this.showBestEnabled = true,
    this.feedbackAnalyzing = false,
    this.pendingPromotion,
    this.premoves = const [],
    this.paused = false,
    this.lastMoveInstant = false,
    this.engineFailed = false,
    this.ratingChange,
    this.accuracy,
    this.accuracyPending = false,
  });

  final Position position;
  final GameMode mode;
  final Bot? bot;
  final Side playerSide;
  final Square? selectedSquare;
  final Set<Square> legalDestinations;
  final List<Square> moveSquares;
  final Set<Square> hintSquares;

  /// Show best: the two squares of the best move for the player to play now,
  /// kept up to date while it is the player's turn in a practice game.
  final Set<Square> suggestSquares;

  /// The same as an arrow, or null.
  ({Square from, Square to})? get suggestArrow => suggestSquares.length == 2
      ? (from: suggestSquares.first, to: suggestSquares.last)
      : null;
  final List<Position> history;
  final List<MoveRecord> moves;
  final GameStatus status;
  final bool isBotThinking;
  final bool isHintThinking;

  final NormalMove? lastMove;
  final Piece? capturedPiece;
  final Square? capturedSquare;
  final bool wasUndo;

  /// Why a drawn or timed-out game ended, for the message shown.
  final EndReason? endReason;

  /// The side whose clock ran out, when the game ended on time.
  final Side? flagFell;

  /// Who gave up, once the game ended by resigning.
  final Side? resignedSide;

  final TimeControl? timeControl;
  final Duration whiteTimeLeft;
  final Duration blackTimeLeft;

  final bool practiceMode;
  final bool evaluationEnabled;
  final EvalScore? evaluation;

  final int? analysisIndex;

  final bool moveFeedbackEnabled;

  /// In a practice game, an arrow to the better move after one of yours
  /// that was not the best.
  final bool showBestEnabled;

  final bool feedbackAnalyzing;
  final ({Square from, Square to})? pendingPromotion;

  /// Whether the clocks of a timed pass-and-play game are stopped; the
  /// board waits until the game is resumed.
  final bool paused;

  /// Whether the clocks can be paused now: a timed local game in progress.
  bool get canPause =>
      mode == GameMode.local &&
      timeControl != null &&
      status == GameStatus.playing;

  /// Moves queued while the bot thinks, played one after each of its
  /// moves, first first.
  final List<Premove> premoves;

  /// Whether the last move appeared in place without gliding: a premove,
  /// which the board already showed made.
  final bool lastMoveInstant;

  ({Board board, int valid}) get _premoveView =>
      premoveBoard(position.board, playerSide, premoves);

  /// The premoves that still make sense on the board.
  List<Premove> get livePremoves =>
      premoves.isEmpty ? premoves : premoves.sublist(0, _premoveView.valid);

  /// The position the board shows: queued premoves are drawn already made,
  /// the way chess.com shows them.
  Position get boardPosition {
    if (premoves.isEmpty || isSelfAnalysisActive) return displayPosition;
    return position.copyWith(board: _premoveView.board);
  }

  /// Whether the player may queue a premove now: a bot game, the bot to
  /// move. (The setting is checked by the controller.)
  bool get canPremove =>
      status == GameStatus.playing &&
      mode == GameMode.bot &&
      position.turn != playerSide &&
      !isSelfAnalysisActive;

  /// The engine could not start or stopped responding during a bot game.
  final bool engineFailed;

  /// Rating points gained or lost in this game, once it has been recorded.
  final int? ratingChange;

  /// Average accuracy of the player's moves once the finished game has been
  /// analyzed, 0..100.
  final double? accuracy;

  /// The finished game is still being analyzed for [accuracy].
  final bool accuracyPending;

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

  /// Whether the game can be called off without a result: before the
  /// player has made a move (in pass and play, before black has).
  bool get canAbort {
    if (status != GameStatus.playing) return false;
    if (mode == GameMode.local) return moves.length < 2;
    return !moves.any((m) => m.side == playerSide);
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
    Set<Square>? suggestSquares,
    List<Position>? history,
    List<MoveRecord>? moves,
    GameStatus? status,
    bool? isBotThinking,
    bool? isHintThinking,
    NormalMove? lastMove,
    Piece? capturedPiece,
    Square? capturedSquare,
    bool? wasUndo,
    EndReason? endReason,
    Side? flagFell,
    Side? resignedSide,
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
    bool? showBestEnabled,
    bool? feedbackAnalyzing,
    ({Square from, Square to})? pendingPromotion,
    List<Premove>? premoves,
    bool? lastMoveInstant,
    bool? paused,
    bool? engineFailed,
    int? ratingChange,
    double? accuracy,
    bool? accuracyPending,
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
      suggestSquares: suggestSquares ?? this.suggestSquares,
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
      flagFell: flagFell ?? this.flagFell,
      resignedSide: resignedSide ?? this.resignedSide,
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
      showBestEnabled: showBestEnabled ?? this.showBestEnabled,
      feedbackAnalyzing: feedbackAnalyzing ?? this.feedbackAnalyzing,
      pendingPromotion: clearSelection
          ? null
          : (pendingPromotion ?? this.pendingPromotion),
      premoves: premoves ?? this.premoves,
      paused: paused ?? this.paused,
      lastMoveInstant: lastMoveInstant ?? this.lastMoveInstant,
      engineFailed: engineFailed ?? this.engineFailed,
      ratingChange: ratingChange ?? this.ratingChange,
      accuracy: accuracy ?? this.accuracy,
      accuracyPending: accuracyPending ?? this.accuracyPending,
    );
  }
}

class ChessController extends Notifier<GameState> {
  int _moveRequestId = 0;
  int _evalRequestId = 0;
  BotPolicy _policy = BotPolicy(elo: 1400);

  /// Counts hint requests, so a stale hint knows whether a newer one runs.
  int _hintRequestId = 0;
  bool _isDisposed = false;
  int _feedbackEpoch = 0;

  /// Whether a move of this game was rated brilliant.
  bool _brilliantThisGame = false;
  int _accuracyEpoch = 0;
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
    listenSelf(_onStateChanged);

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

  /// Moves can be stepped through while playing and once the game is over
  /// (to look back at it), but not while the bot is thinking.
  bool get _canReview =>
      state.status != GameStatus.loading && !state.isBotThinking;

  bool get canAnalysisMoveBack {
    if (!_canReview) return false;
    if (state.moves.isEmpty) return false;

    return state.analysisCursor > 0;
  }

  bool get canAnalysisMoveNext {
    if (!_canReview) return false;
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

  /// Stops both clocks of a timed local game, e.g. for a break.
  void pauseClock() {
    if (!state.canPause || state.paused) return;
    if (!_chargeElapsed()) return;
    _stopClock();
    state = state.copyWith(paused: true, clearSelection: true);
  }

  /// Starts the clocks again where they stopped.
  void resumeClock() {
    if (!state.paused) return;
    state = state.copyWith(paused: false);
    if (state.status != GameStatus.playing || !_timed) return;
    _lastTick = DateTime.now();
    _clockTimer?.cancel();
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

    // FIDE 6.9: if the other side cannot mate by any series of moves (a
    // lone king, say), running out of time is a draw.
    if (state.position.hasInsufficientMaterial(fellSide.opposite)) {
      state = state.copyWith(
        status: GameStatus.draw,
        isBotThinking: false,
        clearSelection: true,
        premoves: const [],
        endReason: EndReason.timeNoMate,
      );
      SoundService.instance.playJingle('game-draw.wav');
      return;
    }

    state = state.copyWith(
      status: GameStatus.timeout,
      isBotThinking: false,
      clearSelection: true,
      flagFell: fellSide,
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
        oldPos.board.pieceAt(move.from)?.role == Role.king &&
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

  Future<void> _playQualityFeedback(MoveQuality quality) async {
    switch (quality) {
      case MoveQuality.brilliant:
      case MoveQuality.great:
        SoundService.instance.buzzMedium();
        break;
      case MoveQuality.mistake:
      case MoveQuality.miss:
      case MoveQuality.blunder:
        SoundService.instance.buzz(heavy: true);
        break;
      default:
        break;
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

  Future<void> setShowBestEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kShowBestPrefKey, enabled);
    if (_isDisposed) return;
    state = state.copyWith(showBestEnabled: enabled);
    // On: an arrow for the position now, and it stays up to date until the
    // switch goes off.
    if (enabled) {
      unawaited(_refreshSuggestion());
    } else {
      _cancelSuggestion();
      state = state.copyWith(suggestSquares: const {});
    }
  }

  int _suggestId = 0;
  bool _suggesting = false;

  /// Drops a suggestion being worked out and stops its search, so the bot is
  /// not kept waiting for it.
  void _cancelSuggestion() {
    _suggestId++;
    if (_suggesting) {
      _suggesting = false;
      _engine.stopThinking();
    }
  }

  /// Works out the best move for the position on the board, when it is the
  /// player's turn in a practice game with Show best on, and shows it.
  Future<void> _refreshSuggestion() async {
    if (_isDisposed) return;
    _cancelSuggestion();
    final id = _suggestId;
    if (state.suggestSquares.isNotEmpty) {
      state = state.copyWith(suggestSquares: const {});
    }
    if (!state.showBestEnabled ||
        !state.practiceMode ||
        state.mode != GameMode.bot ||
        state.status != GameStatus.playing ||
        !state.isPlayerTurn ||
        state.isBotThinking) {
      return;
    }
    final fen = state.position.fen;
    _suggesting = true;
    final String uci;
    try {
      uci = await _engine.evaluateBestHint(fen);
    } catch (_) {
      return;
    } finally {
      if (id == _suggestId) _suggesting = false;
    }
    if (_isDisposed || id != _suggestId || state.position.fen != fen) return;
    if (uci == '(none)' || uci.length < 4) return;
    final from = squareAt(_fileFromChar(uci[0]), int.parse(uci[1]) - 1);
    final to = squareAt(_fileFromChar(uci[2]), int.parse(uci[3]) - 1);
    state = state.copyWith(suggestSquares: {from, to});
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

      var analysis = await _engine.analyzeMove(
        beforeFen: beforePos.fen,
        playedUci: playedUci,
        afterFen: afterPos.fen,
        isStale: () => _isDisposed || epoch != _feedbackEpoch,
      );

      if (_isDisposed || epoch != _feedbackEpoch || analysis == null) return;
      if (moveIndex >= state.moves.length) return;
      if (state.moves[moveIndex].san != played.san) return;

      MoveQuality rate(MoveAnalysis a) => classifyPlayedMove(
        before: beforePos,
        after: afterPos,
        move: played.move,
        bestCp: a.bestCp,
        playedCp: a.playedCp,
        secondBestCp: a.secondBestCp,
        isBest: a.bestUci == playedUci,
      );

      var quality = rate(analysis);
      // The labels that stand out (brilliant, great, mistake, blunder) get a
      // deeper second look before they are shown: a shallow search can miss
      // the refutation of a sacrifice, or the idea behind a move that only
      // looks bad. A wrong "Blunder" is worse than a moment's wait.
      if (quality.needsCheck) {
        final deeper = await _engine.analyzeMove(
          beforeFen: beforePos.fen,
          playedUci: playedUci,
          afterFen: afterPos.fen,
          thinkTime: kFeedbackCheckTime,
          depth: kFeedbackCheckDepth,
          isStale: () => _isDisposed || epoch != _feedbackEpoch,
        );
        if (_isDisposed || epoch != _feedbackEpoch) return;
        if (deeper != null) {
          analysis = deeper;
          quality = rate(deeper);
        }
      }
      if (moveIndex >= state.moves.length) return;
      if (state.moves[moveIndex].san != played.san) return;

      final bestMove = _parseUciMove(analysis.bestUci, beforePos);
      if (!beforePos.isLegal(bestMove)) return;

      final bestSan = moveToSan(
        before: beforePos,
        move: bestMove,
        after: beforePos.play(bestMove),
        capturedSquare: _capturedSquareFor(beforePos, bestMove),
      );

      final lossCp = (analysis.bestCp - analysis.playedCp).clamp(0, 100000);

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
        bestMove: bestMove,
      );
      state = state.copyWith(moves: updated);
      if (state.moveFeedbackEnabled) {
        unawaited(_playQualityFeedback(quality));
      }
      // Celebrated when the game ends, not over the board mid-game.
      if (quality == MoveQuality.brilliant) _brilliantThisGame = true;
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
    final feedback = prefs.getBool(kMoveFeedbackPrefKey) ?? false;
    final showBest = prefs.getBool(kShowBestPrefKey) ?? true;
    if (_isDisposed) return;
    if (enabled != state.evaluationEnabled ||
        feedback != state.moveFeedbackEnabled ||
        showBest != state.showBestEnabled) {
      state = state.copyWith(
        evaluationEnabled: enabled,
        moveFeedbackEnabled: feedback,
        showBestEnabled: showBest,
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
    _accuracyEpoch++;
    _resetFeedbackQueue();
    _brilliantThisGame = false;
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
      showBestEnabled: state.showBestEnabled,
      status: GameStatus.playing,
    );

    _rebuildRepetitions(const <Position>[], state.position);
    _playSound('game-start.wav');
    unawaited(_loadEvalEnabled());

    unawaited(
      _engine
          .start()
          .then((_) {
            if (_isDisposed) return;
            _engine.setSkillLevel(_policy.skillLevel, uciElo: _policy.uciElo);
            if (state.position.turn != playerSide) {
              _requestBotMove();
            } else {
              unawaited(_refreshSuggestion());
            }
          })
          .catchError((Object _) {
            if (!_isDisposed) state = state.copyWith(engineFailed: true);
          }),
    );
  }

  Future<void> startLocalGame({TimeControl? timeControl}) async {
    _moveRequestId++;
    _evalRequestId++;
    _accuracyEpoch++;
    _resetFeedbackQueue();
    _brilliantThisGame = false;
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
      showBestEnabled: state.showBestEnabled,
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

    // A mated side has no move to search (the engine says "mate 0"): the
    // bar goes all the way to the side that gave mate.
    if (state.position.isCheckmate) {
      final whiteWon = state.position.turn == Side.black;
      state = state.copyWith(
        evaluation: EvalScore(
          mate: whiteWon ? 1 : -1,
          result: whiteWon ? '1-0' : '0-1',
        ),
      );
      return;
    }

    final EvalScore? score;
    try {
      score = await _engine.evaluateFen(
        fen,
        isStale: () => _isDisposed || id != _evalRequestId,
      );
    } catch (_) {
      return;
    }

    if (_isDisposed || id != _evalRequestId) return;
    if (state.position.fen != fen) return;

    state = state.copyWith(evaluation: score);
  }

  /// Whether a tap or drag now queues a premove instead of a move.
  bool get _premoving =>
      AppSettings.instance.premoves.value && state.canPremove;

  void selectSquare(Square square) {
    if (state.isSelfAnalysisActive || state.paused) return;
    if (_premoving) {
      _selectPremove(square);
      return;
    }
    if (!state.isPlayerTurn) return;

    final piece = state.position.board.pieceAt(square);

    if (state.selectedSquare == null) {
      if (piece == null) {
        // Premoves waiting from earlier turns go with a tap on an empty
        // square, as when they were queued.
        if (state.premoves.isNotEmpty &&
            _premoveBoard.pieceAt(square) == null) {
          state = state.copyWith(premoves: const []);
        }
        return;
      }
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
      // Premoves waiting from earlier turns go with a tap on an empty
      // square, as when they were queued.
      final emptyTap =
          state.premoves.isNotEmpty && _premoveBoard.pieceAt(square) == null;
      state = state.copyWith(
        clearSelection: true,
        premoves: emptyTap ? const [] : null,
      );
    }
  }

  /// The board as the player sees it, queued premoves made.
  Board get _premoveBoard => state.boardPosition.board;

  /// While the bot thinks: a tap on one of the selected piece's squares
  /// queues that premove (captures included, also onto your own piece for
  /// the recapture), a tap on another of your pieces selects it, and a tap
  /// anywhere else cancels every premove.
  void _selectPremove(Square square) {
    final piece = _premoveBoard.pieceAt(square);
    final mine = piece != null && piece.color == state.playerSide;
    final selected = state.selectedSquare;

    // A destination is a premove even when one of your own pieces stands
    // there: that is the premove capture back, once the bot has taken it.
    if (selected != null &&
        selected != square &&
        state.legalDestinations.contains(square)) {
      _queuePremove(selected, square);
      return;
    }
    if (selected == square) {
      state = state.copyWith(clearSelection: true);
      return;
    }
    if (mine) {
      state = state.copyWith(
        selectedSquare: square,
        legalDestinations: _premoveDestinationsFrom(square),
        hintSquares: const {},
      );
      return;
    }
    state = state.copyWith(premoves: const [], clearSelection: true);
  }

  void _queuePremove(Square from, Square to, {Role? promotion}) {
    final queue = state.livePremoves;
    if (queue.length >= kMaxPremoves) {
      state = state.copyWith(clearSelection: true);
      return;
    }
    // A pawn premoved to the last rank waits for the piece to be picked,
    // like a real promotion.
    if (promotion == null &&
        premovePromotes(_premoveBoard, from, to, state.playerSide)) {
      state = state.copyWith(clearSelection: true);
      state = state.copyWith(pendingPromotion: (from: from, to: to));
      return;
    }
    state = state.copyWith(
      premoves: [...queue, (from: from, to: to, promotion: promotion)],
      clearSelection: true,
    );
    SoundService.instance.buzz();
  }

  /// Where the piece on [square] may be premoved, on the board as the
  /// queued premoves leave it.
  Set<Square> _premoveDestinationsFrom(Square square) => premoveDestinations(
    _premoveBoard,
    square,
    state.playerSide,
    castles: state.position.castles,
    castleOnRook: AppSettings.instance.castleOnRook.value,
  );

  /// Plays the first queued premove now that the bot has moved, if it is
  /// legal; otherwise they all wait for the next bot move. The rest
  /// wait for the bot's next move. A pawn on the last rank becomes the
  /// piece picked when it was queued.
  void _playPremove() {
    final queue = state.livePremoves;
    if (queue.isEmpty) {
      if (state.premoves.isNotEmpty) {
        state = state.copyWith(premoves: const []);
      }
      return;
    }
    final next = queue.first;
    if (!AppSettings.instance.premoves.value) {
      state = state.copyWith(premoves: const [], clearSelection: true);
      return;
    }
    // Not legal yet (the piece to take has not arrived, say): the premoves
    // wait for a later turn. Your clock runs while they wait; a tap on an
    // empty square clears them.
    if (!state.isPlayerTurn ||
        !_displayDestinationsFrom(next.from).contains(next.to)) {
      return;
    }
    state = state.copyWith(premoves: queue.sublist(1), clearSelection: true);
    _playPlayerMove(
      next.from,
      next.to,
      promotion: _isPromotion(next.from, next.to)
          ? (next.promotion ?? Role.queen)
          : null,
      instant: true,
    );
  }

  /// Picks up the piece on [square] to drag it: selects it and shows where
  /// it can go, without the tap toggle of [selectSquare]. Returns whether
  /// there is a piece here the player may move.
  bool pickUp(Square square) {
    if (state.isSelfAnalysisActive || state.paused) return false;
    if (_premoving) {
      final piece = _premoveBoard.pieceAt(square);
      if (piece == null || piece.color != state.playerSide) return false;
      state = state.copyWith(
        selectedSquare: square,
        legalDestinations: _premoveDestinationsFrom(square),
        hintSquares: const {},
      );
      return true;
    }
    if (!state.isPlayerTurn) return false;
    final piece = state.position.board.pieceAt(square);
    if (piece == null) return false;
    final mine = state.mode == GameMode.local
        ? piece.color == state.position.turn
        : piece.color == state.playerSide;
    if (!mine) return false;
    if (state.selectedSquare != square) {
      state = state.copyWith(
        selectedSquare: square,
        legalDestinations: _displayDestinationsFrom(square),
        hintSquares: const {},
      );
    }
    return true;
  }

  /// Drops the picked-up piece on [square]. Plays the move and returns true
  /// when it is legal; otherwise leaves the piece selected.
  bool dropOn(Square square) {
    final from = state.selectedSquare;
    if (from == null || !state.legalDestinations.contains(square)) {
      return false;
    }
    if (_premoving) {
      _queuePremove(from, square);
      return true;
    }
    _playPlayerMove(from, square);
    return true;
  }

  void resign() {
    if (state.status != GameStatus.playing) return;

    _moveRequestId++;
    _engine.stopThinking();
    _stopClock();

    state = state.copyWith(
      status: GameStatus.resigned,
      resignedSide: state.mode == GameMode.local
          ? state.position.turn
          : state.playerSide,
      isBotThinking: false,
      premoves: const [],
    );

    SoundService.instance.playJingle('game-end.wav');
  }

  /// Calls the game off before it has really started: nothing is recorded.
  void abort() {
    if (!state.canAbort) return;
    _moveRequestId++;
    _engine.stopThinking();
    _stopClock();
    state = state.copyWith(isBotThinking: false, premoves: const []);
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
      suggestSquares: const {},
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
      premoves: const [],
      lastMoveInstant: false,
    );
    _playSound(capturedPiece != null ? 'capture.wav' : 'move.wav');

    _refreshEvaluation();
    unawaited(_refreshSuggestion());
  }

  void analysisMoveBack() {
    if (!canAnalysisMoveBack) return;

    final newIndex = state.analysisCursor - 1;
    if (newIndex < 0) return;

    final undone = state.moves[newIndex];
    state = state.copyWith(
      clearSelection: true,
      hintSquares: const <Square>{},
      analysisIndex: newIndex,
    );
    _playSound(undone.capturedPiece != null ? 'capture.wav' : 'move.wav');
  }

  void analysisMoveNext() {
    if (!canAnalysisMoveNext) return;

    final newIndex = state.analysisCursor + 1;
    final replayed = state.moves[newIndex - 1];
    _playMoveSound(
      replayed.move,
      state.history[newIndex - 1],
      newIndex < state.history.length
          ? state.history[newIndex]
          : state.position,
      false,
    );

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

  void completePromotion(Role role) {
    final pending = state.pendingPromotion;
    if (pending == null) return;
    if (_premoving) {
      state = state.copyWith(clearSelection: true);
      _queuePremove(pending.from, pending.to, promotion: role);
      return;
    }
    if (state.status != GameStatus.playing) {
      state = state.copyWith(clearSelection: true);
      return;
    }
    _playPlayerMove(pending.from, pending.to, promotion: role);
  }

  void cancelPromotion() {
    if (state.pendingPromotion == null) return;
    state = state.copyWith(clearSelection: true);
  }

  void stopEngineWork() {
    _engine.stopThinking();
  }

  /// Tries to bring the engine back after [GameState.engineFailed].
  Future<void> retryEngine() async {
    if (state.mode != GameMode.bot || state.status != GameStatus.playing) {
      return;
    }
    state = state.copyWith(engineFailed: false);
    try {
      await _engine.start();
      if (_isDisposed) return;
      _engine.setSkillLevel(_policy.skillLevel, uciElo: _policy.uciElo);
      if (state.position.turn != state.playerSide && !state.isBotThinking) {
        _requestBotMove();
      }
    } catch (_) {
      if (!_isDisposed) state = state.copyWith(engineFailed: true);
    }
  }

  void _onStateChanged(GameState? previous, GameState next) {
    if (previous == null) return;
    final wasPlaying = previous.status == GameStatus.playing;
    final isOver =
        next.status != GameStatus.playing && next.status != GameStatus.loading;
    if (wasPlaying && isOver) {
      // Outside the notification so state can be updated afterwards.
      scheduleMicrotask(() => _recordFinishedGame(next));
    }
  }

  Future<void> _recordFinishedGame(GameState game) async {
    if (_isDisposed || game.moves.isEmpty) return;
    final isLocal = game.mode == GameMode.local;

    final String result;
    if (game.status == GameStatus.draw) {
      result = GameRecord.draw;
    } else {
      final String? winner;
      switch (game.status) {
        case GameStatus.checkmate:
          winner = game.position.turn == Side.white ? 'black' : 'white';
        case GameStatus.timeout:
          winner = game.flagFell?.opposite.name;
        case GameStatus.resigned:
          winner = game.resignedSide?.opposite.name;
        default:
          winner = null;
      }
      if (isLocal) {
        result = winner == 'white' ? GameRecord.whiteWon : GameRecord.blackWon;
      } else {
        result = winner == game.playerSide.name
            ? GameRecord.win
            : GameRecord.loss;
      }
    }

    int? ratingChange;
    final bot = game.bot;
    if (!isLocal && !game.practiceMode && bot != null) {
      final score = result == GameRecord.win
          ? 1.0
          : result == GameRecord.draw
          ? 0.5
          : 0.0;
      ratingChange = await PlayerRatingStore.instance.record(
        opponent: bot.elo,
        score: score,
      );
      if (_isDisposed) return;
      state = state.copyWith(ratingChange: ratingChange);
    }

    final tc = game.timeControl;
    final recordId = DateTime.now().microsecondsSinceEpoch.toString();
    await GameHistoryStore.instance.add(
      GameRecord(
        id: recordId,
        playedAt: DateTime.now().millisecondsSinceEpoch,
        isLocal: isLocal,
        result: result,
        reason: game.endReason?.name ?? '',
        playerIsWhite: game.playerSide == Side.white,
        uciMoves: [for (final m in game.moves) m.move.uci],
        sanMoves: [for (final m in game.moves) m.san],
        botId: bot?.id,
        botName: bot?.name,
        botElo: bot?.elo,
        practice: game.practiceMode,
        ratingChange: ratingChange,
        timeControl: tc == null
            ? null
            : '${tc.baseMinutes}+${tc.incrementSeconds}',
      ),
    );

    if (!isLocal && bot != null) {
      unawaited(
        AchievementTracker.gameFinished(
          won: result == GameRecord.win,
          byCheckmate: game.status == GameStatus.checkmate,
          practice: game.practiceMode,
          playerMoves: game.moves
              .where((m) => m.side == game.playerSide)
              .length,
          totalMoves: (game.moves.length + 1) ~/ 2,
          botElo: bot.elo,
          playerRating: PlayerRatingStore.instance.rating - (ratingChange ?? 0),
        ),
      );
      if (_brilliantThisGame) unawaited(AchievementTracker.brilliantMove());
    }
    if (!isLocal) unawaited(_computeAccuracy(game, recordId));
  }

  /// Most player moves analyzed per game, to keep the wait short.
  static const int _maxAccuracyMoves = 80;

  /// Rates every move the player made against the engine's best move, then
  /// stores the average on the saved game and publishes it for the result
  /// sheet. Stops quietly when a new game starts or the engine is missing.
  Future<void> _computeAccuracy(GameState game, String recordId) async {
    final epoch = ++_accuracyEpoch;
    bool stale() => _isDisposed || epoch != _accuracyEpoch;

    final jobs = playerMoveJobs(
      positions: game.history,
      moves: [for (final m in game.moves) m.move],
      playerIsWhite: game.playerSide == Side.white,
      maxMoves: _maxAccuracyMoves,
    );
    if (jobs.length < kMinAnalysisMoves) return;

    state = state.copyWith(accuracyPending: true);
    final double? value;
    try {
      value = await GameAnalyzer().accuracy(jobs, isStale: stale);
    } catch (_) {
      if (!stale()) state = state.copyWith(accuracyPending: false);
      return;
    }
    if (stale()) return;

    state = state.copyWith(accuracy: value, accuracyPending: false);
    if (value != null) {
      unawaited(AchievementTracker.accuracy(value));
      // The result sheet has just shown it, so History shows it too, for
      // good, instead of hiding it behind Analyze.
      await GameHistoryStore.instance.setAccuracy(
        recordId,
        value,
        analyzed: true,
      );
    }
  }

  Future<void> requestHint() async {
    if (!state.isPlayerTurn || state.isBotThinking) return;
    if (!state.practiceMode) return;
    if (state.mode == GameMode.local) return;

    final requestId = ++_moveRequestId;
    final hintId = ++_hintRequestId;
    state = state.copyWith(isHintThinking: true);

    final String uci;
    try {
      uci = await _engine.evaluateBestHint(state.position.fen);
    } catch (_) {
      if (!_isDisposed && requestId == _moveRequestId) {
        state = state.copyWith(isHintThinking: false, engineFailed: true);
      }
      return;
    }

    if (_isDisposed) return;
    if (requestId != _moveRequestId) {
      // A move or take back came first: the hint is out of date. Free the
      // button, unless a newer hint is already on its way.
      if (hintId == _hintRequestId && state.isHintThinking) {
        state = state.copyWith(isHintThinking: false);
      }
      return;
    }

    if (uci == '(none)') {
      state = state.copyWith(isHintThinking: false);
      return;
    }

    final from = squareAt(_fileFromChar(uci[0]), int.parse(uci[1]) - 1);
    final to = squareAt(_fileFromChar(uci[2]), int.parse(uci[3]) - 1);

    state = state.copyWith(hintSquares: {from, to}, isHintThinking: false);
  }

  Set<Square> _displayDestinationsFrom(Square square, {Position? on}) {
    final position = on ?? state.position;
    final piece = position.board.pieceAt(square);
    if (piece == null) return {};

    final rawDestinations = position.legalMovesOf(square).squares.toSet();
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
        // The rook itself is a target too when castling on the rook is on.
        if (AppSettings.instance.castleOnRook.value) displaySquares.add(dest);
      } else {
        displaySquares.add(dest);
      }
    }

    return displaySquares;
  }

  void _playPlayerMove(
    Square from,
    Square to, {
    Role? promotion,
    bool instant = false,
  }) {
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

    final needsPromotion = _isPromotion(from, target);

    if (needsPromotion && promotion == null) {
      final probe = NormalMove(from: from, to: target, promotion: Role.queen);
      if (!state.position.isLegal(probe)) {
        _playSound('illegal.wav');
        state = state.copyWith(clearSelection: true);
        return;
      }
      state = state.copyWith(pendingPromotion: (from: from, to: target));
      return;
    }

    if (!_chargeElapsed(publish: false)) return;

    final move = NormalMove(
      from: from,
      to: target,
      promotion: needsPromotion ? promotion : null,
    );

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
      suggestSquares: const {},
      status: gameStatus,
      lastMove: move,
      lastMoveInstant: instant,
      capturedPiece: capturedPiece,
      capturedSquare: capturedSquare,
      clearCapture: capturedPiece == null,
      wasUndo: false,
      endReason: reason,
      clearAnalysis: true,
    );

    _cancelSuggestion();
    if (state.status == GameStatus.playing) {
      _addIncrement(oldPosition.turn);
      // The engine works one request at a time, in order: rate the move
      // first so its feedback shows at once instead of after the bot's reply.
      unawaited(
        _analyzeMoveAt(state.moves.length - 1).whenComplete(_refreshEvaluation),
      );
      if (state.mode == GameMode.bot) _requestBotMove();
    } else {
      _stopClock();
      _playGameEndSound(newPosition);
      _refreshEvaluation();
    }
  }

  /// What the bot has left on its clock, or null in an untimed game.
  Duration? _botClockLeft() {
    final left = state.playerSide == Side.white
        ? state.blackTimeLeft
        : state.whiteTimeLeft;
    return left > Duration.zero ? left : null;
  }

  Future<void> _requestBotMove() async {
    final requestId = ++_moveRequestId;
    state = state.copyWith(isBotThinking: true);

    final startedAt = DateTime.now();
    final policy = _policy;

    final String uci;
    Duration delay = Duration.zero;
    try {
      final candidates = await _engine.candidateMoves(
        state.position.fen,
        lines: policy.lines,
        depth: policy.depth,
        thinkTime: policy.thinkTime,
      );
      uci = candidates.isEmpty
          ? '(none)'
          : policy.pick(
              candidates,
              phase: phaseOf(state.position.fen, state.moves.length),
            );
      delay = policy.moveDelay(
        candidates,
        phase: phaseOf(state.position.fen, state.moves.length),
        clockLeft: _botClockLeft(),
      );
    } catch (_) {
      if (!_isDisposed && requestId == _moveRequestId) {
        state = state.copyWith(isBotThinking: false, engineFailed: true);
      }
      return;
    }

    if (uci == '(none)' || uci.length < 4) {
      if (_isDisposed || requestId != _moveRequestId) return;
      state = state.copyWith(isBotThinking: false);
      return;
    }

    final move = _parseUciMove(uci, state.position);

    final remaining = delay - DateTime.now().difference(startedAt);
    if (remaining > Duration.zero) await Future.delayed(remaining);

    if (_isDisposed || requestId != _moveRequestId) return;

    if (state.status != GameStatus.playing) {
      state = state.copyWith(isBotThinking: false);
      return;
    }

    if (!state.position.isLegal(move)) {
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
      lastMoveInstant: false,
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
      state = state.copyWith(premoves: const []);
    } else {
      _addIncrement(beforeBotMove.turn);
      // Straight away, as on chess.com: the board shows the premove made
      // already, so it appears in place while the bot's piece still glides.
      _playPremove();
    }

    _refreshEvaluation();
    if (state.status == GameStatus.playing) unawaited(_refreshSuggestion());
  }

  NormalMove _parseUciMove(String uci, Position position) {
    var from = squareAt(_fileFromChar(uci[0]), int.parse(uci[1]) - 1);
    var to = squareAt(_fileFromChar(uci[2]), int.parse(uci[3]) - 1);

    final promotion = uci.length > 4 ? _roleFromChar(uci[4]) : null;

    if (position.board.pieceAt(from)?.role == Role.king) {
      if (from == Square.e1 && to == Square.g1) {
        to = Square.h1;
      } else if (from == Square.e1 && to == Square.c1) {
        to = Square.a1;
      } else if (from == Square.e8 && to == Square.g8) {
        to = Square.h8;
      } else if (from == Square.e8 && to == Square.c8) {
        to = Square.a8;
      }
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

  EndReason? _getEndReason(
    Position position,
    int repetitions,
    GameStatus status,
  ) {
    if (status != GameStatus.draw) return null;
    if (position.isStalemate) return EndReason.stalemate;
    if (position.halfmoves >= 100) return EndReason.fiftyMove;
    if (position.isInsufficientMaterial) return EndReason.insufficientMaterial;
    if (repetitions >= 3) return EndReason.repetition;
    return EndReason.drawn;
  }
}

final chessControllerProvider =
    NotifierProvider.autoDispose<ChessController, GameState>(
      ChessController.new,
    );
