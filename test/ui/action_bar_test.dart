import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/theme.dart';
import 'package:kust/ui/kust_action_bar.dart';

void main() {
  testWidgets('icons over labels, one filled main action, greyed when off', (
    tester,
  ) async {
    var hinted = 0;
    var backed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: KustActionBar(
            actions: [
              KustAction(
                icon: Icons.refresh_rounded,
                label: 'Retry',
                onTap: () {},
              ),
              KustAction(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Hint',
                primary: true,
                onTap: () => hinted++,
              ),
              KustAction(
                icon: Icons.chevron_left_rounded,
                label: 'Back',
                onTap: null,
              ),
              KustAction(
                icon: Icons.chevron_right_rounded,
                label: 'Forward',
                busy: true,
                onTap: () => backed++,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    // The main action is an icon button; its name is for screen readers.
    expect(find.text('Hint'), findsNothing);
    expect(find.bySemanticsLabel('Hint'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Hint'));
    await tester.tap(find.text('Back'));
    await tester.tap(find.bySemanticsLabel('Forward'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(hinted, 1);
    expect(backed, 0); // busy
  });

  testWidgets('labels fit at a large font size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: KustActionBar(
              actions: [
                for (final l in ['Options', 'Take back', 'Back', 'Forward'])
                  KustAction(icon: Icons.circle, label: l, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
