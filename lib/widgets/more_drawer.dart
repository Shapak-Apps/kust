import 'package:flutter/material.dart';

class MoreDrawer extends StatelessWidget {
  const MoreDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Küşt',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: const [
                  ListTile(
                    leading: Icon(Icons.analytics_outlined),
                    title: Text('Statistics'),
                    subtitle: Text('Accuracy, openings, endgames'),
                  ),
                  ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Game History'),
                    subtitle: Text('Review past games'),
                  ),
                  ListTile(
                    leading: Icon(Icons.school_outlined),
                    title: Text('Training Plan'),
                    subtitle: Text('Personalized puzzles'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.settings_outlined),
                    title: Text('Settings'),
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('About Küşt'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
