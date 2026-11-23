import 'package:flutter/material.dart';

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
/// so guests never see it.
class OfflineInsetHost extends StatefulWidget {
  const OfflineInsetHost({super.key, required this.child, this.service});

  final Widget child;
  final ConnectionService? service;

  @override
  State<OfflineInsetHost> createState() => _OfflineInsetHostState();
}

class _OfflineInsetHostState extends State<OfflineInsetHost> {
  /// What the strip says while it slides away after coming back online.
  ConnectionStatus _shown = ConnectionStatus.offline;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ConnectionStatus>(
      valueListenable: (widget.service ?? ConnectionService.instance).status,
      builder: (context, status, _) {
        final visible = status != ConnectionStatus.online;
        if (visible) _shown = status;
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
                      child: _Strip(
                        restored: _shown == ConnectionStatus.restored,
                        statusBar: top,
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
    // Like the tab bar, turned over: darkest at the very top, lighter
    // toward the bottom, so the page shows faintly through its lower edge.
    final base = restored
        ? k.success
        : dark
        ? const Color(0xFF121110)
        : k.ink;
    // Transparent Material: it gives the text its style above the screens.
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Back online: the plain green. Offline: lighter, about two
            // thirds at the top fading to a third.
            colors: restored
                ? [base, base]
                : [
                    base.withValues(alpha: 0.67),
                    base.withValues(alpha: 0.5),
                    base.withValues(alpha: 0.3),
                  ],
            stops: restored ? null : const [0, 0.55, 1],
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
