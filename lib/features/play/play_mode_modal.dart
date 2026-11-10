import 'package:flutter/material.dart';

import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

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
        KustSheetHeader(title: context.t.newGame),
        KustOption(
          leading: const KustIconTile(
            Icons.smart_toy_rounded,
            color: Color(0xFFFFBB00),
          ),
          title: context.t.playWithBots,
          subtitle: context.t.playWithBotsSub,
          trailing: chevron(),
          onTap: () {
            Navigator.of(context).pop();
            onBots();
          },
        ),
        const SizedBox(height: 8),
        KustOption(
          leading: const KustIconTile(
            Icons.people_rounded,
            color: Color(0xFF3CB77C),
          ),
          title: context.t.playLocally,
          subtitle: context.t.playLocallySub,
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
