import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/ui/tokens.dart';

const double _itemWidth = 80;
const double _itemHeight = 54;

class KustNavItem {
  const KustNavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Compact floating capsule. Icon over label; the selected item sits in a soft
/// gold capsule. The "glass" is a translucent fill plus a light inner edge,
/// not a backdrop blur, so it costs nothing per frame.
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Center(
          heightFactor: 1,
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: k.surface.withValues(alpha: isDark ? 0.92 : 0.88),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SizedBox(
                width: items.length * _itemWidth,
                height: _itemHeight,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      left: selectedIndex * _itemWidth,
                      top: 0,
                      width: _itemWidth,
                      height: _itemHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: k.accent.withValues(
                            alpha: isDark ? 0.13 : 0.17,
                          ),
                          borderRadius: BorderRadius.circular(29),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          _NavButton(
                            item: items[i],
                            selected: i == selectedIndex,
                            onTap: () {
                              if (i != selectedIndex) {
                                HapticFeedback.selectionClick();
                              }
                              onSelected(i);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
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
    required this.onTap,
  });

  final KustNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Pure gold is too light as text on white; deepen it in light mode.
    final tint = isDark ? k.accent : const Color(0xFFB07A00);
    final color = selected ? tint : k.ink;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: _itemWidth,
          height: _itemHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                style: k.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
