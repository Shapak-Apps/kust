import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// Selectable card used by pickers (time control, side, mode).
class KustOption extends StatelessWidget {
  const KustOption({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: subtitle == null ? title : '$title, $subtitle',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? k.accent.withValues(alpha: 0.12) : k.bg,
            borderRadius: BorderRadius.circular(KustSpace.rMedium),
            border: Border.all(
              color: selected ? k.accent : k.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: k.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null) Text(subtitle!, style: k.caption),
                  ],
                ),
              ),
              trailing ??
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: selected ? 1 : 0,
                    child: Icon(Icons.check_circle_rounded, color: k.accent),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square icon tile for use as [KustOption.leading].
class KustIconTile extends StatelessWidget {
  const KustIconTile(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: k.surfaceAlt,
        borderRadius: BorderRadius.circular(KustSpace.rSmall),
      ),
      child: Icon(icon, size: 22, color: k.ink),
    );
  }
}

/// Pill switch with an animated thumb.
class KustSwitch extends StatelessWidget {
  const KustSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? k.accent : k.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: value ? k.accent : k.line),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? k.accentInk : k.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label + optional description + switch.
class KustToggleRow extends StatelessWidget {
  const KustToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: k.muted),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: k.body.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) Text(subtitle!, style: k.caption),
              ],
            ),
          ),
          KustSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Segmented control with a sliding thumb.
class KustSegmented<T> extends StatelessWidget {
  const KustSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final keys = options.keys.toList();
    final index = keys.indexOf(value).clamp(0, keys.length - 1);

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: k.surfaceAlt,
        borderRadius: BorderRadius.circular(KustSpace.rMedium),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / keys.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: index * w,
                width: w,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: k.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: k.line),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final key in keys)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onChanged(key);
                        },
                        child: Center(
                          child: Text(
                            options[key]!,
                            style: k.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: key == value ? k.ink : k.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Small uppercase section label.
class KustSectionLabel extends StatelessWidget {
  const KustSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: context.k.caption.copyWith(letterSpacing: 1),
      ),
    );
  }
}

/// Flat bordered card.
class KustCard extends StatelessWidget {
  const KustCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: k.surface,
        borderRadius: BorderRadius.circular(KustSpace.rMedium),
        border: Border.all(color: k.line),
      ),
      child: child,
    );
    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}
