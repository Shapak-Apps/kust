import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/widgets/more_drawer.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    int selectedIndex = 0;
    if (location.startsWith('/puzzles')) {
      selectedIndex = 1;
    }

    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      endDrawer: const MoreDrawer(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            _scaffoldKey.currentState?.openEndDrawer();
            return;
          }

          switch (index) {
            case 0:
              context.go('/play');
              break;
            case 1:
              context.go('/puzzles');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Play',
          ),
          NavigationDestination(
            icon: Icon(Icons.extension_outlined),
            selectedIcon: Icon(Icons.extension),
            label: 'Puzzles',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
