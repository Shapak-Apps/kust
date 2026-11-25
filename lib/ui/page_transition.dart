import 'package:flutter/material.dart';

/// The push transition of Android, Linux and Windows: the new page slides
/// in from the right in 280 ms; the page under it moves a fifth of its width
/// left and dims 8 %. Quicker and lighter than Cupertino's 500 ms slide
/// (which stays on iOS and macOS for its swipe-back).
class KustPageTransitionsBuilder extends PageTransitionsBuilder {
  const KustPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final cover = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: const Offset(-0.2, 0),
      ).animate(cover),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(enter),
            child: child,
          ),
          // Dims this page once another is pushed over it.
          IgnorePointer(
            child: FadeTransition(
              opacity: Tween(begin: 0.0, end: 0.08).animate(cover),
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
