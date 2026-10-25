import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/move_feedback.dart';

/// Loads the pieces of the chosen set and the move icons ahead of time, and
/// the pieces of a newly chosen set as soon as it is picked.
Future<void> precacheGameSvgs() async {
  AppSettings.instance.pieceSet.addListener(
    () => Future.wait(AppSettings.instance.pieceSet.value.assets.map(_cache)),
  );
  final paths = <String>{
    ...AppSettings.instance.pieceSet.value.assets,
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
