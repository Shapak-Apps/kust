import 'package:flutter/material.dart';

import 'package:kust/features/play/app_bar.dart';

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello Guest!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('You have played 10 games wanna play again?'),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextButton(
                    onPressed: () => {},
                    child: Text('Play a game'),
                    style: ButtonStyle(
                      minimumSize: WidgetStateProperty.all(
                        const Size(double.infinity, 50),
                      ),
                      backgroundColor: WidgetStateProperty.all(Colors.green),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
