import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/board_thumbnail.dart';

/// The Learn tab, laid out like the contents of a chess book: the next
/// lesson up top with a diagram of one of its positions and a Start
/// button, then every lesson by chapter.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    LearnProgress.instance.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  void _open(Lesson lesson) {
    final done = LearnProgress.instance.done.value;
    final index = kLessons.indexOf(lesson);
    final next = kLessons.indexWhere((l) => !done.contains(l.id));
    if (next >= 0 && index > next) {
      _showLocked(next);
      return;
    }
    context.push('/lesson/${lesson.id}');
  }

  /// A lesson ahead of the one you are on: say so, and offer the next one.
  void _showLocked(int next) {
    showKustSheet<bool>(
      context,
      builder: (sheet) {
        final t = sheet.t;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KustSheetHeader(
                title: t.lessonLocked(next + 1),
                subtitle: t.lessonLockedHint,
              ),
              KustButton3D(
                label: t.lessonLockedOpen(next + 1),
                expand: true,
                onTap: () => Navigator.of(sheet).pop(true),
              ),
            ],
          ),
        );
      },
    ).then((open) {
      if (open == true && mounted) context.push('/lesson/${kLessons[next].id}');
    });
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
                ? const SizedBox.expand()
                : ValueListenableBuilder<Set<String>>(
                    valueListenable: LearnProgress.instance.done,
                    builder: (context, done, _) => _contents(context, done),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _contents(BuildContext context, Set<String> done) {
    final k = context.k;
    final t = context.t;
    final progress = LearnProgress.instance;
    final next = kLessons.indexWhere((l) => !done.contains(l.id));
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, KustNavBar.clearance(context)),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(t.learnSub, style: k.body.copyWith(color: k.muted)),
            ),
            const SizedBox(width: 12),
            Icon(Icons.star_rounded, size: 18, color: k.accent),
            const SizedBox(width: 4),
            Text(
              '${progress.totalStars} / ${kLessons.length * 3}',
              style: k.body.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (next >= 0)
          _NextLesson(index: next, onStart: () => _open(kLessons[next]))
        else
          const _AllDone(),
        for (final camp in kCamps) ...[
          const SizedBox(height: 32),
          _Chapter(camp: camp, done: done),
          for (var i = camp.first; i <= camp.last; i++)
            _LessonRow(
              index: i,
              stars: progress.starsOf(kLessons[i].id),
              isNext: i == next,
              locked: next >= 0 && i > next,
              onTap: () => _open(kLessons[i]),
            ),
        ],
      ],
    );
  }
}

/// The position a lesson is pictured by: its busiest one, with the squares
/// it asks about marked.
({Position position, List<Square> marked}) _cover(Lesson lesson) {
  var best = lesson.tasks.first;
  var most = 0;
  for (final task in lesson.tasks) {
    final pieces = task.fen
        .split(' ')
        .first
        .replaceAll(RegExp('[^a-zA-Z]'), '')
        .length;
    if (pieces > most) {
      most = pieces;
      best = task;
    }
  }
  return (
    position: Chess.fromSetup(Setup.parseFen(best.fen)),
    marked: best.targets.toList(),
  );
}

/// The lesson to do now: its diagram, number, name, what it is about, and
/// a Start button.
class _NextLesson extends StatelessWidget {
  const _NextLesson({required this.index, required this.onStart});

  final int index;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final lesson = kLessons[index];
    final cover = _cover(lesson);
    // The whole card starts the lesson, not only its button.
    return Pressable(
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(KustSpace.rLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: BoardThumbnail(
                    position: cover.position,
                    highlight: cover.marked,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.lessonNumber(index + 1)} · '
                        '${Camp.of(index).title(t)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: k.caption.copyWith(color: k.accent),
                      ),
                      const SizedBox(height: 2),
                      Text(lesson.title(t), style: k.title),
                      const SizedBox(height: 6),
                      Text(
                        lesson.intro(t),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: k.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            KustButton3D(
              label: t.lessonStart,
              icon: Icons.play_arrow_rounded,
              expand: true,
              onTap: onStart,
            ),
          ],
        ),
      ),
    );
  }
}

/// In place of the next lesson once every lesson is done: a line and a
/// Play button under it, with no card around them.
class _AllDone extends StatelessWidget {
  const _AllDone();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.learnSummitDone, style: k.title),
        const SizedBox(height: 12),
        KustButton3D(
          label: t.play,
          icon: Icons.play_arrow_rounded,
          expand: true,
          onTap: () => context.go('/play'),
        ),
      ],
    );
  }
}

/// A chapter heading: its name, how many lessons are done, and what it
/// teaches, over a hairline.
class _Chapter extends StatelessWidget {
  const _Chapter({required this.camp, required this.done});

  final Camp camp;
  final Set<String> done;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final count = [
      for (var i = camp.first; i <= camp.last; i++)
        if (done.contains(kLessons[i].id)) i,
    ].length;
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: k.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(camp.title(t), style: k.title)),
              Text(
                '$count/${camp.length}',
                style: k.caption.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Text(camp.subtitle(t), style: k.caption),
        ],
      ),
    );
  }
}

/// One line of the contents: the lesson's number written like a move
/// ("4."), its name, and its stars once done.
class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.index,
    required this.stars,
    required this.isNext,
    required this.locked,
    required this.onTap,
  });

  final int index;
  final int stars;
  final bool isNext;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final lesson = kLessons[index];
    return Semantics(
      button: true,
      label: '${t.lessonLabel(index + 1)}, ${lesson.title(t)}',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${index + 1}.',
                  style: k.body.copyWith(
                    color: isNext ? k.accent : k.muted,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  lesson.title(t),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: k.body.copyWith(
                    fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                    color: locked ? k.muted : k.ink,
                  ),
                ),
              ),
              if (stars > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var s = 1; s <= 3; s++)
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: s <= stars ? k.accent : k.line,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
