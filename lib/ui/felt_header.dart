import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/ui/bold_icon.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// The green felt title bar of the Puzzles and History tabs: a large cream
/// title on the carpet's felt green, with a faint line under it.
class FeltHeader extends StatelessWidget {
  const FeltHeader({super.key, required this.title, this.onBack});

  final String title;

  /// Shows a back arrow before the title when given.
  final VoidCallback? onBack;

  /// The felt green, a shade darker in dark mode.
  static Color colorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? LoomColors.feltDark
      : LoomColors.felt;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: colorOf(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  onBack == null ? 24 : 12,
                  16,
                  24,
                  16,
                ),
                child: Row(
                  children: [
                    if (onBack != null) ...[
                      Semantics(
                        button: true,
                        label: 'Back',
                        excludeSemantics: true,
                        child: Pressable(
                          onTap: onBack,
                          scale: 0.88,
                          // No taller than the title, so every felt header
                          // is the same height with or without it.
                          child: const SizedBox(
                            width: 36,
                            height: 30,
                            child: Center(
                              child: BoldIcon(
                                Icons.arrow_back_rounded,
                                size: 26,
                                color: LoomColors.cream,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: k.display.copyWith(
                            color: LoomColors.cream,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          ],
        ),
      ),
    );
  }
}
