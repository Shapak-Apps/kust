import 'package:flutter/material.dart';

import 'package:kust/features/game/time_control.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_controls.dart';

/// The clock choices for a game against a bot.
const List<TimeControl> kBotTimeControls = [
  TimeControl(baseMinutes: 3, incrementSeconds: 2),
  TimeControl(baseMinutes: 5),
  TimeControl(baseMinutes: 10),
];

/// "Time control": no clock, or one of [kBotTimeControls].
class BotTimeRow extends StatelessWidget {
  const BotTimeRow({super.key, required this.value, required this.onChanged});

  final TimeControl? value;
  final ValueChanged<TimeControl?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KustSectionLabel(t.timeControl),
        KustSegmented<TimeControl?>(
          value: value,
          options: {
            null: t.noClock,
            for (final tc in kBotTimeControls) tc: tc.labelIn(t),
          },
          onChanged: onChanged,
        ),
      ],
    );
  }
}
