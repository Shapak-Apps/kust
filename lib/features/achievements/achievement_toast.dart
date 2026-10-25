import 'dart:async';

import 'package:flutter/material.dart';

import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/ui/tokens.dart';

/// Shows a banner at the top of any screen when an achievement unlocks.
class AchievementToastHost extends StatefulWidget {
  const AchievementToastHost({super.key, required this.child});

  final Widget child;

  @override
  State<AchievementToastHost> createState() => _AchievementToastHostState();
}

class _AchievementToastHostState extends State<AchievementToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  Achievement? _shown;
  Timer? _hide;

  ValueNotifier<Achievement?> get _source =>
      AchievementStore.instance.justUnlocked;

  @override
  void initState() {
    super.initState();
    _source.addListener(_onUnlock);
  }

  @override
  void dispose() {
    _source.removeListener(_onUnlock);
    _hide?.cancel();
    _slide.dispose();
    super.dispose();
  }

  void _onUnlock() {
    final next = _source.value;
    if (next == null || !mounted) return;
    _source.value = null;
    SoundService.instance.buzzMedium();
    setState(() => _shown = next);
    _slide.forward(from: 0);
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) _slide.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return Stack(
      children: [
        widget.child,
        if (shown != null)
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.paddingOf(context).top + 8,
            child: IgnorePointer(
              child: SlideTransition(
                position: Tween(begin: const Offset(0, -1.6), end: Offset.zero)
                    .animate(
                      CurvedAnimation(
                        parent: _slide,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                child: FadeTransition(
                  opacity: _slide,
                  child: AchievementBanner(achievement: shown),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AchievementBanner extends StatelessWidget {
  const AchievementBanner({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      liveRegion: true,
      label: 'Achievement unlocked: ${achievement.title}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
          decoration: BoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(KustSpace.rMedium),
            border: Border.all(color: k.accent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: k.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(achievement.icon, color: k.accentInk, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Achievement unlocked',
                      style: k.caption.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      achievement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
