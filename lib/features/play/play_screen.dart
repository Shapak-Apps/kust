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
          children: [
            Text(
              'Hello Guest!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            Row(children: []),
          ],
        ),
      ),
    );
  }
}
