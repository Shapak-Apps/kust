import 'package:flutter/material.dart';

import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/press_highlight.dart';
import 'package:kust/ui/tokens.dart';

/// A one-row card for a shortcut: an icon, a title with a line under it,
/// something small (a badge) and an arrow.
class KustTile extends StatelessWidget {
  const KustTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.semanticsLabel,
    this.badge,
    this.done = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String semanticsLabel;

  /// Shown before the arrow.
  final Widget? badge;

  /// Finished for now (today's daily puzzle, say): a green tick in place of
  /// the icon, the line under the title in green, a green edge.
  final bool done;

  /// The tile's height.
  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: PressHighlight(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KustSpace.rCard),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(KustSpace.rCard),
            border: Border.all(
              color: done ? k.success.withValues(alpha: 0.6) : k.line,
            ),
          ),
          child: Row(
            children: [
              if (done)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: k.success,
                    borderRadius: BorderRadius.circular(KustSpace.rSmall),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                )
              else
                KustIconTile(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k.rowTitle,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: done
                          ? k.caption.copyWith(
                              color: k.success,
                              fontWeight: FontWeight.w800,
                            )
                          : k.caption,
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 8), badge!],
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: k.muted),
            ],
          ),
        ),
      ),
    );
  }
}
