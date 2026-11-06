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
import 'package:kust/features/game/end_text.dart';
import 'package:kust/features/game/game_export.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/features/game/game_result_dialog.dart';
import 'package:kust/ui/kust_dialog.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_logo.dart';
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
                Text(
                  dialogContext.t.gameStartTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isLocal
                      ? dialogContext.t.whiteMovesFirst
                      : (isWhite
                            ? dialogContext.t.youPlayAsWhite
                            : dialogContext.t.youPlayAsBlack),
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
            title: sheetContext.t.engineUnavailable,
            subtitle: ChessEngine.isSupported
                ? sheetContext.t.engineCouldNotStart
                : sheetContext.t.botsNotSupported,
          ),
          if (ChessEngine.isSupported) ...[
            KustButton(
              label: sheetContext.t.tryAgain,
              icon: Icons.refresh_rounded,
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(chessControllerProvider.notifier).retryEngine();
              },
            ),
            const SizedBox(height: 8),
          ],
          KustButton(
            label: sheetContext.t.playLocallyInstead,
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

  /// Leaving: abort before the game has started, offer to resign while it
  /// goes on, and back to Play once it is over.
  void _leave() {
    final g = ref.read(chessControllerProvider);
    if (g.canAbort) {
      _abort();
    } else if (g.status == GameStatus.playing) {
      _confirmResign();
    } else {
      context.go('/play');
    }
  }

  /// Asks, then calls off a game nobody has really played yet and leaves.
  void _abort() {
    showKustSheet<void>(
      context,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KustSheetHeader(
            title: sheetContext.t.abortTitle,
            subtitle: sheetContext.t.abortSubtitle,
          ),
          KustButton(
            label: sheetContext.t.abort,
            onTap: () {
              Navigator.of(sheetContext).pop();
              ref.read(chessControllerProvider.notifier).abort();
              context.go('/play');
            },
          ),
          const SizedBox(height: 8),
          KustButton(
            label: sheetContext.t.keepPlaying,
            style: KustButtonStyle.outline,
            onTap: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    );
  }

  void _confirmResign() {
    showKustSheet<void>(
      context,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KustSheetHeader(
            title: sheetContext.t.resignTitle,
            subtitle: sheetContext.t.resignSubtitle,
          ),
          KustButton(
            label: sheetContext.t.resign,
            onTap: () {
              Navigator.of(sheetContext).pop();
              ref.read(chessControllerProvider.notifier).resign();
            },
          ),
          const SizedBox(height: 8),
          KustButton(
            label: sheetContext.t.keepPlaying,
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

  /// The title and message of the dialog for a game that has ended, or null
  /// while it goes on.
  (String, String)? _endDialogTexts(GameState state) {
    final t = context.t;
    return switch (state.status) {
      GameStatus.checkmate => (
        t.resultCheckmate,
        t.wonTheGame(sideName(t, state, state.position.turn.opposite)),
      ),
      GameStatus.draw => (t.resultDraw, endMessage(t, state)),
      GameStatus.timeout => (t.resultTimeOut, endMessage(t, state)),
      GameStatus.resigned => (t.resultGameOver, t.youResigned),
      GameStatus.playing || GameStatus.loading => null,
    };
  }

  void _showEndDialogForState(GameState state) {
    final texts = _endDialogTexts(state);
    if (texts != null) _showResultDialog(texts.$1, texts.$2);
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
        case GameStatus.draw:
        case GameStatus.timeout:
        case GameStatus.resigned:
          _showEndDialogForState(next);
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
          canAbort: g.canAbort,
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
    // Android Back does what the arrow in the top bar does.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: k.bg,
        body: Column(
          children: [
            KustTopBar(
              // The players' names and ratings sit by the board already.
              title: widget.isLocal
                  ? context.t.passAndPlay
                  : context.t.vsBot(widget.bot!.name),
              brand: const KustLogo(height: 22),
              leading: KustIconButton(
                icon: Icons.arrow_back_rounded,
                label: context.t.leaveGame,
                onTap: _leave,
              ),
              trailing: [
                // Only a finished game can be exported.
                if (status != GameStatus.playing)
                  KustIconButton(
                    icon: Icons.ios_share_rounded,
                    label: context.t.exportGame,
                    onTap: () {
                      final g = ref.read(chessControllerProvider);
                      showExportSheet(
                        context,
                        position: g.displayPosition,
                        flipped:
                            g.mode == GameMode.bot &&
                            g.playerSide == Side.black,
                        pgn: livePgn(g),
                        highlight: g.displayMoveSquares,
                      );
                    },
                  ),
                if (screen.canAbort)
                  KustIconButton(
                    icon: Icons.close_rounded,
                    label: context.t.abort,
                    onTap: _abort,
                  )
                else if (status == GameStatus.playing)
                  KustIconButton(
                    icon: Icons.flag_outlined,
                    label: context.t.resign,
                    onTap: _confirmResign,
                  ),
                if (isFinished && !_hasDismissedResultDialog)
                  KustIconButton(
                    icon: Icons.emoji_events_outlined,
                    label: context.t.showResult,
                    onTap: () => _showEndDialogForState(
                      ref.read(chessControllerProvider),
                    ),
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
                              constraints.maxHeight -
                              (2 * kPlayerBarHeight) -
                              16;
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
                                          ? context.t.blackName
                                          : widget.bot!.name,
                                      subtitle: widget.isLocal
                                          ? null
                                          : context.t.eloValue(widget.bot!.elo),
                                      avatarPath: widget.isLocal
                                          ? null
                                          : widget.bot!.imagePath,
                                      thinkingText: context.t.thinking,
                                    ),
                                    SizedBox(
                                      width: side,
                                      height: side,
                                      child: status == GameStatus.loading
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : const ChessBoard(),
                                    ),
                                    _PlayerBar(
                                      side: bottomSide,
                                      name: widget.isLocal
                                          ? context.t.whiteName
                                          : context.t.youName,
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
    final t = context.t;
    final lines = [
      t.invite1(widget.name),
      t.invite2(widget.name),
      t.invite3,
      t.invite4(widget.name),
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
          canPause: g.canPause,
          paused: g.paused,
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
              label: context.t.options,
              onTap: () => MoreFloatingMenu.show(context),
            ),
          if (isLocal || practiceMode)
            KustAction(
              icon: Icons.undo_rounded,
              label: context.t.takeBack,
              onTap: s.canUndo ? controller.undoLastMove : null,
            ),
          if (s.canPause)
            KustAction(
              icon: s.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              label: s.paused ? context.t.resume : context.t.pause,
              onTap: s.paused ? controller.resumeClock : controller.pauseClock,
            ),
          if (!isLocal && practiceMode)
            KustAction(
              icon: Icons.lightbulb_outline_rounded,
              label: context.t.hint,
              busy: s.hintThinking,
              onTap: s.hintEnabled ? controller.requestHint : null,
            ),
          KustAction(
            icon: Icons.chevron_left_rounded,
            label: context.t.back,
            onTap: s.cursor > 0 ? controller.analysisMoveBack : null,
          ),
          KustAction(
            icon: Icons.chevron_right_rounded,
            label: context.t.forward,
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
                // After many captures the row is wider than the room beside the
                // clock: it shrinks to fit instead of overflowing.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
      text = feedback.banner(context.t);
    } else if (analyzing) {
      text = context.t.analyzingMove(moves.last.san);
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
