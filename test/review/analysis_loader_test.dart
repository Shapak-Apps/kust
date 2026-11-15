import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/review/analysis_loader.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';

void main() {
  test('the shown percent runs ahead early and slows later', () {
    expect(perceivedPercent(0), 0);
    expect(perceivedPercent(0.4), closeTo(60, 1e-9));
    expect(perceivedPercent(0.2), closeTo(30, 1e-9));
    expect(perceivedPercent(0.7), lessThan(85));
    expect(perceivedPercent(1), lessThan(100));
    expect(
      perceivedRate(30, finishing: false),
      greaterThan(perceivedRate(70, finishing: false)),
    );
    expect(
      perceivedRate(70, finishing: false),
      greaterThan(perceivedRate(90, finishing: false)),
    );
  });

  Widget app(Widget child) => MaterialApp(
    theme: appDarkTheme,
    supportedLocales: kSupportedLocales,
    localizationsDelegates: kLocalizationDelegates,
    home: Scaffold(body: child),
  );

  testWidgets('it counts up, then finishes at 100 and says so', (tester) async {
    var finished = 0;
    await tester.pumpWidget(app(const AnalysisLoader(done: 20, total: 50)));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // 40 % done shows as 60 %.
    expect(find.text('Checking move 21 of 50'), findsOneWidget);
    expect(find.textContaining('60'), findsOneWidget);
    expect(find.text('Analyzing your game'), findsOneWidget);

    await tester.pumpWidget(
      app(
        AnalysisLoader(
          done: 50,
          total: 50,
          finished: true,
          onFinished: () => finished++,
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('100'), findsOneWidget);
    expect(finished, 1);
  });
}
