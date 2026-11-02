import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/widgets/piece_image.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/play/practice_mode_checkbox.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

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
                  Text(context.t.eloValue(bot.elo), style: k.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        KustSectionLabel(context.t.playAs),
        KustOption(
          title: context.t.whiteName,
          subtitle: context.t.youMoveFirst,
          leading: PieceImage(
            AppSettings.instance.pieceSet.value.asset('w', 'K'),
            width: 36,
            height: 36,
          ),
          selected: _side == Side.white,
          onTap: () => setState(() => _side = Side.white),
        ),
        const SizedBox(height: 8),
        KustOption(
          title: context.t.blackName,
          subtitle: context.t.botMovesFirst(bot.name),
          leading: PieceImage(
            AppSettings.instance.pieceSet.value.asset('b', 'K'),
            width: 36,
            height: 36,
          ),
          selected: _side == Side.black,
          onTap: () => setState(() => _side = Side.black),
        ),
        const SizedBox(height: 8),
        KustOption(
          title: context.t.random,
          subtitle: context.t.letFateDecide,
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
          label: context.t.play,
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
