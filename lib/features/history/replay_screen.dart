import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/board/board_geometry.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';
import 'package:kust/features/game/chess/move_feedback.dart';
import 'package:kust/features/game/chess/move_sounds.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/game/evaluation_bar.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/features/game/game_export.dart';
import 'package:kust/features/history/pgn.dart';
import 'package:kust/features/history/replay_positions.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/ui/kust_action_bar.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/move_strip.dart';
import 'package:kust/ui/tokens.dart';

export 'package:kust/features/history/replay_positions.dart';

/// Evaluates a position for the replay's evaluation bar.
typedef ReplayEvaluator = Future<EvalScore?> Function(String fen);

Future<EvalScore?> _engineEvaluator(String fen) =>
    ChessEngine.instance.evaluateFen(fen);

class ReplayScreen extends StatefulWidget {
  const ReplayScreen({
    super.key,
    required this.gameId,
    this.record,
    this.evaluator,
    this.analyzer,
    this.playSound,
  });

  final String gameId;

  /// Use this game instead of looking [gameId] up in the store (for tests).
  final GameRecord? record;

  /// Overrides the chess engine for the evaluation bar (for tests).
  final ReplayEvaluator? evaluator;

  /// Overrides the chess engine for move ratings (for tests).
  final MoveAnalyzer? analyzer;

  /// Overrides sound playback (for tests).
  final void Function(String file)? playSound;

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  late final GameRecord? _game =
      widget.record ?? GameHistoryStore.instance.byId(widget.gameId);
  late final _replay = replayPositions(_game?.uciMoves ?? const []);
  int _ply = 0;
  ({Square from, Square to})? _slide;
  int _slideKey = 0;

  bool _evalOn = false;
  bool _evalFailed = false;
  final Map<int, EvalScore> _evals = {};

  /// Rating each move, with its best alternative, as in a game.
  bool _feedbackOn = true;
  final Map<int, _Review> _reviews = {};
  final Set<int> _reviewing = {};

  int get _last => _replay.positions.length - 1;

  static const String _feedbackPref = 'replay_feedback';

