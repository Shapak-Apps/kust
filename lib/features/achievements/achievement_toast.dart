import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/features/game/chess/sound_service.dart';
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
  /// Everything that plays once: medal, rays fading in, text, confetti.
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  /// The rays keep turning while it is open.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  /// Fading the whole thing out.
  late final AnimationController _out = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _show.forward();
    _spin.repeat();
    SoundService.instance.playJingle('game-win.wav');
    SoundService.instance.buzz(heavy: true);
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      SoundService.instance.buzzMedium();
    });
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
    _spin.dispose();
    _out.dispose();
    super.dispose();
  }

  Animation<double> _interval(
    double begin,
    double end, [
    Curve c = Curves.easeOut,
  ]) => CurvedAnimation(
    parent: _show,
    curve: Interval(begin, end, curve: c),
  );

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final a = widget.achievement;

    final backdrop = _interval(0, 0.1);
    final medal = _interval(0.02, 0.24, Curves.elasticOut);
    final rays = _interval(0.08, 0.3);
    final shine = _interval(0.26, 0.42, Curves.easeInOut);
    final eyebrow = _interval(0.16, 0.3);
    final title = _interval(0.2, 0.34);
    final rest = _interval(0.25, 0.4);

    Widget slideIn(Animation<double> t, Widget child) => AnimatedBuilder(
      animation: t,
      child: child,
      builder: (context, child) => Opacity(
        opacity: t.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t.value)),
          child: child,
        ),
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
                opacity: backdrop,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.25),
                      radius: 1.1,
                      colors: [Color(0xE6151A22), Color(0xF707090C)],
                    ),
                  ),
                ),
              ),
              // Behind the medal and the words: it bursts from the medal
              // but never covers what was earned.
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
                        ),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (!reduceMotion)
                              RepaintBoundary(
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([_spin, rays]),
                                  builder: (context, _) => CustomPaint(
                                    size: const Size.square(260),
                                    painter: _RaysPainter(
                                      turn: _spin.value,
                                      strength: rays.value,
                                    ),
                                  ),
                                ),
                              ),
                            RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([medal, shine]),
                                child: _Medal(icon: a.icon),
                                builder: (context, child) => Transform.scale(
                                  scale: reduceMotion
                                      ? 1
                                      : medal.value.clamp(0.0, 1.3),
                                  child: Transform.rotate(
                                    angle: reduceMotion
                                        ? 0
                                        : (1 - medal.value) * -0.35,
                                    child: CustomPaint(
                                      foregroundPainter: _ShinePainter(
                                        shine.value,
                                      ),
                                      child: child,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      slideIn(
                        eyebrow,
                        Text(
                          'ACHIEVEMENT UNLOCKED',
                          style: k.caption.copyWith(
                            color: const Color(0xFFF2C94C),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      slideIn(
                        title,
                        Text(
                          a.title,
                          textAlign: TextAlign.center,
                          style: k.display.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      slideIn(
                        rest,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              Text(
                                a.description,
                                textAlign: TextAlign.center,
                                style: k.body.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '${widget.earned} of ${widget.total} earned',
                                style: k.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _ContinueButton(onTap: _close),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Material(
      color: const Color(0xFFF2C94C),
      borderRadius: BorderRadius.circular(KustSpace.rLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(KustSpace.rLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          child: Text(
            'Awesome',
            style: k.body.copyWith(
              color: const Color(0xFF1B1405),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// A gold medal: a bevelled rim, a darker inner face and the achievement's
/// icon, with a soft glow under it.
class _Medal extends StatelessWidget {
  const _Medal({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1B8), Color(0xFFF2C94C), Color(0xFFB8860B)],
          stops: [0, 0.45, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2C94C).withValues(alpha: 0.55),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD4A017), Color(0xFF8C6508)],
          ),
          border: Border.all(color: const Color(0xFFFFE9A0), width: 2),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 54,
          color: const Color(0xFFFFF6D6),
          shadows: const [
            Shadow(
              color: Color(0x66000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

/// A band of light that sweeps once across the medal.
class _ShinePainter extends CustomPainter {
  _ShinePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    final x = -size.width + t * size.width * 3;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.35, 0.5, 0.65],
        ).createShader(Rect.fromLTWH(x, 0, size.width, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.t != t;
}

/// Soft golden rays turning slowly behind the medal.
class _RaysPainter extends CustomPainter {
  _RaysPainter({required this.turn, required this.strength});

  final double turn;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final centre = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawCircle(
      centre,
      radius * 0.75,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF2C94C).withValues(alpha: 0.35 * strength),
            const Color(0xFFF2C94C).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius * 0.75)),
    );
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(turn * 2 * math.pi);
    const count = 12;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE08A).withValues(alpha: 0.45 * strength),
          const Color(0xFFFFE08A).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    for (var i = 0; i < count; i++) {
      final a = i * 2 * math.pi / count;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(radius * math.cos(a - 0.09), radius * math.sin(a - 0.09))
        ..lineTo(radius * math.cos(a + 0.09), radius * math.sin(a + 0.09))
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RaysPainter old) =>
      old.turn != turn || old.strength != strength;
}

/// Confetti bursting from just above the middle of the screen and falling.
/// Every piece's place is worked out from the time alone (no state kept
/// from frame to frame), so a frame costs a few hundred small rectangles.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({required this.progress, required this.seed})
    : _pieces = _piecesFor(seed);

  /// 0..1 over the celebration.
  final double progress;
  final int seed;
  final List<_Piece> _pieces;

  static const int count = 140;
  static const List<Color> _colours = [
    Color(0xFFF2C94C),
    Color(0xFFFFE08A),
    Color(0xFF1BADA6),
    Color(0xFFFA412D),
    Color(0xFF5C8BB0),
    Color(0xFF81B64C),
    Color(0xFFFFFFFF),
  ];

  static final Map<int, List<_Piece>> _cache = {};

  static List<_Piece> _piecesFor(int seed) => _cache.putIfAbsent(seed, () {
    final r = math.Random(seed);
    return List.generate(count, (i) {
      final angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.5;
      final speed = 0.55 + r.nextDouble() * 0.75;
      return _Piece(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed * 1.2,
        colour: _colours[r.nextInt(_colours.length)],
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
    final origin = Offset(size.width / 2, size.height * 0.36);
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
      paint.color = p.colour.withValues(alpha: fade);
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
  final Color colour;
  final double width;
  final double height;
  final double spin;
  final double flip;
  final double sway;
  final double delay;
  final bool round;
}
