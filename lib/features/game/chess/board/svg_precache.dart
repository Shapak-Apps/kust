import 'package:flutter/widgets.dart';
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
  if (!path.endsWith('.svg')) {
    // Decode the image once so the first board shows it without a blank
    // frame; the image cache keeps it.
    AssetImage(path)
        .resolve(ImageConfiguration.empty)
        .addListener(ImageStreamListener((_, _) {}, onError: (_, _) {}));
    return;
  }
  try {
    final loader = SvgAssetLoader(path);
    await svg.cache.putIfAbsent(
      loader.cacheKey(null),
      () => loader.loadBytes(null),
    );
  } catch (_) {}
}
