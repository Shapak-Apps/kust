import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/features/game/chess/move_feedback.dart';

/// A move rating's badge: its glyph in white on a ball of its colour,
/// with a darker lip underneath, like the app's 3D buttons.
class QualityBadge extends StatelessWidget {
  const QualityBadge({super.key, required this.quality, required this.size});

  final MoveQuality quality;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = quality.color;
    final glyph = size * quality.iconScale * 1.2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c,
        boxShadow: [
          BoxShadow(
            color: Color.lerp(c, Colors.black, 0.35)!,
            offset: Offset(0, size * 0.07),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        quality.asset,
        width: glyph,
        height: glyph,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}
