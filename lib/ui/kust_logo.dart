import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/ui/tokens.dart';

/// The Küşt wordmark: the letters in the text colour, the two dots over
/// the ü in gold.
///
/// [height] is the height of the capitals. The cedilla of the ş hangs
/// below them, so the mark is laid out by its capitals: the hook spills
/// into the space under it instead of pushing the word off centre.
class KustLogo extends StatelessWidget {
  const KustLogo({super.key, this.height = 22});

  final double height;

  /// The SVG's box against its capital height (540 / 403), and how far
  /// the box reaches below the capitals' baseline (127 / 540).
  static const double _boxPerCap = 540 / 403;
  static const double _below = 127 / 540;

  @override
  Widget build(BuildContext context) {
    final box = height * _boxPerCap;
    final width = box * 1180 / 540;
    Widget layer(String asset, Color color) => SvgPicture.asset(
      asset,
      width: width,
      height: box,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
    return Semantics(
      label: 'Küşt',
      image: true,
      child: SizedBox(
        width: width,
        height: box * (1 - _below),
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: box,
          child: Stack(
            children: [
              layer('assets/images/wordmark_letters.svg', context.k.ink),
              layer('assets/images/wordmark_dots.svg', KustTokens.gold),
            ],
          ),
        ),
      ),
    );
  }
}
