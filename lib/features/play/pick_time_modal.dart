import 'package:flutter/material.dart';

import 'package:kust/features/game/time_control.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/features/play/bot_time_row.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/l10n/app_locale.dart';

class PickTimeControlModal extends StatefulWidget {
  const PickTimeControlModal({super.key, required this.onPick});

  final void Function(TimeControl? timeControl) onPick;

  static Future<void> show(
    BuildContext context, {
    required void Function(TimeControl? timeControl) onPick,
  }) {
    return showKustSheet<void>(
      context,
      builder: (_) => PickTimeControlModal(onPick: onPick),
    );
  }

  @override
  State<PickTimeControlModal> createState() => _PickTimeControlModalState();
}

class _PickTimeControlModalState extends State<PickTimeControlModal> {
  // The same row and choices as against a bot or a friend.
  TimeControl? _time = kTimeControls[1];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KustSheetHeader(
          title: context.t.timeControl,
          subtitle: context.t.timeControlSub,
        ),
        TimeControlRow(
          value: _time,
          onChanged: (v) => setState(() => _time = v),
        ),
        const SizedBox(height: 16),
        KustButton(
          label: context.t.startGame,
          onTap: () {
            Navigator.of(context).pop();
            widget.onPick(_time);
          },
        ),
      ],
    );
  }
}
