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
          break;
      }
    });

    final gameState = ref.watch(chessControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('vs ${widget.bot.name}'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(chessControllerProvider.notifier).resign(),
            icon: const Icon(Icons.flag_outlined),
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
                  child: const AspectRatio(aspectRatio: 1, child: ChessBoard()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
