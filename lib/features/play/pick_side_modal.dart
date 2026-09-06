import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Kust/features/play/pick_opponent_modal.dart';

class PickSideModal extends StatefulWidget {
  const PickSideModal({super.key, required this.bot, required this.onPlay});

  final Bot bot;
  final void Function(Side side) onPlay;

  static Future<void> show(
    BuildContext context, {
    required Bot bot,
    required void Function(Side side) onPlay,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PickSideModal(bot: bot, onPlay: onPlay);
      },
    );
  }

  @override
  State<PickSideModal> createState() => _PickSideModalState();
}

class _PickSideModalState extends State<PickSideModal> {
  Side? selectedSide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.bot.imagePath,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.bot.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.bot.elo} Elo',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('Play as', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 10),

            _SideOption(
              label: 'White',
              leading: SvgPicture.asset(
                'assets/pieces/wK.svg',
                width: 28,
                height: 28,
              ),
              isSelected: selectedSide == Side.white,
              onTap: () {
                setState(() {
                  selectedSide = Side.white;
                });
              },
            ),
            const SizedBox(height: 8),

            _SideOption(
              label: 'Black',
              leading: SvgPicture.asset(
                'assets/pieces/bK.svg',
                width: 28,
                height: 28,
              ),
              isSelected: selectedSide == Side.black,
              onTap: () {
                setState(() {
                  selectedSide = Side.black;
                });
              },
            ),
            const SizedBox(height: 8),

            _SideOption(
              label: 'Random',
              leading: const Icon(Icons.shuffle_rounded),
              isSelected: selectedSide == null,
              onTap: () {
                setState(() {
                  selectedSide = null;
                });
              },
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final side =
                      selectedSide ??
                      (Random().nextBool() ? Side.white : Side.black);

                  Navigator.of(context).pop();
                  widget.onPlay(side);
                },
                child: const Text(
                  'Play',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideOption extends StatelessWidget {
  const _SideOption({
    required this.label,
    required this.leading,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
