import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dartchess/dartchess.dart';

import 'package:Kust/features/game/chess/board/chess_board.dart';
import 'package:Kust/features/game/chess/chess_controller.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';
import 'package:Kust/features/game/chess/chess_helpers.dart';
import 'package:Kust/features/game/chess/move_record.dart';

import 'package:flutter_svg/flutter_svg.dart';

const double kBoardMaxWidth = 480;

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.bot, required this.playerSide});

  final Bot bot;
  final Side playerSide;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _hasDismissedResultDialog = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chessControllerProvider.notifier)
          .startGame(widget.bot, playerSide: widget.playerSide);
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
                  'You play as ${isWhite ? "White" : "Black"}',
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
                ref
                    .read(chessControllerProvider.notifier)
                    .startGame(widget.bot, playerSide: widget.playerSide);
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

  void _showEndDialogForState(GameState state) {
    switch (state.status) {
      case GameStatus.checkmate:
        final winner = state.position.turn == state.playerSide
            ? widget.bot.name
            : 'You';
        _showResultDialog('Checkmate', '$winner won the game.');
      case GameStatus.draw:
        _showResultDialog(
          'Draw',
          state.endReason ?? 'The game ended in a draw.',
        );
      case GameStatus.resigned:
        _showResultDialog('Game over', 'You resigned.');
      case GameStatus.playing:
      case GameStatus.loading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chessControllerProvider, (previous, next) {
      if (previous?.status == next.status) return;

      switch (next.status) {
        case GameStatus.playing:
          _hasDismissedResultDialog = false;
          _showGameStartModal(next.playerSide);
        case GameStatus.checkmate:
          final winner = next.position.turn == next.playerSide
              ? widget.bot.name
              : 'You';
          _showResultDialog('Checkmate', '$winner won the game.');
        case GameStatus.draw:
          _showResultDialog(
            'Draw',
            next.endReason ?? 'The game ended in a draw.',
          );
        case GameStatus.resigned:
          _showResultDialog('Game over', 'You resigned.');
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
        title: Text('vs ${widget.bot.name}'),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _PlayerBar(
                side: oppositeSide(widget.playerSide),
                name: widget.bot.name,
                subtitle: '${widget.bot.elo} Elo',
                position: gameState.position,
                moves: gameState.moves,
                isThinking: gameState.isBotThinking,
                thinkingText: '${widget.bot.name} is thinking',
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kBoardMaxWidth),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: gameState.status == GameStatus.loading
                        ? const Center(child: CircularProgressIndicator())
                        : const ChessBoard(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _PlayerBar(
                side: widget.playerSide,
                name: 'You',
                subtitle: 'Player',
                position: gameState.position,
                moves: gameState.moves,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _MoveHistoryBar(moves: gameState.moves),
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
                  IconButton(
                    tooltip: 'Hint',
                    onPressed:
                        gameState.isPlayerTurn && !gameState.isHintThinking
                        ? ref.read(chessControllerProvider.notifier).requestHint
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
    this.isThinking = false,
    this.thinkingText,
  });

  final Side side;
  final String name;
  final Position position;
  final List<MoveRecord> moves;
  final String? subtitle;
  final bool isThinking;
  final String? thinkingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final captured = piecesCapturedBy(side, moves);
    final advantage = boardMaterialAdvantageFor(position, side);

    return Row(
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        if (isThinking) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          if (thinkingText != null)
            Flexible(
              child: Text(
                thinkingText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(width: 8),
        ],

        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final piece in captured)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: SvgPicture.asset(
                      assetForPiece(piece),
                      width: 18,
                      height: 18,
                    ),
                  ),

                if (advantage > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$advantage',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoveHistoryBar extends StatelessWidget {
  const _MoveHistoryBar({required this.moves});

  final List<MoveRecord> moves;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (moves.isEmpty) {
      return SizedBox(
        height: 40,
        child: Center(
          child: Text('No moves yet', style: theme.textTheme.bodySmall),
        ),
      );
    }

    final labels = _pairLabels(moves);

    return GestureDetector(
      onTap: () => _showMoveHistoryDialog(context, moves),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                labels[index],
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

List<String> _pairLabels(List<MoveRecord> moves) {
  final labels = <String>[];

  var index = 0;
  var moveNumber = 1;

  if (moves.isNotEmpty && moves.first.side == Side.black) {
    labels.add('$moveNumber... ${moves.first.san}');
    index = 1;
    moveNumber = 2;
  }

  for (; index < moves.length; index += 2) {
    final white = moves[index].san;
    final black = index + 1 < moves.length ? moves[index + 1].san : '';

    labels.add('$moveNumber. $white${black.isEmpty ? '' : ' $black'}');

    moveNumber++;
  }

  return labels;
}

void _showMoveHistoryDialog(BuildContext context, List<MoveRecord> moves) {
  final theme = Theme.of(context);
  final labels = _pairLabels(moves);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Move history'),
        content: SingleChildScrollView(
          child: Text(
            labels.join('\n'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
