import 'package:flutter/material.dart';

import 'package:Kust/features/game/time_control.dart';
import 'package:Kust/ui/kust_button.dart';
import 'package:Kust/ui/kust_controls.dart';
import 'package:Kust/ui/kust_sheet.dart';

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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          children: [
            for (var i = 0; i < _options.length; i++)
              KustOption(
                title: _options[i].label,
                subtitle: _options[i].subtitle,
                selected: selected == i,
                trailing: const SizedBox.shrink(),
                onTap: () => setState(() => _selected = i),
              ),
          ],
        ),
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
