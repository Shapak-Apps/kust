import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/features/puzzles/coach_bubble.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/loom.dart';
import 'package:kust/features/puzzles/loom_progress.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';
import 'package:kust/features/puzzles/puzzle_theme.dart';

/// One level of the carpet: the tribal göl it weaves and its puzzle theme.
class LoomLevel {
  const LoomLevel(this.gol, this.tribe, this.theme);

  final GolKind gol;
  final String tribe;
  final String theme;
}

/// The five göls of the carpet, bottom to top, one per puzzle level
/// (`assets/puzzles/level1.json` to `level5.json`).
const List<LoomLevel> kLoomLevels = [
  LoomLevel(GolKind.teke, 'Teke', 'Mate in 1'),
  LoomLevel(GolKind.yomut, 'Ýomut', 'Mate in 2'),
  LoomLevel(GolKind.arsary, 'Arsary', 'Forks'),
  LoomLevel(GolKind.cowdur, 'Çowdur', 'Pins'),
  LoomLevel(GolKind.salyr, 'Salyr', 'Endgames'),
];

final List<GolKind> _gols = [for (final l in kLoomLevels) l.gol];

/// Room kept above the carpet for the coach: its face (64) plus margins.
const double _coachInset = 88;

/// How far the carpet was woven when the screen last showed it, so returning
/// after a solve weaves the new knots in front of the player.
double? _lastWoven;

/// Loads every level. A level that cannot be read counts as having no
/// puzzles yet, so one missing file never hides the others.
Future<List<PuzzleLevel?>> _loadLevels() => Future.wait([
  for (var n = 1; n <= kLoomLevels.length; n++)
    PuzzleRepository.instance
        .loadLevel(n)
        .then<PuzzleLevel?>((level) => level, onError: (_) => null),
]);

class PuzzlesScreen extends StatefulWidget {
  const PuzzlesScreen({super.key});

  @override
  State<PuzzlesScreen> createState() => _PuzzlesScreenState();
}

class _PuzzlesScreenState extends State<PuzzlesScreen> {
  final ScrollController _scroll = ScrollController();
  late Future<List<PuzzleLevel?>> _levelsFuture = _loadLevels();
  bool _initialJumpDone = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToFell(double woven) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final fell = LoomMetrics.fell(kLoomLevels.length, woven);
    position.jumpTo(
      (fell + _coachInset - position.viewportDimension * 0.55)
          .clamp(0.0, position.maxScrollExtent)
          .toDouble(),
    );
  }

  /// Opens puzzle [index] of the level at [levelIndex] (0 for the first).
  void _openPuzzle(BuildContext context, int levelIndex, int index) {
    context.push('/puzzle/${levelIndex + 1}/$index');
  }

  void _showList(
    BuildContext context,
    int levelIndex,
    PuzzleLevel level,
    PuzzleProgress progress,
    int current,
  ) {
    showKustSheet<void>(
      context,
      builder: (sheetContext) {
        final k = sheetContext.k;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KustSheetHeader(
              title: 'All puzzles',
              subtitle:
                  '${kLoomLevels[levelIndex].theme} · '
                  '${level.puzzles.where((p) => progress.isSolved(p.id)).length} of ${level.puzzles.length} solved',
            ),
            for (var index = 0; index < level.puzzles.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Opacity(
                  opacity: index > current ? 0.5 : 1,
                  child: KustOption(
                    title: 'Puzzle ${index + 1}',
                    subtitle:
                        '${puzzleThemeLabel(level.puzzles[index].theme)} · ${level.puzzles[index].rating}',
                    leading: KustIconTile(
                      progress.isSolved(level.puzzles[index].id)
                          ? Icons.check_rounded
                          : progress.isRevealed(level.puzzles[index].id)
                          ? Icons.visibility_rounded
                          : index > current
                          ? Icons.lock_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    trailing: progress.isSolved(level.puzzles[index].id)
                        ? Icon(Icons.check_circle_rounded, color: k.success)
                        : const SizedBox.shrink(),
                    onTap: index > current
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            _openPuzzle(context, levelIndex, index);
                          },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: Theme.of(context).brightness == Brightness.dark
            ? LoomColors.feltDark
            : LoomColors.felt,
        child: FutureBuilder<List<PuzzleLevel?>>(
          future: _levelsFuture,
          builder: (context, snapshot) {
            final levels = snapshot.data;
            if (levels == null) {
              return const _Frame(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: LoomColors.saffron,
                  ),
                ),
              );
            }
            if (levels.first == null) {
              return _Frame(
                child: _StateMessage(
                  icon: Icons.cloud_off_rounded,
                  message: 'Could not load puzzles',
                  actionLabel: 'Try again',
                  onAction: () => setState(() {
                    _levelsFuture = _loadLevels();
                  }),
                ),
              );
            }
            if (levels.every((l) => l == null || l.puzzles.isEmpty)) {
              return const _Frame(
                child: _StateMessage(
                  icon: Icons.extension_off_rounded,
                  message: 'No puzzles yet. Check back soon.',
                ),
              );
            }
            return ValueListenableBuilder(
              valueListenable: PuzzleProgressStore.instance.listenable(),
              builder: (context, _, _) => _loaded(context, levels),
            );
          },
        ),
      ),
    );
  }

  Widget _loaded(BuildContext context, List<PuzzleLevel?> levels) {
    final progress = PuzzleProgressStore.instance.load();
    final loom = LoomProgress.from(levels, progress);
    final level = levels[loom.current]!;
    final next = level.puzzles[loom.nextPuzzle];
    final from = _lastWoven ?? loom.woven;
    _lastWoven = loom.woven;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialJumpDone && mounted) {
        _initialJumpDone = true;
        _scrollToFell(from);
      }
    });

    void play() => _openPuzzle(context, loom.current, loom.nextPuzzle);
    void list() =>
        _showList(context, loom.current, level, progress, loom.nextPuzzle);

    return _Frame(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scroll,
                  // The coach floats over the top of the carpet; keep the
                  // carpet's start below it.
                  padding: const EdgeInsets.only(top: _coachInset),
                  child: _Carpet(
                    from: from,
                    loom: loom,
                    onOpen: loom.allDone ? list : play,
                  ),
                ),
                // Touches pass through the coach to the carpet below.
                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: CoachBubble(
                      title: loom.allDone
                          ? 'All puzzles woven!'
                          : 'Next: ${puzzleThemeLabel(next.theme)}',
                      tip: loom.allDone
                          ? 'More are coming soon.'
                          : CoachBubble.tipOfTheDay(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Panel(
            progress: progress,
            done: loom.done,
            total: loom.total,
            action: loom.allDone
                ? 'Review puzzles'
                : 'Continue · ${puzzleThemeLabel(next.theme)}',
            onAction: loom.allDone ? list : play,
            onList: list,
          ),
        ],
      ),
    );
  }
}

