import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/time_control.dart';
import 'package:kust/features/play/bot_time_row.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';

void main() {
  testWidgets('the clock row offers no clock and three controls', (
    tester,
  ) async {
    TimeControl? picked;
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationDelegates,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TimeControlRow(
              value: picked,
              onChanged: (v) => setState(() {
                picked = v;
                changes++;
              }),
            ),
          ),
        ),
      ),
    );
    expect(find.text('No clock'), findsOneWidget);
    expect(find.text('3+2'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);

    await tester.tap(find.text('5 min'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(picked, const TimeControl(baseMinutes: 5));
    await tester.tap(find.text('No clock'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(picked, isNull);
    expect(changes, 2);
  });
}
