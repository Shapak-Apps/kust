import 'package:flutter/material.dart';

import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/tokens.dart';

/// The header of a section of a screen: its title (17/700) with a count
/// beside it, and View all in gold at the end when there is more.
/// 24 above it, 8 below, 16 at the sides.
class KustSectionHeader extends StatelessWidget {
  const KustSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.onViewAll,
  });

  final String title;
  final String? count;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, onViewAll == null ? 16 : 4, 8),
      child: Row(
        children: [
          // The title takes the room up to View all, and only then is cut.
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k.section,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: k.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(count!, style: k.captionStrong),
                  ),
                ],
              ],
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              // No extra height: the row is as tall as the title.
              style: TextButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                foregroundColor: k.accent,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(context.t.viewAll, maxLines: 1),
            ),
        ],
      ),
    );
  }
}
