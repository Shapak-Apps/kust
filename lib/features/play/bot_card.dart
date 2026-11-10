import 'package:flutter/material.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

/// A bot on the home screen and in the opponent picker: its portrait as a
/// bust on a backdrop coloured by how strong it is, its name and its rating.
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

  /// Green for beginners, amber in the middle, red for the strong ones.
  /// The backdrop's two shades and a bright one for the rating.
  static (Color, Color, Color) backdrop(int elo) => elo < 800
      ? (
          const Color(0xFF2B7553),
          const Color(0xFF173F2E),
          const Color(0xFF6BD8A2),
        )
      : elo < 1300
      ? (
          const Color(0xFF8A6A1E),
          const Color(0xFF4A3810),
          const Color(0xFFF2C14E),
        )
      : (
          const Color(0xFF8A3238),
          const Color(0xFF4A1A1E),
          const Color(0xFFFF8A8F),
        );

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final (light, dark, bright) = backdrop(bot.elo);
    return Semantics(
      button: true,
      selected: selected,
      label: '${bot.name}, ${context.t.eloValue(bot.elo)}',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          decoration: BoxDecoration(
            color: selected
                ? k.accent.withValues(alpha: 0.14)
                : Color.alphaBlend(const Color(0x0DFFFFFF), k.surface),
            borderRadius: BorderRadius.circular(KustSpace.rMedium),
            border: Border.all(
              color: selected ? k.accent : const Color(0x14FFFFFF),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The backdrop, with the bust standing on its bottom edge.
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          KustSpace.rMedium - 4,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.2),
                              radius: 0.95,
                              colors: [light, dark],
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Image.asset(
                              bot.imagePath,
                              width: 86,
                              height: 86,
                              cacheWidth: 258,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: ValueListenableBuilder(
                        valueListenable: AppStorage.instance
                            .botProgressListenable(),
                        builder: (context, _, _) =>
                            AppStorage.instance.isBotBeaten(bot.id)
                            ? Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xCC141210),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  size: 13,
                                  color: k.accent,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    if (bot.isTkm)
                      Positioned(
                        top: 5,
                        left: 5,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icons/TKM.webp',
                            width: 16,
                            height: 16,
                            cacheWidth: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                bot.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k.body.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 1),
              Text(
                '${bot.elo}',
                style: k.caption.copyWith(
                  color: bright,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
