import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

/// Every achievement, earned ones in colour, the rest greyed out.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          FeltHeader(
            title: context.t.achievements,
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/play'),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: AchievementStore.instance.listenable(),
              builder: (context, _, _) {
                final unlocked = AchievementStore.instance.unlocked();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Text(
                      context.t.achEarnedOf(
                        unlocked.length,
                        kAchievements.length,
                      ),
                      style: k.caption.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    for (final a in kAchievements) ...[
                      AchievementTile(
                        achievement: a,
                        earned: unlocked.containsKey(a.id),
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

class AchievementTile extends StatelessWidget {
  const AchievementTile({
    super.key,
    required this.achievement,
    required this.earned,
  });

  final Achievement achievement;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      label:
          '${achievement.titleIn(context.t)}, ${achievement.descriptionIn(context.t)}, '
          '${achievement.tier.labelIn(context.t)}, '
          '${earned ? context.t.achEarned : context.t.achNotEarned}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(KustSpace.rMedium),
          border: Border.all(
            color: earned
                ? achievement.tier.color.withValues(alpha: 0.6)
                : k.line,
          ),
        ),
        child: Row(
          children: [
            AchievementIcon(achievement: achievement, earned: earned, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.titleIn(context.t),
                    style: k.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: earned ? k.ink : k.muted,
                    ),
                  ),
                  Text(achievement.descriptionIn(context.t), style: k.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              achievement.tier.labelIn(context.t),
              style: k.caption.copyWith(
                color: achievement.tier.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An achievement's picture: its icon on a tile in its tier's colour (green
/// common, yellow rare, red mythic), raised on a darker lip once earned;
/// faded in the same colour, with a small lock, until then.
class AchievementIcon extends StatelessWidget {
  const AchievementIcon({
    super.key,
    required this.achievement,
    required this.earned,
    this.size = 72,
  });

  final Achievement achievement;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final c = achievement.tier.color;
    final radius = BorderRadius.circular(size * 0.28);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: earned
              ? BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(c, Colors.white, 0.22)!, c],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(c, Colors.black, 0.4)!,
                      offset: Offset(0, size * 0.06),
                    ),
                  ],
                )
              : BoxDecoration(
                  borderRadius: radius,
                  color: Color.alphaBlend(c.withValues(alpha: 0.12), k.surface),
                  border: Border.all(color: c.withValues(alpha: 0.35)),
                ),
          child: Icon(
            achievement.icon,
            size: size * 0.47,
            color: earned
                ? achievement.tier.onColor
                : c.withValues(alpha: 0.55),
          ),
        ),
        if (!earned)
          Positioned(
            right: -size * 0.06,
            bottom: -size * 0.06,
            child: Container(
              width: size * 0.33,
              height: size * 0.33,
              decoration: BoxDecoration(
                color: k.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: k.bg, width: 2),
              ),
              child: Icon(
                Icons.lock_rounded,
                size: size * 0.17,
                color: k.muted,
              ),
            ),
          ),
      ],
    );
  }
}
