import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/core/settings.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/play/practice_mode_checkbox.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/tokens.dart';

class PickSideModal extends StatefulWidget {
  const PickSideModal({super.key, required this.bot, required this.onPlay});

  final Bot bot;
  final void Function(Side side, bool practiceMode) onPlay;

  static Future<void> show(
    BuildContext context, {
    required Bot bot,
    required void Function(Side side, bool practiceMode) onPlay,
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
                  Text('${bot.elo} Elo', style: k.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const KustSectionLabel('Play as'),
        KustOption(
          title: 'White',
          subtitle: 'You move first',
          leading: SvgPicture.asset(
            AppSettings.instance.pieceSet.value.asset('w', 'K'),
            width: 36,
            height: 36,
          ),
          selected: _side == Side.white,
          onTap: () => setState(() => _side = Side.white),
        ),
        const SizedBox(height: 8),
        KustOption(
          title: 'Black',
          subtitle: '${bot.name} moves first',
          leading: SvgPicture.asset(
            AppSettings.instance.pieceSet.value.asset('b', 'K'),
            width: 36,
            height: 36,
          ),
          selected: _side == Side.black,
          onTap: () => setState(() => _side = Side.black),
        ),
        const SizedBox(height: 8),
        KustOption(
          title: 'Random',
          subtitle: 'Let fate decide',
          leading: const KustIconTile(Icons.shuffle_rounded),
          selected: _side == null,
          onTap: () => setState(() => _side = null),
        ),
        const SizedBox(height: 8),
        PracticeModeCheckbox(
          value: _practice,
          onChanged: (v) => setState(() => _practice = v),
        ),
        const SizedBox(height: 16),
        KustButton(
          label: 'Play',
          onTap: () {
            final side =
                _side ?? (Random().nextBool() ? Side.white : Side.black);
            Navigator.of(context).pop();
            widget.onPlay(side, _practice);
          },
        ),
      ],
    );
  }
}
