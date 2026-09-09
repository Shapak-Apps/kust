import 'package:flutter/material.dart';

import 'package:Kust/features/game/time_control.dart';

class PickTimeControlModal extends StatefulWidget {
  const PickTimeControlModal({super.key, required this.onPick});

  final void Function(TimeControl? timeControl) onPick;

  static Future<void> show(
    BuildContext context, {
    required void Function(TimeControl? timeControl) onPick,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PickTimeControlModal(onPick: onPick),
    );
  }

  @override
  State<PickTimeControlModal> createState() => _PickTimeControlModalState();
}

class _PickTimeControlModalState extends State<PickTimeControlModal> {
  int? _selectedIndex;

  static const List<_Option> _options = [
    _Option(
      label: '10 min',
      subtitle: '10+0',
      timeControl: TimeControl(baseMinutes: 10),
    ),
    _Option(
      label: '15 min',
      subtitle: '15+0',
      timeControl: TimeControl(baseMinutes: 15),
    ),
    _Option(
      label: '3+2',
      subtitle: '3 min, +2s per move',
      timeControl: TimeControl(baseMinutes: 3, incrementSeconds: 2),
    ),
    _Option(
      label: '5 min',
      subtitle: '5+0',
      timeControl: TimeControl(baseMinutes: 5),
    ),
    _Option(
      label: 'No clock',
      subtitle: 'Untimed casual game',
      timeControl: null,
    ),
  ];

  void _start() {
    if (_selectedIndex == null) return;
    Navigator.of(context).pop();
    widget.onPick(_options[_selectedIndex!].timeControl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = _selectedIndex != null;

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
                'Pick time control',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: _options[0].label,
                    subtitle: _options[0].subtitle,
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeTile(
                    label: _options[1].label,
                    subtitle: _options[1].subtitle,
                    isSelected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: _options[2].label,
                    subtitle: _options[2].subtitle,
                    isSelected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeTile(
                    label: _options[3].label,
                    subtitle: _options[3].subtitle,
                    isSelected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TimeTile(
              label: _options[4].label,
              subtitle: _options[4].subtitle,
              isSelected: _selectedIndex == 4,
              onTap: () => setState(() => _selectedIndex = 4),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: hasSelection ? _start : null,
                child: const Text(
                  'Start game',
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

class _Option {
  const _Option({
    required this.label,
    required this.subtitle,
    required this.timeControl,
  });

  final String label;
  final String subtitle;
  final TimeControl? timeControl;
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
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
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
