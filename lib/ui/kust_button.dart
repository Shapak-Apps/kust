import 'package:flutter/material.dart';

import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

enum KustButtonStyle { primary, secondary, outline }

class KustButton extends StatelessWidget {
  const KustButton({
    super.key,
    required this.label,
    required this.onTap,
    this.style = KustButtonStyle.primary,
    this.icon,
    this.height = 52,
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
    final k = context.k;
    final enabled = onTap != null;

    final Color bg;
    final Color fg;
    BoxBorder? border;
    switch (style) {
      case KustButtonStyle.primary:
        bg = enabled ? k.accent : k.surfaceAlt;
        fg = enabled ? k.accentInk : k.muted;
      case KustButtonStyle.secondary:
        bg = k.surfaceAlt;
        fg = enabled ? k.ink : k.muted;
      case KustButtonStyle.outline:
        bg = Colors.transparent;
        fg = enabled ? k.ink : k.muted;
        border = Border.all(color: k.line, width: 1.5);
    }

    final child = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(KustSpace.rMedium),
      ),
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
              style: k.body.copyWith(color: fg, fontWeight: FontWeight.w800),
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
