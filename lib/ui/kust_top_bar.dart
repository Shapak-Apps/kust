import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/ui/bold_icon.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// Replacement for AppBar. Plain layout, no elevation, no tint.
///
/// [large] puts a big left-aligned title under the action row (tab screens).
/// Otherwise the title sits centered between leading and trailing (pushed
/// screens).
class KustTopBar extends StatelessWidget {
  const KustTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing = const [],
    this.large = false,
    this.brand,
    this.translucent = false,
  });

  /// The height of a centred bar with one line of content, under the
  /// status bar: for screens whose content scrolls beneath it.
  static const double barHeight = 54;

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> trailing;
  final bool large;

  /// Shown in place of the centred title, such as the logo.
  final Widget? brand;

  /// See-through: whatever scrolls under the bar shows blurred, as on
  /// chess.com. The screen lays its content out under the bar.
  final bool translucent;

  /// The old layout, for a bar showing the logo: it sits in the middle.
  Widget _centred(KustTokens k) => Row(
    children: [
      SizedBox(
        width: kMinTap * 2 + 8,
        child: Align(
          alignment: Alignment.centerLeft,
          child: leading ?? const SizedBox.shrink(),
        ),
      ),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(header: true, label: title, child: brand),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k.caption,
              ),
            ],
          ],
        ),
      ),
      SizedBox(
        width: kMinTap * 2 + 8,
        child: Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < trailing.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                trailing[i],
              ],
            ],
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget content;
    if (large) {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle != null) Text(subtitle!, style: k.caption),
                  Text(title, style: k.display),
                ],
              ),
            ),
            for (final t in trailing) ...[const SizedBox(width: 8), t],
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
        // At least 44 high, and taller when big text needs the room.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: brand != null
              ? _centred(k)
              : Row(
                  children: [
                    // The title starts after the back button, as on
                    // chess.com; with no button it starts at the edge.
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A long title shrinks to fit; a short one keeps
                          // its size.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              maxLines: 1,
                              style: k.body.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: k.caption,
                            ),
                        ],
                      ),
                    ),
                    for (var i = 0; i < trailing.length; i++) ...[
                      SizedBox(width: i == 0 ? 12 : 8),
                      trailing[i],
                    ],
                  ],
                ),
        ),
      );
    }

    final bar = SafeArea(
      bottom: false,
      // Top bar buttons are plain icons.
      child: _InTopBar(child: content),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: translucent
          // Its own layer, and a blur light enough to redo every frame of a
          // scroll on a mid-range phone.
          ? RepaintBoundary(
              child: ClipRect(
                // Grouped with the tab bar's blur: one read of the page for
                // both.
                child: BackdropFilter.grouped(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: ColoredBox(
                    color: k.bg.withValues(alpha: 0.8),
                    child: bar,
                  ),
                ),
              ),
            )
          : ColoredBox(color: k.bg, child: bar),
    );
  }
}

/// The smallest touch target, as the platform guidelines ask.
const double kMinTap = 48;

/// Round, hairline-bordered icon button used in top bars and toolbars.
class KustIconButton extends StatelessWidget {
  const KustIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.filled = false,
    this.size = 40,
    this.plain,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? label;
  final bool filled;
  final double size;

  /// Just the icon, larger and bolder, with no circle around it. Defaults to
  /// on inside a [KustTopBar] and off elsewhere.
  final bool? plain;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final enabled = onTap != null;
    if (plain ?? _InTopBar.of(context)) {
      return Semantics(
        button: true,
        label: label,
        enabled: enabled,
        child: Pressable(
          onTap: onTap,
          scale: 0.88,
          child: SizedBox.square(
            dimension: kMinTap,
            child: Center(
              child: BoldIcon(
                icon,
                size: 27,
                color: enabled ? k.ink : k.muted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: Pressable(
        onTap: onTap,
        scale: 0.92,
        // The circle keeps its look; the touch area is at least 48 px.
        child: SizedBox.square(
          dimension: size < kMinTap ? kMinTap : size,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? k.accent : k.surface,
                border: filled ? null : Border.all(color: k.line),
              ),
              child: Icon(
                icon,
                size: 20,
                color: filled
                    ? k.accentInk
                    : enabled
                    ? k.ink
                    : k.muted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Marks a [KustTopBar]'s contents so its [KustIconButton]s draw plain.
class _InTopBar extends InheritedWidget {
  const _InTopBar({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InTopBar>() != null;

  @override
  bool updateShouldNotify(_InTopBar oldWidget) => false;
}
