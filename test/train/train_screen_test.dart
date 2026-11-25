import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/train/train_opening_screen.dart';
import 'package:kust/features/train/train_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';

Widget _app(Widget home) => MaterialApp(
  theme: appDarkTheme,
  supportedLocales: kSupportedLocales,
  localizationsDelegates: kLocalizationDelegates,
  home: Scaffold(body: home),
);

void main() {
  testWidgets('lists openings, and search and kinds narrow the list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const TrainScreen()));
    await tester.pump();
    expect(find.text('Italian Game'), findsOneWidget);
    expect(find.text('Sicilian'), findsOneWidget);
    expect(find.text('Try'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'najdorf');
    await tester.pump();
    expect(find.text('Sicilian'), findsOneWidget);
    expect(find.text('Italian Game'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    final gambit = find.widgetWithText(ChoiceChip, 'Gambit');
    await tester.ensureVisible(gambit);
    await tester.pump();
    await tester.tap(gambit);
    await tester.pump();
    expect(find.text('Queen’s Gambit'), findsOneWidget);
    expect(find.text('Italian Game'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an opening steps through its lines', (tester) async {
    tester.view.physicalSize = const Size(412, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const TrainOpeningScreen(id: 'italian')));
    await tester.pump();
    expect(find.text('Main line'), findsOneWidget);
    expect(find.text('Giuoco Pianissimo'), findsOneWidget);
    expect(find.text('Practise vs ${'Karl'}'), findsNothing); // any bot
    expect(find.textContaining('Practise vs'), findsOneWidget);

    await tester.tap(find.byTooltip('To the start'));
    await tester.pump();
    final first = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.first_page_rounded),
    );
    expect(first.onPressed, isNull);

    await tester.tap(find.text('Evans Gambit'));
    await tester.pump();
    expect(find.text('6. d4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
