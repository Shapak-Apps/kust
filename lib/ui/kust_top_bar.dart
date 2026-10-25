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
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> trailing;
  final bool large;

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        // At least 44 high, and taller when big text needs the room.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              SizedBox(
                width: 96,
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
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, maxLines: 1, style: k.caption),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
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
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: k.bg,
        child: SafeArea(
          bottom: false,
          // Top bar buttons are plain icons.
          child: _InTopBar(child: content),
        ),
      ),
    );
  }
}

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
            dimension: 44,
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
