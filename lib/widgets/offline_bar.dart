import 'package:flutter/material.dart';

import 'package:kust/core/net/connection_service.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/motion.dart';
import 'package:kust/ui/tokens.dart';

/// The line of text under the tabs, and the most room kept under it.
const double kOfflineBarHeight = 26;
const double kOfflineMinUnder = 14;

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

class OfflineInset extends InheritedWidget {
  const OfflineInset({super.key, required this.visible, required super.child});

  final bool visible;

  static double of(BuildContext context) {
    final inset = context.dependOnInheritedWidgetOfExactType<OfflineInset>();
    return inset != null && inset.visible
        ? kOfflineBarHeight + kOfflineMinUnder
        : 0;
  }

  @override
  bool updateShouldNotify(OfflineInset oldWidget) =>
      visible != oldWidget.visible;
}

class OfflineInsetHost extends StatelessWidget {
  const OfflineInsetHost({super.key, required this.child, this.service});

  final Widget child;
  final ConnectionService? service;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ConnectionStatus>(
      valueListenable: (service ?? ConnectionService.instance).status,
      child: child,
      builder: (context, status, child) => OfflineInset(
        visible: status != ConnectionStatus.online,
        child: child!,
      ),
    );
  }
}

/// "You're offline" in a line of plain text, as Spotify shows it under its
/// tabs; "Back online" in green for a moment when the connection returns.
class OfflineBar extends StatefulWidget {
  const OfflineBar({super.key, this.service, this.edge = false});

  final ConnectionService? service;

  /// At the bottom of a screen with no tab bar: on the page's colour, and
  /// clear of the gesture bar.
  final bool edge;

  @override
  State<OfflineBar> createState() => _OfflineBarState();
}

class _OfflineBarState extends State<OfflineBar> {
  ConnectionStatus _shown = ConnectionStatus.offline;

  ConnectionService get _service =>
      widget.service ?? ConnectionService.instance;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ValueListenableBuilder<ConnectionStatus>(
      valueListenable: _service.status,
      builder: (context, status, _) {
        final visible = status != ConnectionStatus.online;
        if (visible) _shown = status;
        final restored = _shown == ConnectionStatus.restored;
        final text = restored
            ? context.t.backOnlineBanner
            : context.t.offlineBanner;
        return ExcludeSemantics(
          excluding: !visible,
          child: AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: visible ? 1 : 0,
            duration: motion(context, const Duration(milliseconds: 250)),
            curve: Curves.easeOutCubic,
            child: ClipRect(
              // A solid strip, as on Spotify, so the page never shows
              // through the words.
              child: ColoredBox(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF121110)
                    : k.bg,
                child: Padding(
                  // At least [kOfflineMinUnder] under the words: some phones
                  // report no bottom inset yet draw the gesture bar there.
                  padding: EdgeInsets.only(
                    bottom: widget.edge
                        ? bottomGap(context, min: kOfflineMinUnder)
                        : (kOfflineMinUnder - bottomGap(context, min: 0)).clamp(
                            0,
                            kOfflineMinUnder,
                          ),
                  ),
                  child: SizedBox(
                    height: kOfflineBarHeight,
                    width: double.infinity,
                    child: Center(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: k.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            color: restored
                                ? k.success
                                : Theme.of(context).brightness ==
                                      Brightness.dark
                                ? Colors.white
                                : k.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
