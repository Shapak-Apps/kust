import 'package:flutter/material.dart';

import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// A squarish card for a shortcut: an icon at the top, a title and a line
/// under it at the bottom, and something small (a badge) in the corner.
class KustTile extends StatelessWidget {
  const KustTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.semanticsLabel,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String semanticsLabel;

  /// Shown in the top right corner.
  final Widget? badge;

  /// The tile's height.
  static const double height = 132;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(KustSpace.rMedium),
            border: Border.all(color: k.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [KustIconTile(icon), const Spacer(), ?badge],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k.body.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
