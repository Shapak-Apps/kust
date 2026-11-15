import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/accuracy.dart';
import 'package:kust/features/game/chess/analysis_cache.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';
import 'package:kust/features/history/replay_positions.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';

/// A mistake from a game, set up again: find the move you should have
/// played. Another move that is nearly as good counts too.
class RetryScreen extends StatefulWidget {
  const RetryScreen({
    super.key,
    required this.gameId,
    required this.ply,
    this.record,
    this.analyzer,
  });

  final String gameId;

  /// 1 for White's first move: the move to take back.
  final int ply;

  /// Use this game instead of looking [gameId] up (for tests).
  final GameRecord? record;

  /// Overrides the chess engine (for tests).
  final MoveAnalyzer? analyzer;

  @override
  State<RetryScreen> createState() => _RetryScreenState();
}

enum _Phase { loading, asking, checking, right, wrong, shown, unavailable }

class _RetryScreenState extends State<RetryScreen> {
  /// A move this close to the best (in winning chances, points) is fine.
  static const double _closeEnough = 3;

  late final GameRecord? _game =
      widget.record ?? GameHistoryStore.instance.byId(widget.gameId);
  late final MoveAnalyzer _analyze = widget.analyzer ?? sharedMoveAnalyzer;

  Position? _before;
  Position? _shown;
  NormalMove? _played;
  String? _bestUci;
  _Phase _phase = _Phase.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final game = _game;
    if (game == null) return _fail();
    final replay = replayPositions(game.uciMoves);
    final ply = widget.ply;
    if (ply < 1 || ply >= replay.positions.length) return _fail();
    final before = replay.positions[ply - 1];
    final move = replay.moves[ply];
    if (move == null) return _fail();
    try {
      final a = await _analyze(
        beforeFen: before.fen,
        playedUci: engineUci(move, before),
        afterFen: replay.positions[ply].fen,
        thinkTime: kAnalysisThinkTime,
      );
      if (!mounted) return;
      if (a == null) return _fail();
      setState(() {
        _before = before;
        _shown = before;
        _bestUci = a.bestUci;
        _phase = _Phase.asking;
      });
    } catch (_) {
      _fail();
    }
  }

  void _fail() {
    if (mounted) setState(() => _phase = _Phase.unavailable);
  }

  Future<void> _onMove(NormalMove move) async {
    final before = _before;
    final best = _bestUci;
    if (before == null || best == null) return;
    if (_phase != _Phase.asking && _phase != _Phase.wrong) return;
    final uci = engineUci(move, before);
    if (uci == best) return _right(move);

    setState(() => _phase = _Phase.checking);
    try {
      final a = await _analyze(
        beforeFen: before.fen,
        playedUci: uci,
        afterFen: before.play(move).fen,
        thinkTime: kAnalysisThinkTime,
      );
      if (!mounted) return;
      final close =
          a != null &&
          winPercent(a.bestCp) - winPercent(a.playedCp) <= _closeEnough;
      if (close) return _right(move);
    } catch (_) {
      // Counted as a miss: the answer can still be shown.
    }
    if (mounted) setState(() => _phase = _Phase.wrong);
  }

  void _right(NormalMove move) {
    final before = _before!;
    setState(() {
      _played = move;
      _shown = before.play(move);
      _phase = _Phase.right;
    });
  }

  void _showAnswer() {
    if (_before == null || _bestUci == null) return;
    setState(() => _phase = _Phase.shown);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final before = _before;
    final best = _bestUci;
    ({Square from, Square to})? answer;
    if (_phase == _Phase.shown && best != null) {
      answer = (
        from: Square.fromName(best.substring(0, 2)),
        to: Square.fromName(best.substring(2, 4)),
      );
    }
    final message = switch (_phase) {
      _Phase.right => (t.retryRight, k.success),
      _Phase.wrong => (t.retryWrong, k.danger),
      _Phase.unavailable => (t.retryNoPosition, k.muted),
      _ => (t.retryTitle, k.ink),
    };
    final done = _phase == _Phase.right || _phase == _Phase.shown;

    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          KustTopBar(
            title: t.retryTitle,
            leading: KustIconButton(
              icon: Icons.arrow_back_rounded,
              label: t.back,
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/play'),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  if (before != null)
                    AspectRatio(
                      aspectRatio: 1,
                      child: PuzzleBoard(
                        position: _shown ?? before,
                        flipped: before.turn == Side.black,
                        interactive:
                            _phase == _Phase.asking || _phase == _Phase.wrong,
                        onMove: _onMove,
                        lastMove: _played,
                        arrow: answer,
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(height: 20),
                  Text(
                    message.$1,
                    textAlign: TextAlign.center,
                    style: k.title.copyWith(color: message.$2),
                  ),
                  const Spacer(),
                  if (done || _phase == _Phase.unavailable)
                    KustButton(
                      label: t.back,
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/play'),
                    )
                  else if (before != null)
                    KustButton(
                      label: t.retryShow,
                      style: KustButtonStyle.outline,
                      onTap: _showAnswer,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
