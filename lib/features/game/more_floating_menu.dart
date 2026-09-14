import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Kust/features/game/chess/chess_controller.dart';

class MoreFloatingMenu extends ConsumerWidget {
  const MoreFloatingMenu({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) => const MoreFloatingMenu(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(chessControllerProvider);
    final double bottomNavHeight = MediaQuery.of(context).padding.bottom + 88;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          right: 16,
          bottom: bottomNavHeight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 230,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.analytics_outlined, size: 20),
                      title: const Text(
                        'Evaluation bar',
                        style: TextStyle(fontSize: 14),
                      ),
                      trailing: Checkbox(
                        value: gameState.evaluationEnabled,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (v) => ref
                            .read(chessControllerProvider.notifier)
                            .setEvaluationEnabled(v ?? false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
