import 'package:flutter/material.dart';

import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/features/puzzles/gol.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/tokens.dart';

/// Shows the göl of a level that has just been woven, knot row by knot row
/// from the bottom, the way the carpet itself is made.
Future<void> showWovenDialog(
  BuildContext context, {
  required GolKind gol,
  required String tribe,
  required int knots,
  required String? nextTribe,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(
          begin: 0.92,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    ),
    pageBuilder: (context, _, _) => Center(
      child: WovenCard(
        gol: gol,
        tribe: tribe,
        knots: knots,
        nextTribe: nextTribe,
        onContinue: () => Navigator.of(context).pop(),
      ),
    ),
  );
}

/// The card of the celebration, apart from the dialog so tests can show it.
class WovenCard extends StatefulWidget {
  const WovenCard({
    super.key,
    required this.gol,
    required this.tribe,
    required this.knots,
    required this.nextTribe,
    required this.onContinue,
  });

  final GolKind gol;
  final String tribe;
  final int knots;

  /// The göl that comes next, or null when this was the last one.
  final String? nextTribe;
  final VoidCallback onContinue;

  @override
  State<WovenCard> createState() => _WovenCardState();
}

class _WovenCardState extends State<WovenCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _weave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _weave.forward();
    SoundService.instance.playJingle('promote.wav');
    SoundService.instance.buzz(heavy: true);
  }

  @override
  void dispose() {
    _weave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final next = widget.nextTribe;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(KustSpace.rLarge),
          border: Border.all(color: k.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: '${widget.tribe} göl, woven',
              child: AspectRatio(
                aspectRatio: 1.25,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: LoomColors.wool,
                    borderRadius: BorderRadius.circular(KustSpace.rMedium),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: AnimatedBuilder(
                      animation: _weave,
                      builder: (context, _) => CustomPaint(
                        painter: GolPainter(
                          kind: widget.gol,
                          woven: Curves.easeInOut.transform(_weave.value),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.tribe} göl woven',
              textAlign: TextAlign.center,
              style: k.title,
            ),
            const SizedBox(height: 6),
            Text(
              next == null
                  ? '${widget.knots} of ${widget.knots} knots. '
                        'The whole carpet is done.'
                  : '${widget.knots} of ${widget.knots} knots. '
                        'The $next göl is next.',
              textAlign: TextAlign.center,
              style: k.caption,
            ),
            const SizedBox(height: 20),
            KustButton(label: 'Continue', onTap: widget.onContinue),
          ],
        ),
      ),
    );
  }
}

/// Paints one göl's chart, filling it in from the bottom up as [woven] goes
/// from 0 to 1.
class GolPainter extends CustomPainter {
  GolPainter({required this.kind, required this.woven});

  final GolKind kind;
  final double woven;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = GolChart.of(kind);
    var r0 = chart.rows, r1 = -1, c0 = chart.cols, c1 = -1;
    for (var r = 0; r < chart.rows; r++) {
      for (var c = 0; c < chart.cols; c++) {
        if (chart.knots[r][c] == null) continue;
        if (r < r0) r0 = r;
        if (r > r1) r1 = r;
        if (c < c0) c0 = c;
        if (c > c1) c1 = c;
      }
    }
    if (r1 < 0) return;
    final rows = r1 - r0 + 1, cols = c1 - c0 + 1;
    final cell = (size.width / cols) < (size.height / rows)
        ? size.width / cols
        : size.height / rows;
    final dx = (size.width - cols * cell) / 2;
    final dy = (size.height - rows * cell) / 2;
    final shown = (woven.clamp(0.0, 1.0) * rows).ceil();
    final paint = Paint()..isAntiAlias = false;
    for (var r = r1; r > r1 - shown; r--) {
      for (var c = c0; c <= c1; c++) {
        final knot = chart.knots[r][c];
        if (knot == null) continue;
        paint.color = LoomColors.of(knot);
        canvas.drawRect(
          Rect.fromLTWH(
            dx + (c - c0) * cell,
            dy + (r - r0) * cell,
            cell + 0.3,
            cell + 0.3,
          ),
          paint,
        );
      }
    }
    // The weft that is being laid.
    if (shown < rows) {
      final y = dy + (r1 - shown + 1 - r0) * cell;
      canvas.drawRect(
        Rect.fromLTWH(dx, y - cell, cols * cell, cell * 1.4),
        Paint()..color = LoomColors.madder.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(GolPainter old) => old.kind != kind || old.woven != woven;
}
