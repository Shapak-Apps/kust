import 'package:flutter/material.dart';

import 'package:kust/ui/tokens.dart';

/// The player's picture in a square with softened corners. With no photo yet it shows a ghost: a
/// muted silhouette on a soft disc, never an empty space.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, this.photo, this.size = 36, this.name});

  /// The player's photo, once there is one.
  final ImageProvider? photo;
  final double size;

  /// For screen readers.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final photo = this.photo;
    return Semantics(
      label: name == null ? 'Your avatar' : '$name, your avatar',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: k.surfaceAlt,
          border: Border.all(color: k.line),
          image: photo == null
              ? null
              : DecorationImage(image: photo, fit: BoxFit.cover),
        ),
        clipBehavior: Clip.antiAlias,
        child: photo != null
            ? null
            // The ghost: a muted silhouette in the middle.
            : Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_rounded,
                  size: size * 0.98 - 5,
                  color: k.muted.withValues(alpha: 0.55),
                ),
              ),
      ),
    );
  }
}
