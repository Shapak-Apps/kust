import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dartchess/dartchess.dart';

import 'package:Kust/features/game/chess/board/chess_board.dart';
import 'package:Kust/features/game/chess/chess_controller.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';

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
    );
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
    final theme = Theme.of(context);

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

          if (isFinished)
            IconButton(
              tooltip: 'Show result',
              onPressed: () => _showEndDialogForState(gameState),
              icon: const Icon(Icons.info_outline_rounded),
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
