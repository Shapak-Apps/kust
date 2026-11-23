import 'package:flutter/material.dart';

import 'package:kust/core/net/connection_service.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/motion.dart';
import 'package:kust/ui/tokens.dart';

const double kOfflineBarHeight = 26;

class OfflineInset extends InheritedWidget {
  const OfflineInset({super.key, required this.visible, required super.child});

  final bool visible;

  static double of(BuildContext context) {
    final inset = context.dependOnInheritedWidgetOfExactType<OfflineInset>();
    return inset != null && inset.visible ? kOfflineBarHeight : 0;
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

class OfflineBar extends StatefulWidget {
  const OfflineBar({super.key, this.service});

  final ConnectionService? service;

  @override
  State<OfflineBar> createState() => _OfflineBarState();
}

class _OfflineBarState extends State<OfflineBar> {
  ConnectionStatus _shown = ConnectionStatus.offline;

  ConnectionService get _service => widget.service ?? ConnectionService.instance;

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
                      style: k.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: restored ? k.success : k.muted,
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
