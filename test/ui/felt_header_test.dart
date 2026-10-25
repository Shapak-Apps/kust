import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/theme.dart';
import 'package:kust/ui/felt_header.dart';

void main() {
  testWidgets('a back arrow does not make the header taller', (tester) async {
    Future<double> heightOf(Widget header) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(body: Column(children: [header])),
        ),
      );
      return tester.getSize(find.byType(FeltHeader)).height;
    }

    final plain = await heightOf(const FeltHeader(title: 'History'));
    final withBack = await heightOf(
      FeltHeader(title: 'Achievements', onBack: () {}),
    );
    expect(withBack, plain);
  });
}
