import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/auth/login_screen.dart';
import 'package:kust/theme.dart';

void main() {
  testWidgets('sign in is bare: title, two fields, button, link, skip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const LoginScreen(next: '/onboarding?step=name'),
      ),
    );
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Skip for now'), findsOneWidget);
    expect(find.textContaining("Don't have an account?"), findsOneWidget);
    expect(find.text("You're offline"), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
