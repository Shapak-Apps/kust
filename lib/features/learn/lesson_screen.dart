import 'dart:async';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/game/chess/chess_helpers.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/features/learn/lesson_task.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/piece_image.dart';

/// One lesson: an introduction, then its tasks one after the other.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final Lesson? _lesson = kLessons
      .where((l) => l.id == widget.lessonId)
      .firstOrNull;

  /// -1 is the introduction, 0.. the tasks, and the number of tasks the end.
  int _step = -1;
  TaskRunner? _runner;
  NormalMove? _lastMove;

  /// The position before [_lastMove], to find where it landed.
  Position? _beforeLast;
  ({Square from, Square to})? _slide;
  int _slideKey = 0;
  Square? _hintFrom;
  Square? _hintTo;

  /// What the board says after a move that was not right, or null.
  String? _message;
  bool _solved = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start(int step) {
    final lesson = _lesson!;
    _timer?.cancel();
    setState(() {
      _step = step;
      _message = null;
      _solved = false;
      _lastMove = null;
      _beforeLast = null;
      _slide = null;
      _hintFrom = _hintTo = null;
      _runner = step >= 0 && step < lesson.tasks.length
          ? TaskRunner(lesson.tasks[step])
          : null;
    });
    if (step >= lesson.tasks.length) {
      LearnProgress.instance.complete(lesson.id);
      SoundService.instance.playJingle('game-win.wav');
      SoundService.instance.buzzMedium();
    }
  }

  void _onMove(NormalMove move) {
    final runner = _runner;
    if (runner == null || _solved) return;
    final before = runner.position;
    final step = runner.apply(move);
    switch (step) {
      case TaskStep.wrong:
      case TaskStep.stalemate:
        SoundService.instance.playSfx('illegal.wav');
        SoundService.instance.buzz(heavy: true);
        setState(
          () => _message = step == TaskStep.stalemate
              ? context.t.learnStalemate
              : context.t.learnWrong,
        );
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 2400), () {
          if (mounted) setState(() => _message = null);
        });
      case TaskStep.progress:
      case TaskStep.done:
        final capture = before.board.pieceAt(move.to) != null;
        SoundService.instance.playSfx(capture ? 'capture.wav' : 'move.wav');
        setState(() {
          _message = null;
          _hintFrom = _hintTo = null;
          _lastMove = move;
          _beforeLast = before;
          _slide = (from: move.from, to: TaskRunner.landing(move, before));
          _slideKey++;
          _solved = step == TaskStep.done;
        });
        if (step == TaskStep.done) {
          SoundService.instance.buzzMedium();
          _timer?.cancel();
          _timer = Timer(const Duration(milliseconds: 1100), () {
            if (mounted) _start(_step + 1);
          });
        }
    }
  }

  void _hint() {
    final move = _runner?.hint();
    if (move == null) return;
    setState(() {
      _hintFrom = move.from;
      _hintTo = move.to;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _hintFrom = _hintTo = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final lesson = _lesson;
    final t = context.t;
    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          KustTopBar(
            title: lesson?.title(t) ?? t.learnTitle,
            leading: KustIconButton(
              icon: Icons.arrow_back_rounded,
              label: t.back,
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/learn'),
            ),
          ),
          Expanded(
            child: lesson == null
                ? const SizedBox.shrink()
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _step < 0
                          ? _Intro(lesson: lesson, onStart: () => _start(0))
                          : _step >= lesson.tasks.length
                          ? _Complete(lesson: lesson)
                          : _taskView(context, lesson),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _taskView(BuildContext context, Lesson lesson) {
    final k = context.k;
    final t = context.t;
    final runner = _runner!;
    final task = runner.task;
    return LayoutBuilder(
      builder: (context, box) {
        const chrome = 150.0; // prompt, progress and the hint row
        final side = math.min(box.maxWidth, box.maxHeight - chrome);
        final landed = _lastMove == null
            ? null
            : TaskRunner.landing(_lastMove!, _beforeLast ?? runner.position);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _StepBar(count: lesson.tasks.length, at: _step),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.taskProgress(_step + 1, lesson.tasks.length),
                        style: k.caption,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          taskPrompt(t, task),
                          textAlign: TextAlign.center,
                          style: k.title,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: side,
                        height: side,
                        child: Stack(
                          children: [
                            PuzzleBoard(
                              position: runner.position,
                              flipped: false,
                              interactive: !_solved,
                              onMove: _onMove,
                              lastMove: _lastMove,
                              hintFrom: _hintFrom,
                              hintTo: _hintTo,
                              slide: _slide,
                              slideKey: _slideKey,
                            ),
                            IgnorePointer(
                              child: _Marks(
                                squares: runner.remaining,
                                starred: task.starred,
                              ),
                            ),
                            if (_solved && landed != null)
                              IgnorePointer(child: _DoneBadge(square: landed)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 24,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: _solved
                              ? Text(
                                  t.learnWellDone,
                                  key: const ValueKey('ok'),
                                  style: k.body.copyWith(
                                    color: k.success,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : Text(
                                  _message ?? '',
                                  key: ValueKey(_message),
                                  style: k.body.copyWith(color: k.danger),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      KustButton(
                        label: t.learnHint,
                        icon: Icons.lightbulb_outline_rounded,
                        style: KustButtonStyle.outline,
                        expand: false,
                        onTap: _solved ? null : _hint,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

/// A green tick on the corner of the square the task was finished on.
class _DoneBadge extends StatelessWidget {
  const _DoneBadge({required this.square});

  final Square square;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cell = box.maxWidth / 8;
        return Stack(
          children: [
            Positioned(
              left: square.file.value * cell + cell * 0.52,
              top: (7 - square.rank.value) * cell - cell * 0.08,
              width: cell * 0.56,
              height: cell * 0.56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.k.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: cell * 0.4,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The squares still to reach (stars) or to capture (rings).
class _Marks extends StatelessWidget {
  const _Marks({required this.squares, required this.starred});

  final Set<Square> squares;
  final bool starred;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cell = box.maxWidth / 8;
        return Stack(
          children: [
            for (final sq in squares)
              Positioned(
                left: sq.file.value * cell,
                top: (7 - sq.rank.value) * cell,
                width: cell,
                height: cell,
                child: starred
                    ? Icon(
                        Icons.star_rounded,
                        size: cell * 0.78,
                        color: const Color(0xFFFFC21A),
                        shadows: const [
                          Shadow(color: Color(0x66000000), blurRadius: 4),
                        ],
                      )
                    : Container(
                        margin: EdgeInsets.all(cell * 0.06),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE5484D),
                            width: 3,
                          ),
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.count, required this.at});

  final int count;
  final int at;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6,
              decoration: BoxDecoration(
                color: i < at
                    ? k.success
                    : i == at
                    ? k.accent
                    : k.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.lesson, required this.onStart});

  final Lesson lesson;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final piece = lesson.piece;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: k.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: piece == null
                    ? Icon(lesson.icon, size: 52, color: k.accent)
                    : PieceImage(
                        assetForPiece(Piece(color: Side.white, role: piece)),
                        width: 76,
                        height: 76,
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lesson.title(t),
              textAlign: TextAlign.center,
              style: k.display,
            ),
            const SizedBox(height: 12),
            Text(
              lesson.intro(t),
              textAlign: TextAlign.center,
              style: k.body.copyWith(height: 1.5, color: k.muted),
            ),
            const SizedBox(height: 28),
            KustButton(label: t.lessonStart, onTap: onStart),
          ],
        ),
      ),
    );
  }
}

class _Complete extends StatelessWidget {
  const _Complete({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final next = LearnProgress.instance.after(lesson.id);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, size: 72, color: k.accent),
            const SizedBox(height: 16),
            Text(t.lessonDone, textAlign: TextAlign.center, style: k.display),
            if (next == null) ...[
              const SizedBox(height: 8),
              Text(
                t.learnAllDone,
                textAlign: TextAlign.center,
                style: k.body.copyWith(color: k.muted),
              ),
            ],
            const SizedBox(height: 28),
            if (next != null)
              KustButton(
                label: t.lessonNext,
                onTap: () => context.pushReplacement('/lesson/${next.id}'),
              )
            else
              KustButton(
                label: t.lessonPlayGame,
                onTap: () => context.go('/play'),
              ),
            const SizedBox(height: 10),
            KustButton(
              label: t.lessonAll,
              style: KustButtonStyle.outline,
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/learn'),
            ),
          ],
        ),
      ),
    );
  }
}
