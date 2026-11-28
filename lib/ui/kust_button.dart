import 'package:flutter/material.dart';

import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

enum KustButtonStyle {
  /// The main action of a screen: the green 3D button.
  primary,
  secondary,
  outline,

  /// The felt green of the app's headers, for the quieter main action.
  green,

  /// Something that can't be undone lightly, such as logging out.
  danger,

  /// The brand's gold, for a bold second action (Challenge).
  gold,
}

class KustButton extends StatelessWidget {
  const KustButton({
    super.key,
    required this.label,
    required this.onTap,
    this.style = KustButtonStyle.primary,
    this.icon,
    this.height = 50,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final KustButtonStyle style;
  final IconData? icon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    // Secondary is 3D too, in the dark grey, in the dark theme.
    final dark3d =
        style == KustButtonStyle.secondary &&
        Theme.of(context).brightness == Brightness.dark;
    if (style == KustButtonStyle.primary ||
        style == KustButtonStyle.gold ||
        dark3d) {
      return KustButton3D(
        colors: switch (style) {
          KustButtonStyle.gold => KustButton3D.gold,
          KustButtonStyle.secondary => KustButton3D.dark,
          _ => KustButton3D.green,
        },
        label: label,
        onTap: onTap,
        expand: expand,
        icon: icon,
        height: height,
      );
    }
    final k = context.k;
    final enabled = onTap != null;

    final Color bg;
    final Color fg;
    var side = BorderSide.none;
    switch (style) {
      case KustButtonStyle.primary:
        return const SizedBox.shrink(); // drawn by KustButton3D above
      case KustButtonStyle.secondary:
        bg = k.surfaceAlt;
        fg = enabled ? k.ink : k.muted;
      case KustButtonStyle.outline:
        bg = Colors.transparent;
        fg = enabled ? k.ink : k.muted;
        side = BorderSide(color: k.line, width: 1.5);
      case KustButtonStyle.gold:
        bg = enabled ? KustTokens.gold : k.surfaceAlt;
        fg = enabled ? const Color(0xFF17181A) : k.muted;
      case KustButtonStyle.danger:
        bg = enabled ? k.danger : k.surfaceAlt;
        fg = enabled ? Colors.white : k.muted;
      case KustButtonStyle.green:
        bg = enabled ? const Color(0xFF145A3F) : k.surfaceAlt;
        fg = enabled ? const Color(0xFFBFF0D6) : k.muted;
        side = BorderSide(
          color: enabled ? const Color(0xFF3CB77C) : k.line,
          width: 1.5,
        );
    }

    final child = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: squircle(KustSpace.rCard, color: bg, side: side),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: k.body.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Pressable(onTap: onTap, haptic: true, child: child),
    );
  }
}
