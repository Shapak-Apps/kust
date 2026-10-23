import 'package:flutter/material.dart';

import 'package:Kust/core/storage/app_storage.dart';
import 'package:Kust/features/play/bots.dart';
import 'package:Kust/ui/pressable.dart';
import 'package:Kust/ui/tokens.dart';

/// Compact bot card used on the home screen and in the opponent picker.
class BotCard extends StatelessWidget {
  const BotCard({
    super.key,
    required this.bot,
    required this.onTap,
    this.selected = false,
  });

  final Bot bot;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: '${bot.name}, ${bot.elo} Elo',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? k.accent.withValues(alpha: 0.12) : k.surface,
            borderRadius: BorderRadius.circular(KustSpace.rMedium),
            border: Border.all(
              color: selected ? k.accent : k.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(KustSpace.rSmall),
                child: Image.asset(
                  bot.imagePath,
                  width: 56,
                  height: 56,
                  cacheWidth: 168,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      bot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (bot.isTkm) ...[
                    const SizedBox(width: 4),
                    ClipOval(
                      child: Image.asset(
                        'assets/icons/TKM.webp',
                        width: 14,
                        height: 14,
                        cacheWidth: 42,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
              ValueListenableBuilder(
                valueListenable: AppStorage.instance.botProgressListenable(),
                builder: (context, _, _) {
                  final beaten = AppStorage.instance.isBotBeaten(bot.id);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${bot.elo}', style: k.caption),
                      if (beaten) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 14,
                          color: k.accent,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
