import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// The tab just tapped, shown selected before its page is built: a page
  /// that is slow to build the first time (Puzzles) must not hold the tab
  /// back, so the bar answers the tap at once and the page follows.
  int? _pending;

  void _select(int index) {
    setState(() => _pending = index);
    // After the frame that shows the new tab, so its slow build comes
    // second.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(const ['/play', '/puzzles', '/learn', '/history'][index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final current = location.startsWith('/puzzles')
        ? 1
        : location.startsWith('/learn')
        ? 2
        : location.startsWith('/history')
        ? 3
        : 0;
    if (_pending == current) _pending = null;
    final selected = _pending ?? current;

    return Scaffold(
      backgroundColor: context.k.bg,
      // The top bar and the tab bar blur the page through one shared read.
      body: BackdropGroup(
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: KustNavBar(
                selectedIndex: selected,
                items: [
                  KustNavItem(
                    Icons.sports_esports_outlined,
                    Icons.sports_esports_rounded,
                    context.t.navPlay,
                  ),
                  KustNavItem(
                    Icons.extension_outlined,
                    Icons.extension_rounded,
                    context.t.navPuzzles,
                  ),
                  KustNavItem(
                    Icons.school_outlined,
                    Icons.school_rounded,
                    context.t.navLearn,
                  ),
                  KustNavItem(
                    Icons.history_rounded,
                    Icons.history_rounded,
                    context.t.navHistory,
                  ),
                ],
                onSelected: _select,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
