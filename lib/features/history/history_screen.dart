import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/history/history_analysis.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/pressable.dart';
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
                // No side padding on the list, so the hairlines run edge to
                // edge; each row pads its own content.
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    8,
                    0,
                    KustNavBar.clearance(context),
                  ),
                  itemCount: games.length,
                  separatorBuilder: (context, _) =>
                      Divider(height: 1, thickness: 1, color: context.k.line),
                  itemBuilder: (context, i) => _GameTile(game: games[i]),
                );
              },
            ),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      '${formatGameDate(game.date)}'
                      '${game.practice ? ' · Practice' : ''}'
                      '${change == null ? '' : ' · ${change > 0 ? '+' : ''}$change'}',
                      style: k.caption,
                    ),
                  ],
                ),
              ),
              _AnalysisSlot(game: game),
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

/// Right end of a history row: the game's accuracy, or an Analyze button that
/// turns into a live percentage while it runs and then into the accuracy.
class _AnalysisSlot extends StatelessWidget {
  const _AnalysisSlot({required this.game});

  final GameRecord game;

  Future<void> _start(BuildContext context) async {
    final ok = await HistoryAnalysis.instance.start(game);
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Analysis is not available on this device right now'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final accuracy = game.accuracy;

    Widget slot(Widget child) => SizedBox(
      width: 76,
      child: Align(alignment: Alignment.centerRight, child: child),
    );

    if (accuracy != null) {
      return slot(
        Text(
          '${accuracy.toStringAsFixed(1)}%',
          style: k.body.copyWith(fontWeight: FontWeight.w800),
        ),
      );
    }
    if (!HistoryAnalysis.canAnalyze(game)) return const SizedBox.shrink();

    return ValueListenableBuilder<AnalysisState?>(
      valueListenable: HistoryAnalysis.instance.stateFor(game.id),
      builder: (context, state, _) {
        if (state?.status == AnalysisStatus.running) {
          return slot(
            Text(
              '${state!.percent}%',
              style: k.body.copyWith(
                fontWeight: FontWeight.w800,
                color: k.accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          );
        }
        final failed = state?.status == AnalysisStatus.failed;
        return slot(
          // Just the icon, no circle around it; the hit area stays generous.
          Semantics(
            button: true,
            label: failed ? 'Retry analysis' : 'Analyze this game',
            excludeSemantics: true,
            child: Pressable(
              onTap: () => _start(context),
              scale: 0.9,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  failed ? Icons.refresh_rounded : Icons.insights_rounded,
                  size: 28,
                  color: k.ink,
                ),
              ),
            ),
          ),
        );
      },
    );
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
