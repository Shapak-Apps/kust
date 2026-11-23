import 'package:flutter/material.dart';

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
    url == null ? null : NetworkImage(url);
