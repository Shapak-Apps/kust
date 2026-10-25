import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dartchess/dartchess.dart';

import 'package:kust/widgets/piece_image.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/play/pick_opponent_modal.dart';
import 'package:kust/features/game/chess/chess_helpers.dart';
import 'package:kust/features/game/chess/move_record.dart';
import 'package:kust/features/game/evaluation_bar.dart';
import 'package:kust/features/game/more_floating_menu.dart';
import 'package:kust/features/game/time_control.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/game_args.dart';
import 'package:kust/ui/kust_action_bar.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/features/game/game_export.dart';
import 'package:kust/features/game/game_result_dialog.dart';
import 'package:kust/ui/kust_dialog.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/move_strip.dart';
import 'package:kust/ui/tokens.dart';

const double kBoardMaxWidth = 480;
const double kPlayerBarHeight = 56;

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    this.bot,
    required this.playerSide,
    this.isLocal = false,
    this.timeControl,
    this.practiceMode = false,
  });

  final Bot? bot;
  final Side playerSide;
  final bool isLocal;
  final TimeControl? timeControl;
  final bool practiceMode;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  bool _hasDismissedResultDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundService.instance.warmUp();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(chessControllerProvider.notifier);
      if (widget.isLocal) {
        controller.startLocalGame(timeControl: widget.timeControl);
      } else {
        controller.startGame(
          widget.bot!,
          playerSide: widget.playerSide,
          practiceMode: widget.practiceMode,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused) {
      ref.read(chessControllerProvider.notifier).stopEngineWork();
    }
  }

  void _showGameStartModal(dynamic playerSide) {
    final isWhite = playerSide.toString().toLowerCase().contains('white');
    final pieceAsset = isWhite
        ? AppSettings.instance.pieceSet.value.asset('w', 'K')
        : AppSettings.instance.pieceSet.value.asset('b', 'K');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PieceImage(pieceAsset, width: 64, height: 64),
                const SizedBox(height: 16),
                const Text(
                  'Game Start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isLocal
                      ? 'White moves first'
                      : 'You play as ${isWhite ? "White" : "Black"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _engineSheetOpen = false;

  void _showEngineFailed() {
    if (_engineSheetOpen || !mounted) return;
    _engineSheetOpen = true;
    showKustSheet<void>(
      context,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KustSheetHeader(
            title: 'Engine unavailable',
            subtitle: ChessEngine.isSupported
                ? 'The chess engine could not start. Try again, or play '
                      'on this device with a friend.'
                : 'Playing against bots is not supported on this device.',
          ),
          if (ChessEngine.isSupported) ...[
            KustButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(chessControllerProvider.notifier).retryEngine();
              },
            ),
            const SizedBox(height: 8),
          ],
          KustButton(
            label: 'Play locally instead',
            style: KustButtonStyle.outline,
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.go(
                '/game',
                extra: GameArgs(
                  playerSide: Side.white,
                  isLocal: true,
                  timeControl: widget.timeControl,
                ),
              );
            },
          ),
        ],
      ),
    ).whenComplete(() => _engineSheetOpen = false);
  }

  void _confirmResign() {
    showKustSheet<void>(
      context,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KustSheetHeader(
            title: 'Resign this game?',
            subtitle: 'The game will end and count as a loss.',
          ),
          KustButton(
            label: 'Resign',
            onTap: () {
              Navigator.of(sheetContext).pop();
              ref.read(chessControllerProvider.notifier).resign();
            },
          ),
          const SizedBox(height: 8),
          KustButton(
            label: 'Keep playing',
            style: KustButtonStyle.outline,
            onTap: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(String title, String message) {
    showKustDialog<void>(
      context,
      builder: (dialogContext) => GameResultContent(
        title: title,
        message: message,
        onRematch: () {
          Navigator.of(dialogContext).pop();
          final controller = ref.read(chessControllerProvider.notifier);
          if (widget.isLocal) {
            controller.startLocalGame(timeControl: widget.timeControl);
          } else {
            controller.startGame(
              widget.bot!,
              playerSide: widget.playerSide,
              practiceMode: widget.practiceMode,
            );
          }
        },
        onLobby: () {
          Navigator.of(dialogContext).pop();
          context.go('/play');
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _hasDismissedResultDialog = true;
        });
      }
    });
  }

  String _winnerLabel(GameState state) {
    if (widget.isLocal) {
      return state.position.turn == Side.white ? 'Black' : 'White';
    }
    return state.position.turn == state.playerSide ? widget.bot!.name : 'You';
  }

  void _showEndDialogForState(GameState state) {
    switch (state.status) {
      case GameStatus.checkmate:
        _showResultDialog('Checkmate', '${_winnerLabel(state)} won the game.');
        break;
      case GameStatus.draw:
        _showResultDialog(
          'Draw',
          state.endReason ?? 'The game ended in a draw.',
        );
        break;
      case GameStatus.timeout:
        _showResultDialog(
          'Time out',
          state.endReason ?? 'The game ended on time.',
        );
        break;
      case GameStatus.resigned:
        _showResultDialog('Game over', 'You resigned.');
        break;
      case GameStatus.playing:
      case GameStatus.loading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(chessControllerProvider, (previous, next) {
      if (next.engineFailed && previous?.engineFailed != true) {
        _showEngineFailed();
      }
      if (previous?.status == next.status) return;

      switch (next.status) {
        case GameStatus.playing:
          _hasDismissedResultDialog = false;
          _showGameStartModal(next.playerSide);
          break;
        case GameStatus.checkmate:
          _showResultDialog('Checkmate', '${_winnerLabel(next)} won the game.');
          break;
        case GameStatus.draw:
          _showResultDialog(
            'Draw',
            next.endReason ?? 'The game ended in a draw.',
          );
          break;
        case GameStatus.timeout:
          _showResultDialog(
            'Time out',
            next.endReason ?? 'The game ended on time.',
          );
          break;
        case GameStatus.resigned:
          _showResultDialog('Game over', 'You resigned.');
          break;
        case GameStatus.loading:
          break;
      }
    });

    final screen = ref.watch(
      chessControllerProvider.select(
        (g) => (
          status: g.status,
          practice: g.practiceMode,
          eval: g.evaluationEnabled,
          feedback: g.moveFeedbackEnabled,
        ),
      ),
    );
    final status = screen.status;
    final isFinished =
        status == GameStatus.checkmate ||
        status == GameStatus.draw ||
        status == GameStatus.resigned ||
        status == GameStatus.timeout;

    final topSide = widget.isLocal
        ? Side.black
        : oppositeSide(widget.playerSide);
    final bottomSide = widget.isLocal ? Side.white : widget.playerSide;

    final k = context.k;
    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          KustTopBar(
            title: widget.isLocal ? 'Pass & Play' : 'vs ${widget.bot!.name}',
            subtitle: widget.isLocal
                ? null
                : '${widget.bot!.elo} Elo${widget.practiceMode ? ' · Practice' : ''}',
            leading: KustIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Leave game',
              onTap: () {
                if (status == GameStatus.playing) {
                  _confirmResign();
                } else {
                  context.go('/play');
                }
              },
            ),
            trailing: [
              KustIconButton(
                icon: Icons.ios_share_rounded,
                label: 'Export game',
                onTap: () {
                  final g = ref.read(chessControllerProvider);
                  showExportSheet(
                    context,
                    position: g.displayPosition,
                    flipped:
                        g.mode == GameMode.bot && g.playerSide == Side.black,
                    pgn: livePgn(g),
                    highlight: g.displayMoveSquares,
                  );
                },
              ),
              if (status == GameStatus.playing)
                KustIconButton(
                  icon: Icons.flag_outlined,
                  label: 'Resign',
                  onTap: _confirmResign,
                ),
              if (isFinished && !_hasDismissedResultDialog)
                KustIconButton(
                  icon: Icons.emoji_events_outlined,
                  label: 'Show result',
                  onTap: () =>
                      _showEndDialogForState(ref.read(chessControllerProvider)),
                ),
            ],
          ),
          const _EngineSetupBanner(),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (screen.eval && (widget.isLocal || widget.practiceMode))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _EvalBarSlot(
                        whiteOnLeft: bottomSide == Side.white,
                      ),
                    ),
                  const _HistorySlot(),
                  if (screen.practice && screen.feedback)
                    const SizedBox(
                      height: 24,
                      child: Stack(children: [_FeedbackSlot()]),
                    ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight =
                            constraints.maxHeight - (2 * kPlayerBarHeight) - 16;
                        final maxSide = math.min(
                          constraints.maxWidth,
                          availableHeight,
                        );
                        final side = math.max(
                          0.0,
                          math.min(maxSide, kBoardMaxWidth),
                        );

                        return Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: side,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PlayerBar(
                                    side: topSide,
                                    name: widget.isLocal
                                        ? 'Black'
                                        : widget.bot!.name,
                                    subtitle: widget.isLocal
                                        ? null
                                        : '${widget.bot!.elo} Elo',
                                    avatarPath: widget.isLocal
                                        ? null
                                        : widget.bot!.imagePath,
                                    thinkingText: 'thinking',
                                  ),
                                  SizedBox(
                                    width: side,
                                    height: side,
                                    child: status == GameStatus.loading
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : const ChessBoard(),
                                  ),
                                  _PlayerBar(
                                    side: bottomSide,
                                    name: widget.isLocal ? 'White' : 'You',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _ControlsBar(
                    isLocal: widget.isLocal,
                    practiceMode: widget.practiceMode,
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

/// Friendly waiting line while the opponent is being set up. It says nothing
/// about engines or files; it simply goes away when the game can start.
class _EngineSetupBanner extends ConsumerWidget {
  const _EngineSetupBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(
      chessControllerProvider.select(
        (g) => (
          botName: g.mode == GameMode.bot ? g.bot?.name : null,
          playing: g.status == GameStatus.playing,
          failed: g.engineFailed,
        ),
      ),
    );
    final name = game.botName;
    if (name == null || !game.playing || game.failed) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: ChessEngine.readyNotifier,
      builder: (context, ready, _) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: ready
              ? const SizedBox(width: double.infinity)
              : _WaitingLine(name: name),
        );
      },
    );
  }
}

