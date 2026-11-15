import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/tokens.dart';

/// The percent to show for real progress [real] (0..1): it runs ahead early,
/// reaching 60 % while the work is at 40 %, then takes the rest slowly, so
/// the wait feels short. Below 100 until the work is done.
double perceivedPercent(double real) {
  final r = real.clamp(0.0, 1.0);
  if (r <= 0.4) return r / 0.4 * 60;
  return 60 + (r - 0.4) / 0.6 * 39;
}

/// How fast (percent a second) the shown number moves at [shown]: brisk to
/// 60, then easing off.
double perceivedRate(double shown, {required bool finishing}) {
  if (finishing) return 160;
  if (shown < 60) return 75;
  if (shown < 85) return 14;
  return 4;
}

/// While a game is analyzed: a ring that fills fast and then slows, the
/// move being checked, and a tip that changes every few seconds.
class AnalysisLoader extends StatefulWidget {
  const AnalysisLoader({
    super.key,
    required this.done,
    required this.total,
    this.finished = false,
    this.onFinished,
  });

  final int done;
  final int total;

  /// The work is done: the ring runs to 100 and then [onFinished] is called.
  final bool finished;
  final VoidCallback? onFinished;

  @override
  State<AnalysisLoader> createState() => _AnalysisLoaderState();
}

class _AnalysisLoaderState extends State<AnalysisLoader>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  double _shown = 0;
  bool _told = false;
  int _tip = 0;
  Duration _tipAt = Duration.zero;

  static const Duration _tipEvery = Duration(milliseconds: 3800);

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    final real = widget.total == 0 ? 0.0 : widget.done / widget.total;
    final target = widget.finished ? 100.0 : perceivedPercent(real);
    var next = _shown;
    if (next < target) {
      next = math.min(
        target,
        next + perceivedRate(next, finishing: widget.finished) * dt,
      );
    }
    if (now - _tipAt > _tipEvery) {
      _tipAt = now;
      _tip++;
    }
    if (next != _shown || _tipAt == now) setState(() => _shown = next);
    if (widget.finished && _shown >= 100 && !_told) {
      _told = true;
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted) widget.onFinished?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final tips = [
      t.reviewTip1,
      t.reviewTip2,
      t.reviewTip3,
      t.reviewTip4,
      t.reviewTip5,
    ];
    final moveNo = math.min(widget.done + 1, widget.total);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 168,
              child: CustomPaint(
                painter: _RingPainter(value: _shown / 100, track: k.line),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${_shown.floor()}'),
                        TextSpan(
                          text: '%',
                          style: TextStyle(fontSize: 22, color: k.muted),
                        ),
                      ],
                    ),
                    style: k.title.copyWith(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.reviewAnalyzingTitle,
              textAlign: TextAlign.center,
              style: k.title,
            ),
            const SizedBox(height: 6),
            Text(
              widget.total == 0
                  ? ' '
                  : t.reviewCheckingMove(moveNo, widget.total),
              style: k.caption.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 76),
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              decoration: BoxDecoration(
                color: k.surface,
                borderRadius: BorderRadius.circular(KustSpace.rMedium),
                border: Border.all(color: k.line),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFFFFC94D),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        tips[_tip % tips.length],
                        key: ValueKey(_tip % tips.length),
                        style: k.body.copyWith(height: 1.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track});

  final double value;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    canvas.drawArc(
      ring,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (value <= 0) return;
    final sweep = math.pi * 2 * value.clamp(0.0, 1.0);
    canvas.drawArc(
      ring,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + math.pi * 2,
          transform: const GradientRotation(-math.pi / 2),
          colors: const [KustButton3D.lipColor, KustButton3D.faceTop],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track;
}
