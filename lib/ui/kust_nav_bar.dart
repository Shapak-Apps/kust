import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/ui/tokens.dart';

const double _itemWidth = 80;
const double _itemHeight = 56;

class KustNavItem {
  const KustNavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The floating tab bar: a compact capsule, icon over label. The selected
/// tab sits in a soft droplet that stretches towards the tab you tap and
/// settles there with a little wobble. No blur, so it costs nothing per
/// frame; the droplet repaints alone in its own layer from its animation.
class KustNavBar extends StatefulWidget {
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
  State<KustNavBar> createState() => _KustNavBarState();
}

class _KustNavBarState extends State<KustNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );
  late int _from = widget.selectedIndex;
  late int _to = widget.selectedIndex;

  /// Pressed tab, for the droplet's squeeze under the finger.
  final ValueNotifier<int?> _pressed = ValueNotifier(null);

  @override
  void didUpdateWidget(KustNavBar old) {
    super.didUpdateWidget(old);
    if (widget.selectedIndex != _to) {
      // Start from wherever the droplet is now, even mid-flight.
      _from = _to;
      _to = widget.selectedIndex;
      _move.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    _pressed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(34);
    final width = widget.items.length * _itemWidth;

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
                borderRadius: radius,
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
                width: width,
                height: _itemHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _DropletPainter(
                            move: _move,
                            from: _from,
                            to: _to,
                            pressed: _pressed,
                            dark: isDark,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < widget.items.length; i++)
                          _NavButton(
                            item: widget.items[i],
                            selected: i == widget.selectedIndex,
                            dark: isDark,
                            onDown: () => _pressed.value = i,
                            onUp: () => _pressed.value = null,
                            onTap: () {
                              if (i != widget.selectedIndex) {
                                HapticFeedback.selectionClick();
                              }
                              widget.onSelected(i);
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

/// The droplet under the selected tab. Moving, its leading edge races ahead
/// and its trailing edge follows late, so it stretches like a drop of water
/// and thins a little; at the end the trailing edge overshoots and springs
/// back. Pressing a tab squeezes it.
class _DropletPainter extends CustomPainter {
  _DropletPainter({
    required this.move,
    required this.from,
    required this.to,
    required this.pressed,
    required this.dark,
  }) : super(repaint: Listenable.merge([move, pressed]));

  final Animation<double> move;
  final int from;
  final int to;
  final ValueNotifier<int?> pressed;
  final bool dark;

  static const Curve _lead = Interval(0, 0.6, curve: Curves.easeOutCubic);
  static const Curve _trail = Interval(0.12, 1, curve: ElasticOutCurve(0.55));

  @override
  void paint(Canvas canvas, Size size) {
    final t = move.value;
    final a = from * _itemWidth, b = to * _itemWidth;
    // The leading edge gets there early; the trailing one follows late and
    // springs a little past, which squeezes the drop before it settles.
    final leadX = lerpDouble(a, b, _lead.transform(t))!;
    final trailX = lerpDouble(a, b, _trail.transform(t))!;
    double left, rightEdge;
    if (to >= from) {
      left = math.min(trailX, leadX);
      rightEdge = leadX + _itemWidth;
    } else {
      left = leadX;
      rightEdge = math.max(trailX, leadX) + _itemWidth;
    }
    // Never thinner than most of a tab.
    if (rightEdge - left < _itemWidth * 0.8) {
      final mid = (left + rightEdge) / 2;
      left = mid - _itemWidth * 0.4;
      rightEdge = mid + _itemWidth * 0.4;
    }
    final stretch = ((rightEdge - left) / _itemWidth - 1).clamp(0.0, 3.0);
    final squeeze = pressed.value == null ? 0.0 : 0.06;
    final h = size.height * (1 - 0.1 * math.min(stretch, 1) - squeeze);
    final inset = size.height * squeeze * 0.5;
    final rect = Rect.fromLTRB(
      left + inset,
      (size.height - h) / 2,
      rightEdge - inset,
      (size.height + h) / 2,
    );
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));
    canvas.drawRRect(
      rr,
      Paint()
        ..color = dark
            ? Colors.white.withValues(alpha: 0.11)
            : Colors.black.withValues(alpha: 0.07),
    );
    // A highlight across its top, like light on a drop.
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.16 : 0.6),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.5],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: dark ? 0.22 : 0.8),
    );
  }

  @override
  bool shouldRepaint(_DropletPainter old) =>
      old.from != from || old.to != to || old.dark != dark;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.dark,
    required this.onTap,
    required this.onDown,
    required this.onUp,
  });

  final KustNavItem item;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final on = dark ? Colors.white : k.ink;
    final off = dark ? const Color(0xFF9C988F) : const Color(0xFF6E6C66);
    final color = selected ? on : off;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onDown(),
        onTapCancel: onUp,
        onTapUp: (_) => onUp(),
        onTap: onTap,
        child: SizedBox(
          width: _itemWidth,
          height: _itemHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                style: k.caption.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