class _WaitingLine extends StatefulWidget {
  const _WaitingLine({required this.name});

  final String name;

  @override
  State<_WaitingLine> createState() => _WaitingLineState();
}

class _WaitingLineState extends State<_WaitingLine> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (mounted) setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final lines = [
      'Inviting ${widget.name} to the game…',
      '${widget.name} is taking a seat…',
      'Setting up the board…',
      '${widget.name} is getting ready…',
    ];
    final text = lines[_index % lines.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: k.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Align(
                key: ValueKey(text),
                alignment: Alignment.centerLeft,
                child: Text(text, style: k.caption),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvalBarSlot extends ConsumerWidget {
  const _EvalBarSlot({required this.whiteOnLeft});

  final bool whiteOnLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(
      chessControllerProvider.select((g) => g.evaluation),
    );
    return EvaluationBar(score: score, whiteOnLeft: whiteOnLeft);
  }
}

class _HistorySlot extends ConsumerWidget {
  const _HistorySlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      chessControllerProvider.select(
        (g) => (moves: g.moves, cursor: g.analysisCursor),
      ),
    );
    return MoveStrip(
      labels: [
        for (var i = 0; i < data.moves.length; i++)
          moveLabel(i, data.moves[i].san),
      ],
      // The move on the board: the latest, or the one being reviewed.
      selected: data.cursor,
    );
  }
}

