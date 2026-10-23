import 'package:flutter/material.dart';

import 'package:Kust/core/settings.dart';
import 'package:Kust/ui/kust_controls.dart';
import 'package:Kust/ui/kust_sheet.dart';
import 'package:Kust/ui/tokens.dart';

Future<void> showMoreSheet(BuildContext context) {
  return showKustSheet<void>(context, builder: (_) => const _MoreSheet());
}

class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KustSheetHeader(title: 'More'),
        const _SoonRow(Icons.insights_rounded, 'Statistics'),
        const _SoonRow(Icons.history_rounded, 'Game history'),
        const _SoonRow(Icons.school_rounded, 'Training'),
        const SizedBox(height: 8),
        KustOption(
          leading: const KustIconTile(Icons.tune_rounded),
          title: 'Settings',
          subtitle: 'Theme, sound and haptics',
          trailing: Icon(Icons.chevron_right_rounded, color: k.muted),
          onTap: () {
            Navigator.of(context).pop();
            showSettingsSheet(context);
          },
        ),
      ],
    );
  }
}

class _SoonRow extends StatelessWidget {
  const _SoonRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: 0.6,
        child: KustOption(
          leading: KustIconTile(icon),
          title: label,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: k.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Soon', style: k.caption),
          ),
        ),
      ),
    );
  }
}

Future<void> showSettingsSheet(BuildContext context) {
  return showKustSheet<void>(context, builder: (_) => const _SettingsSheet());
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KustSheetHeader(title: 'Settings'),
        const KustSectionLabel('Appearance'),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: s.themeMode,
          builder: (_, mode, _) => KustSegmented<ThemeMode>(
            value: mode,
            options: const {
              ThemeMode.system: 'Auto',
              ThemeMode.light: 'Light',
              ThemeMode.dark: 'Dark',
            },
            onChanged: s.setThemeMode,
          ),
        ),
        const SizedBox(height: 24),
        const KustSectionLabel('Feedback'),
        ValueListenableBuilder<bool>(
          valueListenable: s.sound,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.volume_up_rounded,
            title: 'Sound effects',
            value: v,
            onChanged: s.setSound,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: s.haptics,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.vibration_rounded,
            title: 'Haptics',
            value: v,
            onChanged: s.setHaptics,
          ),
        ),
      ],
    );
  }
}
