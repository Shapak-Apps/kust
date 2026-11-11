import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/ui/tokens.dart';

const double _barHeight = 62;

class KustNavItem {
  const KustNavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The bottom bar, in the manner of Spotify's: full width, no capsule, the
/// tabs spread evenly with the icon over its label. It fades in from the
/// page above it into a near-solid dark, so content scrolling under it
/// dissolves instead of being cut off. The selected tab is white and
/// filled, the others grey; the selected icon pops on a tap.
class KustNavBar extends StatelessWidget {
  const KustNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<KustNavItem> items;
  final ValueChanged<int> onSelected;

  /// Space content must leave at the bottom so nothing hides under the bar.
  static double clearance(BuildContext context) =>
      MediaQuery.of(context).padding.bottom + 64 + 8 + 12;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF0E0D0C) : k.bg;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              base.withValues(alpha: 0),
              base.withValues(alpha: 0.9),
              base.withValues(alpha: 0.98),
            ],
            stops: const [0, 0.32, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: SizedBox(
              height: _barHeight,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavButton(
                        item: items[i],
                        selected: i == selectedIndex,
                        dark: isDark,
                        onTap: () {
                          if (i != selectedIndex) {
                            HapticFeedback.selectionClick();
                          }
                          onSelected(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final KustNavItem item;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final on = dark ? Colors.white : k.ink;
    final off = dark ? const Color(0xFFA7A39B) : const Color(0xFF6E6C66);
    final color = selected ? on : off;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pops as it is selected.
            TweenAnimationBuilder<double>(
              key: ValueKey(selected),
              tween: Tween(begin: selected ? 0.78 : 1, end: 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.elasticOut,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: k.caption.copyWith(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0,
                color: color,
              ),
              child: Text(item.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
