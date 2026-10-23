import 'package:flutter/material.dart';

import 'package:kust/ui/tokens.dart';

/// Shows Kust's centered modal: a flat card in the middle of the screen over
/// a dimmed page. Use it for moments that deserve full attention, such as a
/// game result. Content is laid out by the caller, so it can center it.
Future<T?> showKustDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<T>(_KustDialogRoute<T>(builder: builder, dismissible: dismissible));
}

class _KustDialogRoute<T> extends PopupRoute<T> {
  _KustDialogRoute({required this.builder, required this.dismissible});

  final WidgetBuilder builder;
  final bool dismissible;

  @override
  Color? get barrierColor => null; // drawn by the transition below

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 240);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final k = context.k;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              key: const ValueKey('kustDialogCard'),
              color: k.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KustSpace.rLarge),
                side: BorderSide(color: k.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: dismissible ? () => Navigator.of(context).maybePop() : null,
            child: FadeTransition(
              opacity: curved,
              child: ColoredBox(color: context.k.scrim),
            ),
          ),
        ),
        FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      ],
    );
  }
}
