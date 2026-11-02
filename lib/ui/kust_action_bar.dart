import 'package:flutter/material.dart';

import 'package:kust/ui/bold_icon.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// One button of a [KustActionBar].
class KustAction {
  const KustAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;

  /// Null greys the button out.
  final VoidCallback? onTap;

  /// Shows a spinner instead of the icon, e.g. while a hint is worked out.
  final bool busy;
}

/// Icons whose weight sits off their middle, by code point, moved down so
/// they look centred beside the others: the bulb's round head is up top and
/// its base thin, so centred by its box it looks high.
final Map<int, double> _opticalDrop = {
  Icons.lightbulb_outline_rounded.codePoint: 2,
};

/// The row of actions under a board: each a bold icon over a short label,
/// spread evenly across, with nothing around them.
class KustActionBar extends StatelessWidget {
  const KustActionBar({super.key, required this.actions});

  final List<KustAction> actions;

  /// The bar's height, for screens that keep a fixed slot for it.
  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (final action in actions) Expanded(child: _Item(action: action)),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.action});

  final KustAction action;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final enabled = action.onTap != null && !action.busy;
    final colour = enabled ? k.ink : k.muted.withValues(alpha: 0.45);

    final Widget icon = action.busy
        // As tall as an icon, so the label does not move while it spins.
        ? SizedBox.square(
            dimension: 30,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: CircularProgressIndicator(strokeWidth: 2.8, color: k.ink),
            ),
          )
        : Transform.translate(
            offset: Offset(0, _opticalDrop[action.icon.codePoint] ?? 0),
            child: BoldIcon(action.icon, size: 30, color: colour),
          );

    final body = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(height: 4),
        Text(
          action.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // The bar has a fixed height, so labels stop growing a little
          // above the normal size.
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: 1.15),
          style: k.caption.copyWith(color: colour, fontWeight: FontWeight.w800),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: action.label,
      excludeSemantics: true,
      child: Pressable(
        onTap: enabled ? action.onTap : null,
        scale: 0.92,
        child: body,
      ),
    );
  }
}
