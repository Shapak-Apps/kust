import 'package:flutter/material.dart';

import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/tokens.dart';

class PlayModeModal extends StatelessWidget {
  const PlayModeModal({super.key, required this.onBots, required this.onLocal});

  final VoidCallback onBots;
  final VoidCallback onLocal;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onBots,
    required VoidCallback onLocal,
  }) {
    return showKustSheet<void>(
      context,
      builder: (_) => PlayModeModal(onBots: onBots, onLocal: onLocal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    Widget chevron() => Icon(Icons.chevron_right_rounded, color: k.muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KustSheetHeader(title: 'New game'),
        KustOption(
          leading: const KustIconTile(Icons.smart_toy_outlined),
          title: 'Play with bots',
          subtitle: 'Challenge one of our bots',
          trailing: chevron(),
          onTap: () {
            Navigator.of(context).pop();
            onBots();
          },
        ),
        const SizedBox(height: 8),
        KustOption(
          leading: const KustIconTile(Icons.people_outline_rounded),
          title: 'Play locally',
          subtitle: 'Pass & play on this device',
          trailing: chevron(),
          onTap: () {
            Navigator.of(context).pop();
            onLocal();
          },
        ),
      ],
    );
  }
}
