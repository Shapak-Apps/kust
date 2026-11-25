import 'package:flutter/material.dart';

import 'package:kust/features/game/time_control.dart';
import 'package:kust/ui/tokens.dart';

/// A player's clock, the same in every game: 40 px high, at least 96 wide,
/// numbers of one width. The running one is light with dark digits and a
/// small clock; the waiting one is grey. Under 20 seconds the running clock
/// turns red and pulses once a second; under 10 it shows tenths.
class GameClock extends StatefulWidget {
  const GameClock({super.key, required this.time, required this.active});

  final Duration time;
  final bool active;

  static const Duration lowTime = Duration(seconds: 20);

  @override
  State<GameClock> createState() => _GameClockState();
}

class _GameClockState extends State<GameClock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  bool get _low => widget.active && widget.time < GameClock.lowTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant GameClock old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still = MediaQuery.disableAnimationsOf(context);
    if (_low && !still) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final low = _low;
    final fill = widget.active
        ? (low ? k.danger : const Color(0xFFF2F0EA))
        : k.surfaceAlt;
    final ink = widget.active
        ? (low ? Colors.white : const Color(0xFF17181A))
        : k.muted;
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.75).animate(_pulse),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 96),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.active) ...[
              Icon(Icons.schedule_rounded, size: 16, color: ink),
              const SizedBox(width: 6),
            ],
            Text(
              TimeControl.formatClock(widget.time),
              style: k.number.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
