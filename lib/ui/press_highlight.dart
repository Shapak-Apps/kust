import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tap target for a list row or card: the moment a finger touches it the
/// surface lightens (darkens in the light theme), and fades back when it
/// lifts. It does not shrink, as rows don't in the apps this follows.
/// Buttons and icons keep the scale of [Pressable].
class PressHighlight extends StatefulWidget {
  const PressHighlight({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.borderRadius = BorderRadius.zero,
    this.haptic = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// The corners of the highlight; a card's own radius.
  final BorderRadius borderRadius;
  final bool haptic;

  @override
  State<PressHighlight> createState() => _PressHighlightState();
}

class _PressHighlightState extends State<PressHighlight> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onLongPress: widget.onLongPress,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: Stack(
        // The row keeps the width and height its parent gives it.
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                // On at once, off over a moment.
                duration: Duration(milliseconds: _down ? 0 : 120),
                opacity: _down ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0x0FFFFFFF)
                        : const Color(0x0A000000),
                    borderRadius: widget.borderRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
