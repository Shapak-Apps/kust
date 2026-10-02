import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:Kust/features/game/chess/move_feedback.dart';

class MoveFeedbackBadge extends StatefulWidget {
  const MoveFeedbackBadge({
    super.key,
    required this.feedback,
    this.size = 22,
    this.iconScale,
  });

  final MoveFeedback feedback;
  final double size;
  final double? iconScale;

  @override
  State<MoveFeedbackBadge> createState() => _MoveFeedbackBadgeState();
}

class _MoveFeedbackBadgeState extends State<MoveFeedbackBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScale;
  late final Animation<double> _iconOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _circleScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant MoveFeedbackBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedback.quality != widget.feedback.quality ||
        oldWidget.feedback.playedSan != widget.feedback.playedSan) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.feedback.quality.color;
    final iconSize = widget.size * (widget.iconScale ?? widget.feedback.quality.iconScale);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _circleScale.value.clamp(0.01, 1.0),
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FadeTransition(
          opacity: _iconOpacity,
          child: SvgPicture.asset(
            widget.feedback.quality.asset,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
            placeholderBuilder: (_) => Icon(
              Icons.star,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
