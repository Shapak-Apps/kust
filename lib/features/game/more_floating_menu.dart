import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Kust/features/game/chess/chess_controller.dart';
import 'package:Kust/ui/kust_controls.dart';
import 'package:Kust/ui/kust_sheet.dart';

/// In-game options. Kept under its old name; now a Kust sheet.
class MoreFloatingMenu extends ConsumerWidget {
  const MoreFloatingMenu({super.key});

  static Future<void> show(BuildContext context) {
    return showKustSheet<void>(
      context,
      builder: (_) => const MoreFloatingMenu(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(chessControllerProvider);
    final controller = ref.read(chessControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KustSheetHeader(title: 'Game options'),
        KustToggleRow(
          icon: Icons.align_horizontal_left_rounded,
          title: 'Evaluation bar',
          subtitle: 'Shows who is better',
          value: game.evaluationEnabled,
          onChanged: controller.setEvaluationEnabled,
        ),
        if (game.practiceMode)
          KustToggleRow(
            icon: Icons.insights_rounded,
            title: 'Move feedback',
            subtitle: 'Rates each move you play',
            value: game.moveFeedbackEnabled,
            onChanged: controller.setMoveFeedbackEnabled,
          ),
      ],
    );
  }
}
