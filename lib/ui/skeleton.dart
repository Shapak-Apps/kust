import 'package:flutter/material.dart';

import 'package:kust/ui/tokens.dart';

/// A grey, rounded stand-in for a piece of content that is still loading.
class KustSkeleton extends StatelessWidget {
  const KustSkeleton({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 4,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.k.surfaceAlt,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Pulses everything under it slowly (1.2 s, between 55 % and full), as one
/// layer: no shimmer sweep to repaint. Still under reduced motion.
class KustSkeletonPulse extends StatefulWidget {
  const KustSkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<KustSkeletonPulse> createState() => _KustSkeletonPulseState();
}

class _KustSkeletonPulseState extends State<KustSkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (!still && !_started) {
      _started = true;
      _c.repeat(reverse: true);
    } else if (still && _started) {
      _started = false;
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(
      begin: 1.0,
      end: 0.55,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
    child: widget.child,
  );
}

/// List rows still loading, shaped like the real ones (see
/// [KustSpace.row]): an avatar, two lines of text and a small block at the
/// end.
class KustSkeletonRows extends StatelessWidget {
  const KustSkeletonRows({super.key, this.count = 8, this.avatar = true});

  final int count;
  final bool avatar;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: KustSkeletonPulse(
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          itemBuilder: (_, i) => SizedBox(
            height: KustSpace.row,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (avatar) ...[
                    const KustSkeleton(width: 36, height: 36, radius: 4),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (_, c) => KustSkeleton(
                            width: c.maxWidth * (i.isEven ? 0.6 : 0.45),
                            height: 13,
                          ),
                        ),
                        const SizedBox(height: 7),
                        LayoutBuilder(
                          builder: (_, c) => KustSkeleton(
                            width: c.maxWidth * (i.isEven ? 0.35 : 0.5),
                            height: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const KustSkeleton(width: 32, height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A whole screen waiting: four little squares of a board lighting up in
/// turn, in gold on grey (28 px, 600 ms a round).
class KustLoader extends StatefulWidget {
  const KustLoader({super.key, this.size = 28});

  final double size;

  @override
  State<KustLoader> createState() => _KustLoaderState();
}

class _KustLoaderState extends State<KustLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // The squares light clockwise: top left, top right, bottom right, bottom
  // left.
  static const _order = [0, 1, 3, 2];

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final cell = (widget.size - 2) / 2;
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: cell,
                  height: cell,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      KustTokens.gold,
                      k.surfaceAlt,
                      // 1 right when this square's turn comes, fading away.
                      (((_c.value * 4) - _order.indexOf(i)) % 4 / 4 * 1.6)
                          .clamp(0.0, 1.0),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
