import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/core/settings.dart';
import 'package:kust/widgets/piece_image.dart';

import 'package:kust/features/game/time_control.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_controls.dart';

/// The clock choices, the same everywhere a game is set up: against a
/// bot, on one phone, or a friend online.
const List<TimeControl> kTimeControls = [
  TimeControl(baseMinutes: 3, incrementSeconds: 2),
  TimeControl(baseMinutes: 5),
  TimeControl(baseMinutes: 10),
];

/// "Time control": one of [kTimeControls], or no clock where that is
/// allowed (not online, where both clocks must run). One picker for every
/// kind of game.
class TimeControlRow extends StatelessWidget {
  const TimeControlRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowNoClock = true,
  });

  final TimeControl? value;
  final ValueChanged<TimeControl?> onChanged;
  final bool allowNoClock;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KustSectionLabel(t.timeControl),
        KustSegmented<TimeControl?>(
          value: value,
          options: {
            if (allowNoClock) null: t.noClock,
            for (final tc in kTimeControls) tc: tc.labelIn(t),
          },
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// "Play as": White, Black or Random, the same cards wherever a game is
/// set up. [opponent] names who moves first when you are Black.
class SidePicker extends StatelessWidget {
  const SidePicker({
    super.key,
    required this.side,
    required this.onChanged,
    required this.opponent,
  });

  /// Null means random.
  final Side? side;
  final ValueChanged<Side?> onChanged;
  final String opponent;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final pieces = AppSettings.instance.pieceSet.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KustSectionLabel(t.playAs),
        KustOption(
          title: t.whiteName,
          subtitle: t.youMoveFirst,
          leading: PieceImage(pieces.asset('w', 'K'), width: 36, height: 36),
          selected: side == Side.white,
          onTap: () => onChanged(Side.white),
        ),
        const SizedBox(height: 8),
        KustOption(
          title: t.blackName,
          subtitle: t.botMovesFirst(opponent),
          leading: PieceImage(pieces.asset('b', 'K'), width: 36, height: 36),
          selected: side == Side.black,
          onTap: () => onChanged(Side.black),
        ),
        const SizedBox(height: 8),
        KustOption(
          title: t.random,
          subtitle: t.letFateDecide,
          leading: const KustIconTile(
            Icons.shuffle_rounded,
            color: Color(0xFFB78CF2),
          ),
          selected: side == null,
          onTap: () => onChanged(null),
        ),
      ],
    );
  }
}
