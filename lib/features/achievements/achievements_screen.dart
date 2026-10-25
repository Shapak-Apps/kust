import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';

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
          KustTopBar(
            title: 'Achievements',
            leading: KustIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/play'),
            ),
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
                      '${unlocked.length} of ${kAchievements.length} earned',
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
          '${achievement.title}, ${achievement.description}, '
          '${earned ? 'earned' : 'not earned yet'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(KustSpace.rMedium),
          border: Border.all(color: earned ? k.accent : k.line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: earned ? k.accent : k.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                earned ? achievement.icon : Icons.lock_rounded,
                color: earned ? k.accentInk : k.muted,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: k.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: earned ? k.ink : k.muted,
                    ),
                  ),
                  Text(achievement.description, style: k.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
