import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/board_theme.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// The Learn tab: the lessons in order, from the first pawn move to
/// checkmate, grouped by camp. Each lesson is a square of the player's board
/// with its piece standing on it; the squares run down the page like a file
/// of the board, joined by a line. The next lesson is marked in gold with
/// its Start button.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _nextKey = GlobalKey();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    LearnProgress.instance.load().then((_) {
      if (!mounted) return;
      setState(() => _loaded = true);
      // Start with the next lesson in view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _nextKey.currentContext;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(
            target,
            alignment: 0.4,
            // Only when it is off screen: the top stays put otherwise.
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
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
    final t = context.t;
    return ColoredBox(
      color: k.bg,
      child: Column(
        children: [
          FeltHeader(title: t.learnTitle),
          Expanded(
            child: !_loaded
                ? const SizedBox.expand()
                : ValueListenableBuilder<Set<String>>(
                    valueListenable: LearnProgress.instance.done,
                    builder: (context, done, _) => ValueListenableBuilder(
                      valueListenable: AppSettings.instance.boardTheme,
                      builder: (context, board, _) =>
                          _list(context, done, board),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, Set<String> done, BoardTheme board) {
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
            Icon(Icons.star_rounded, size: 20, color: k.accent),
            const SizedBox(width: 4),
            Text(
              '${progress.totalStars} / ${kLessons.length * 3}',
              style: k.body.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        for (final camp in kCamps) ...[
          const SizedBox(height: 24),
          _CampTitle(camp: camp, done: done),
          const SizedBox(height: 12),
          for (var i = camp.first; i <= camp.last; i++)
            _LessonRow(
              key: i == next ? _nextKey : null,
              index: i,
              board: board,
              state: done.contains(kLessons[i].id)
                  ? _LessonState.done
                  : i == next
                  ? _LessonState.next
                  : _LessonState.locked,
              stars: progress.starsOf(kLessons[i].id),
              // The line runs on to the next square, within the camp.
              lineBelow: i < camp.last,
              lineAbove: i > camp.first,
              onTap: () => _open(kLessons[i]),
            ),
        ],
        if (next < 0) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: k.surface,
              borderRadius: BorderRadius.circular(KustSpace.rMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: k.accent, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.learnSummitDone,
                    style: k.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                KustButton(
                  label: t.play,
                  expand: false,
                  height: 40,
                  onTap: () => context.go('/play'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// "CAMP 1 · 2/6", the camp's name and what it teaches.
class _CampTitle extends StatelessWidget {
  const _CampTitle({required this.camp, required this.done});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              camp.label(t),
              style: k.caption.copyWith(
                color: k.accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '$count/${camp.length}',
              style: k.caption.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(camp.title(t), style: k.title),
        Text(camp.subtitle(t), style: k.caption),
      ],
    );
  }
}

enum _LessonState { done, next, locked }

/// One lesson: its square on the board's file, and its number and name;
/// stars once done, a Start button when it is next, a lock after that.
class _LessonRow extends StatelessWidget {
  const _LessonRow({
    super.key,
    required this.index,
    required this.board,
    required this.state,
    required this.stars,
    required this.lineAbove,
    required this.lineBelow,
    required this.onTap,
  });

  final int index;
  final BoardTheme board;
  final _LessonState state;
  final int stars;
  final bool lineAbove;
  final bool lineBelow;
  final VoidCallback onTap;

  static const double _square = 56;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final lesson = kLessons[index];
    final next = state == _LessonState.next;
    final locked = state == _LessonState.locked;
    final light = index.isEven;

    final square = Container(
      width: _square,
      height: _square,
      decoration: BoxDecoration(
        color: locked
            ? k.surfaceAlt
            : light
            ? board.light
            : board.dark,
        borderRadius: BorderRadius.circular(8),
        border: next ? Border.all(color: k.accent, width: 3) : null,
      ),
      alignment: Alignment.center,
      child: Opacity(
        opacity: locked ? 0.35 : 1,
        child: lesson.piece != null
            ? LearnPiece(lesson.piece!, height: _square * 0.78)
            : Icon(
                lesson.icon,
                size: _square * 0.48,
                color: locked
                    ? k.muted
                    : light
                    ? board.dark
                    : board.light,
              ),
      ),
    );

    // The line through the squares: the walk done so far in green.
    Widget line(bool visible, bool lit) => Container(
      width: 3,
      height: _gap / 2,
      color: !visible
          ? Colors.transparent
          : lit
          ? k.success
          : k.line,
    );

    return Semantics(
      button: true,
      label: '${t.lessonLabel(index + 1)}, ${lesson.title(t)}',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
          decoration: BoxDecoration(
            color: next ? k.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(KustSpace.rMedium),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  line(lineAbove, state != _LessonState.locked),
                  square,
                  line(lineBelow, state == _LessonState.done),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.lessonLabel(index + 1),
                      style: k.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: next ? k.accent : k.muted,
                      ),
                    ),
                    Text(
                      lesson.title(t),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: k.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: locked ? k.muted : k.ink,
                      ),
                    ),
                    if (next)
                      Text(
                        t.lessonMinutes(
                          lesson.tasks.length,
                          (lesson.tasks.length * 0.7).ceil(),
                        ),
                        style: k.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              switch (state) {
                _LessonState.done => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var s = 1; s <= 3; s++)
                      Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: s <= stars ? k.accent : k.line,
                      ),
                  ],
                ),
                _LessonState.next => KustButton3D(
                  label: t.lessonStart.split(' ').first,
                  height: 40,
                  onTap: onTap,
                ),
                _LessonState.locked => Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: k.muted,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
