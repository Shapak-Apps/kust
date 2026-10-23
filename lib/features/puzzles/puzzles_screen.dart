import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:Kust/core/storage/puzzle_progress_store.dart';
import 'package:Kust/features/play/play_screen.dart';
import 'package:Kust/features/puzzles/puzzle_data.dart';

const int kPuzzleLevel = 1;
const double _nodeSpacing = 112;
const double _nodeSize = 68;
const double _pathPadding = 24;
const List<double> _zigzag = [0.5, 0.25, 0.5, 0.75];
const Color _solvedColor = Color(0xFF3CB371);
const Color _revealedColor = Color(0xFF8E8E93);

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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: level.puzzles.length,
            itemBuilder: (itemContext, index) {
              final puzzle = level.puzzles[index];
              final locked = index > current;
              final solved = progress.isSolved(puzzle.id);
              final revealed = progress.isRevealed(puzzle.id);
              return ListTile(
                enabled: !locked,
                leading: Icon(
                  solved
                      ? Icons.check_circle_rounded
                      : revealed
                      ? Icons.visibility_rounded
                      : locked
                      ? Icons.lock_rounded
                      : Icons.play_circle_rounded,
                  color: solved
                      ? _solvedColor
                      : (revealed ? _revealedColor : null),
                ),
                title: Text('Puzzle ${index + 1}'),
                subtitle: Text(
                  '${_themeLabel(puzzle.theme)} · ${puzzle.rating}',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openPuzzle(context, index);
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.extension_rounded, color: kAccentColor),
            SizedBox(width: 8),
            Text('Puzzles', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: FutureBuilder<PuzzleLevel>(
        future: _levelFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load puzzles'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() {
                      _levelFuture = PuzzleRepository.instance.loadLevel(
                        kPuzzleLevel,
                      );
                    }),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }
          final level = snapshot.data;
          if (level == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (level.puzzles.isEmpty) {
            return const Center(child: Text('No puzzles yet'));
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
                          child: FloatingActionButton.small(
                            heroTag: 'puzzles-jump-to-current',
                            backgroundColor: kAccentColor,
                            foregroundColor: Colors.black,
                            onPressed: () => _scrollTo(current, count),
                            child: const Icon(Icons.arrow_upward_rounded),
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
      ),
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
    final scheme = Theme.of(context).colorScheme;
    final fill = solved
        ? _solvedColor
        : revealed
        ? _revealedColor
        : locked
        ? scheme.surfaceContainerHighest
        : kAccentColor;

    final Widget center = solved
        ? const Icon(Icons.check_rounded, color: Colors.white, size: 34)
        : revealed
        ? const Icon(Icons.visibility_rounded, color: Colors.white, size: 30)
        : locked
        ? Icon(Icons.lock_rounded, color: scheme.onSurfaceVariant)
        : Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          );

    return GestureDetector(
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
                border: Border.all(color: scheme.surface, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, offset: Offset(0, 4)),
                ],
              ),
              child: Center(child: center),
            ),
            if (current)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface,
                    border: Border.all(color: kAccentColor, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, size: 18),
                ),
              ),
          ],
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RATING',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: muted,
                  ),
                ),
                Text(
                  '${progress.rating}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _Stat(label: 'HIGHEST', value: '${progress.highest}'),
          const SizedBox(width: 20),
          _Stat(label: 'ATTEMPTS', value: '${progress.attempts}'),
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, letterSpacing: 1, color: muted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: FilledButton(
              onPressed: onList,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: kAccentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(Icons.format_list_bulleted_rounded, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: onSolve,
                style: FilledButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Solve Puzzles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
