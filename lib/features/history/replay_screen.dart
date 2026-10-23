import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';

/// Positions reached by [uciMoves], starting from the initial position.
/// Stops at the first move that cannot be played, so a damaged record still
/// opens up to that point.
({List<Position> positions, List<NormalMove?> moves}) replayPositions(
  List<String> uciMoves,
) {
  final positions = <Position>[Chess.initial];
  final moves = <NormalMove?>[null];
  for (final uci in uciMoves) {
    final move = Move.parse(uci);
    final current = positions.last;
    if (move is! NormalMove || !current.isLegal(move)) break;
    positions.add(current.play(move));
    moves.add(move);
  }
  return (positions: positions, moves: moves);
}

class ReplayScreen extends StatefulWidget {
  const ReplayScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  late final GameRecord? _game = GameHistoryStore.instance.byId(widget.gameId);
  late final _replay = replayPositions(_game?.uciMoves ?? const []);
  int _ply = 0;

  int get _last => _replay.positions.length - 1;

  void _go(int ply) => setState(() => _ply = ply.clamp(0, _last));

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final game = _game;

    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          KustTopBar(
            title: game == null
                ? 'Game'
                : game.isLocal
                ? 'Pass & Play'
                : 'vs ${game.botName ?? 'Bot'}',
            subtitle: game == null
                ? null
                : '${describeResult(game)} · ${formatGameDate(game.date)}',
            leading: KustIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/history'),
            ),
          ),
          Expanded(
            child: game == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: k.muted,
                          ),
                          const SizedBox(height: 12),
                          Text('This game could not be found.', style: k.body),
                          const SizedBox(height: 20),
                          KustButton(
                            label: 'Back to history',
                            expand: false,
                            onTap: () => context.go('/history'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildReplay(context, game),
          ),
        ],
      ),
    );
  }

  Widget _buildReplay(BuildContext context, GameRecord game) {
    final k = context.k;
    final san = _ply == 0 || _ply > game.sanMoves.length
        ? 'Start position'
        : '${(_ply + 1) ~/ 2}${_ply.isOdd ? '.' : '...'} ${game.sanMoves[_ply - 1]}';

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PuzzleBoard(
                    position: _replay.positions[_ply],
                    flipped: !game.isLocal && !game.playerIsWhite,
                    interactive: false,
                    onMove: (_) {},
                    lastMove: _replay.moves[_ply],
                  ),
                ),
              ),
            ),
          ),
          Text(san, style: k.title),
          Text('Move $_ply of $_last', style: k.caption),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                KustIconButton(
                  icon: Icons.first_page_rounded,
                  label: 'First move',
                  size: 48,
                  onTap: _ply > 0 ? () => _go(0) : null,
                ),
                KustIconButton(
                  icon: Icons.chevron_left_rounded,
                  label: 'Previous move',
                  size: 48,
                  onTap: _ply > 0 ? () => _go(_ply - 1) : null,
                ),
                KustIconButton(
                  icon: Icons.chevron_right_rounded,
                  label: 'Next move',
                  size: 48,
                  onTap: _ply < _last ? () => _go(_ply + 1) : null,
                ),
                KustIconButton(
                  icon: Icons.last_page_rounded,
                  label: 'Last move',
                  size: 48,
                  onTap: _ply < _last ? () => _go(_last) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
