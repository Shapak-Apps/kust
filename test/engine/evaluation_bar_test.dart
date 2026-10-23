import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/evaluation_bar.dart';

Widget _bar(EvalScore? score, {bool whiteOnLeft = true}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 300,
        child: EvaluationBar(score: score, whiteOnLeft: whiteOnLeft),
      ),
    ),
  ),
);

void main() {
  testWidgets('draws its label exactly once', (tester) async {
    for (final score in const [
      EvalScore(cp: 90),
      EvalScore(cp: -90),
      EvalScore(mate: 3),
      null,
    ]) {
      await tester.pumpWidget(_bar(score));
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsOneWidget, reason: '$score');
    }
  });

  testWidgets('the label is fully inside the bar, never clipped', (
    tester,
  ) async {
    for (final white in [true, false]) {
      for (final cp in [-900, -90, 0, 90, 900]) {
        await tester.pumpWidget(_bar(EvalScore(cp: cp), whiteOnLeft: white));
        await tester.pumpAndSettle();
        final bar = tester.getRect(find.byType(EvaluationBar));
        final label = tester.getRect(find.byType(Text));
        expect(bar.contains(label.topLeft), isTrue, reason: '$cp $white');
        expect(bar.contains(label.bottomRight), isTrue, reason: '$cp $white');
      }
    }
  });

  testWidgets('has no rounded corners or border', (tester) async {
    await tester.pumpWidget(_bar(const EvalScore(cp: 50)));
    expect(find.byType(ClipRRect), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border != null,
      ),
      findsNothing,
    );
  });

  testWidgets('the white fill follows the score and the side', (tester) async {
    await tester.pumpWidget(_bar(const EvalScore(cp: 900)));
    await tester.pumpAndSettle();
    final fill = tester.getRect(
      find.byWidgetPredicate((w) => w is ColoredBox && w.color == Colors.white),
    );
    final bar = tester.getRect(find.byType(EvaluationBar));
    expect(fill.left, bar.left);
    expect(fill.width / bar.width, greaterThan(0.9));
  });

  testWidgets('the white fill sits on the right when flipped', (tester) async {
    await tester.pumpWidget(_bar(const EvalScore(cp: 900), whiteOnLeft: false));
    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byType(EvaluationBar));
    final flipped = tester.getRect(
      find.byWidgetPredicate((w) => w is ColoredBox && w.color == Colors.white),
    );
    expect(flipped.right, bar.right);
  });
}
