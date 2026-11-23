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
    // Only what the switches show.
    ref.watch(
      chessControllerProvider.select(
        (g) => (
          g.evaluationEnabled,
          g.moveFeedbackEnabled,
          g.showBestEnabled,
          g.practiceMode,
          g.mode,
          g.moves.length,
          g.lineLength,
        ),
      ),
    );
    final game = ref.read(chessControllerProvider);
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
        if (game.practiceMode && game.mode != GameMode.local)
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
            // Not while an opening line is drilled: the player builds it
            // without help.
            subtitle: game.inLine
                ? context.t.showBestAfterLine
                : context.t.showBestSub,
            value: game.showBestEnabled && !game.inLine,
            onChanged: game.inLine ? null : controller.setShowBestEnabled,
          ),
      ],
    );
  }
}
