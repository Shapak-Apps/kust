import 'package:flutter/material.dart';

import 'package:kust/ui/kust_controls.dart';

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
      title: 'Practice mode',
      subtitle: 'Allows undo, hints and move feedback',
      value: value,
      onChanged: onChanged,
    );
  }
}
