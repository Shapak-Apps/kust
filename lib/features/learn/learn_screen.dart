import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// The Learn tab: the lessons in order, from the first pawn move to
/// checkmate, with the one to do next marked.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  @override
  void initState() {
    super.initState();
    LearnProgress.instance.load();
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
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: LearnProgress.instance.done,
              builder: (context, done, _) {
                final next = LearnProgress.instance.next;
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    KustNavBar.clearance(context),
                  ),
                  children: [
                    Text(context.t.learnSub, style: k.body),
                    const SizedBox(height: 12),
                    _Progress(done: done.length, total: kLessons.length),
                    const SizedBox(height: 16),
                    for (var i = 0; i < kLessons.length; i++) ...[
                      _LessonTile(
                        number: i + 1,
                        lesson: kLessons[i],
                        finished: done.contains(kLessons[i].id),
                        isNext: next?.id == kLessons[i].id,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 6,
            backgroundColor: k.line,
            color: k.accent,
          ),
        ),
        const SizedBox(height: 6),
        Text(context.t.lessonCount(done, total), style: k.caption),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.number,
    required this.lesson,
    required this.finished,
    required this.isNext,
  });

  final int number;
  final Lesson lesson;
  final bool finished;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final title = lesson.title(t);
    return Semantics(
      button: true,
      label: '$title, ${t.lessonTasks(lesson.tasks.length)}',
      excludeSemantics: true,
      child: Pressable(
        onTap: () => context.push('/lesson/${lesson.id}'),
        haptic: true,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isNext ? k.accent.withValues(alpha: 0.1) : k.surface,
            borderRadius: BorderRadius.circular(KustSpace.rMedium),
            border: Border.all(
              color: isNext ? k.accent : k.line,
              width: isNext ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: finished
                      ? k.success.withValues(alpha: 0.18)
                      : k.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: finished
                    ? Icon(Icons.check_rounded, color: k.success)
                    : Text(
                        '$number',
                        style: k.body.copyWith(fontWeight: FontWeight.w800),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNext)
                      Text(
                        t.learnNext.toUpperCase(),
                        style: k.caption.copyWith(
                          color: k.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    Text(
                      title,
                      style: k.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(t.lessonTasks(lesson.tasks.length), style: k.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: k.muted),
            ],
          ),
        ),
      ),
    );
  }
}
