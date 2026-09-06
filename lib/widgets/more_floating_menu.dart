import 'package:flutter/material.dart';

class MoreFloatingMenu extends StatelessWidget {
  const MoreFloatingMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final double bottomNavHeight = MediaQuery.of(context).padding.bottom + 80;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.transparent),
        ),

        Positioned(
          right: 16,
          bottom: bottomNavHeight + 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.analytics_outlined, size: 20),
                      title: const Text(
                        'Statistics',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 20),
                      title: const Text(
                        'Game History',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.school_outlined, size: 20),
                      title: const Text(
                        'Training',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate
                      },
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.settings_outlined, size: 20),
                      title: const Text(
                        'Settings',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
