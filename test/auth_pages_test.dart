import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/auth/auth_support.dart';
import 'package:kust/features/auth/login_screen.dart';
import 'package:kust/theme.dart';
import 'package:kust/ui/code_boxes.dart';
import 'package:kust/ui/kust_text_field.dart';

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

  testWidgets('the step label shows the current number in gold', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(body: StepLabel(step: 2, total: 2)),
      ),
    );
    final rich = tester.widget<RichText>(find.byType(RichText).first);
    final spans = (rich.text as TextSpan).children!.first as TextSpan;
    final parts = spans.children!.cast<TextSpan>();
    expect(parts.map((p) => p.text).join(), 'Step 2 of 2');
    final numbers = parts.where((p) => p.text == '2').toList();
    expect(numbers.first.style!.color, const Color(0xFFFFBB00));
    expect(numbers.last.style!.color, isNot(const Color(0xFFFFBB00)));
    expect(numbers.first.style!.fontSize, 20);
  });

  testWidgets('the eye shows and hides a password', (tester) async {
    final c = TextEditingController(text: 'Secret123');
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: KustTextField(controller: c, maxLength: 128, obscure: true),
        ),
      ),
    );
    bool hidden() =>
        tester.widget<TextField>(find.byType(TextField)).obscureText;
    expect(hidden(), isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(hidden(), isFalse);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(hidden(), isTrue);
  });

  testWidgets('the code shows one digit per box and takes a paste', (
    tester,
  ) async {
    final c = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: Scaffold(body: CodeBoxes(controller: c)),
      ),
    );
    await tester.enterText(find.byType(TextField), '12a3456789');
    await tester.pump();
    expect(c.text, '123456');
    for (final d in ['1', '2', '3', '4', '5', '6']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a judged code runs its wave and settles', (tester) async {
    final c = TextEditingController(text: '123456');
    Widget boxes(CodeStatus status) => MaterialApp(
      theme: appTheme,
      home: Scaffold(
        body: CodeBoxes(controller: c, status: status),
      ),
    );
    await tester.pumpWidget(boxes(CodeStatus.typing));
    for (final status in [CodeStatus.correct, CodeStatus.wrong]) {
      await tester.pumpWidget(boxes(status));
      await tester.pump(CodeBoxes.wave ~/ 2);
      await tester.pump(CodeBoxes.wave);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(boxes(CodeStatus.typing));
    }
  });
}
