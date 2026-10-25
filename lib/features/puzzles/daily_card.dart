import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/puzzles/daily.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/features/puzzles/puzzle_theme.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/pressable.dart';
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
        if (levels == null) return const SizedBox.shrink();
        return ValueListenableBuilder(
          valueListenable: DailyStore.instance.listenable(),
          builder: (context, _, _) {
            final now = DateTime.now();
            final daily = dailyPuzzle(levels, now);
            if (daily == null) return const SizedBox.shrink();
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
    return Semantics(
      button: true,
      label:
          'Daily puzzle, ${solved ? 'solved' : subtitle}'
          '${streak > 0 ? ', streak $days' : ''}',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(KustSpace.rMedium),
            border: Border.all(color: k.line),
          ),
          child: Row(
            children: [
              KustIconTile(solved ? Icons.check_rounded : Icons.today_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily puzzle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      solved ? 'Solved today' : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k.caption,
                    ),
                  ],
                ),
              ),
              if (streak > 0) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 20,
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
              ] else
                Icon(Icons.chevron_right_rounded, color: k.muted),
            ],
          ),
        ),
      ),
    );
  }
}
