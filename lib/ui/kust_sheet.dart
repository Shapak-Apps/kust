import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:Kust/ui/tokens.dart';

/// Shows Kust's own bottom sheet: flat surface, grabber, drag to dismiss.
/// Built on a plain [PopupRoute] so nothing from Material's modal sheet leaks
/// in.
Future<T?> showKustSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<T>(_KustSheetRoute<T>(builder: builder, dismissible: dismissible));
}

class _KustSheetRoute<T> extends PopupRoute<T> {
  _KustSheetRoute({required this.builder, required this.dismissible});

  final WidgetBuilder builder;
  final bool dismissible;

  @override
  Color? get barrierColor => null; // drawn by the transition below

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> a,
    Animation<double> b,
  ) {
    return _SheetFrame(dismissible: dismissible, child: builder(context));
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final scrim = context.k.scrim;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: dismissible ? () => Navigator.of(context).maybePop() : null,
            child: FadeTransition(
              opacity: curved,
              child: ColoredBox(color: scrim),
            ),
          ),
        ),
        SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ],
    );
  }
}

class _SheetFrame extends StatefulWidget {
  const _SheetFrame({required this.child, required this.dismissible});

  final Widget child;
  final bool dismissible;

  @override
  State<_SheetFrame> createState() => _SheetFrameState();
}

class _SheetFrameState extends State<_SheetFrame> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.9;

    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onVerticalDragUpdate: widget.dismissible
            ? (d) => setState(() => _drag = math.max(0, _drag + d.delta.dy))
            : null,
        onVerticalDragEnd: widget.dismissible
            ? (d) {
                if (_drag > 120 || (d.primaryVelocity ?? 0) > 800) {
                  Navigator.of(context).maybePop();
                } else {
                  setState(() => _drag = 0);
                }
              }
            : null,
        child: Transform.translate(
          offset: Offset(0, _drag),
          child: Material(
            color: k.surface,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(KustSpace.rSheet),
              ),
              side: BorderSide(color: k.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 560),
              child: SizedBox(
                width: double.infinity,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: k.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: widget.child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KustSheetHeader extends StatelessWidget {
  const KustSheetHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: k.title),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: k.body.copyWith(color: k.muted)),
          ],
        ],
      ),
    );
  }
}