class _FeedbackSlot extends ConsumerWidget {
  const _FeedbackSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      chessControllerProvider.select(
        (g) => (moves: g.moves, analyzing: g.feedbackAnalyzing),
      ),
    );
    return _MoveFeedbackLine(moves: data.moves, analyzing: data.analyzing);
  }
}

class _ControlsBar extends ConsumerWidget {
  const _ControlsBar({required this.isLocal, required this.practiceMode});

  final bool isLocal;
  final bool practiceMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      chessControllerProvider.select(
        (g) => (
          cursor: g.analysisCursor,
          canUndo: g.canUndo,
          hintEnabled: g.practiceMode && g.isPlayerTurn && !g.isHintThinking,
          hintThinking: g.isHintThinking,
          practice: g.practiceMode,
          analysisActive: g.isSelfAnalysisActive,
        ),
      ),
    );
    final controller = ref.read(chessControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: KustActionBar(
        actions: [
          if (isLocal || practiceMode)
            KustAction(
              icon: Icons.tune_rounded,
              label: 'Options',
              onTap: () => MoreFloatingMenu.show(context),
            ),
          if (isLocal || practiceMode)
            KustAction(
              icon: Icons.undo_rounded,
              label: 'Take back',
              onTap: s.canUndo ? controller.undoLastMove : null,
            ),
          if (!isLocal && practiceMode)
            KustAction(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Hint',
              primary: true,
              busy: s.hintThinking,
              onTap: s.hintEnabled ? controller.requestHint : null,
            ),
          KustAction(
            icon: Icons.chevron_left_rounded,
            label: 'Back',
            onTap: s.cursor > 0 ? controller.analysisMoveBack : null,
          ),
          KustAction(
            icon: Icons.chevron_right_rounded,
            label: 'Forward',
            onTap: s.analysisActive ? controller.analysisMoveNext : null,
          ),
        ],
      ),
    );
  }
}

