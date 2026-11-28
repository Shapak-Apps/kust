import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/connection_service.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/motion.dart';
import 'package:kust/ui/tokens.dart';

/// The height of the offline strip.
const double kOfflineBarHeight = 26;

/// Space to leave under the last line on screen: the gesture bar's, read
/// from the window so a parent that took the padding away cannot hide it,
/// and never less than [min].
double bottomGap(BuildContext context, {double min = 8}) {
  final window = View.of(context);
  final gap = [
    MediaQuery.viewPaddingOf(context).bottom,
    MediaQuery.paddingOf(context).bottom,
    window.viewPadding.bottom / window.devicePixelRatio,
    window.padding.bottom / window.devicePixelRatio,
  ].reduce((a, b) => a > b ? a : b);
  return gap < min ? min : gap;
}

/// Wraps the whole app: while the connection is lost, "You're offline"
/// shows in a strip right under the status bar and every screen below
/// moves down to make room for it (the screens lay out under a top padding
/// that grows by the strip). "Back online" shows in green for a moment
/// when the connection returns. Only signed-in players are ever checked,
/// so guests never see it. Never over a board: a game shows its own link.
class OfflineInsetHost extends StatefulWidget {
  const OfflineInsetHost({
    super.key,
    required this.child,
    this.service,
    this.router,
  });

  final Widget child;
  final ConnectionService? service;

  /// Where the app is, to keep the strip off the board screens.
  final GoRouter? router;

  @override
  State<OfflineInsetHost> createState() => _OfflineInsetHostState();
}

class _OfflineInsetHostState extends State<OfflineInsetHost> {
  /// What the strip says while it slides away after coming back online.
  ConnectionStatus _shown = ConnectionStatus.offline;

  static final _boards = RegExp(
    r'^/(game|online/|puzzle/|review/|history/)',
  );

  @override
  Widget build(BuildContext context) {
    final status = (widget.service ?? ConnectionService.instance).status;
    final router = widget.router;
    return ListenableBuilder(
      listenable: Listenable.merge([status, router?.routerDelegate]),
      builder: (context, _) {
        final onBoard =
            router != null &&
            router.routerDelegate.currentConfiguration.isNotEmpty &&
            _boards.hasMatch(router.state.matchedLocation);
        final visible = status.value != ConnectionStatus.online && !onBoard;
        if (visible) _shown = status.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(end: visible ? kOfflineBarHeight : 0),
          duration: motion(context, const Duration(milliseconds: 250)),
          curve: Curves.easeOutCubic,
          builder: (context, height, _) {
            final media = MediaQuery.of(context);
            final top = media.padding.top;
            return Stack(
              children: [
                MediaQuery(
                  data: media.copyWith(
                    padding: media.padding.copyWith(top: top + height),
                    viewPadding: media.viewPadding.copyWith(
                      top: media.viewPadding.top + height,
                    ),
                  ),
                  child: widget.child,
                ),
                if (height > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: top + height,
                    child: ExcludeSemantics(
                      excluding: !visible,
                      // Fades in and out as it opens and closes.
                      child: Opacity(
                        opacity: (height / kOfflineBarHeight).clamp(0, 1),
                        child: _Strip(
                          restored: _shown == ConnectionStatus.restored,
                          statusBar: top,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// The strip itself: dark (green when back online), one line of text,
/// under the status bar.
class _Strip extends StatelessWidget {
  const _Strip({required this.restored, required this.statusBar});

  final bool restored;
  final double statusBar;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Offline: like the tab bar, turned over: darkest at the very top,
    // fading to nothing at the bottom, so there is no edge line over the
    // screen below. Back online: a plain mid-dark green.
    final base = dark ? const Color(0xFF121110) : k.ink;
    // Transparent Material: it gives the text its style above the screens.
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: restored
            ? const BoxDecoration(color: Color(0xFF2B8A5A))
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    base.withValues(alpha: 0.8),
                    base.withValues(alpha: 0.55),
                    base.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.6, 1],
                ),
              ),
        child: ClipRect(
          child: Padding(
            padding: EdgeInsets.only(top: statusBar),
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: kOfflineBarHeight,
              maxHeight: kOfflineBarHeight,
              child: Center(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    restored
                        ? context.t.backOnlineBanner
                        : context.t.offlineBanner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: Colors.white,
                    ),
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
