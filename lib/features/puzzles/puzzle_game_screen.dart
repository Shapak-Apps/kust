import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:Kust/core/storage/puzzle_progress_store.dart';
import 'package:Kust/features/game/chess/sound_service.dart';
import 'package:Kust/features/puzzles/puzzle_board.dart';
import 'package:Kust/features/puzzles/puzzle_data.dart';
import 'package:Kust/features/puzzles/puzzle_session.dart';
import 'package:Kust/ui/kust_button.dart';
import 'package:Kust/ui/kust_top_bar.dart';
import 'package:Kust/ui/pressable.dart';
import 'package:Kust/ui/tokens.dart';
import 'package:Kust/widgets/more_sheet.dart';

const Duration _opponentDelay = Duration(milliseconds: 350);
const Duration _mistakeDelay = Duration(milliseconds: 700);

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key, required this.level, required this.index});

  final int level;
  final int index;

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  PuzzleEntry? _puzzle;
  PuzzleSession? _session;
  String? _error;
  int _puzzleCount = 0;
  int _index = 0;

  int _ply = 0;
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
      _index = index;
      _ply = 0;
    });
  }

  PuzzleSession get _s => _session!;

  Position get _position => _s.positions[_ply];

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
      setState(() => _ply = _s.positions.length - 1);
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
        setState(() => _ply = _s.positions.length - 1);
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
    setState(() {
      _ply = _s.positions.length - 1;
      _busy = false;
    });

    if (_solved) _onSolved(puzzle);
  }

  void _onMistake(PuzzleEntry puzzle) {
    SoundService.instance.playSfx('illegal.wav');
    SoundService.instance.buzz(heavy: true);
    if (_s.mistakes == 1) {
      unawaited(PuzzleProgressStore.instance.recordMistake(puzzle));
    }

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
      PuzzleProgressStore.instance.recordSolved(
        puzzle,
        clean: _s.mistakes == 0,
      ),
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
    unawaited(PuzzleProgressStore.instance.recordRevealed(puzzle));
    setState(() {
      _mistakeFlash = false;
      _busy = true;
      _ply = _s.positions.length - 1;
    });
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
    setState(() => _ply = _s.positions.length - 1);
    _timer = Timer(_opponentDelay * 2, _revealStep);
  }

  void _retry() {
    _timer?.cancel();
    setState(() {
      _s.retry();
      _ply = 0;
      _busy = false;
      _mistakeFlash = false;
    });
  }

  void _back() {
    if (_busy || _ply == 0) return;
    setState(() => _ply--);
  }

  void _forward() {
    if (_busy || _atTip) return;
    setState(() => _ply++);
  }

  String get _statusText {
    if (_solved) return 'Puzzle solved!';
    if (_revealed) return 'Solution shown';
    if (_mistakeFlash) return 'Not that one';
    return _position.turn == Side.white ? 'White to move' : 'Black to move';
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

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _StatusLine(
                      text: _statusText,
                      whiteToMove: _position.turn == Side.white,
                      highlight: _solved
                          ? context.k.success
                          : _mistakeFlash
                          ? context.k.danger
                          : null,
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1,
                    child: PuzzleBoard(
                      position: _position,
                      flipped: _s.solverSide == Side.black,
                      interactive: _atTip && !_busy && !finished,
                      onMove: _onUserMove,
                      lastMove: _s.lastMoves[_ply],
                      hintFrom: hintFrom,
                      hintTo: hintTo,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (finished)
            _FinishedBar(
              hasNext: hasNext,
              busy: _busy,
              onRetry: _retry,
              onNext: () => _nextPuzzle(context),
            )
          else
            _ControlBar(
              canHint:
                  _atTip && !_busy && _s.hintLevel < PuzzleSession.maxHintLevel,
              canReveal: !_busy,
              canBack: _ply > 0 && !_busy,
              canForward: !_atTip && !_busy,
              onHint: _onHint,
              onReveal: _onReveal,
              onRetry: _retry,
              onBack: _back,
              onForward: _forward,
            ),
        ],
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
            subtitle: _puzzle == null ? null : _themeLabel(_puzzle!.theme),
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

  String _themeLabel(String theme) {
    if (theme.startsWith('mateIn')) {
      return 'Mate in ${theme.substring('mateIn'.length)}';
    }
    return 'Win material';
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

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.text,
    required this.whiteToMove,
    this.highlight,
  });

  final String text;
  final bool whiteToMove;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: whiteToMove ? Colors.white : Colors.black,
            border: Border.all(color: k.muted),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: k.title.copyWith(color: highlight ?? k.ink)),
        ),
      ],
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
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(KustSpace.rLarge),
          border: Border.all(color: k.line),
        ),
        child: Row(
          children: [
            _ControlButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Hint',
              enabled: canHint,
              onTap: onHint,
            ),
            _ControlButton(
              icon: Icons.visibility_outlined,
              label: 'Solution',
              enabled: canReveal,
              onTap: onReveal,
            ),
            _ControlButton(
              icon: Icons.refresh_rounded,
              label: 'Retry',
              enabled: canReveal,
              onTap: onRetry,
            ),
            _ControlButton(
              icon: Icons.chevron_left_rounded,
              label: 'Back',
              enabled: canBack,
              onTap: onBack,
            ),
            _ControlButton(
              icon: Icons.chevron_right_rounded,
              label: 'Forward',
              enabled: canForward,
              onTap: onForward,
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final color = enabled ? k.ink : k.muted.withValues(alpha: 0.5);
    return Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        child: Pressable(
          onTap: enabled ? onTap : null,
          scale: 0.92,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 2),
                Text(label, style: k.caption.copyWith(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishedBar extends StatelessWidget {
  const _FinishedBar({
    required this.hasNext,
    required this.busy,
    required this.onRetry,
    required this.onNext,
  });

  final bool hasNext;
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
              label: hasNext ? 'Next puzzle' : 'Back to puzzles',
              onTap: busy ? null : onNext,
            ),
          ),
        ],
      ),
    );
  }
}
