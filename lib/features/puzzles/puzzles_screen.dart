import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';

const int kPuzzleLevel = 1;
const double _nodeSpacing = 112;
const double _nodeSize = 68;
const double _pathPadding = 24;
const List<double> _zigzag = [0.5, 0.25, 0.5, 0.75];

double _pathHeight(int count) {
  return count * _nodeSpacing + _nodeSpacing + _pathPadding * 2;
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
    final lineColor = Theme.of(context).colorScheme.outlineVariant;

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
              CustomPaint(
                size: Size(width, height),
                painter: _PathPainter(centers: centers, color: lineColor),
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

class _PathPainter extends CustomPainter {
  _PathPainter({required this.centers, required this.color});

  final List<Offset> centers;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (final center in centers.skip(1)) {
      path.lineTo(center.dx, center.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.centers != centers || oldDelegate.color != color;
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
    final Color fill = solved
        ? k.success
        : revealed
        ? k.muted
        : locked
        ? k.surfaceAlt
        : k.accent;

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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(color: k.bg, width: 4),
                ),
                child: Center(child: center),
              ),
              if (current)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: k.ink,
                      border: Border.all(color: k.bg, width: 3),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 14,
                      color: k.bg,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
