import 'package:flutter/material.dart';

import 'package:kust/ui/press_highlight.dart';
import 'package:kust/ui/tokens.dart';

/// The row of every list: at least [KustSpace.row] (56) tall, 16 at the
/// sides, an avatar or icon first, a title with a line under it, something
/// at the end, and a hairline below. It lightens under the finger.
class KustListRow extends StatelessWidget {
  const KustListRow({
    super.key,
    this.leading,
    required this.title,
    this.meta,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.divider = true,
  });

  /// An avatar or an icon tile, 36 px.
  final Widget? leading;

  /// Usually the name, in [KustTokens.rowTitle].
  final Widget title;

  /// The line under it, in [KustTokens.caption].
  final Widget? meta;

  /// A rating, a result, a button: what the row ends with.
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return PressHighlight(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(minHeight: KustSpace.row),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: divider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: k.line)),
              )
            : null,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [title, ?meta],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}

/// An avatar with the little green dot of someone who is online.
class OnlineDot extends StatelessWidget {
  const OnlineDot({super.key, required this.online, required this.child});

  final bool online;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (online)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: k.success,
                shape: BoxShape.circle,
                border: Border.all(color: k.bg, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
