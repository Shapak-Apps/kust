import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Kust/widgets/more_floating_menu.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    int selectedIndex = 0;
    if (location.startsWith('/puzzles')) {
      selectedIndex = 1;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            showDialog(
              context: context,
              barrierColor: Colors.transparent,
              builder: (context) => const MoreFloatingMenu(),
            );
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_filled),
            label: 'Home',
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
