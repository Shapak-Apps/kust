import 'package:flutter/material.dart';

/// An icon drawn a touch heavier than the font's: the same glyph laid down
/// four times, shifted by a fraction of a pixel. The icon font has a single
/// weight, so this is how a bolder look is had without new assets.
class BoldIcon extends StatelessWidget {
  const BoldIcon(
    this.icon, {
    super.key,
    required this.size,
    required this.color,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final d = size * 0.022;
    return Icon(
      icon,
      size: size,
      color: color,
      shadows: [
        for (final o in [
          Offset(d, 0),
          Offset(-d, 0),
          Offset(0, d),
          Offset(0, -d),
        ])
          Shadow(color: color, offset: o),
      ],
    );
  }
}
