import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/tokens.dart';

/// Celebrates each achievement as it unlocks, over any screen: the screen
/// dims, a gold medal pops in with turning rays behind it, confetti bursts
/// and falls, and the title follows. A tap or a few seconds closes it;
/// several unlocks play one after another.
class AchievementToastHost extends StatefulWidget {
  const AchievementToastHost({super.key, required this.child});

  final Widget child;

  @override
  State<AchievementToastHost> createState() => _AchievementToastHostState();
}

class _AchievementToastHostState extends State<AchievementToastHost> {
  final List<Achievement> _queue = [];
  Achievement? _shown;
  int _shownKey = 0;

  AchievementStore get _store => AchievementStore.instance;

  @override
  void initState() {
    super.initState();
    _store.justUnlocked.addListener(_onUnlock);
  }

  @override
  void dispose() {
    _store.justUnlocked.removeListener(_onUnlock);
    super.dispose();
  }

  void _onUnlock() {
    if (_store.justUnlocked.value == null || !mounted) return;
    _queue.addAll(_store.takeUnlocked());
    _store.justUnlocked.value = null;
    if (_shown == null) _next();
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      _shown = _queue.isEmpty ? null : _queue.removeAt(0);
      _shownKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return Stack(
      children: [
        widget.child,
        if (shown != null)
          Positioned.fill(
            child: AchievementCelebration(
              key: ValueKey(_shownKey),
              achievement: shown,
              earned: _store.unlocked().length,
              total: kAchievements.length,
              onDone: _next,
            ),
          ),
      ],
    );
  }
}

/// The celebration of one achievement. Calls [onDone] once it has faded
/// out, after a tap or [stay].
class AchievementCelebration extends StatefulWidget {
  const AchievementCelebration({
    super.key,
    required this.achievement,
    required this.earned,
    required this.total,
    required this.onDone,
    this.stay = const Duration(milliseconds: 4200),
  });

  final Achievement achievement;
  final int earned;
  final int total;
  final VoidCallback onDone;
  final Duration stay;

  @override
  State<AchievementCelebration> createState() => _AchievementCelebrationState();
}

class _AchievementCelebrationState extends State<AchievementCelebration>
    with TickerProviderStateMixin {
  /// The card coming in, the medal, the progress bar and the confetti.
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// Fading the whole thing out.
  late final AnimationController _out = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _show.forward();
    SoundService.instance.playJingle('game-win.wav');
    SoundService.instance.buzzMedium();
    _timer = Timer(widget.stay, _close);
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    _out.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _show.dispose();
    _out.dispose();
    super.dispose();
  }

  Animation<double> _interval(
    double begin,
    double end, [
    Curve c = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _show,
    curve: Interval(begin, end, curve: c),
  );

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final a = widget.achievement;

    final enter = _interval(0, 0.14);
    final medal = _interval(0.06, 0.24, Curves.easeOutBack);
    final bar = _interval(0.22, 0.5);
    final before = ((widget.earned - 1) / widget.total).clamp(0.0, 1.0);
    final after = (widget.earned / widget.total).clamp(0.0, 1.0);

    final card = Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color: k.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: reduceMotion ? kAlwaysCompleteAnimation : medal,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: k.accent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(a.icon, size: 36, color: k.accentInk),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Achievement unlocked',
            style: k.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            a.title,
            textAlign: TextAlign.center,
            style: k.title.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            a.description,
            textAlign: TextAlign.center,
            style: k.body.copyWith(color: k.muted),
          ),
          const SizedBox(height: 20),
          // The reward: the count fills up to its new value.
          AnimatedBuilder(
            animation: bar,
            builder: (context, _) {
              final v = reduceMotion
                  ? after
                  : before + (after - before) * bar.value;
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: k.line,
                      color: k.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.earned} of ${widget.total} earned',
                    style: k.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: KustButton(label: 'Continue', onTap: _close),
          ),
        ],
      ),
    );

    return FadeTransition(
      opacity: ReverseAnimation(_out),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: Semantics(
          liveRegion: true,
          label: 'Achievement unlocked: ${a.title}. ${a.description}',
          excludeSemantics: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: enter,
                child: const ColoredBox(color: Color(0x99000000)),
              ),
              if (!reduceMotion)
                IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _show,
                      builder: (context, _) => CustomPaint(
                        size: Size.infinite,
                        painter: ConfettiPainter(
                          progress: _show.value,
                          seed: a.id.hashCode,
                          colours: [k.accent, Colors.white],
                        ),
                      ),
                    ),
                  ),
                ),
              Center(
                child: FadeTransition(
                  opacity: enter,
                  child: ScaleTransition(
                    scale: reduceMotion
                        ? kAlwaysCompleteAnimation
                        : Tween(begin: 0.94, end: 1.0).animate(enter),
                    child: card,
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

/// Confetti bursting from just above the middle of the screen and falling.
/// Every piece's place is worked out from the time alone (no state kept
/// from frame to frame), so a frame costs a few hundred small rectangles.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({
    required this.progress,
    required this.seed,
    this.colours = const [Color(0xFFF2C94C), Color(0xFFFFFFFF)],
  }) : _pieces = _piecesFor(seed);

  /// 0..1 over the celebration.
  final double progress;
  final int seed;

  /// The pieces come in these colours, in turn.
  final List<Color> colours;
  final List<_Piece> _pieces;

  /// Few pieces: a small burst, not a storm.
  static const int count = 44;

  static final Map<int, List<_Piece>> _cache = {};

  static List<_Piece> _piecesFor(int seed) => _cache.putIfAbsent(seed, () {
    final r = math.Random(seed);
    return List.generate(count, (i) {
      final angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.5;
      final speed = 0.55 + r.nextDouble() * 0.75;
      return _Piece(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed * 1.2,
        colour: i,
        width: 6 + r.nextDouble() * 6,
        height: 9 + r.nextDouble() * 8,
        spin: (r.nextDouble() - 0.5) * 18,
        flip: 4 + r.nextDouble() * 10,
        sway: r.nextDouble() * math.pi * 2,
        delay: r.nextDouble() * 0.08,
        round: r.nextDouble() < 0.25,
      );
    });
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.42);
    final scale = size.shortestSide;
    final paint = Paint();
    for (final p in _pieces) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0) * 3.2;
      if (t <= 0) continue;
      // Thrown out fast, slowed by the air, then falling with a sway.
      final drag = (1 - math.exp(-2.6 * t)) / 2.6;
      final x = origin.dx + p.vx * drag * scale + math.sin(p.sway + t * 3) * 10;
      final y = origin.dy + p.vy * drag * scale + 0.16 * scale * t * t;
      if (y > size.height + 20) continue;
      final fade = (1 - (t - 2.4) / 0.8).clamp(0.0, 1.0);
      paint.color = colours[p.colour % colours.length].withValues(
        alpha: fade * 0.9,
      );
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      // Tumbling: the piece narrows and widens as it turns over.
      final w = p.width * math.cos(p.flip * t).abs().clamp(0.15, 1.0);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: w,
        height: p.height,
      );
      if (p.round) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRect(rect, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) =>
      old.progress != progress || old.seed != seed;
}

class _Piece {
  const _Piece({
    required this.vx,
    required this.vy,
    required this.colour,
    required this.width,
    required this.height,
    required this.spin,
    required this.flip,
    required this.sway,
    required this.delay,
    required this.round,
  });

  final double vx;
  final double vy;

  /// Which of the painter's colours.
  final int colour;
  final double width;
  final double height;
  final double spin;
  final double flip;
  final double sway;
  final double delay;
  final bool round;
}
