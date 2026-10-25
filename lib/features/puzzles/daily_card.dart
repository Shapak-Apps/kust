import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/puzzles/daily.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/features/puzzles/puzzle_theme.dart';
import 'package:kust/ui/kust_tile.dart';
import 'package:kust/ui/tokens.dart';

/// Every puzzle level, loaded once for the daily pick. A level that cannot
/// be read counts as empty.
Future<List<PuzzleLevel?>> _loadLevels() => Future.wait([
  for (var n = 1; n <= 5; n++)
    PuzzleRepository.instance
        .loadLevel(n)
        .then<PuzzleLevel?>((level) => level, onError: (_) => null),
]);

/// The puzzle of the day on the Play screen: it opens the puzzle and shows
/// the streak. Shows nothing until the puzzles have loaded, or if there are
/// none.
class DailyPuzzleCard extends StatefulWidget {
  const DailyPuzzleCard({super.key});

  @override
  State<DailyPuzzleCard> createState() => _DailyPuzzleCardState();
}

class _DailyPuzzleCardState extends State<DailyPuzzleCard> {
  final Future<List<PuzzleLevel?>> _levels = _loadLevels();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PuzzleLevel?>>(
      future: _levels,
      builder: (context, snapshot) {
        final levels = snapshot.data;
        // Keeps its place in the row while the puzzles load.
        if (levels == null) return const SizedBox(height: KustTile.height);
        return ValueListenableBuilder(
          valueListenable: DailyStore.instance.listenable(),
          builder: (context, _, _) {
            final now = DateTime.now();
            final daily = dailyPuzzle(levels, now);
            if (daily == null) return const SizedBox(height: KustTile.height);
            final streak = DailyStore.instance.load();
            return DailyTile(
              subtitle:
                  '${puzzleThemeLabel(daily.puzzle.theme)} · ${daily.puzzle.rating}',
              solved: streak.doneOn(now),
              streak: streak.on(now),
              onTap: () =>
                  context.push('/puzzle/${daily.level}/${daily.index}?daily=1'),
            );
          },
        );
      },
    );
  }
}

/// The puzzle of the day, with the player's streak.
class DailyTile extends StatelessWidget {
  const DailyTile({
    super.key,
    required this.subtitle,
    required this.solved,
    required this.streak,
    required this.onTap,
  });

  final String subtitle;
  final bool solved;

  /// Days in a row the daily puzzle was solved.
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final days = streak == 1 ? '1 day' : '$streak days';
    return KustTile(
      icon: solved ? Icons.check_rounded : Icons.today_rounded,
      title: 'Daily puzzle',
      subtitle: solved ? 'Solved today' : subtitle,
      onTap: onTap,
      semanticsLabel:
          'Daily puzzle, ${solved ? 'solved' : subtitle}'
          '${streak > 0 ? ', streak $days' : ''}',
      badge: streak > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: LoomColors.rust,
                ),
                const SizedBox(width: 2),
                Text(
                  days,
                  style: k.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: k.ink,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