  bool get _canRate => widget.analyzer != null || ChessEngine.isSupported;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() => _feedbackOn = prefs.getBool(_feedbackPref) ?? true);
    });
  }

  Future<void> _setFeedback(bool on) async {
    setState(() => _feedbackOn = on);
    _reviewCurrent();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_feedbackPref, on);
  }

  /// Rates the move that led to the position on the board.
  Future<void> _reviewCurrent() async {
    final ply = _ply;
    if (!_feedbackOn || !_canRate || ply == 0) return;
    if (_reviews.containsKey(ply) || !_reviewing.add(ply)) return;
    final before = _replay.positions[ply - 1];
    final move = _replay.moves[ply]!;
    final after = _replay.positions[ply];
    final playedUci = engineUci(move, before);
    try {
      final analyze = widget.analyzer ?? _engineAnalyze;
      final analysis = await analyze(
        beforeFen: before.fen,
        playedUci: playedUci,
        afterFen: after.fen,
        thinkTime: const Duration(milliseconds: 700),
        isStale: () => !mounted,
      );
      if (!mounted || analysis == null) return;
      final quality = classifyPlayedMove(
        before: before,
        after: after,
        move: move,
        bestCp: analysis.bestCp,
        playedCp: analysis.playedCp,
        secondBestCp: analysis.secondBestCp,
        isBest: analysis.bestUci == playedUci,
      );
      final best = analysis.bestUci;
      final bestFrom = Square.parse(best.substring(0, 2));
      final bestTo = Square.parse(best.substring(2, 4));
      String? bestSan;
      if (bestFrom != null && bestTo != null) {
        final bestMove = NormalMove(
          from: bestFrom,
          to: bestTo,
          promotion: best.length > 4 ? Role.queen : null,
        );
        if (before.isLegal(bestMove)) {
          bestSan = before.makeSan(bestMove).$2;
        }
      }
      setState(() {
        _reviews[ply] = _Review(
          quality: quality,
          bestFrom: bestFrom,
          bestTo: bestTo,
          bestSan: bestSan,
        );
      });
    } catch (_) {
      // No rating for this move; the replay carries on without it.
    } finally {
      _reviewing.remove(ply);
    }
  }

  static Future<MoveAnalysis?> _engineAnalyze({
    required String beforeFen,
    required String playedUci,
    required String afterFen,
    required Duration thinkTime,
    bool Function()? isStale,
  }) => ChessEngine.instance.analyzeMove(
    beforeFen: beforeFen,
    playedUci: playedUci,
    afterFen: afterFen,
    thinkTime: thinkTime,
    isStale: isStale,
  );

  /// Where the piece of the move at [ply] ended up: the king's square for
  /// castling, which is stored as the king taking its rook.
  Square _landing(int ply) {
    final move = _replay.moves[ply]!;
    final before = _replay.positions[ply - 1];
    final piece = before.board.pieceAt(move.from);
    final target = before.board.pieceAt(move.to);
    if (piece?.role == Role.king && target?.color == piece?.color) {
      return Square.fromCoords(
        File(fileOf(move.to) > fileOf(move.from) ? 6 : 2),
        Rank(rankOf(move.to)),
      );
    }
    return move.to;
  }

  /// Jumps to [ply]. A single step glides the piece (backwards when going
  /// back); bigger jumps just set the position.
  void _go(int ply) {
    final target = ply.clamp(0, _last);
    if (target == _ply) return;
    final slide = slideBetween(_replay.positions, _replay.moves, _ply, target);
    final from = _ply;
    setState(() {
      _ply = target;
      _slide = slide;
      _slideKey++;
    });
    _playStepSound(from, target);
    _evaluateCurrent();
    _reviewCurrent();
  }

  /// Sound for a single step; jumps over several moves stay silent.
  void _playStepSound(int from, int to) {
    final String? file;
    if (to == from + 1) {
      file = moveSoundFor(
        _replay.positions[from],
        _replay.moves[to]!,
        _replay.positions[to],
      );
    } else if (to == from - 1) {
      file = 'move.wav';
    } else {
      file = null;
    }
    if (file == null) return;
    (widget.playSound ?? SoundService.instance.playSfx)(file);
  }

  Future<void> _evaluateCurrent() async {
    if (!_evalOn || _evals.containsKey(_ply)) return;
    final ply = _ply;
    final position = _replay.positions[ply];

    if (position.isCheckmate) {
      // Nothing to search: the side that just moved won.
      final whiteWon = position.turn == Side.black;
      setState(() => _evals[ply] = EvalScore(cp: whiteWon ? 3000 : -3000));
      return;
    }

    try {
      final score = await (widget.evaluator ?? _engineEvaluator)(position.fen);
      if (!mounted) return;
      setState(() {
        if (score != null) _evals[ply] = score;
      });
    } catch (_) {
      if (mounted) setState(() => _evalFailed = true);
    }
  }

  void _setEval(bool on) {
    setState(() {
      _evalOn = on;
      _evalFailed = false;
    });
    _evaluateCurrent();
  }

  Future<void> _copyPgn(GameRecord game) async {
    await Clipboard.setData(ClipboardData(text: buildPgn(game)));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('PGN copied')));
  }

  void _openSettings(GameRecord game) {
    showKustSheet<void>(
      context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          final canEvaluate =
              widget.evaluator != null || ChessEngine.isSupported;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KustSheetHeader(title: 'Replay settings'),
              KustToggleRow(
                icon: Icons.align_horizontal_left_rounded,
                title: 'Evaluation bar',
                subtitle: canEvaluate
                    ? 'Shows who is better at each move'
                    : 'Not available on this device',
                value: _evalOn && canEvaluate,
                onChanged: (v) {
                  if (!canEvaluate) return;
                  _setEval(v);
                  setSheet(() {});
                },
              ),
              KustToggleRow(
                icon: Icons.insights_rounded,
                title: 'Move feedback',
                subtitle: _canRate
                    ? 'Rates each move and shows the best one'
                    : 'Not available on this device',
                value: _feedbackOn && _canRate,
                onChanged: (v) {
                  if (!_canRate) return;
                  _setFeedback(v);
                  setSheet(() {});
                },
              ),
              const SizedBox(height: 16),
              KustButton(
                label: 'Copy PGN',
                icon: Icons.copy_rounded,
                style: KustButtonStyle.secondary,
                onTap: game.sanMoves.isEmpty
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        _copyPgn(game);
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final game = _game;

    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          KustTopBar(
            title: game == null
                ? 'Game'
                : game.isLocal
                ? 'Pass & Play'
                : 'vs ${game.botName ?? 'Bot'}',
            subtitle: game == null
                ? null
                : '${describeResult(game)} · ${formatGameDate(game.date)}',
            leading: KustIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/history'),
            ),
            trailing: [
              if (game != null)
                KustIconButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Export game',
                  onTap: () => showExportSheet(
                    context,
                    position: _replay.positions[_ply],
                    flipped: !game.isLocal && !game.playerIsWhite,
                    pgn: buildPgn(game),
                  ),
                ),
              if (game != null)
                KustIconButton(
                  icon: Icons.tune_rounded,
                  label: 'Replay settings',
                  onTap: () => _openSettings(game),
                ),
            ],
          ),
          Expanded(
            child: game == null
                ? const _MissingGame()
                : _buildReplay(context, game),
          ),
        ],
      ),
    );
  }

  Widget _buildReplay(BuildContext context, GameRecord game) {
    final k = context.k;
    final position = _replay.positions[_ply];
    final score = _evals[_ply];
    final review = _feedbackOn && _ply > 0 ? _reviews[_ply] : null;
    // The best move is drawn only when another move was played.
    final showBest =
        review != null &&
        !review.isBest &&
        review.bestFrom != null &&
        review.bestTo != null;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          MoveStrip(
            labels: [
              for (var i = 0; i < game.sanMoves.length; i++)
                moveLabel(i, game.sanMoves[i]),
            ],
            selected: _ply,
            onTap: _go,
          ),
          if (review != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                review.describe(game.sanMoves[_ply - 1]),
                style: k.caption.copyWith(
                  color: review.quality.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (_evalOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _evalFailed
                  ? Text(
                      'Evaluation is unavailable right now',
                      style: k.caption,
                    )
                  : EvaluationBar(
                      score: score,
                      whiteOnLeft: game.isLocal || game.playerIsWhite,
                      showLabel: !position.isCheckmate,
                    ),
            ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: PuzzleBoard(
                  position: position,
                  flipped: !game.isLocal && !game.playerIsWhite,
                  interactive: false,
                  onMove: (_) {},
                  lastMove: _replay.moves[_ply],
                  slide: _slide,
                  slideKey: _slideKey,
                  badge: review == null
                      ? null
                      : (square: _landing(_ply), quality: review.quality),
                  arrow: showBest
                      ? (from: review.bestFrom!, to: review.bestTo!)
                      : null,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: KustActionBar(
              actions: [
                KustAction(
                  icon: Icons.first_page_rounded,
                  label: 'Start',
                  onTap: _ply > 0 ? () => _go(0) : null,
                ),
                KustAction(
                  icon: Icons.chevron_left_rounded,
                  label: 'Back',
                  onTap: _ply > 0 ? () => _go(_ply - 1) : null,
                ),
                KustAction(
                  icon: Icons.chevron_right_rounded,
                  label: 'Forward',
                  onTap: _ply < _last ? () => _go(_ply + 1) : null,
                ),
                KustAction(
                  icon: Icons.last_page_rounded,
                  label: 'End',
                  onTap: _ply < _last ? () => _go(_last) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingGame extends StatelessWidget {
  const _MissingGame();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: k.muted),
            const SizedBox(height: 12),
            Text('This game could not be found.', style: k.body),
            const SizedBox(height: 20),
            KustButton(
              label: 'Back to history',
              expand: false,
              onTap: () => context.go('/history'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rating of one replayed move and the engine's choice instead.
class _Review {
  const _Review({
    required this.quality,
    required this.bestFrom,
    required this.bestTo,
    required this.bestSan,
  });

  final MoveQuality quality;
  final Square? bestFrom;
  final Square? bestTo;
  final String? bestSan;

  bool get isBest =>
      quality == MoveQuality.best ||
      quality == MoveQuality.brilliant ||
      quality == MoveQuality.great;

  /// 'Nf3 was a mistake · d4 was best', or 'e4 · best move'.
  String describe(String playedSan) => MoveFeedback(
    quality: quality,
    bestSan: bestSan ?? '',
    playedSan: playedSan,
  ).bannerText;
}
