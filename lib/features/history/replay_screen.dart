import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/move_sounds.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/game/evaluation_bar.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/features/history/pgn.dart';
import 'package:kust/features/history/replay_positions.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
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
    this.playSound,
  });

  final String gameId;

  /// Use this game instead of looking [gameId] up in the store (for tests).
  final GameRecord? record;

  /// Overrides the chess engine for the evaluation bar (for tests).
  final ReplayEvaluator? evaluator;

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

  int get _last => _replay.positions.length - 1;

  @override
  void dispose() {
    super.dispose();
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
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                KustIconButton(
                  icon: Icons.first_page_rounded,
                  label: 'First move',
                  size: 48,
                  onTap: _ply > 0 ? () => _go(0) : null,
                ),
                KustIconButton(
                  icon: Icons.chevron_left_rounded,
                  label: 'Previous move',
                  size: 48,
                  onTap: _ply > 0 ? () => _go(_ply - 1) : null,
                ),
                KustIconButton(
                  icon: Icons.chevron_right_rounded,
                  label: 'Next move',
                  size: 48,
                  onTap: _ply < _last ? () => _go(_ply + 1) : null,
                ),
                KustIconButton(
                  icon: Icons.last_page_rounded,
                  label: 'Last move',
                  size: 48,
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
