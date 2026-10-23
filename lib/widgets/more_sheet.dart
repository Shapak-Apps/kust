import 'package:flutter/material.dart';

import 'package:Kust/core/settings.dart';
import 'package:Kust/ui/kust_controls.dart';
import 'package:Kust/ui/kust_sheet.dart';

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
