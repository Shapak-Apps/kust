import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/features/learn/mountain.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/tokens.dart';

/// The Learn tab: a trail up a mountain with a stop for every lesson, from
/// the first pawn move at the foot to checkmate at the top.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  ScrollController? _scroll;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    LearnProgress.instance.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  /// The trail starts at the foot, scrolled so the next stop is in view.
  ScrollController _controllerFor(
    MountainLayout layout,
    double viewport,
    int next,
  ) {
    return _scroll ??= ScrollController(
      initialScrollOffset: (layout.fromBottom(next) - viewport / 2).clamp(
        0.0,
        layout.height - viewport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ColoredBox(
      color: k.bg,
      child: Column(
        children: [
          FeltHeader(title: context.t.learnTitle),
          Expanded(
            child: !_loaded
                ? const SizedBox.shrink()
                : LayoutBuilder(
                    builder: (context, box) {
                      final layout = MountainLayout(
                        width: box.maxWidth,
                        count: kLessons.length,
                        footRoom: KustNavBar.clearance(context) + 40,
                      );
                      return ValueListenableBuilder<Set<String>>(
                        valueListenable: LearnProgress.instance.done,
                        builder: (context, done, _) {
                          final next = kLessons.indexWhere(
                            (l) => !done.contains(l.id),
                          );
                          final controller = _controllerFor(
                            layout,
                            box.maxHeight,
                            next < 0 ? kLessons.length - 1 : next,
                          );
                          return Stack(
                            children: [
                              // Scrolled from the bottom, the way you climb.
                              SingleChildScrollView(
                                controller: controller,
                                reverse: true,
                                child: MountainPath(
                                  layout: layout,
                                  done: done,
                                  onOpen: (lesson) =>
                                      context.push('/lesson/${lesson.id}'),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 16,
                                child: _ProgressPill(
                                  done: done.length,
                                  total: kLessons.length,
                                ),
                              ),
                            ],
                          );
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

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xCC141210),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 16, color: MountainPainter.gold),
          const SizedBox(width: 6),
          Text(
            context.t.lessonCount(done, total),
            style: k.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
