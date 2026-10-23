import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/history/pgn.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';

String describeResult(GameRecord game) {
  if (game.isLocal) {
    return switch (game.result) {
      GameRecord.whiteWon => 'White won',
      GameRecord.blackWon => 'Black won',
      _ => 'Draw',
    };
  }
  return switch (game.result) {
    GameRecord.win => 'Win',
    GameRecord.loss => 'Loss',
    _ => 'Draw',
  };
}

Color resultColor(BuildContext context, GameRecord game) {
  final k = context.k;
  if (game.isLocal || game.result == GameRecord.draw) return k.muted;
  return game.result == GameRecord.win ? k.success : k.danger;
}

String formatGameDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ColoredBox(
      color: k.bg,
      child: Column(
        children: [
          const KustTopBar(
            large: true,
            title: 'History',
            subtitle: 'Your past games',
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: GameHistoryStore.instance.listenable(),
              builder: (context, _, _) {
                final games = GameHistoryStore.instance.all();
                if (games.isEmpty) return const _EmptyHistory();
                final stats = HistoryStats.from(games);
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    KustNavBar.clearance(context),
                  ),
                  itemCount: games.length + (stats.total > 0 ? 1 : 0),
                  separatorBuilder: (context, i) => i == 0 && stats.total > 0
                      ? const SizedBox(height: 8)
                      : Divider(height: 1, thickness: 1, color: context.k.line),
                  itemBuilder: (context, i) {
                    if (stats.total > 0) {
                      if (i == 0) return _StatsCard(stats: stats);
                      i--;
                    }
                    return _GameTile(game: games[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final HistoryStats stats;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    Widget cell(String value, String label, Color color) => Expanded(
      child: Column(
        children: [
          Text(value, style: k.title.copyWith(color: color)),
          Text(label, style: k.caption),
        ],
      ),
    );

    return KustCard(
      child: Row(
        children: [
          cell('${stats.wins}', 'Wins', k.success),
          cell('${stats.losses}', 'Losses', k.danger),
          cell('${stats.draws}', 'Draws', k.muted),
          cell('${stats.winRate}%', 'Win rate', k.ink),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(32, 0, 32, KustNavBar.clearance(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 40, color: k.muted),
            const SizedBox(height: 12),
            Text('No games yet', style: k.title),
            const SizedBox(height: 4),
            Text(
              'Finished games show up here so you can replay them.',
              textAlign: TextAlign.center,
              style: k.body.copyWith(color: k.muted),
            ),
            const SizedBox(height: 20),
            KustButton(
              label: 'Play a game',
              expand: false,
              onTap: () => context.go('/play'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game});

  final GameRecord game;

  void _confirmDelete(BuildContext context) {
    showKustSheet<void>(
      context,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KustSheetHeader(
            title: 'Delete this game?',
            subtitle: 'It will be removed from your history.',
          ),
          KustButton(
            label: 'Delete',
            onTap: () {
              Navigator.of(sheetContext).pop();
              GameHistoryStore.instance.delete(game.id);
            },
          ),
          const SizedBox(height: 8),
          KustButton(
            label: 'Keep',
            style: KustButtonStyle.outline,
            onTap: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final plies = game.uciMoves.length;
    final accuracy = game.accuracy;
    final change = game.ratingChange;

    // A flat row: no card around it. Rows are separated by hairlines.
    return Semantics(
      button: true,
      label:
          '${game.isLocal ? 'Pass and play' : 'Game against ${game.botName}'}, '
          '${describeResult(game)}'
          '${accuracy == null ? '' : ', accuracy ${accuracy.toStringAsFixed(1)} percent'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/history/${game.id}'),
        onLongPress: () => _confirmDelete(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Icon(
                  _kindIcon(game),
                  size: 22,
                  color: game.isLocal || game.practice ? k.muted : k.accent,
                ),
              ),
              const SizedBox(width: 12),
              _Avatar(game: game),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            game.isLocal
                                ? 'Pass & Play'
                                : game.botName ?? 'Bot',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: k.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (game.botElo != null) ...[
                          const SizedBox(width: 6),
                          Text('(${game.botElo})', style: k.caption),
                        ],
                        const SizedBox(width: 8),
                        _ResultBadge(game: game),
                      ],
                    ),
                    Text(
                      '${formatGameDate(game.date)} · ${(plies + 1) ~/ 2} moves'
                      '${game.practice ? ' · Practice' : ''}'
                      '${change == null ? '' : ' · ${change > 0 ? '+' : ''}$change'}',
                      style: k.caption,
                    ),
                  ],
                ),
              ),
              if (accuracy != null)
                Text(
                  '${accuracy.toStringAsFixed(1)}%',
                  style: k.body.copyWith(fontWeight: FontWeight.w800),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _kindIcon(GameRecord game) {
    if (game.isLocal) return Icons.people_outline_rounded;
    if (game.practice) return Icons.school_outlined;
    return game.timeControl == null
        ? Icons.hourglass_empty_rounded
        : Icons.bolt_rounded;
  }
}

/// Small square with + (win), - (loss) or = (draw) like the reference list.
class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.game});

  final GameRecord game;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final String symbol;
    final Color color;
    if (game.isLocal || game.result == GameRecord.draw) {
      symbol = '=';
      color = k.muted;
    } else if (game.result == GameRecord.win) {
      symbol = '+';
      color = k.success;
    } else {
      symbol = '\u2212';
      color = k.danger;
    }
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        symbol,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.game});

  final GameRecord game;

  @override
  Widget build(BuildContext context) {
    final path = game.botId == null ? null : 'assets/bots/${_asset(game)}.png';
    // Avatars here are square: no corner rounding.
    if (path == null) {
      return const KustIconTile(Icons.people_outline_rounded, radius: 0);
    }
    return Image.asset(
      path,
      width: 44,
      height: 44,
      cacheWidth: 132,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const KustIconTile(Icons.smart_toy_outlined, radius: 0),
    );
  }

  static String _asset(GameRecord game) {
    final name = game.botName ?? '';
    return name.isEmpty ? '' : name[0].toUpperCase() + name.substring(1);
  }
}
