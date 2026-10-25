import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/ui/kust_tile.dart';
import 'package:kust/ui/tokens.dart';

/// The way into the achievements list from the Play screen, with a count.
class AchievementsCard extends StatelessWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ValueListenableBuilder(
      valueListenable: AchievementStore.instance.listenable(),
      builder: (context, _, _) {
        final earned = AchievementStore.instance.unlocked().length;
        final total = kAchievements.length;
        return KustTile(
          icon: Icons.emoji_events_outlined,
          title: 'Achievements',
          subtitle: '$earned of $total earned',
          semanticsLabel: 'Achievements, $earned of $total earned',
          onTap: () => context.push('/achievements'),
          badge: Text(
            '${(earned * 100 / total).round()}%',
            style: k.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: k.ink,
            ),
          ),
        );
      },
    );
  }
}