/// The screen chrome on the felt: title, coach line and the content below.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Puzzles',
                    style: k.display.copyWith(
                      color: LoomColors.cream,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        Expanded(child: child),
      ],
    );
  }
}

/// The runner with each level's label beside its göl.
class _Carpet extends StatelessWidget {
  const _Carpet({required this.from, required this.loom, required this.onOpen});

  final double from;
  final LoomProgress loom;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final count = kLoomLevels.length;
    final height = LoomMetrics.height(count) + 24;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final woven = loom.woven;
    final onLoom = loom.levels[loom.current];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final left = (width - LoomMetrics.width) / 2;
        final labelWidth = left - 26;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: left,
                top: 0,
                width: LoomMetrics.width,
                height: LoomMetrics.height(count),
                child: RepaintBoundary(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: from, end: woven),
                    duration: reduceMotion
                        ? Duration.zero
                        : Duration(
                            milliseconds: (900 + (woven - from).abs() * 1800)
                                .round(),
                          ),
                    curve: Curves.easeInOutCubic,
                    builder: (context, value, _) => CustomPaint(
                      painter: LoomPainter(gols: _gols, woven: value),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < count; i++)
                _label(
                  context,
                  index: i,
                  left: i.isEven ? 16 : left + LoomMetrics.width + 10,
                  width: labelWidth,
                  alignRight: i.isOdd,
                  progress: loom.levels[i],
                ),
              // Tapping the göl on the loom opens the next puzzle.
              Positioned(
                left: left,
                width: LoomMetrics.width,
                top: LoomMetrics.golTop(count, loom.current),
                height: LoomMetrics.slot,
                child: Semantics(
                  button: true,
                  label:
                      '${kLoomLevels[loom.current].theme}, '
                      '${onLoom.done} of ${onLoom.total} knots woven',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onOpen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(
    BuildContext context, {
    required int index,
    required double left,
    required double width,
    required bool alignRight,
    required LevelProgress progress,
  }) {
    final k = context.k;
    final level = kLoomLevels[index];
    final dim =
        progress.state == LevelState.waiting ||
        progress.state == LevelState.comingSoon;
    final onLoom = progress.state == LevelState.onLoom;
    final color = LoomColors.cream.withValues(alpha: dim ? 0.65 : 1);
    final align = alignRight ? TextAlign.right : TextAlign.left;
    final center = LoomMetrics.golCenter(kLoomLevels.length, index);

    return Positioned(
      left: left,
      width: width,
      top: center - 22,
      child: ExcludeSemantics(
        // The göl on the loom is described by the tap area instead.
        excluding: index == loom.current,
        child: Column(
          crossAxisAlignment: alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              level.theme,
              textAlign: align,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: k.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              progress.status,
              textAlign: align,
              style: k.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onLoom
                    ? LoomColors.saffron
                    : LoomColors.cream.withValues(alpha: dim ? 0.65 : 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stats and the main action, on a panel the carpet's fringe hangs over.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.progress,
    required this.done,
    required this.total,
    required this.action,
    required this.onAction,
    required this.onList,
  });

  final PuzzleProgress progress;
  final int done;
  final int total;
  final String action;
  final VoidCallback onAction;
  final VoidCallback onList;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      decoration: BoxDecoration(
        color: k.bg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KustSpace.rLarge),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        18,
        24,
        12 + KustNavBar.clearance(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Stat(
                  label: 'RATING',
                  value: '${progress.rating}',
                  big: true,
                ),
              ),
              Expanded(
                child: _Stat(label: 'KNOTS', value: '$done / $total'),
              ),
              _Stat(label: 'BEST', value: '${progress.highest}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              KustIconButton(
                icon: Icons.format_list_bulleted_rounded,
                label: 'All puzzles',
                size: 52,
                onTap: onList,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KustButton(label: action, onTap: onAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.big = false});

  final String label;
  final String value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: k.caption.copyWith(
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: (big ? k.display : k.title).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: LoomColors.cream),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: k.body.copyWith(color: LoomColors.cream),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              KustButton(label: actionLabel!, onTap: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}
