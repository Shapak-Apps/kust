import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// One chess piece from a piece set: a vector for the drawn sets, an image
/// for the textured ones (see [PieceSet]).
class PieceImage extends StatelessWidget {
  const PieceImage(this.asset, {super.key, this.width, this.height});

  final String asset;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(asset, width: width, height: height);
    }
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      // The images are drawn larger than any square and scaled down.
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}
