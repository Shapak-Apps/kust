import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/piece_image.dart';

/// The small figurine of a taken piece (designed in Figma for the bars):
/// light pieces cream with a grey edge, dark ones near-black with a light
/// edge, so both are easy on the eye on the dark bar and on light.
String capturedAsset(Piece piece) =>
    'assets/captured/${piece.color == Side.white ? 'w' : 'b'}'
    '${piece.role.uppercaseLetter}.svg';

/// The strip over and under the board in every game: a 40 px avatar, the
/// name with a flag, the rating, what has been taken and who is ahead, and
/// the clock at the end. 56 high, 12 at the sides.
class GamePlayerBar extends StatelessWidget {
  const GamePlayerBar({
    super.key,
    required this.avatar,
    required this.name,
    this.flag,
    this.rating,
    this.captured = const [],
    this.advantage = 0,
    this.thinking,
    this.wrapCaptured,
    this.clock,
  });

  static const double height = 56;

  /// A 40 px avatar with 4 px corners.
  final Widget avatar;
  final String name;

  /// The country flag, 14 px high.
  final Widget? flag;
  final String? rating;
  final List<Piece> captured;

  /// Material ahead, in pawns; shown after the captured pieces when above 0.
  final int advantage;

  /// After the name while a bot is thinking.
  final Widget? thinking;

  /// Lets a bot's remark take the place of the captured pieces for a moment.
  final Widget Function(Widget captured)? wrapCaptured;
  final Widget? clock;

  /// Captured pieces in groups of one kind, in the order they come.
  static List<List<Piece>> _groups(List<Piece> pieces) {
    final byRole = <Role, List<Piece>>{};
    for (final p in pieces) {
      (byRole[p.role] ??= []).add(p);
    }
    return byRole.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    Widget material = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // One group per kind, the pieces of a group overlapping.
          for (final group in _groups(captured))
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 14 + 6.0 * (group.length - 1),
                height: 14,
                child: Stack(
                  children: [
                    for (var i = 0; i < group.length; i++)
                      Positioned(
                        left: 6.0 * i,
                        child: PieceImage(
                          capturedAsset(group[i]),
                          width: 14,
                          height: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (advantage > 0)
            Text(
              '+$advantage',
              style: k.caption.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
    if (wrapCaptured != null) material = wrapCaptured!(material);
    final hasRating = rating != null && rating!.isNotEmpty;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: k.rowTitle,
                        ),
                      ),
                      if (flag != null) ...[const SizedBox(width: 6), flag!],
                      if (thinking != null) ...[
                        const SizedBox(width: 8),
                        Flexible(child: thinking!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (hasRating) ...[
                        Text(
                          rating!,
                          maxLines: 1,
                          style: k.caption.copyWith(fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(child: material),
                    ],
                  ),
                ],
              ),
            ),
            if (clock != null) ...[const SizedBox(width: 8), clock!],
          ],
        ),
      ),
    );
  }
}
