import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/auth/auth_support.dart';
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

  test('password rules match the server', () {
    expect(
      passwordRules('Kust-Chess-42', 'merdan', 'm@x.io'),
      everyElement(true),
    );
    expect(passwordRules('kustchess42', 'merdan', 'm@x.io')[1], isFalse);
    expect(passwordRules('KUSTCHESS42', 'merdan', 'm@x.io')[2], isFalse);
    expect(passwordRules('KustChess', 'merdan', 'm@x.io')[3], isFalse);
    expect(passwordRules('Merdan2026x', 'merdan', 'm@x.io')[4], isFalse);
    expect(passwordRules('Short1a', 'merdan', 'm@x.io')[0], isFalse);
  });
}
