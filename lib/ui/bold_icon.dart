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
    this.weight = 0.009,
  });

  final IconData icon;
  final double size;
  final Color color;

  /// How far each copy is shifted, as a share of [size]: the extra weight.
  final double weight;

  @override
  Widget build(BuildContext context) {
    // Just a hint heavier: a stronger shift reads as smudged.
    final d = size * weight;
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
