import 'package:flutter/material.dart';

import 'package:kust/ui/motion.dart';

/// A number that counts from [from] to [to] when it appears, over 400 ms
/// (easeOutCubic), in digits of one width. Counts from the old value to the
/// new one when [to] changes later. Shows [to] at once under reduced motion.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.to,
    this.from,
    this.style,
    this.prefix = '',
  });

  final int to;

  /// Where it starts; the first value it shows. Defaults to [to] (no count).
  final int? from;
  final TextStyle? style;

  /// Put before the number, such as `+` for a gain.
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final base = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: (from ?? to).toDouble(), end: to.toDouble()),
      duration: motion(context, const Duration(milliseconds: 400)),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('$prefix${v.round()}', style: base),
    );
  }
}
