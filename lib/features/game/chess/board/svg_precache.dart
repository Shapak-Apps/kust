import 'package:flutter_svg/flutter_svg.dart';

import 'package:Kust/features/game/chess/move_feedback.dart';

final List<String> _pieceAssets = [
  for (final color in ['w', 'b'])
    for (final role in ['K', 'Q', 'R', 'B', 'N', 'P'])
      'assets/pieces/$color$role.svg',
];

Future<void> precacheGameSvgs() async {
  final paths = <String>{
    ..._pieceAssets,
    for (final quality in MoveQuality.values) quality.asset,
  };
  await Future.wait(paths.map(_cache));
}

Future<void> _cache(String path) async {
  try {
    final loader = SvgAssetLoader(path);
    await svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () => loader.loadBytes(null),
    );
  } catch (_) {}
}
