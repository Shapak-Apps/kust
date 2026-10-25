import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/theme.dart';
import 'package:kust/ui/kust_action_bar.dart';

void main() {
  testWidgets('plain icons over labels, greyed when off, spinner when busy', (
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
    expect(find.text('Hint'), findsOneWidget);
    // No box around any of them.
    expect(
      find.descendant(
        of: find.byType(KustActionBar),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration != null,
        ),
      ),
      findsNothing,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Hint'));
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
