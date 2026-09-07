import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Kust/features/game/chess/board/chess_board.dart';
import 'package:Kust/features/game/chess/chess_controller.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';
import 'package:Kust/features/game/chess/chess_helpers.dart';
import 'package:Kust/features/game/chess/move_record.dart';

const double kBoardMaxWidth = 480;
const double kPlayerBarHeight = 56;

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    this.bot,
    required this.playerSide,
    this.isLocal = false,
  });

  final Bot? bot;
  final Side playerSide;
  final bool isLocal;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _hasDismissedResultDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(chessControllerProvider.notifier);
      if (widget.isLocal) {
        controller.startLocalGame();
      } else {
        controller.startGame(widget.bot!, playerSide: widget.playerSide);
      }
    });
  }

  void _showGameStartModal(dynamic playerSide) {
    final isWhite = playerSide.toString().toLowerCase().contains('white');
    final pieceAsset = isWhite
        ? 'assets/pieces/wK.svg'
        : 'assets/pieces/bK.svg';

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
                SvgPicture.asset(pieceAsset, width: 64, height: 64),
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

  void _confirmResign() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Resign'),
          content: const Text('Are you sure you want to resign?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(chessControllerProvider.notifier).resign();
              },
              child: const Text('Resign'),
            ),
          ],
        );
      },
    );
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/play');
              },
              child: const Text('Back to lobby'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final controller = ref.read(chessControllerProvider.notifier);
                if (widget.isLocal) {
                  controller.startLocalGame();
                } else {
                  controller.startGame(
                    widget.bot!,
                    playerSide: widget.playerSide,
                  );
                }
              },
              child: const Text('Rematch'),
            ),
          ],
        );
      },
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
        case GameStatus.resigned:
          _showResultDialog('Game over', 'You resigned.');
          break;
        case GameStatus.loading:
          break;
      }
    });

    final gameState = ref.watch(chessControllerProvider);

    final isFinished =
        gameState.status == GameStatus.checkmate ||
        gameState.status == GameStatus.draw ||
        gameState.status == GameStatus.resigned;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLocal ? 'Pass & Play' : 'vs ${widget.bot!.name}'),
        actions: [
          if (gameState.status == GameStatus.playing)
            IconButton(
              tooltip: 'Resign',
              onPressed: _confirmResign,
              icon: const Icon(Icons.flag_rounded),
            ),
          if (isFinished && !_hasDismissedResultDialog)
            IconButton(
              tooltip: 'Show result',
              onPressed: () => _showEndDialogForState(gameState),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          if (isFinished && _hasDismissedResultDialog)
            IconButton(
              tooltip: 'Back to lobby',
              onPressed: () => context.go('/play'),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _MoveHistoryBar(moves: gameState.moves),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight =
                      constraints.maxHeight - (2 * kPlayerBarHeight) - 16;
                  final maxSide = math.min(
                    constraints.maxWidth,
                    availableHeight,
                  );
                  final side = math.max(0.0, math.min(maxSide, kBoardMaxWidth));

                  return Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: side,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PlayerBar(
                              side: widget.isLocal
                                  ? Side.black
                                  : oppositeSide(widget.playerSide),
                              name: widget.isLocal ? 'Black' : widget.bot!.name,
                              subtitle: widget.isLocal
                                  ? null
                                  : '${widget.bot!.elo} Elo',
                              avatarPath: widget.isLocal
                                  ? null
                                  : widget.bot!.imagePath,
                              position: gameState.position,
                              moves: gameState.moves,
                              isThinking: gameState.isBotThinking,
                              thinkingText: 'thinking',
                            ),
                            SizedBox(
                              width: side,
                              height: side,
                              child: gameState.status == GameStatus.loading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : const ChessBoard(),
                            ),
                            _PlayerBar(
                              side: widget.isLocal
                                  ? Side.white
                                  : widget.playerSide,
                              name: widget.isLocal ? 'White' : 'You',
                              position: gameState.position,
                              moves: gameState.moves,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Take back',
                    onPressed: gameState.canUndo
                        ? ref
                              .read(chessControllerProvider.notifier)
                              .undoLastMove
                        : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  if (!widget.isLocal)
                    IconButton(
                      tooltip: 'Hint',
                      onPressed:
                          gameState.isPlayerTurn && !gameState.isHintThinking
                          ? ref
                                .read(chessControllerProvider.notifier)
                                .requestHint
                          : null,
                      icon: gameState.isHintThinking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lightbulb_rounded),
                    ),
                  IconButton(
                    tooltip: 'More',
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({
    required this.side,
    required this.name,
    required this.position,
    required this.moves,
    this.subtitle,
    this.avatarPath,
    this.isThinking = false,
    this.thinkingText,
  });

  final Side side;
  final String name;
  final Position position;
  final List<MoveRecord> moves;
  final String? subtitle;
  final String? avatarPath;
  final bool isThinking;
  final String? thinkingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final captured = piecesCapturedBy(side, moves);
    final advantage = boardMaterialAdvantageFor(position, side);

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
                    if (isThinking) ...[
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
                        child: SvgPicture.asset(
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
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (avatarPath != null && avatarPath!.isNotEmpty) {
      return ClipRRect(
        child: Image.asset(
          avatarPath!,
          width: 40,
          height: 40,
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
          color: theme.colorScheme.secondaryContainer,
        ),
        child: Icon(
          Icons.person_rounded,
          size: 24,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _MoveHistoryBar extends StatefulWidget {
  const _MoveHistoryBar({required this.moves});

  final List<MoveRecord> moves;

  @override
  State<_MoveHistoryBar> createState() => _MoveHistoryBarState();
}

class _MoveHistoryBarState extends State<_MoveHistoryBar> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
  }

  @override
  void didUpdateWidget(covariant _MoveHistoryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moves.length != widget.moves.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpToEnd() {
    if (!mounted || !_controller.hasClients) return;
    if (_controller.position.maxScrollExtent > 0) {
      _controller.jumpTo(_controller.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final normalStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final highlightStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.primary,
    );

    if (widget.moves.isEmpty) {
      return SizedBox(
        height: 40,
        child: Center(
          child: Text(
            'No moves yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final children = <Widget>[const SizedBox(width: 16)];
    int index = 0;
    int number = 1;

    if (widget.moves.first.side == Side.black) {
      children.add(Text('$number...', style: mutedStyle));
      children.add(const SizedBox(width: 5));
      children.add(
        Text(
          widget.moves.first.san,
          style: widget.moves.length == 1 ? highlightStyle : normalStyle,
        ),
      );
      children.add(const SizedBox(width: 14));
      index = 1;
      number = 2;
    }

    for (; index < widget.moves.length; index += 2) {
      children.add(Text('$number.', style: mutedStyle));
      children.add(const SizedBox(width: 5));

      final isWhiteLast = index == widget.moves.length - 1;
      children.add(
        Text(
          widget.moves[index].san,
          style: isWhiteLast ? highlightStyle : normalStyle,
        ),
      );

      if (index + 1 < widget.moves.length) {
        children.add(const SizedBox(width: 6));
        final isBlackLast = (index + 1) == widget.moves.length - 1;
        children.add(
          Text(
            widget.moves[index + 1].san,
            style: isBlackLast ? highlightStyle : normalStyle,
          ),
        );
      }

      children.add(const SizedBox(width: 14));
      number++;
    }

    children.add(const SizedBox(width: 16));

    return SizedBox(
      height: 40,
      child: ListView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        children: children,
      ),
    );
  }
}
