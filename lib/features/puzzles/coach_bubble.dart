import 'package:flutter/material.dart';

import 'package:kust/features/play/bots.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/features/puzzles/speech_bubble.dart';
import 'package:kust/ui/tokens.dart';

/// The puzzle coach: a bot's face with a speech bubble beside it. Used on the
/// puzzle map and on the puzzle screen, so the same face greets you in both.
class CoachBubble extends StatelessWidget {
  const CoachBubble({
    super.key,
    required this.title,
    required this.tip,
    this.leading,
    this.titleColor = LoomColors.indigo,
    this.size = 64,
  });

  /// The bold first line, e.g. "Next: Mate in 2".
  final String title;

  /// The second line.
  final String tip;

  /// Shown before the title, e.g. the colour to move.
  final Widget? leading;
  final Color titleColor;

  /// Width and height of the face.
  final double size;

  static int get _day => DateTime.now().difference(DateTime(2026)).inDays;

  /// The coach of the day; the same for every screen.
  static Bot get bot => kInternationalBots[_day % kInternationalBots.length];

  static const List<String> _tips = [
    'Never skip puzzle day!',
    'Look for checks, captures and threats first.',
    'One puzzle a day keeps the blunders away.',
    'Take your time: the best move is usually forcing.',
  ];

  static String tipOfTheDay() => _tips[_day % _tips.length];

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: LoomColors.saffron,
          ),
          padding: const EdgeInsets.all(2.5),
          child: ClipOval(
            child: Image.asset(
              bot.imagePath,
              cacheWidth: (size * 3).round(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: CustomPaint(
            painter: const SpeechBubblePainter(
              fill: LoomColors.cream,
              border: LoomColors.indigo,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BubbleMetrics.tail + 14,
                10,
                14,
                11,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: k.body.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    tip,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: k.caption.copyWith(
                      color: LoomColors.walnut,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
