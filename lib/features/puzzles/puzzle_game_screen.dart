import 'dart:async';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/achievements/achievement_tracker.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/puzzles/coach_bubble.dart';
import 'package:kust/features/puzzles/daily.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/features/puzzles/puzzle_coach.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/features/puzzles/puzzle_session.dart';
import 'package:kust/features/puzzles/loom_progress.dart';
import 'package:kust/features/puzzles/puzzle_theme.dart';
import 'package:kust/features/puzzles/puzzles_screen.dart' show kLoomLevels;
import 'package:kust/features/puzzles/woven_dialog.dart';
import 'package:kust/ui/kust_action_bar.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/more_sheet.dart';

const Duration _opponentDelay = Duration(milliseconds: 350);
const Duration _mistakeDelay = Duration(milliseconds: 700);

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({
    super.key,
    required this.level,
    required this.index,
    this.progress,
    this.daily = false,
    this.dailyStore,
  });

  final int level;
  final int index;

  /// Where results are recorded; the saved progress store unless a test
  /// passes its own.
  final PuzzleProgressRecorder? progress;

  /// Whether this is the puzzle of the day, whose solving feeds the streak.
  final bool daily;

  /// Where the streak is kept; the saved one unless a test passes its own.
  final DailyRecorder? dailyStore;

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  PuzzleEntry? _puzzle;
  PuzzleSession? _session;
  String? _error;
  int _puzzleCount = 0;
  List<PuzzleEntry> _levelPuzzles = const [];
  int _index = 0;

  /// Whether the level after this one has puzzles to move on to.
  bool _hasNextLevel = false;

  int _ply = 0;
  ({Square from, Square to})? _slide;
  int _slideKey = 0;
  bool _busy = false;
  bool _mistakeFlash = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _session = null;
    });
    final PuzzleLevel level;
    try {
      level = await PuzzleRepository.instance.loadLevel(widget.level);
    } on PuzzleDataException catch (e) {
      if (mounted) setState(() => _error = e.message);
      return;
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load this puzzle');
      return;
    }
    if (!mounted) return;
    if (level.puzzles.isEmpty) {
      setState(() => _error = 'No puzzles are available yet');
      return;
    }

    final index = widget.index.clamp(0, level.puzzles.length - 1).toInt();
    final puzzle = level.puzzles[index];

    setState(() {
      _puzzle = puzzle;
      _session = PuzzleSession(puzzle);
      _puzzleCount = level.puzzles.length;
      _levelPuzzles = level.puzzles;
      _index = index;
      _ply = 0;
    });
    _probeNextLevel();
  }

  /// Finds out whether a next level exists, so the last puzzle of a level
  /// can offer to continue there.
  Future<void> _probeNextLevel() async {
    try {
      final next = await PuzzleRepository.instance.loadLevel(widget.level + 1);
      if (mounted) setState(() => _hasNextLevel = next.puzzles.isNotEmpty);
    } catch (_) {
      if (mounted) setState(() => _hasNextLevel = false);
    }
  }

  PuzzleProgressRecorder get _recorder =>
      widget.progress ?? PuzzleProgressStore.instance;

  PuzzleSession get _s => _session!;

  Position get _position => _s.positions[_ply];

  /// Shows [ply] and glides the piece there when it is one move away.
  void _showPly(int ply) {
    final slide = slideBetween(_s.positions, _s.lastMoves, _ply, ply);
    setState(() {
      _ply = ply;
      _slide = slide;
      _slideKey++;
    });
  }

  bool get _atTip => _ply == _s.positions.length - 1;

  bool get _solved => _s.status == PuzzleStatus.solved;

  bool get _revealed => _s.status == PuzzleStatus.revealed;

  void _playMoveFeedback(
    Position before,
    NormalMove move,
    Position after,
    bool isUser,
  ) {
    final piece = before.board.pieceAt(move.from);
    final target = before.board.pieceAt(move.to);
    final isCastle =
        piece?.role == Role.king &&
        target != null &&
        target.color == piece?.color;
    final isCapture = target != null && !isCastle;
    final isCheck = after.isCheck;

    String sound;
    if (isCastle) {
      sound = 'castle.wav';
    } else if (move.promotion != null) {
      sound = 'promote.wav';
    } else if (isCapture) {
      sound = 'capture.wav';
    } else {
      sound = isUser ? 'move.wav' : 'move-opponent.wav';
    }

    SoundService.instance.playSfx(isCheck ? 'check.wav' : sound);

    if (isCapture || isCheck) {
      SoundService.instance.buzz(heavy: true);
    } else {
      SoundService.instance.buzz();
    }
  }

  void _onUserMove(NormalMove move) {
    final puzzle = _puzzle;
    if (puzzle == null || _busy || _s.isFinished) return;

    if (!_atTip) {
      _showPly(_s.positions.length - 1);
      return;
    }

    final before = _s.position;
    final result = _s.submit(move);
    switch (result) {
      case PuzzleMoveResult.ignored:
        return;
      case PuzzleMoveResult.incorrect:
        _onMistake(puzzle);
        return;
      case PuzzleMoveResult.correct:
      case PuzzleMoveResult.solved:
        _playMoveFeedback(before, move, _s.position, true);
        _showPly(_s.positions.length - 1);
    }

    if (result == PuzzleMoveResult.solved) {
      _onSolved(puzzle);
      return;
    }

    _busy = true;
    _timer = Timer(_opponentDelay, () => _playOpponent(puzzle));
  }

  void _playOpponent(PuzzleEntry puzzle) {
    if (!mounted) return;
    final before = _s.position;
    final reply = _s.playReply();
    if (reply == null) {
      setState(() => _busy = false);
      return;
    }

    _playMoveFeedback(before, reply, _s.position, false);
    _busy = false;
    _showPly(_s.positions.length - 1);

    if (_solved) _onSolved(puzzle);
  }

  void _onMistake(PuzzleEntry puzzle) {
    SoundService.instance.playSfx('illegal.wav');
    SoundService.instance.buzz(heavy: true);
    if (_s.mistakes == 1) {
      unawaited(_recorder.recordMistake(puzzle));
    }

    // Point at the piece to move, not at where it goes.
    _s.revealPieceHint();
    setState(() {
      _mistakeFlash = true;
      _busy = true;
    });

    _timer = Timer(_mistakeDelay, () {
      if (!mounted) return;
      setState(() {
        _mistakeFlash = false;
        _busy = false;
      });
    });
  }

  void _onSolved(PuzzleEntry puzzle) {
    _busy = false;
    SoundService.instance.playJingle('game-win.wav');
    SoundService.instance.buzzMedium();
    if (mounted) setState(() {});
    unawaited(
      _record(() => _recorder.recordSolved(puzzle, clean: _s.mistakes == 0)),
    );
    if (widget.daily) {
      unawaited(
        (widget.dailyStore ?? DailyStore.instance)
            .markSolved(DateTime.now())
            .then((_) {
              if (widget.dailyStore == null) {
                return AchievementTracker.dailySolved();
              }
            }),
      );
    }
  }

  /// Saves a result, and when it weaves the last knot of the level, shows the
  /// finished göl.
  Future<void> _record(
    Future<void> Function() write, {
    Duration wait = const Duration(milliseconds: 900),
  }) async {
    final before = _recorder.load();
    await write();
    if (widget.progress == null) unawaited(AchievementTracker.puzzleDone());
    if (!mounted) return;
    final after = _recorder.load();
    if (!levelJustWoven(_levelPuzzles, before, after)) return;
    await Future<void>.delayed(wait);
    if (!mounted) return;
    final i = widget.level - 1;
    if (i < 0 || i >= kLoomLevels.length) return;
    final next = i + 1 < kLoomLevels.length && _hasNextLevel
        ? kLoomLevels[i + 1].tribe
        : null;
    await showWovenDialog(
      context,
      gol: kLoomLevels[i].gol,
      tribe: kLoomLevels[i].tribe,
      knots: _levelPuzzles.length,
      nextTribe: next,
    );
  }

  void _onHint() {
    if (_busy || _s.isFinished || !_atTip) return;
    setState(_s.useHint);
  }

  void _onReveal() {
    final puzzle = _puzzle;
    if (puzzle == null || _s.isFinished) return;
    _timer?.cancel();
    unawaited(
      _record(
        () => _recorder.recordRevealed(puzzle),
        // Let the solution play out first.
        wait: const Duration(milliseconds: 2400),
      ),
    );
    setState(() {
      _mistakeFlash = false;
      _busy = true;
    });
    _showPly(_s.positions.length - 1);
    _revealStep();
  }

  void _revealStep() {
    if (!mounted) return;
    final before = _s.position;
    final move = _s.revealNext();
    if (move == null) {
      setState(() => _busy = false);
      return;
    }
    _playMoveFeedback(before, move, _s.position, false);
    _showPly(_s.positions.length - 1);
    _timer = Timer(_opponentDelay * 2, _revealStep);
  }

  void _retry() {
    _timer?.cancel();
    setState(() {
      _s.retry();
      _ply = 0;
      _slide = null;
      _slideKey++;
      _busy = false;
      _mistakeFlash = false;
    });
  }

  void _back() {
    if (_busy || _ply == 0) return;
    _showPly(_ply - 1);
  }

  void _forward() {
    if (_busy || _atTip) return;
    _showPly(_ply + 1);
  }

  String get _statusText {
    if (_solved) return 'Puzzle solved!';
    if (_revealed) return 'Solution shown';
    if (_mistakeFlash) return 'Not that one';
    return _position.turn == Side.white ? 'White to move' : 'Black to move';
  }

  CoachMood get _coachMood => _solved
      ? CoachMood.solved
      : _revealed
      ? CoachMood.revealed
      : _mistakeFlash
      ? CoachMood.mistake
      : CoachMood.thinking;

  /// The coach's second line. It stays the same while the puzzle is open,
  /// and changes with each new mistake.
  String get _coachTip {
    final puzzle = _puzzle;
    if (puzzle == null) return '';
    return coachTip(
      mood: _coachMood,
      theme: puzzle.theme,
      seed: coachSeed(puzzle.id) + (_session?.mistakes ?? 0),
    );
  }

  void _exit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/puzzles');
    }
  }

  void _nextPuzzle(BuildContext context) {
    if (_index + 1 < _puzzleCount) {
      context.pushReplacement('/puzzle/${widget.level}/${_index + 1}');
    } else if (_hasNextLevel) {
      context.pushReplacement('/puzzle/${widget.level + 1}/0');
    } else {
      _exit(context);
    }
  }

  Widget _buildBody(BuildContext context) {
    final error = _error;
    if (error != null) {
      return _MessageState(
        message: error,
        actionLabel: 'Try again',
        onAction: _load,
        secondaryLabel: 'Back to puzzles',
        onSecondary: () => _exit(context),
      );
    }
    if (_session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final finished = _s.isFinished;
    final hintFrom = _atTip && !finished ? _s.hintFrom : null;
    final hintTo = _atTip && !finished ? _s.hintTo : null;
    final hasNext = _index + 1 < _puzzleCount;

    // Fixed slots for the coach and the bottom bar, so the board never moves
    // when the words change or the controls swap for the result bar. The
    // coach's bubble grows with the text size, and so does its slot.
    final statusHeight = coachSlotHeight(
      MediaQuery.textScalerOf(context).scale(1),
    );
    const barHeight = 112.0;
    const sideMargin = 0.0;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math
              .max(
                0.0,
                math.min(
                  constraints.maxWidth - sideMargin * 2,
                  constraints.maxHeight - statusHeight - barHeight,
                ),
              )
              .toDouble();

          return Column(
            children: [
              // The coach stands on the top edge of the board, and the two
              // sit together right under the top bar.
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: statusHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: CoachBubble(
                            standing: true,
                            size: coachFigureHeight,
                            title: _statusText,
                            tip: _coachTip,
                            leading: _SideDot(
                              whiteToMove: _position.turn == Side.white,
                            ),
                            titleColor: _solved
                                ? const Color(0xFF1F7A4D)
                                : _mistakeFlash
                                ? const Color(0xFFB3261E)
                                : LoomColors.indigo,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: side,
                        height: side,
                        child: PuzzleBoard(
                          position: _position,
                          flipped: _s.solverSide == Side.black,
                          interactive: _atTip && !_busy && !finished,
                          onMove: _onUserMove,
                          lastMove: _s.lastMoves[_ply],
                          hintFrom: hintFrom,
                          hintTo: hintTo,
                          slide: _slide,
                          slideKey: _slideKey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: barHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: finished
                      ? _FinishedBar(
                          hasNext: hasNext,
                          nextLevel: _hasNextLevel,
                          busy: _busy,
                          onRetry: _retry,
                          onNext: () => _nextPuzzle(context),
                        )
                      : _ControlBar(
                          canHint:
                              _atTip &&
                              !_busy &&
                              _s.hintLevel < PuzzleSession.maxHintLevel,
                          canReveal: !_busy,
                          canBack: _ply > 0 && !_busy,
                          canForward: !_atTip && !_busy,
                          onHint: _onHint,
                          onReveal: _onReveal,
                          onRetry: _retry,
                          onBack: _back,
                          onForward: _forward,
                        ),
                ),
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
    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          KustTopBar(
            title: 'Puzzle ${_session == null ? '' : _index + 1}',
            subtitle: _puzzle == null ? null : puzzleThemeLabel(_puzzle!.theme),
            leading: KustIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onTap: () => _exit(context),
            ),
            trailing: [
              KustIconButton(
                icon: Icons.tune_rounded,
                label: 'Settings',
                onTap: () => showSettingsSheet(context),
              ),
            ],
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

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
            Text(message, textAlign: TextAlign.center, style: k.body),
            const SizedBox(height: 20),
            KustButton(label: actionLabel, onTap: onAction, expand: false),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              KustButton(
                label: secondaryLabel!,
                onTap: onSecondary,
                style: KustButtonStyle.outline,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The colour to move, as a small disc.
class _SideDot extends StatelessWidget {
  const _SideDot({required this.whiteToMove});

  final bool whiteToMove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: whiteToMove ? Colors.white : Colors.black,
        border: Border.all(color: LoomColors.walnut, width: 1.5),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.canHint,
    required this.canReveal,
    required this.canBack,
    required this.canForward,
    required this.onHint,
    required this.onReveal,
    required this.onRetry,
    required this.onBack,
    required this.onForward,
  });

  final bool canHint;
  final bool canReveal;
  final bool canBack;
  final bool canForward;
  final VoidCallback onHint;
  final VoidCallback onReveal;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: KustActionBar(
        actions: [
          KustAction(
            icon: Icons.refresh_rounded,
            label: 'Retry',
            onTap: canReveal ? onRetry : null,
          ),
          KustAction(
            icon: Icons.visibility_outlined,
            label: 'Solution',
            onTap: canReveal ? onReveal : null,
          ),
          KustAction(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            primary: true,
            onTap: canHint ? onHint : null,
          ),
          KustAction(
            icon: Icons.chevron_left_rounded,
            label: 'Back',
            onTap: canBack ? onBack : null,
          ),
          KustAction(
            icon: Icons.chevron_right_rounded,
            label: 'Forward',
            onTap: canForward ? onForward : null,
          ),
        ],
      ),
    );
  }
}

class _FinishedBar extends StatelessWidget {
  const _FinishedBar({
    required this.hasNext,
    required this.nextLevel,
    required this.busy,
    required this.onRetry,
    required this.onNext,
  });

  final bool hasNext;

  /// The last puzzle of a level, with another level after it.
  final bool nextLevel;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          KustIconButton(
            icon: Icons.refresh_rounded,
            label: 'Retry',
            size: 52,
            onTap: busy ? null : onRetry,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: KustButton(
              label: hasNext
                  ? 'Next puzzle'
                  : nextLevel
                  ? 'Next level'
                  : 'Back to puzzles',
              onTap: busy ? null : onNext,
            ),
          ),
        ],
      ),
    );
  }
}
