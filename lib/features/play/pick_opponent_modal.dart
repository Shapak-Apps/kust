import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:Kust/features/play/practice_mode_checkbox.dart';

class Bot {
  final String name;
  final int elo;
  final String imagePath;
  final bool isTkm;

  const Bot({
    required this.name,
    required this.elo,
    required this.imagePath,
    this.isTkm = false,
  });
}

class PickOpponentModal extends StatefulWidget {
  const PickOpponentModal({super.key, required this.onPlay});

  final void Function(Bot bot, Side side, bool practiceMode) onPlay;

  static Future<void> show(
    BuildContext context, {
    required void Function(Bot bot, Side side, bool practiceMode) onPlay,
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
  final List<Bot> internationalBots = const [
    Bot(name: 'Elizabeth', elo: 600, imagePath: 'assets/bots/Elizabeth.png'),
    Bot(name: 'Mark', elo: 700, imagePath: 'assets/bots/Mark.png'),
    Bot(name: 'Apex', elo: 800, imagePath: 'assets/bots/Apex.png'),
    Bot(name: 'Karl', elo: 1000, imagePath: 'assets/bots/Karl.png'),
    Bot(name: 'Maya', elo: 1200, imagePath: 'assets/bots/Maya.png'),
    Bot(name: 'Yura', elo: 1400, imagePath: 'assets/bots/Yura.png'),
  ];

  final List<Bot> tkmBots = const [
    Bot(
      name: 'Bahar',
      elo: 400,
      imagePath: 'assets/bots/Bahar.png',
      isTkm: true,
    ),
    Bot(
      name: 'Enejan',
      elo: 1000,
      imagePath: 'assets/bots/Enejan.png',
      isTkm: true,
    ),
    Bot(
      name: 'Berdi',
      elo: 2000,
      imagePath: 'assets/bots/Berdi.png',
      isTkm: true,
    ),
  ];

  late final List<Bot> bots = [...internationalBots, ...tkmBots];

  final ScrollController _scrollController = ScrollController();

  int? selectedIndex;
  Side? selectedSide;
  bool practiceMode = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onBotSelected(int index) {
    setState(() {
      selectedIndex = index;
    });

    // Auto scroll down to show options and the Play button after selecting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

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
        child: SingleChildScrollView(
          controller: _scrollController,
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
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pick opponent',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: internationalBots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final bot = internationalBots[index];
                  return _BotTile(
                    bot: bot,
                    isSelected: selectedIndex == index,
                    onTap: () => _onBotSelected(index),
                  );
                },
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'New students from Turkmenistan want to challenge you',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tkmBots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final bot = tkmBots[index];
                  final globalIndex = internationalBots.length + index;
                  return _BotTile(
                    bot: bot,
                    isSelected: selectedIndex == globalIndex,
                    onTap: () => _onBotSelected(globalIndex),
                  );
                },
              ),

              const SizedBox(height: 12),
              PracticeModeCheckbox(
                value: practiceMode,
                onChanged: (v) => setState(() => practiceMode = v),
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

              const SizedBox(height: 20),

              // Remade Play Button with enhanced UI state
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: selectedIndex == null
                      ? null
                      : () {
                          final bot = bots[selectedIndex!];
                          final side =
                              selectedSide ??
                              (Random().nextBool() ? Side.white : Side.black);

                          Navigator.of(context).pop();
                          widget.onPlay(bot, side, practiceMode);
                        },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    selectedIndex != null
                        ? 'Play against ${bots[selectedIndex!].name}'
                        : 'Select an opponent',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotTile extends StatelessWidget {
  const _BotTile({
    required this.bot,
    required this.isSelected,
    required this.onTap,
  });

  final Bot bot;
  final bool isSelected;
  final VoidCallback onTap;

  static const double flagSize = 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Image.asset(bot.imagePath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    bot.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                if (bot.isTkm) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(flagSize / 2),
                    child: Image.asset(
                      'assets/icons/TKM.webp',
                      width: flagSize,
                      height: flagSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${bot.elo} Elo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
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
