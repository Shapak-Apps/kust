import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Kust/features/game/chess/board/chess_board.dart';
import 'package:Kust/features/game/chess/chess_controller.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';

const double kBoardMaxWidth = 480;

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.bot});

  final Bot bot;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chessControllerProvider.notifier).startGame(widget.bot);
    });
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to lobby'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref
                    .read(chessControllerProvider.notifier)
                    .startGame(widget.bot);
              },
              child: const Text('Rematch'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chessControllerProvider, (previous, next) {
      if (previous?.status == next.status) return;

      switch (next.status) {
        case GameStatus.checkmate:
          final winner = next.position.turn == next.playerSide
              ? widget.bot.name
              : 'You';
          _showResultDialog('Checkmate', '$winner won the game.');
        case GameStatus.draw:
          _showResultDialog('Draw', 'The game ended in a draw.');
        case GameStatus.resigned:
          _showResultDialog('Game over', 'You resigned.');
        case GameStatus.playing:
        case GameStatus.loading:
          break;
      }
    });

    final gameState = ref.watch(chessControllerProvider);
    final theme = Theme.of(context);
    final notifier = ref.read(chessControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('vs ${widget.bot.name}'),
        actions: [
          IconButton(
            tooltip: 'Resign',
            onPressed: gameState.status == GameStatus.playing
                ? notifier.resign
                : null,
            icon: const Icon(Icons.flag_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.bot.elo} Elo',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (gameState.isBotThinking)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.bot.name} is thinking',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Take back',
                    onPressed: gameState.canUndo ? notifier.undoLastMove : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  IconButton(
                    tooltip: 'Hint',
                    onPressed:
                        gameState.isPlayerTurn && !gameState.isHintThinking
                        ? notifier.requestHint
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
