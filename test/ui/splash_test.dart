import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/ui/kust_logo.dart';
import 'package:kust/ui/kust_splash.dart';

void main() {
  Widget app({bool reduceMotion = false}) => MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 844),
      disableAnimations: reduceMotion,
    ),
    child: const Directionality(
      textDirection: TextDirection.ltr,
      child: KustSplash(child: Text('app')),
    ),
  );

  testWidgets('starts on the K and fades into the app', (tester) async {
    await tester.pumpWidget(app());
    expect(find.byType(KustSymbol), findsOneWidget);
    // The K starts the size it is on the native splash, centred.
    final k = tester.getRect(find.byType(KustSymbol));
    expect(k.height, SplashArt.startHeight);
    expect(k.center.dy, closeTo(844 / 2, 0.5));

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(KustSymbol), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(KustSymbol), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('is skipped when the system asks for less motion', (
    tester,
  ) async {
    await tester.pumpWidget(app(reduceMotion: true));
    expect(find.byType(KustSymbol), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });
}
