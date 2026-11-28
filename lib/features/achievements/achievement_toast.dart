import 'dart:async';

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
    final t = context.t;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final a = widget.achievement;
    final enter = _interval(0, 0.12);

    // A plain card: the badge, what was earned, and its tier and count in
    // one quiet line. No glow, rings or confetti.
    final card = Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: squircle(20, color: k.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AchievementIcon(achievement: a, earned: true, size: 80),
          const SizedBox(height: 18),
          Text(
            t.achUnlocked,
            style: k.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            a.titleIn(t),
            textAlign: TextAlign.center,
            style: k.title.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            a.descriptionIn(t),
            textAlign: TextAlign.center,
            style: k.body.copyWith(color: k.muted),
          ),
          const SizedBox(height: 12),
          Text(
            '${a.tier.labelIn(t)} · ${t.achEarnedOf(widget.earned, widget.total)}',
            textAlign: TextAlign.center,
            style: k.caption.copyWith(
              color: a.tier.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: KustButton(label: t.cont, onTap: _close),
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
          label: '${t.achUnlocked}: ${a.titleIn(t)}. ${a.descriptionIn(t)}',
          excludeSemantics: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: enter,
                child: const ColoredBox(color: Color(0xB3000000)),
              ),
              Center(
                child: FadeTransition(
                  opacity: enter,
                  child: ScaleTransition(
                    scale: reduceMotion
                        ? kAlwaysCompleteAnimation
                        : Tween(begin: 0.96, end: 1.0).animate(enter),
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