class _PlayerBar extends ConsumerWidget {
  const _PlayerBar({
    required this.side,
    required this.name,
    this.subtitle,
    this.avatarPath,
    this.thinkingText,
  });

  final Side side;
  final String name;
  final String? subtitle;
  final String? avatarPath;
  final String? thinkingText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      chessControllerProvider.select(
        (g) => (
          position: g.position,
          moves: g.moves,
          thinking: thinkingText != null && g.isBotThinking,
          time: g.timeControl == null
              ? null
              : (side == Side.white ? g.whiteTimeLeft : g.blackTimeLeft),
          clockActive:
              g.timeControl != null &&
              g.status == GameStatus.playing &&
              g.position.turn == side,
        ),
      ),
    );
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final captured = piecesCapturedBy(side, s.moves);
    final advantage = boardMaterialAdvantageFor(s.position, side);

    return SizedBox(
      height: kPlayerBarHeight,
      child: Row(
        children: [
          Padding(padding: const EdgeInsets.all(4), child: _buildAvatar(theme)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                    if (s.thinking) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      if (thinkingText != null) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            thinkingText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    for (final piece in captured)
                      Padding(
                        padding: const EdgeInsets.only(right: 1),
                        child: PieceImage(
                          assetForPiece(piece),
                          width: 16,
                          height: 16,
                        ),
                      ),
                    if (captured.isNotEmpty && advantage > 0)
                      const SizedBox(width: 5),
                    if (advantage > 0)
                      Text(
                        '+$advantage',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: muted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (s.time != null) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
              child: _ClockChip(
                time: s.time!,
                active: s.clockActive,
                side: side,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (avatarPath != null && avatarPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(KustSpace.rSmall),
        child: Image.asset(
          avatarPath!,
          width: 40,
          height: 40,
          cacheWidth: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(KustSpace.rSmall),
        ),
        child: Icon(
          Icons.person_rounded,
          size: 24,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ClockChip extends StatelessWidget {
  const _ClockChip({
    required this.time,
    required this.active,
    required this.side,
  });

  final Duration time;
  final bool active;
  final Side side;

  @override
  Widget build(BuildContext context) {
    final isWhite = side == Side.white;

    final base = isWhite ? Colors.white : const Color(0xFF1B1B1B);
    final foreground = isWhite ? const Color(0xFF1B1B1B) : Colors.white;

    final background = active ? base : base.withValues(alpha: 0.35);
    final text = active ? foreground : foreground.withValues(alpha: 0.65);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KustSpace.rSmall),
        border: Border.all(color: context.k.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) ...[
            Icon(Icons.schedule_rounded, size: 15, color: text),
            const SizedBox(width: 6),
          ],
          Text(
            TimeControl.format(time),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveFeedbackLine extends StatelessWidget {
  const _MoveFeedbackLine({required this.moves, required this.analyzing});

  final List<MoveRecord> moves;
  final bool analyzing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (moves.isEmpty) return const SizedBox.shrink();

    MoveRecord? target;
    for (var i = moves.length - 1; i >= 0; i--) {
      if (moves[i].feedback != null) {
        target = moves[i];
        break;
      }
    }
    final feedback = target?.feedback;

    String? text;
    if (feedback != null) {
      text = feedback.bannerText;
    } else if (analyzing) {
      text = 'Analyzing ${moves.last.san}…';
    } else {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            text,
            key: ValueKey('${target?.san}_${feedback?.quality}_$analyzing'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
