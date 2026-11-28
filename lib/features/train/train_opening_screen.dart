import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/train/train_openings.dart';
import 'package:kust/features/train/train_practice.dart';
import 'package:kust/features/train/train_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/static_board.dart';

/// One opening up close: its lines to step through move by move, what it
/// is about, and a button to practise the chosen line against a bot.
class TrainOpeningScreen extends StatefulWidget {
  const TrainOpeningScreen({super.key, required this.id});

  final String id;

  @override
  State<TrainOpeningScreen> createState() => _TrainOpeningScreenState();
}

class _TrainOpeningScreenState extends State<TrainOpeningScreen> {
  late final TrainOpening _o = kTrainOpenings.firstWhere(
    (o) => o.id == widget.id,
    orElse: () => kTrainOpenings.first,
  );
  int _line = 0;

  /// How many moves of the line are on the board; all of them at first.
  late int _ply = _o.lines.first.san.length;

  void _pickLine(int i) => setState(() {
    _line = i;
    _ply = _o.lines[i].san.length;
  });

  void _go(int ply) =>
      setState(() => _ply = ply.clamp(0, _o.lines[_line].san.length));

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final line = _o.lines[_line];
    final positions = line.positions;
    Move? last;
    if (_ply > 0) last = positions[_ply - 1].parseSan(line.san[_ply - 1]);
    final ordinals = [t.trainMainLine, t.trainSecondLine, t.trainThirdLine];

    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          FeltHeader(
            title: _o.nameIn(t),
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/train'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Edge to edge, like the board in a game.
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: StaticBoard(
                      position: positions[_ply],
                      flipped: _o.side == Side.black,
                      highlight: last is NormalMove
                          ? [last.from, last.to]
                          : const [],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: t.toStart,
                            onPressed: _ply == 0 ? null : () => _go(0),
                            icon: const Icon(Icons.first_page_rounded),
                          ),
                          IconButton(
                            tooltip: t.back,
                            onPressed: _ply == 0 ? null : () => _go(_ply - 1),
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 32,
                            ),
                          ),
                          IconButton(
                            tooltip: t.forward,
                            onPressed: _ply == line.san.length
                                ? null
                                : () => _go(_ply + 1),
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              size: 32,
                            ),
                          ),
                          IconButton(
                            tooltip: t.toEnd,
                            onPressed: _ply == line.san.length
                                ? null
                                : () => _go(line.san.length),
                            icon: const Icon(Icons.last_page_rounded),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (var i = 0; i < line.san.length; i++)
                            Pressable(
                              onTap: () => _go(i + 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: i + 1 == _ply
                                      ? k.accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${i.isEven ? '${i ~/ 2 + 1}. ' : ''}${line.san[i]}',
                                  style: k.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: i + 1 == _ply
                                        ? k.accentInk
                                        : i < _ply
                                        ? k.ink
                                        : k.muted,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      for (var i = 0; i < _o.lines.length; i++) ...[
                        _LineChoice(
                          title: ordinals[i],
                          name: _o.lines[i].nameIn(t),
                          selected: i == _line,
                          onTap: () => _pickLine(i),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 12),
                      Text(_o.descriptionIn(t), style: k.body),
                      const SizedBox(height: 8),
                      Text(
                        '${t.trainOrigin(_o.originIn(t))} ${_o.flag}',
                        style: k.caption,
                      ),
                      const SizedBox(height: 12),
                      LineProgress(opening: _o),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: KustButton(
                label: t.trainPractise(trainBot().name),
                icon: Icons.play_arrow_rounded,
                onTap: () => practiseLine(context, _o, _line),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A line to pick: "Main line" over its name, the picked one outlined.
class _LineChoice extends StatelessWidget {
  const _LineChoice({
    required this.title,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $name',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: squircle(
            KustSpace.rCard,
            color: k.surface,
            side: BorderSide(
              color: selected ? k.accent : k.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: k.caption),
                    Text(
                      name,
                      style: k.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? k.accent : k.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
