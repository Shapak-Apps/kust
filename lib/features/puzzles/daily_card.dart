import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/puzzles/daily.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/features/puzzles/puzzle_theme.dart';
import 'package:kust/ui/press_highlight.dart';
import 'package:kust/widgets/board_thumbnail.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

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
        if (levels == null) return const SizedBox(height: _height);
        return ValueListenableBuilder(
          valueListenable: DailyStore.instance.listenable(),
          builder: (context, _, _) {
            final now = DateTime.now();
            final daily = dailyPuzzle(levels, now);
            if (daily == null) return const SizedBox(height: _height);
            final streak = DailyStore.instance.load();
            Position? start;
            try {
              start = Chess.fromSetup(Setup.parseFen(daily.puzzle.fen));
            } catch (_) {
              start = null;
            }
            return _DailySection(
              theme: puzzleThemeLabel(daily.puzzle.theme, context.t),
              rating: daily.puzzle.rating,
              position: start,
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

/// Room the section takes while the puzzles load, so nothing jumps.
const double _height = 112;

/// The puzzle of the day as a section of the page, like Continue: its
/// title with the streak at the end, then the puzzle's board beside its
/// theme and a pill with its rating (green "Solved today" once done).
class _DailySection extends StatelessWidget {
  const _DailySection({
    required this.theme,
    required this.rating,
    required this.position,
    required this.solved,
    required this.streak,
    required this.onTap,
  });

  final String theme;
  final int rating;
  final Position? position;
  final bool solved;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final days = t.streakDays(streak);
    final board = position;
    return Semantics(
      button: true,
      label:
          '${t.dailyPuzzle}, ${solved ? t.dailySolved : '$theme, $rating'}'
          '${streak > 0 ? ', ${t.dailyStreakSem(days)}' : ''}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.dailyPuzzle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: k.section,
                ),
              ),
              if (streak > 0) ...[
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: LoomColors.rust,
                ),
                const SizedBox(width: 3),
                Text(days, style: k.captionStrong.copyWith(color: k.ink)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          PressHighlight(
            onTap: onTap,
            borderRadius: BorderRadius.circular(KustSpace.rCard),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: board == null
                      ? const AspectRatio(aspectRatio: 1)
                      : BoardThumbnail(
                          position: board,
                          flipped: board.turn == Side.black,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: k.rowTitle,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: solved
                              ? k.success.withValues(alpha: 0.16)
                              : k.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          solved ? t.solvedToday : '$rating',
                          style: k.captionStrong.copyWith(
                            color: solved ? k.success : k.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: k.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
