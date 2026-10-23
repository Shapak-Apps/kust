import 'package:flutter/material.dart';

import 'package:kust/features/game/chess/chess_engine.dart';

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
    final share = score?.whiteShare ?? 0.5;
    final whiteLeads = share >= 0.5;
    final label = score?.label ?? '0.00';

    // The white fill grows from the white side's edge.
    final whiteEdge = whiteOnLeft
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final blackEdge = whiteOnLeft
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          const SizedBox.expand(child: ColoredBox(color: _blackSide)),
          // Positioned.fill gives the fraction box the full bar to align in;
          // without it the fill always hugs the left edge.
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: share),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                alignment: whiteEdge,
                child: const SizedBox.expand(
                  child: ColoredBox(color: _whiteSide),
                ),
              ),
            ),
          ),
          // One label, drawn on the side that is winning, so it is never cut
          // off by the other color.
          if (showLabel)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: whiteLeads ? whiteEdge : blackEdge,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: whiteLeads ? Colors.black : _whiteSide,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
