import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/ui/tokens.dart';

/// The Küşt wordmark: the letters in the text colour, the two dots over
/// the ü and the tail under the ş in gold.
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
    final width = box * 1214 / 540;
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
            // The gold goes first, so the tail of the ş sits behind the letter
            // and the S stays whole on top of it.
            children: [
              layer('assets/images/wordmark_dots.svg', KustTokens.gold),
              layer('assets/images/wordmark_letters.svg', context.k.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Square K: a K built from nine board squares, with the last move in
/// gold. Drawn on a 4 by 5 grid; [height] is the K's height.
class KustSymbol extends StatelessWidget {
  const KustSymbol({
    super.key,
    this.height = 80,
    this.color,
    this.lastMove = KustTokens.gold,
  });

  final double height;

  /// The squares; the text colour when null.
  final Color? color;

  /// The last-move square. White on gold.
  final Color lastMove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Küşt',
      image: true,
      child: CustomPaint(
        size: Size(height * 4 / 5, height),
        painter: _SquareKPainter(color ?? context.k.ink, lastMove),
      ),
    );
  }
}

class _SquareKPainter extends CustomPainter {
  const _SquareKPainter(this.ink, this.lastMove);

  final Color ink;
  final Color lastMove;

  static const _cells = [
    (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), //
    (1, 2), (2, 1), (3, 0), (2, 3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 5;
    // A hair of overlap so neighbouring squares show no seam.
    Rect cell(int c, int r) => Rect.fromLTWH(c * s, r * s, s + 0.5, s + 0.5);
    final paint = Paint()..color = ink;
    for (final (c, r) in _cells) {
      canvas.drawRect(cell(c, r), paint);
    }
    canvas.drawRect(cell(3, 4), Paint()..color = lastMove);
  }

  @override
  bool shouldRepaint(_SquareKPainter old) =>
      old.ink != ink || old.lastMove != lastMove;
}
