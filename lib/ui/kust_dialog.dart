import 'package:flutter/material.dart';

import 'package:kust/ui/motion.dart';

/// A small card over a dimmed screen: it fades in while growing from 94 %,
/// in 200 ms, instead of the stock dialog's plain fade.
Future<T?> showKustDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x99000000),
    transitionDuration: motion(context, const Duration(milliseconds: 200)),
    pageBuilder: (context, _, _) => Center(child: builder(context)),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
