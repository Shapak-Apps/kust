import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/ui/tokens.dart';

/// The green felt title bar of the Puzzles and History tabs: a large cream
/// title on the carpet's felt green, with a faint line under it.
class FeltHeader extends StatelessWidget {
  const FeltHeader({super.key, required this.title});

  final String title;

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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: k.display.copyWith(
                      color: LoomColors.cream,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
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
