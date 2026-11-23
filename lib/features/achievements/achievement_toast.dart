import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/features/achievements/achievements_screen.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

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
          // The host sits above the app's pages, outside any Material, so
          // the celebration brings its own: without it text falls back to
          // the debug style (yellow underlines, a plain font).
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: AchievementCelebration(
                key: ValueKey(_shownKey),
                achievement: shown,
                earned: _store.unlocked().length,
                total: kAchievements.length,
                onDone: _next,
              ),
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
    final medal = _interval(0.05, 0.26, Curves.easeOutBack);
    final ring = _interval(0.12, 0.62);
    final text = _interval(0.18, 0.36);
    final tier = a.tier;
    final glow = tier.color;

    // The card: the badge itself, as it looks on the profile, standing in
    // its tier's light; a ring of that colour spreading out once; the tier,
    // the name, what it was for, and how many are earned.
    final card = Container(
      width: 304,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      decoration: BoxDecoration(
        color: k.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glow.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            Color.alphaBlend(glow.withValues(alpha: 0.16), k.surface),
            k.surface,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 168,
            child: AnimatedBuilder(
              animation: _show,
              builder: (context, _) {
                final r = reduceMotion ? 1.0 : ring.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft light behind the badge.
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            glow.withValues(
                              alpha: 0.38 * medal.value.clamp(0, 1),
                            ),
                            glow.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                    // The ring, once, wider and fainter as it goes.
                    if (!reduceMotion && r > 0 && r < 1)
                      Container(
                        width: 100 + 70 * r,
                        height: 100 + 70 * r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: glow.withValues(alpha: 0.6 * (1 - r)),
                            width: 2,
                          ),
                        ),
                      ),
                    Transform.scale(
                      scale: reduceMotion ? 1 : medal.value,
                      child: AchievementIcon(
                        achievement: a,
                        earned: true,
                        size: 96,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          FadeTransition(
            opacity: reduceMotion ? kAlwaysCompleteAnimation : text,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(text),
              child: Column(
                children: [
                  Text(
                    context.t.achUnlocked,
                    style: k.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.titleIn(context.t),
                    textAlign: TextAlign.center,
                    style: k.title.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.descriptionIn(context.t),
                    textAlign: TextAlign.center,
                    style: k.body.copyWith(color: k.muted),
                  ),
                  const SizedBox(height: 14),
                  // The tier in its colour, and how many are earned.
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: glow.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tier.labelIn(context.t).toUpperCase(),
                          style: k.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: glow,
                          ),
                        ),
                      ),
                      Text(
                        context.t.achEarnedOf(widget.earned, widget.total),
                        style: k.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: KustButton(label: context.t.cont, onTap: _close),
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
          label:
              '${context.t.achUnlocked}: ${a.titleIn(context.t)}. ${a.descriptionIn(context.t)}',
          excludeSemantics: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: enter,
                child: const ColoredBox(color: Color(0xCC000000)),
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
                          colours: [glow, Colors.white],
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
