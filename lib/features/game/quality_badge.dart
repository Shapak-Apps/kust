import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/features/game/chess/move_feedback.dart';

/// A move rating's badge: its glyph in white on a glossy ball of its
/// colour, lit from above, with a soft glow of the same colour.
class QualityBadge extends StatelessWidget {
  const QualityBadge({super.key, required this.quality, required this.size});

  final MoveQuality quality;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = quality.color;
    final light = Color.lerp(c, Colors.white, 0.35)!;
    final dark = Color.lerp(c, Colors.black, 0.25)!;
    final glyph = size * quality.iconScale * 1.25;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [light, c, dark],
          stops: const [0, 0.5, 1],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: size * 0.03,
        ),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.55),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The shine: a soft white oval across the top.
          Positioned(
            top: size * 0.07,
            child: Container(
              width: size * 0.62,
              height: size * 0.32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.elliptical(size * 0.31, size * 0.16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // A faint dark copy under the glyph lifts it off the ball.
          Transform.translate(
            offset: Offset(0, size * 0.03),
            child: SvgPicture.asset(
              quality.asset,
              width: glyph,
              height: glyph,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.25),
                BlendMode.srcIn,
              ),
            ),
          ),
          SvgPicture.asset(
            quality.asset,
            width: glyph,
            height: glyph,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }
}
