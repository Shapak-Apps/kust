import 'package:flutter/material.dart';

import 'package:kust/features/game/time_control.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';

class PickTimeControlModal extends StatefulWidget {
  const PickTimeControlModal({super.key, required this.onPick});

  final void Function(TimeControl? timeControl) onPick;

  static Future<void> show(
    BuildContext context, {
    required void Function(TimeControl? timeControl) onPick,
  }) {
    return showKustSheet<void>(
      context,
      builder: (_) => PickTimeControlModal(onPick: onPick),
    );
  }

  @override
  State<PickTimeControlModal> createState() => _PickTimeControlModalState();
}

class _Option {
  const _Option(this.label, this.subtitle, this.timeControl);

  final String label;
  final String subtitle;
  final TimeControl? timeControl;
}

class _PickTimeControlModalState extends State<PickTimeControlModal> {
  int? _selected;

  static const List<_Option> _options = [
    _Option('3+2', 'Blitz', TimeControl(baseMinutes: 3, incrementSeconds: 2)),
    _Option('5 min', 'Blitz', TimeControl(baseMinutes: 5)),
    _Option('10 min', 'Rapid', TimeControl(baseMinutes: 10)),
    _Option('15 min', 'Rapid', TimeControl(baseMinutes: 15)),
  ];

  void _start(TimeControl? tc) {
    Navigator.of(context).pop();
    widget.onPick(tc);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KustSheetHeader(
          title: 'Time control',
          subtitle: 'How long does each player get?',
        ),
        // Two per row, as tall as their text needs: a fixed aspect ratio
        // cut the subtitle off with larger fonts.
        for (var row = 0; row < _options.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = row; i < row + 2; i++) ...[
                  if (i > row) const SizedBox(width: 8),
                  Expanded(
                    child: i < _options.length
                        ? KustOption(
                            title: _options[i].label,
                            subtitle: _options[i].subtitle,
                            selected: selected == i,
                            trailing: const SizedBox.shrink(),
                            onTap: () => setState(() => _selected = i),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        KustOption(
          title: 'No clock',
          subtitle: 'Untimed casual game',
          leading: const KustIconTile(Icons.all_inclusive_rounded),
          selected: selected == _options.length,
          onTap: () => setState(() => _selected = _options.length),
        ),
        const SizedBox(height: 16),
        KustButton(
          label: 'Start game',
          onTap: selected == null
              ? null
              : () => _start(
                  selected == _options.length
                      ? null
                      : _options[selected].timeControl,
                ),
        ),
      ],
    );
  }
}
