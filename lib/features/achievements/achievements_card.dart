import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/pressable.dart';
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
        return Semantics(
          button: true,
          label: 'Achievements, $earned of $total earned',
          excludeSemantics: true,
          child: Pressable(
            onTap: () => context.push('/achievements'),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
              decoration: BoxDecoration(
                color: k.surface,
                borderRadius: BorderRadius.circular(KustSpace.rMedium),
                border: Border.all(color: k.line),
              ),
              child: Row(
                children: [
                  const KustIconTile(Icons.emoji_events_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievements',
                          style: k.body.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text('$earned of $total earned', style: k.caption),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: k.muted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
