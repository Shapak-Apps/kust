import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/l10n/app_locale.dart';

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
        KustSheetHeader(title: context.t.gameOptions),
        KustToggleRow(
          icon: Icons.align_horizontal_left_rounded,
          title: context.t.evalBar,
          subtitle: context.t.evalBarSub,
          value: game.evaluationEnabled,
          onChanged: controller.setEvaluationEnabled,
        ),
        if (game.practiceMode)
          KustToggleRow(
            icon: Icons.insights_rounded,
            title: context.t.moveFeedback,
            subtitle: context.t.moveFeedbackSub,
            value: game.moveFeedbackEnabled,
            onChanged: controller.setMoveFeedbackEnabled,
          ),
        if (game.practiceMode)
          KustToggleRow(
            icon: Icons.north_east_rounded,
            title: context.t.showBest,
            subtitle: context.t.showBestSub,
            value: game.showBestEnabled,
            onChanged: controller.setShowBestEnabled,
          ),
      ],
    );
  }
}
