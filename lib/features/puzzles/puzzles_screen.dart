import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/features/puzzles/carpet.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';

const int kPuzzleLevel = 1;
const double _nodeSpacing = 112;
const double _nodeSize = 68;
const double _pathPadding = 24;

/// Room above the last puzzle for the coach, which floats over the carpet.
const double _coachSpace = 92;
const List<double> _zigzag = [0.5, 0.25, 0.5, 0.75];

double _pathHeight(int count) {
  return count * _nodeSpacing + _nodeSpacing + _pathPadding * 2 + _coachSpace;
}

double _nodeCenterY(int index, int count) {
  return _pathHeight(count) -
      _pathPadding -
      (index * _nodeSpacing + _nodeSpacing / 2);
}

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

  void _scrollTo(int index, int count) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final target = (_nodeCenterY(index, count) - position.viewportDimension / 2)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
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
              title: 'All puzzles',
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
    final k = context.k;
    return ColoredBox(
      color: k.bg,
      child: Column(
        children: [
          const KustTopBar(
            large: true,
            title: 'Puzzles',
            subtitle: 'Sharpen your tactics',
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: KustNavBar.clearance(context)),
              child: _body(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    return FutureBuilder<PuzzleLevel>(
      future: _levelFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StateMessage(
            icon: Icons.cloud_off_rounded,
            message: 'Could not load puzzles',
            actionLabel: 'Try again',
            onAction: () => setState(() {
              _levelFuture = PuzzleRepository.instance.loadLevel(kPuzzleLevel);
            }),
          );
        }
        final level = snapshot.data;
        if (level == null) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: context.k.accent,
            ),
          );
        }
        if (level.puzzles.isEmpty) {
          return const _StateMessage(
            icon: Icons.extension_off_rounded,
            message: 'No puzzles yet. Check back soon.',
          );
        }
        return ValueListenableBuilder(
          valueListenable: PuzzleProgressStore.instance.listenable(),
          builder: (context, _, _) {
            final progress = PuzzleProgressStore.instance.load();
            final current = _currentIndex(level, progress);
            final count = level.puzzles.length;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_initialJumpDone && mounted) {
                _initialJumpDone = true;
                _scrollTo(current, count);
              }
            });

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        controller: _scroll,
                        child: _PuzzlePath(
                          level: level,
                          progress: progress,
                          currentIndex: current,
                          onOpen: (index) => _openPuzzle(context, index),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 16,
                        right: 16,
                        child: _Coach(
                          next: _themeLabel(level.puzzles[current].theme),
                          allDone: level.puzzles.every(
                            (p) => progress.isCompleted(p.id),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: KustIconButton(
                          icon: Icons.my_location_rounded,
                          label: 'Jump to current puzzle',
                          filled: true,
                          onTap: () => _scrollTo(current, count),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatsBar(progress: progress),
                _ActionBar(
                  onSolve: () => _openPuzzle(context, current),
                  onList: () => _showList(context, level, progress, current),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PuzzlePath extends StatelessWidget {
  const _PuzzlePath({
    required this.level,
    required this.progress,
    required this.currentIndex,
    required this.onOpen,
  });

  final PuzzleLevel level;
  final PuzzleProgress progress;
  final int currentIndex;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final count = level.puzzles.length;
    final k = context.k;
    final colors = CarpetColors.of(Theme.of(context).brightness);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = _pathHeight(count);
        final centers = [
          for (var i = 0; i < count; i++)
            Offset(width * _zigzag[i % _zigzag.length], _nodeCenterY(i, count)),
        ];

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              // Drawn once and kept as a layer while scrolling.
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: CarpetPatternPainter(colors: colors),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: ThreadPainter(
                    centers: centers,
                    reachedIndex: currentIndex,
                    done: k.accent,
                    todo: k.muted.withValues(alpha: 0.55),
                  ),
                ),
              ),
              for (var i = 0; i < count; i++)
                Positioned(
                  left: centers[i].dx - _nodeSize / 2,
                  top: centers[i].dy - _nodeSize / 2,
                  child: _PuzzleNode(
                    index: i,
                    solved: progress.isSolved(level.puzzles[i].id),
                    revealed: progress.isRevealed(level.puzzles[i].id),
                    current: i == currentIndex,
                    locked: i > currentIndex,
                    onTap: () => onOpen(i),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PuzzleNode extends StatelessWidget {
  const _PuzzleNode({
    required this.index,
    required this.solved,
    required this.revealed,
    required this.current,
    required this.locked,
    required this.onTap,
  });

  final int index;
  final bool solved;
  final bool revealed;
  final bool current;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = CarpetColors.of(Theme.of(context).brightness);

    final Color fill = solved
        ? k.success
        : revealed
        ? k.muted
        : locked
        ? k.surfaceAlt
        : k.accent;
    final Color ring = solved || revealed
        ? Colors.white.withValues(alpha: 0.85)
        : locked
        ? k.line
        : k.accentInk.withValues(alpha: 0.55);

    final Widget center = solved
        ? const Icon(Icons.check_rounded, color: Colors.white, size: 32)
        : revealed
        ? const Icon(Icons.visibility_rounded, color: Colors.white, size: 28)
        : locked
        ? Icon(Icons.lock_rounded, color: k.muted, size: 24)
        : Text('${index + 1}', style: k.title.copyWith(color: k.accentInk));

    final status = solved
        ? 'solved'
        : revealed
        ? 'solution shown'
        : locked
        ? 'locked'
        : 'available';

    return Semantics(
      button: !locked,
      label: 'Puzzle ${index + 1}, $status',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: SizedBox(
          width: _nodeSize,
          height: _nodeSize,
          child: CustomPaint(
            painter: OctagonPainter(
              fill: fill,
              ring: ring,
              halo: current ? (isDark ? colors.gold : colors.red) : null,
            ),
            child: Center(child: center),
          ),
        ),
      ),
    );
  }
}

/// The coach: a bot with a speech bubble saying what is next and a tip.
class _Coach extends StatelessWidget {
  const _Coach({required this.next, required this.allDone});

  /// Theme label of the next puzzle, e.g. "Mate in 2".
  final String next;
  final bool allDone;

  static const List<String> _tips = [
    'Never skip puzzle day!',
    'Look for checks, captures and threats first.',
    'One puzzle a day keeps the blunders away.',
    'Take your time: the best move is usually forcing.',
  ];

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final day = DateTime.now().difference(DateTime(2026)).inDays;
    final bot = kInternationalBots[day % kInternationalBots.length];
    final tip = _tips[day % _tips.length];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Image.asset(
          bot.imagePath,
          width: 56,
          height: 56,
          cacheWidth: 168,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox(width: 56, height: 56),
        ),
        Expanded(
          child: CustomPaint(
            painter: SpeechBubblePainter(fill: k.surface, border: k.line),
            child: Padding(
              // Extra room on the left for the bubble's tail.
              padding: const EdgeInsets.fromLTRB(
                BubbleMetrics.tail + 14,
                10,
                14,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone ? 'You solved them all!' : 'Next: $next',
                    style: k.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    allDone ? 'More puzzles are coming soon.' : tip,
                    style: k.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.progress});

  final PuzzleProgress progress;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RATING', style: k.caption.copyWith(letterSpacing: 1)),
                Text('${progress.rating}', style: k.display),
              ],
            ),
          ),
          _Stat(label: 'HIGHEST', value: '${progress.highest}'),
          const SizedBox(width: 24),
          _Stat(label: 'SOLVED', value: '${progress.solved.length}'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: k.caption.copyWith(letterSpacing: 1)),
        Text(value, style: k.title),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onSolve, required this.onList});

  final VoidCallback onSolve;
  final VoidCallback onList;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          KustIconButton(
            icon: Icons.format_list_bulleted_rounded,
            label: 'All puzzles',
            size: 52,
            onTap: onList,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: KustButton(label: 'Solve puzzles', onTap: onSolve),
          ),
        ],
      ),
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
            Icon(icon, size: 40, color: k.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: k.body),
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
