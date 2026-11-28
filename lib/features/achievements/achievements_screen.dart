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
                // Flat rows with a hairline between them, as tall as their
                // text: no cards of different heights side by side.
                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        context.t.achEarnedOf(
                          unlocked.length,
                          kAchievements.length,
                        ),
                        style: k.caption.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final a in kAchievements)
                      AchievementTile(
                        achievement: a,
                        earned: unlocked.containsKey(a.id),
                      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: k.line)),
        ),
        child: Row(
          children: [
            AchievementIcon(achievement: achievement, earned: earned, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.titleIn(context.t),
                    style: k.rowTitle.copyWith(color: earned ? k.ink : k.muted),
                  ),
                  Text(achievement.descriptionIn(context.t), style: k.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              achievement.tier.labelIn(context.t),
              style: k.caption.copyWith(
                color: earned ? achievement.tier.color : k.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An achievement's picture, kept flat: once earned, its icon in its
/// tier's colour on a soft tint of it; until then, a grey tile with the
/// icon faded. No gradients, edges or shadows.
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
    return Container(
      width: size,
      height: size,
      decoration: squircle(
        size * 0.26,
        color: earned
            ? Color.alphaBlend(c.withValues(alpha: 0.16), k.surface)
            : k.surfaceAlt,
      ),
      child: Icon(
        achievement.icon,
        size: size * 0.46,
        color: earned ? c : k.muted.withValues(alpha: 0.45),
      ),
    );
  }
}
