import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/train/train_openings.dart';
import 'package:kust/features/train/train_practice.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/board_thumbnail.dart';

/// The Train tab: openings, defences, gambits and attacks to learn and to
/// practise against a bot from the end of one of their lines.
class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key});

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  String _query = '';
  OpeningKind? _kind;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final o in kTrainOpenings)
        if ((_kind == null || o.kind == _kind) &&
            (q.isEmpty ||
                o.en.toLowerCase().contains(q) ||
                o.ru.toLowerCase().contains(q) ||
                o.lines.any((l) => l.en.toLowerCase().contains(q))))
          o,
    ];
    return ColoredBox(
      color: k.bg,
      child: Column(
        children: [
          FeltHeader(title: t.navTrain),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                KustNavBar.clearance(context),
              ),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: k.body,
                  decoration: InputDecoration(
                    hintText: t.trainSearch,
                    prefixIcon: Icon(Icons.search_rounded, color: k.muted),
                    filled: true,
                    fillColor: k.surfaceAlt,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(KustSpace.rMedium),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final kind in [null, ...OpeningKind.values]) ...[
                        ChoiceChip(
                          label: Text(
                            kind == null ? t.trainAll : kindLabel(t, kind),
                          ),
                          selected: _kind == kind,
                          onSelected: (_) => setState(() => _kind = kind),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      t.trainNoResults,
                      textAlign: TextAlign.center,
                      style: k.body.copyWith(color: k.muted),
                    ),
                  ),
                for (final o in shown) ...[
                  _OpeningCard(opening: o),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One opening: its main line on a board, name, kind, where its name comes
/// from, a short description, how many of its lines were practised, and a
/// way to practise the first one at once.
class _OpeningCard extends StatelessWidget {
  const _OpeningCard({required this.opening});

  final TrainOpening opening;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final main = opening.lines.first;
    return Semantics(
      button: true,
      label: '${opening.nameIn(t)}, ${kindLabel(t, opening.kind)}',
      child: Pressable(
        onTap: () => context.push('/train/${opening.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: k.surface,
            borderRadius: BorderRadius.circular(KustSpace.rCard),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 132,
                child: BoardThumbnail(
                  position: main.positions.last,
                  flipped: opening.side == Side.black,
                  highlight: main.lastSquares,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opening.nameIn(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k.body.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _KindChip(kind: opening.kind),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${opening.originIn(t)} ${opening.flag}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: k.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      opening.descriptionIn(t),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: k.caption.copyWith(color: k.muted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          t.trainLines(opening.lines.length),
                          style: k.caption.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: LineProgress(opening: opening)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Pressable(
                      onTap: () => practiseLine(context, opening, 0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                t.trainTryFirst,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: k.body.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: k.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: k.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The kind of an opening as a small coloured label.
class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind});

  final OpeningKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kindColor(kind),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        kindLabel(context.t, kind).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// One bar per line of [opening], lit once the line has been practised.
class LineProgress extends StatelessWidget {
  const LineProgress({super.key, required this.opening});

  final TrainOpening opening;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    Widget bars() => Row(
      children: [
        for (var i = 0; i < opening.lines.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: TrainProgress.instance.tried(opening, i)
                    ? k.accent
                    : k.surfaceAlt,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
    if (!AppStorage.isReady) return bars();
    return ValueListenableBuilder(
      valueListenable: TrainProgress.instance.listenable(),
      builder: (context, _, _) => bars(),
    );
  }
}
