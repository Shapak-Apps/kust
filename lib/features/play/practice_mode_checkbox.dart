import 'package:flutter/material.dart';

import 'package:kust/ui/kust_controls.dart';
import 'package:kust/l10n/app_locale.dart';

class PracticeModeCheckbox extends StatelessWidget {
  const PracticeModeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return KustToggleRow(
      icon: Icons.school_outlined,
      title: context.t.practiceMode,
      subtitle: context.t.practiceModeSub,
      value: value,
      onChanged: onChanged,
    );
  }
}
