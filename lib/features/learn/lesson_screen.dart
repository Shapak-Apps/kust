import 'dart:async';
import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/features/learn/lesson_moments.dart';
import 'package:kust/features/learn/lesson_task.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/features/puzzles/speech_bubble.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/static_board.dart';
import 'package:kust/ui/kust_top_bar.dart' show kMinTap;
import 'package:kust/ui/motion.dart';

/// The guide who explains every lesson.
const String _coachImage = 'assets/bots/Bahar.webp';

/// One lesson: an introduction from the coach, the tasks one after the
/// other, and the stars at the end.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

/// What the coach says under the prompt after a move.
enum _Note { none, wrong, stalemate, done }

class _LessonScreenState extends State<LessonScreen> {
  late final Lesson? _lesson = kLessons
      .where((l) => l.id == widget.lessonId)
      .firstOrNull;

  int get _index => kLessons.indexWhere((l) => l.id == widget.lessonId);

  /// -1 is the introduction, 0.. the tasks, and the number of tasks the end.
  int _step = -1;
  TaskRunner? _runner;
  NormalMove? _lastMove;

  /// The position before [_lastMove], to find where it landed.
  Position? _beforeLast;
  ({Square from, Square to})? _slide;
  int _slideKey = 0;

  /// The lines of a tactic just played: what the fork hits, what the pin
  /// or the skewer runs through.
  List<({Square from, Square to, Color color})> _arrows = const [];
  Square? _hintFrom;
  Square? _hintTo;
  _Note _note = _Note.none;
  bool _solved = false;
  int _mistakes = 0;
  int _hints = 0;
  int _stars = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _go(int step) {
    final lesson = _lesson!;
    _timer?.cancel();
    setState(() {
      _step = step;
      _note = _Note.none;
      _solved = false;
      _lastMove = null;
      _slide = null;
      _arrows = const [];
      _hintFrom = _hintTo = null;
      _runner = step >= 0 && step < lesson.tasks.length
          ? TaskRunner(lesson.tasks[step])
          : null;
    });
    // A task that starts in check shows the check being given: the piece
    // slides in, the king's square turns red, and the check sounds.
    final runner = _runner;
    final arrival = runner == null ? null : checkArrival(runner.position);
    if (arrival != null) {
      setState(() {
        _lastMove = NormalMove(from: arrival.from, to: arrival.to);
        _slide = arrival;
        _slideKey++;
      });
      SoundService.instance.playSfx('check.wav');
      SoundService.instance.buzz(heavy: true);
    }
    if (step >= lesson.tasks.length) {
      _stars = LearnProgress.starsFor(mistakes: _mistakes, hints: _hints);
      LearnProgress.instance.complete(lesson.id, stars: _stars);
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
        _mistakes++;
        SoundService.instance.playSfx('illegal.wav');
        SoundService.instance.buzz(heavy: true);
        setState(
          () => _note = step == TaskStep.stalemate
              ? _Note.stalemate
              : _Note.wrong,
        );
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 2600), () {
          if (mounted) setState(() => _note = _Note.none);
        });
      case TaskStep.progress:
      case TaskStep.done:
        final capture = before.board.pieceAt(move.to) != null;
        final check = runner.position.isCheck;
        SoundService.instance.playSfx(
          check
              ? 'check.wav'
              : capture
              ? 'capture.wav'
              : 'move.wav',
        );
        if (step == TaskStep.done) {
          // A bright chime for every task done, not only the lesson.
          SoundService.instance.playSfx('correct.wav');
        }
        _timer?.cancel();
        setState(() {
          _note = step == TaskStep.done ? _Note.done : _Note.none;
          _hintFrom = _hintTo = null;
          _lastMove = move;
          _beforeLast = before;
          _slide = (from: move.from, to: TaskRunner.landing(move, before));
          _slideKey++;
          _solved = step == TaskStep.done;
          _arrows = step == TaskStep.done
              ? _tacticArrows(runner, TaskRunner.landing(move, before))
              : const [];
        });
        if (step == TaskStep.done) SoundService.instance.buzzMedium();
    }
  }

  /// Fork: gold arrows to what it hits. Pin and skewer: red arrows
  /// through the piece in front to the one behind.
  List<({Square from, Square to, Color color})> _tacticArrows(
    TaskRunner runner,
    Square at,
  ) {
    final kind = runner.task.kind;
    if (kind != TaskKind.fork &&
        kind != TaskKind.pin &&
        kind != TaskKind.skewer) {
      return const [];
    }
    final fork = kind == TaskKind.fork;
    return [
      for (final a in tacticArrows(runner.position, at, throughLine: !fork))
        (
          from: a.from,
          to: a.to,
          color: fork ? const Color(0xE6F5A524) : const Color(0xE6E5484D),
        ),
    ];
  }

  void _hint() {
    final move = _runner?.hint();
    if (move == null || _solved) return;
    _hints++;
    setState(() {
      _hintFrom = move.from;
      _hintTo = move.to;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _hintFrom = _hintTo = null);
    });
  }

  void _close() => context.canPop() ? context.pop() : context.go('/learn');

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    return Scaffold(
      backgroundColor: context.k.bg,
      body: SafeArea(
        child: lesson == null
            ? const SizedBox.shrink()
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(a),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _step < 0
                      ? _Intro(
                          lesson: lesson,
                          number: _index + 1,
                          onClose: _close,
                          onStart: () => _go(0),
                        )
                      : _step >= lesson.tasks.length
                      ? _Complete(
                          lesson: lesson,
                          stars: _stars,
                          mistakes: _mistakes,
                          hints: _hints,
                          onClose: _close,
                        )
                      : _taskView(context, lesson),
                ),
              ),
      ),
    );
  }

  Widget _taskView(BuildContext context, Lesson lesson) {
    final t = context.t;
    final runner = _runner!;
    final task = runner.task;
    final landed = _lastMove == null
        ? null
        : TaskRunner.landing(_lastMove!, _beforeLast!);
    final (note, noteColor) = switch (_note) {
      _Note.none => (null, null),
      _Note.wrong => (t.learnWrong, BubbleColors.bad),
      _Note.stalemate => (t.learnStalemate, BubbleColors.bad),
      _Note.done => (t.learnCoachDone, BubbleColors.good),
    };
    // The room for the Continue panel is kept all the time, and the panel
    // slides into it: nothing on the board moves when a task is done.
    return Stack(
      children: [
        Column(
          children: [
            _TopBar(
              count: lesson.tasks.length,
              at: _step,
              solved: _solved,
              onClose: _close,
              onHint: _solved ? null : _hint,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  // The coach and the board sit together in the middle of the
                  // room left between the top bar and the bottom.
                  const coach = _Coach.height + 14;
                  final side = math.min(box.maxWidth, box.maxHeight - coach);
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: _Coach(
                            title: taskPrompt(t, task),
                            note: note,
                            noteColor: noteColor,
                          ),
                        ),
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
                                arrows: _arrows,
                              ),
                              IgnorePointer(
                                child: _Marks(
                                  squares: runner.remaining,
                                  starred: task.starred,
                                ),
                              ),
                              if (_solved && landed != null)
                                IgnorePointer(
                                  child: _DoneBadge(square: landed),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: _panelRoom),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSlide(
            offset: _solved ? Offset.zero : const Offset(0, 1.1),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: _DonePanel(
              last: _step == lesson.tasks.length - 1,
              onContinue: _solved ? () => _go(_step + 1) : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.count,
    required this.at,
    required this.solved,
    required this.onClose,
    required this.onHint,
  });

  final int count;
  final int at;
  final bool solved;
  final VoidCallback onClose;
  final VoidCallback? onHint;

  @override
  Widget build(BuildContext context) {
    final done = at + (solved ? 1 : 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            tooltip: context.t.close,
            icon: Icon(Icons.close_rounded, color: context.k.muted),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: done / count),
                duration: motion(context, const Duration(milliseconds: 400)),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Stack(
                  children: [
                    Container(height: 14, color: context.k.surfaceAlt),
                    FractionallySizedBox(
                      widthFactor: v.clamp(0.02, 1.0),
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: context.k.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.fromLTRB(6, 3, 6, 0),
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: context.t.learnHint,
            child: Pressable(
              onTap: onHint,
              haptic: true,
              child: SizedBox.square(
                dimension: kMinTap,
                child: Center(
                  child: Opacity(
                    opacity: onHint == null ? 0.35 : 1,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.k.accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.k.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        Icons.lightbulb_rounded,
                        color: context.k.accent,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The coach with the task in a speech bubble, and a note under it after a
/// move: what went wrong, or that it is done.
/// Height kept free under the board for the Continue panel.
const double _panelRoom = 146;

class _Coach extends StatelessWidget {
  const _Coach({required this.title, this.note, this.noteColor});

  final String title;
  final String? note;
  final Color? noteColor;

  /// Always this tall, with room for three lines of task and a note, so
  /// the board below never moves when the words change.
  static const double height = 116;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              _coachImage,
              width: 84,
              height: 84,
              cacheWidth: 252,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SpeechBubble(
              child: SizedBox(
                height: height - 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: note == null ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: k.body.copyWith(
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: BubbleColors.ink,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: k.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: noteColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slides up when a task is done: a cheer and the Continue button.
class _DonePanel extends StatelessWidget {
  const _DonePanel({required this.last, required this.onContinue});

  final bool last;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: context.k.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.k.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                t.learnWellDone,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.k.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          KustButton3D(label: t.cont, expand: true, onTap: onContinue),
        ],
      ),
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
              // In the square's top right corner, inside the board.
              left: square.file.value * cell + cell * 0.5,
              top: (7 - square.rank.value) * cell + cell * 0.02,
              width: cell * 0.48,
              height: cell * 0.48,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: motion(context, const Duration(milliseconds: 380)),
                curve: Curves.easeOutBack,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
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
                        color: context.k.accent,
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

/// The lesson's piece standing in a soft glow, or its icon on a round badge.
class _Intro extends StatelessWidget {
  const _Intro({
    required this.lesson,
    required this.number,
    required this.onClose,
    required this.onStart,
  });

  final Lesson lesson;
  final int number;
  final VoidCallback onClose;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = context.k;
    final camp = Camp.of(number - 1);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: IconButton(
              onPressed: onClose,
              tooltip: t.close,
              icon: Icon(Icons.close_rounded, color: context.k.muted),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The first position of the lesson, the squares it asks
                  // about marked: what the lesson starts with.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: StaticBoard(
                      position: Chess.fromSetup(
                        Setup.parseFen(lesson.tasks.first.fen),
                      ),
                      highlight: lesson.tasks.first.targets.toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${t.lessonNumber(number)} · ${camp.title(t)}',
                    style: k.caption.copyWith(color: k.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.title(t),
                    textAlign: TextAlign.center,
                    style: k.display.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lesson.intro(t),
                    textAlign: TextAlign.center,
                    style: k.body.copyWith(height: 1.45, color: k.muted),
                  ),
                  const SizedBox(height: 16),
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: KustButton3D(
            label: t.lessonStart,
            expand: true,
            onTap: onStart,
          ),
        ),
      ],
    );
  }
}

class _Complete extends StatelessWidget {
  const _Complete({
    required this.lesson,
    required this.stars,
    required this.mistakes,
    required this.hints,
    required this.onClose,
  });

  final Lesson lesson;
  final int stars;
  final int mistakes;
  final int hints;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = context.k;
    final next = LearnProgress.instance.after(lesson.id);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 3; i++)
                        _PopStar(
                          on: i < stars,
                          delay: Duration(milliseconds: 250 + i * 220),
                          size: i == 1 ? 76 : 58,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    stars == 3 ? t.lessonPerfect : t.lessonDone,
                    textAlign: TextAlign.center,
                    style: k.display.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(lesson.title(t), style: k.body.copyWith(color: k.muted)),
                  if (next == null) ...[
                    const SizedBox(height: 10),
                    Text(
                      t.learnAllDone,
                      textAlign: TextAlign.center,
                      style: k.body.copyWith(color: context.k.success),
                    ),
                  ],
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      _Stat(
                        label: t.lessonTasksDone,
                        value: '${lesson.tasks.length}/${lesson.tasks.length}',
                        color: context.k.success,
                        icon: Icons.check_circle_rounded,
                      ),
                      const SizedBox(width: 10),
                      _Stat(
                        label: t.lessonMistakes,
                        value: '$mistakes',
                        // Red even with none: the colour names the thing,
                        // not the score.
                        color: context.k.danger,
                        icon: Icons.cancel_rounded,
                      ),
                      const SizedBox(width: 10),
                      _Stat(
                        label: t.lessonHintsUsed,
                        value: '$hints',
                        color: context.k.accent,
                        icon: Icons.lightbulb_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: KustButton3D(
            label: next == null ? t.lessonPlayGame : t.lessonNext,
            expand: true,
            onTap: () => next == null
                ? context.go('/play')
                : context.pushReplacement('/lesson/${next.id}'),
          ),
        ),
        TextButton(
          onPressed: onClose,
          child: Text(
            t.lessonBackToMap,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.k.muted,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

/// A star that pops in after [delay], gold when earned, grey when not.
class _PopStar extends StatefulWidget {
  const _PopStar({required this.on, required this.delay, required this.size});

  final bool on;
  final Duration delay;
  final double size;

  @override
  State<_PopStar> createState() => _PopStarState();
}

class _PopStarState extends State<_PopStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.delay, () {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
      if (widget.on) SoundService.instance.playSfx('move.wav');
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = Curves.elasticOut.transform(_c.value);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Transform.scale(
            scale: 0.2 + 0.8 * v,
            child: Opacity(
              opacity: _c.value.clamp(0.0, 1.0),
              child: Icon(
                Icons.star_rounded,
                size: widget.size,
                color: widget.on ? context.k.accent : context.k.line,
                shadows: widget.on
                    ? const [Shadow(color: Color(0x88FFBB00), blurRadius: 18)]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 6),
          Text(value, style: k.title.copyWith(fontWeight: FontWeight.w900)),
          Text(label, style: k.caption),
        ],
      ),
    );
  }
}
