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
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/loom.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';

const int kPuzzleLevel = 1;

/// One level of the carpet: the tribal göl it weaves and its puzzle theme.
class LoomLevel {
  const LoomLevel(this.gol, this.tribe, this.theme);

  final GolKind gol;
  final String tribe;
  final String theme;
}

/// The five göls of the carpet, bottom to top. Only the first level has
/// puzzles so far; the others show as charted göls still to come.
const List<LoomLevel> kLoomLevels = [
  LoomLevel(GolKind.teke, 'Teke', 'Mate in 1'),
  LoomLevel(GolKind.yomut, 'Ýomut', 'Mate in 2'),
  LoomLevel(GolKind.arsary, 'Arsary', 'Forks'),
  LoomLevel(GolKind.cowdur, 'Çowdur', 'Pins'),
  LoomLevel(GolKind.salyr, 'Salyr', 'Endgames'),
];

final List<GolKind> _gols = [for (final l in kLoomLevels) l.gol];

/// How far the carpet was woven when the screen last showed it, so returning
/// after a solve weaves the new knots in front of the player.
double? _lastWoven;

int _currentIndex(PuzzleLevel level, PuzzleProgress progress) {
  final index = level.puzzles.indexWhere((p) => !progress.isCompleted(p.id));
  return index == -1 ? level.puzzles.length - 1 : index;
}

String _themeLabel(String theme) {
  if (theme.startsWith('mateIn')) {
    return 'Mate in ${theme.substring('mateIn'.length)}';
  }
  return 'Win material';
}

class PuzzlesScreen extends StatefulWidget {
  const PuzzlesScreen({super.key});

  @override
  State<PuzzlesScreen> createState() => _PuzzlesScreenState();
}

class _PuzzlesScreenState extends State<PuzzlesScreen> {
  final ScrollController _scroll = ScrollController();
  late Future<PuzzleLevel> _levelFuture = PuzzleRepository.instance.loadLevel(
    kPuzzleLevel,
  );
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
      (fell - position.viewportDimension * 0.55)
          .clamp(0.0, position.maxScrollExtent)
          .toDouble(),
    );
  }

  void _openPuzzle(BuildContext context, int index) {
    context.push('/puzzle/$kPuzzleLevel/$index');
  }

  void _showList(
    BuildContext context,
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
              title: '${kLoomLevels.first.tribe} göl',
              subtitle:
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
                        '${_themeLabel(level.puzzles[index].theme)} · ${level.puzzles[index].rating}',
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
                            _openPuzzle(context, index);
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
        child: FutureBuilder<PuzzleLevel>(
          future: _levelFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Frame(
                child: _StateMessage(
                  icon: Icons.cloud_off_rounded,
                  message: 'Could not load puzzles',
                  actionLabel: 'Try again',
                  onAction: () => setState(() {
                    _levelFuture = PuzzleRepository.instance.loadLevel(
                      kPuzzleLevel,
                    );
                  }),
                ),
              );
            }
            final level = snapshot.data;
            if (level == null) {
              return const _Frame(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: LoomColors.saffron,
                  ),
                ),
              );
            }
            if (level.puzzles.isEmpty) {
              return const _Frame(
                child: _StateMessage(
                  icon: Icons.extension_off_rounded,
                  message: 'No puzzles yet. Check back soon.',
                ),
              );
            }
            return ValueListenableBuilder(
              valueListenable: PuzzleProgressStore.instance.listenable(),
              builder: (context, _, _) => _loaded(context, level),
            );
          },
        ),
      ),
    );
  }

  Widget _loaded(BuildContext context, PuzzleLevel level) {
    final progress = PuzzleProgressStore.instance.load();
    final total = level.puzzles.length;
    final done = level.puzzles.where((p) => progress.isCompleted(p.id)).length;
    final allDone = done == total;
    final current = _currentIndex(level, progress);
    final woven = done / total;
    final from = _lastWoven ?? woven;
    _lastWoven = woven;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialJumpDone && mounted) {
        _initialJumpDone = true;
        _scrollToFell(from);
      }
    });

    return _Frame(
      coach: _Coach(
        line: allDone
            ? 'Teke göl woven! New göls are coming soon.'
            : 'Next: ${_themeLabel(level.puzzles[current].theme)}. '
                  '${_Coach.tipOfTheDay()}',
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              child: _Carpet(
                from: from,
                woven: woven,
                done: done,
                total: total,
                onOpen: allDone
                    ? () => _showList(context, level, progress, current)
                    : () => _openPuzzle(context, current),
              ),
            ),
          ),
          _Panel(
            progress: progress,
            done: done,
            total: total,
            action: allDone
                ? 'Review puzzles'
                : 'Continue · ${_themeLabel(level.puzzles[current].theme)}',
            onAction: allDone
                ? () => _showList(context, level, progress, current)
                : () => _openPuzzle(context, current),
            onList: () => _showList(context, level, progress, current),
          ),
        ],
      ),
    );
  }
}

