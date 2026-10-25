import 'package:flutter/material.dart';

import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// One button of a [KustActionBar].
class KustAction {
  const KustAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;

  /// Null greys the button out.
  final VoidCallback? onTap;

  /// The main action: a filled button standing out in the middle.
  final bool primary;

  /// Shows a spinner instead of the icon, e.g. while a hint is worked out.
  final bool busy;
}

/// The row of actions under a board: each an icon over a short label,
/// spread evenly across, with at most one filled main action.
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
    final colour = action.primary
        ? k.accentInk
        : enabled
        ? k.ink
        : k.muted.withValues(alpha: 0.5);

    final Widget icon = action.busy
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: colour),
          )
        : Icon(action.icon, size: action.primary ? 28 : 26, color: colour);

    final Widget body;
    if (action.primary) {
      body = Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled || action.busy ? 1 : 0.45,
          child: Container(
            width: 64,
            height: 52,
            decoration: BoxDecoration(
              color: k.accent,
              borderRadius: BorderRadius.circular(KustSpace.rSmall + 4),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
        ),
      );
    } else {
      body = Column(
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
            style: k.caption.copyWith(
              color: colour,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

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
