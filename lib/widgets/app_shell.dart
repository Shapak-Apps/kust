import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:Kust/ui/kust_nav_bar.dart';
import 'package:Kust/ui/tokens.dart';
import 'package:Kust/widgets/more_sheet.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = location.startsWith('/puzzles') ? 1 : 0;

    return Scaffold(
      backgroundColor: context.k.bg,
      body: Column(
        children: [
          Expanded(child: child),
          KustNavBar(
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
                Icons.grid_view_outlined,
                Icons.grid_view_rounded,
                'More',
              ),
            ],
            onSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/play');
                case 1:
                  context.go('/puzzles');
                case 2:
                  showMoreSheet(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
