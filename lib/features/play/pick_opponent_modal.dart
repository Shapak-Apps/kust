import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

class Bot {
  final String name;
  final int elo;
  final String imagePath;

  const Bot({required this.name, required this.elo, required this.imagePath});
}

class PickOpponentModal extends StatefulWidget {
  const PickOpponentModal({super.key, required this.onPlay});

  final void Function(Bot bot, Side side) onPlay;

  static Future<void> show(
    BuildContext context, {
    required void Function(Bot bot, Side side) onPlay,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PickOpponentModal(onPlay: onPlay);
      },
    );
  }

  @override
  State<PickOpponentModal> createState() => _PickOpponentModalState();
}

class _PickOpponentModalState extends State<PickOpponentModal> {
  final List<Bot> bots = const [
    Bot(name: 'Apex', elo: 800, imagePath: 'assets/bots/Apex.png'),
    Bot(name: 'Karl', elo: 1000, imagePath: 'assets/bots/Karl.png'),
    Bot(name: 'Maya', elo: 1200, imagePath: 'assets/bots/Maya.png'),
    Bot(name: 'Yura', elo: 1400, imagePath: 'assets/bots/Yura.png'),
  ];

  int? selectedIndex;
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

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pick opponent',
                style: theme.textTheme.headlineMedium,
              ),
            ),

            const SizedBox(height: 20),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final bot = bots[index];
                final isSelected = selectedIndex == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: Image.asset(
                              bot.imagePath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(bot.name, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          '${bot.elo} Elo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('Play as', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _SideChoiceChip(
                  label: 'White',
                  isSelected: selectedSide == Side.white,
                  onTap: () => setState(() => selectedSide = Side.white),
                ),
                const SizedBox(width: 8),
                _SideChoiceChip(
                  label: 'Black',
                  isSelected: selectedSide == Side.black,
                  onTap: () => setState(() => selectedSide = Side.black),
                ),
                const SizedBox(width: 8),
                _SideChoiceChip(
                  label: 'Random',
                  isSelected: selectedSide == null,
                  onTap: () => setState(() => selectedSide = null),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: selectedIndex == null
                    ? null
                    : () {
                        final bot = bots[selectedIndex!];
                        final side =
                            selectedSide ??
                            (Random().nextBool() ? Side.white : Side.black);

                        Navigator.of(context).pop();
                        widget.onPlay(bot, side);
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

class _SideChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
