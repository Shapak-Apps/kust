import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:Kust/ui/kust_nav_bar.dart';
import 'package:Kust/ui/tokens.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = location.startsWith('/puzzles')
        ? 1
        : location.startsWith('/history')
        ? 2
        : 0;

    return Scaffold(
      backgroundColor: context.k.bg,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: KustNavBar(
              selectedIndex: selected,
              items: const [
                KustNavItem(
                  Icons.sports_esports_outlined,
                  Icons.sports_esports_rounded,
                  'Play',
                ),
                KustNavItem(
                  Icons.extension_outlined,
                  Icons.extension_rounded,
                  'Puzzles',
                ),
                KustNavItem(
                  Icons.history_rounded,
                  Icons.history_rounded,
                  'History',
                ),
              ],
              onSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/play');
                  case 1:
                    context.go('/puzzles');
                  case 2:
                    context.go('/history');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
