import 'package:flutter/material.dart';

import 'package:Kust/features/game/time_control.dart';

class PickTimeControlModal extends StatelessWidget {
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

  void _pick(BuildContext context, TimeControl? timeControl) {
    Navigator.of(context).pop();
    onPick(timeControl);
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
                    label: '10 min',
                    subtitle: '10+0',
                    onTap: () =>
                        _pick(context, const TimeControl(baseMinutes: 10)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeTile(
                    label: '15 min',
                    subtitle: '15+0',
                    onTap: () =>
                        _pick(context, const TimeControl(baseMinutes: 15)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: '3+2',
                    subtitle: '3 min, +2s per move',
                    onTap: () => _pick(
                      context,
                      const TimeControl(baseMinutes: 3, incrementSeconds: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeTile(
                    label: '5 min',
                    subtitle: '5+0',
                    onTap: () =>
                        _pick(context, const TimeControl(baseMinutes: 5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TimeTile(
              label: 'No clock',
              subtitle: 'Untimed casual game',
              onTap: () => _pick(context, null),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
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
