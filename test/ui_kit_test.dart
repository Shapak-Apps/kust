import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/theme.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_top_bar.dart';

Widget _app(Widget home, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? appTheme,
  home: Scaffold(body: home),
);

void main() {
  testWidgets('KustButton taps and respects disabled state', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(KustButton(label: 'Go', onTap: () => taps++)));
    await tester.tap(find.text('Go'));
    expect(taps, 1);

    await tester.pumpWidget(_app(const KustButton(label: 'Go', onTap: null)));
    await tester.tap(find.text('Go'));
    expect(taps, 1);
  });

  testWidgets('KustSegmented reports the tapped value', (tester) async {
    int value = 1;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => KustSegmented<int>(
            value: value,
            options: const {1: 'One', 2: 'Two', 3: 'Three'},
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Three'));
    await tester.pump();
    expect(value, 3);
  });

  testWidgets('KustSwitch toggles', (tester) async {
    var on = false;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => KustToggleRow(
            title: 'Sound',
            value: on,
            onChanged: (v) => setState(() => on = v),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(KustSwitch));
    await tester.pump();
    expect(on, isTrue);
  });

  testWidgets('KustNavBar shows labels and selects', (tester) async {
    int selected = 0;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Align(
            alignment: Alignment.bottomCenter,
            child: KustNavBar(
              selectedIndex: selected,
              onSelected: (i) => setState(() => selected = i),
              items: const [
                KustNavItem(Icons.home_outlined, Icons.home, 'Play'),
                KustNavItem(
                  Icons.extension_outlined,
                  Icons.extension,
                  'Puzzles',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Puzzles'), findsOneWidget);
    await tester.tap(find.text('Puzzles'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets('KustSheet opens, shows content and closes on scrim tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showKustSheet<void>(
                  context,
                  builder: (_) => const KustSheetHeader(title: 'Hello sheet'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Hello sheet'), findsOneWidget);

    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(find.text('Hello sheet'), findsNothing);
  });

  testWidgets('KustTopBar renders title and actions without an AppBar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            KustTopBar(
              title: 'Play',
              trailing: [KustIconButton(icon: Icons.tune, onTap: () {})],
            ),
          ],
        ),
      ),
    );
    expect(find.text('Play'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
  });
}
