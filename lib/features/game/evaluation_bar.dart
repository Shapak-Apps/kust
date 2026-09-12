import 'package:flutter/material.dart';

import 'package:Kust/features/game/chess/chess_engine.dart';

class EvaluationBar extends StatelessWidget {
  const EvaluationBar({
    super.key,
    required this.score,
    this.height = 24,
    this.whiteOnLeft = true,
    this.showLabel = true,
  });

  final EvalScore? score;
  final double height;
  final bool whiteOnLeft;
  final bool showLabel;

  static const Color _whiteSide = Colors.white;
  static const Color _blackSide = Color(0xFF3D3D3D);

  @override
  Widget build(BuildContext context) {
    double share = score?.whiteShare ?? 0.5;
    if (!whiteOnLeft) share = 1.0 - share;

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            const SizedBox.expand(child: ColoredBox(color: _blackSide)),

            if (showLabel)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    score?.label ?? '0.00',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _whiteSide,
                    ),
                  ),
                ),
              ),

            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: share),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                alignment: whiteOnLeft
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: ClipRect(
                  child: Stack(
                    children: [
                      const SizedBox.expand(
                        child: ColoredBox(color: _whiteSide),
                      ),

                      if (showLabel)
                        Positioned(
                          left: 8,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              score?.label ?? '0.00',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
