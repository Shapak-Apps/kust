import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:kust/core/storage/app_storage.dart';

import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/tokens.dart';

/// The player's picture in a square with softened corners. With no photo
/// yet it shows the first letter of their name, or a muted silhouette when
/// there is no name either; never an empty space.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, this.photo, this.size = 36, this.name});

  /// The player's photo, once there is one.
  final ImageProvider? photo;
  final double size;

  /// Read out by screen readers, and its first letter stands in for a
  /// missing photo.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final photo = this.photo;
    final initial = name?.trim().characters.firstOrNull?.toUpperCase();
    return Semantics(
      label: name == null ? context.t.yourAvatar : context.t.avatarOf(name!),
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: k.surfaceAlt,
          border: Border.all(color: k.line),
        ),
        clipBehavior: Clip.antiAlias,
        // The letter (or silhouette) always sits underneath, so a photo
        // still loading, or one that fails to load, never leaves a hole.
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (initial != null)
              Center(
                child: Text(
                  initial,
                  style: k.title.copyWith(
                    fontSize: size * 0.46,
                    height: 1,
                    color: k.ink.withValues(alpha: 0.8),
                  ),
                ),
              )
            else
              // The ghost: a muted silhouette in the middle.
              Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_rounded,
                  size: size * 0.98 - 5,
                  color: k.muted.withValues(alpha: 0.55),
                ),
              ),
            if (photo != null)
              Image(
                image: photo,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                frameBuilder: (context, child, frame, sync) => AnimatedOpacity(
                  opacity: sync || frame != null ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: child,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A player's photo from the server, or null when they have none.
ImageProvider? avatarImage(String? url) =>
    url == null ? null : CachedAvatar(url);

/// A profile photo kept on the phone after the first download. Photo
/// addresses never change (a new photo gets a new one), so a saved copy is
/// always right and is shown at once, without the network.
@immutable
class CachedAvatar extends ImageProvider<CachedAvatar> {
  const CachedAvatar(this.url);

  final String url;

  @override
  Future<CachedAvatar> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    CachedAvatar key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);

  /// The saved copy: named after the photo's address, which is unique.
  File _file() {
    final dir = AppStorage.filesDir ?? Directory.systemTemp.path;
    final name = url
        .split('/v1/')
        .last
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return File('$dir/avatar_cache/$name');
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final file = _file();
    Uint8List bytes;
    if (await file.exists()) {
      bytes = await file.readAsBytes();
    } else {
      final client = HttpClient();
      try {
        final response = await (await client.getUrl(Uri.parse(url))).close();
        if (response.statusCode != 200) {
          throw HttpException(
            'avatar ${response.statusCode}',
            uri: Uri.parse(url),
          );
        }
        bytes = await consolidateHttpClientResponseBytes(response);
      } finally {
        client.close();
      }
      try {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
      } on FileSystemException {
        // Shown anyway; saved next time.
      }
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) => other is CachedAvatar && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
