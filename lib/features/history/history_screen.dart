import 'package:flutter/material.dart';

import 'package:Kust/ui/kust_top_bar.dart';
import 'package:Kust/ui/tokens.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ColoredBox(
      color: k.bg,
      child: Column(
        children: [
          const KustTopBar(
            large: true,
            title: 'History',
            subtitle: 'Your past games',
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: KustSpace.xl * 2),
                child: Text(
                  'Coming soon',
                  style: k.title.copyWith(color: k.muted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
