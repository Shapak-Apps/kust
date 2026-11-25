import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/features/game/time_control.dart';
import 'package:kust/features/play/bot_time_row.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/play/practice_mode_checkbox.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

class PickSideModal extends StatefulWidget {
  const PickSideModal({super.key, required this.bot, required this.onPlay});

  final Bot bot;
  final void Function(Side side, bool practiceMode, TimeControl? timeControl)
  onPlay;

  static Future<void> show(
    BuildContext context, {
    required Bot bot,
    required void Function(
      Side side,
      bool practiceMode,
      TimeControl? timeControl,
    )
    onPlay,
  }) {
    return showKustSheet<void>(
      context,
      builder: (_) => PickSideModal(bot: bot, onPlay: onPlay),
    );
  }

  @override
  State<PickSideModal> createState() => _PickSideModalState();
}

class _PickSideModalState extends State<PickSideModal> {
  Side? _side; // null = random
  bool _practice = false;
  TimeControl? _time;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final bot = widget.bot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(KustSpace.rMedium),
              child: Image.asset(
                bot.imagePath,
                width: 56,
                height: 56,
                cacheWidth: 168,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bot.name, style: k.title),
                  Text(context.t.eloValue(bot.elo), style: k.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SidePicker(
          side: _side,
          opponent: bot.name,
          onChanged: (v) => setState(() => _side = v),
        ),
        const SizedBox(height: 16),
        TimeControlRow(
          value: _time,
          onChanged: (v) => setState(() => _time = v),
        ),
        const SizedBox(height: 8),
        PracticeModeCheckbox(
          value: _practice,
          onChanged: (v) => setState(() => _practice = v),
        ),
        const SizedBox(height: 16),
        KustButton(
          label: context.t.play,
          onTap: () {
            final side =
                _side ?? (Random().nextBool() ? Side.white : Side.black);
            Navigator.of(context).pop();
            widget.onPlay(side, _practice, _time);
          },
        ),
      ],
    );
  }
}