/// The screen chrome on the felt: title, coach line and the content below.
class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.coach});

  final Widget child;
  final Widget? coach;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
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
                if (coach != null) ...[const SizedBox(height: 8), coach!],
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

/// The coach: a bot's face and one line saying what is next.
class _Coach extends StatelessWidget {
  const _Coach({required this.line});

  final String line;

  static const List<String> _tips = [
    'Never skip puzzle day!',
    'Look for checks, captures and threats first.',
    'One puzzle a day keeps the blunders away.',
    'Take your time: the best move is usually forcing.',
  ];

  static int get _day => DateTime.now().difference(DateTime(2026)).inDays;

  static String tipOfTheDay() => _tips[_day % _tips.length];

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final bot = kInternationalBots[_day % kInternationalBots.length];
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: LoomColors.saffron,
          ),
          padding: const EdgeInsets.all(1.5),
          child: ClipOval(
            child: Image.asset(
              bot.imagePath,
              cacheWidth: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            line,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: k.caption.copyWith(
              color: LoomColors.cream.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// The runner with each level's label beside its göl.
class _Carpet extends StatelessWidget {
  const _Carpet({
    required this.from,
    required this.woven,
    required this.done,
    required this.total,
    required this.onOpen,
  });

  final double from;
  final double woven;
  final int done;
  final int total;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final count = kLoomLevels.length;
    final height = LoomMetrics.height(count) + 24;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final current = woven >= 1 ? 1 : 0;

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
                      painter: LoomPainter(
                        gols: _gols,
                        woven: value,
                        current: value >= 1 ? 1 : 0,
                      ),
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
                  state: i < current
                      ? _GolState.woven
                      : i == current
                      ? _GolState.onLoom
                      : _GolState.charted,
                ),
              // Tapping the göl on the loom opens the next puzzle.
              Positioned(
                left: left,
                width: LoomMetrics.width,
                top: LoomMetrics.golTop(count, 0),
                height: LoomMetrics.slot,
                child: Semantics(
                  button: true,
                  label:
                      '${kLoomLevels.first.tribe} göl, ${kLoomLevels.first.theme}, '
                      '$done of $total knots woven',
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
    required _GolState state,
  }) {
    final k = context.k;
    final level = kLoomLevels[index];
    final dim = state == _GolState.charted;
    final onLoom = state == _GolState.onLoom;
    final color = LoomColors.cream.withValues(alpha: dim ? 0.65 : 1);
    final align = alignRight ? TextAlign.right : TextAlign.left;
    final center = LoomMetrics.golCenter(kLoomLevels.length, index);

    final status = switch (state) {
      _GolState.woven => 'Woven ✓',
      _GolState.onLoom when index == 0 => '$done of $total knots',
      _GolState.onLoom => 'Coming soon',
      _GolState.charted => 'Coming soon',
    };

    return Positioned(
      left: left,
      width: width,
      top: center - 22,
      child: ExcludeSemantics(
        excluding: index == 0,
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
              status,
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

enum _GolState { woven, onLoom, charted }

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
