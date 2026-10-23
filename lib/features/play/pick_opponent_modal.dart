import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:Kust/features/play/bot_card.dart';
import 'package:Kust/features/play/bots.dart';
import 'package:Kust/features/play/practice_mode_checkbox.dart';
import 'package:Kust/ui/kust_button.dart';
import 'package:Kust/ui/kust_controls.dart';
import 'package:Kust/ui/kust_sheet.dart';

export 'package:Kust/features/play/bots.dart';

class PickOpponentModal extends StatefulWidget {
  const PickOpponentModal({super.key, required this.onPlay});

  final void Function(Bot bot, Side side, bool practiceMode) onPlay;

  static Future<void> show(
    BuildContext context, {
    required void Function(Bot bot, Side side, bool practiceMode) onPlay,
  }) {
    return showKustSheet<void>(
      context,
      builder: (_) => PickOpponentModal(onPlay: onPlay),
    );
  }

  @override
  State<PickOpponentModal> createState() => _PickOpponentModalState();
}

class _PickOpponentModalState extends State<PickOpponentModal> {
  Bot? _bot;
  Side? _side; // null = random
  bool _practice = false;

  Widget _grid(List<Bot> bots) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.92,
      children: [
        for (final bot in bots)
          BotCard(
            bot: bot,
            selected: _bot?.id == bot.id,
            onTap: () => setState(() => _bot = bot),
          ),
      ],
    );
  }

  void _play() {
    final bot = _bot;
    if (bot == null) return;
    final side = _side ?? (Random().nextBool() ? Side.white : Side.black);
    Navigator.of(context).pop();
    widget.onPlay(bot, side, _practice);
  }

  @override
  Widget build(BuildContext context) {
    final bot = _bot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KustSheetHeader(
          title: 'Pick opponent',
          subtitle: 'Elo shows how strong they play',
        ),
        _grid(kInternationalBots),
        const SizedBox(height: 24),
        const KustSectionLabel('New students from Turkmenistan'),
        _grid(kTkmBots),
        const SizedBox(height: 24),
        const KustSectionLabel('Play as'),
        KustSegmented<Side?>(
          value: _side,
          options: const {
            Side.white: 'White',
            Side.black: 'Black',
            null: 'Random',
          },
          onChanged: (v) => setState(() => _side = v),
        ),
        const SizedBox(height: 8),
        PracticeModeCheckbox(
          value: _practice,
          onChanged: (v) => setState(() => _practice = v),
        ),
        const SizedBox(height: 16),
        KustButton(
          label: bot == null ? 'Select an opponent' : 'Play ${bot.name}',
          onTap: bot == null ? null : _play,
        ),
      ],
    );
  }
}
