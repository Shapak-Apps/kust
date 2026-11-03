import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/ui/kust_tile.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

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
          title: context.t.achievements,
          subtitle: context.t.achEarnedOf(earned, total),
          semanticsLabel:
              '${context.t.achievements}, ${context.t.achEarnedOf(earned, total)}',
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
