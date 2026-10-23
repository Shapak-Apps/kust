import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/theme.dart';
import 'package:kust/ui/move_strip.dart';

List<String> _labels(int count) => [
  for (var i = 0; i < count; i++) moveLabel(i, 'x${i + 1}'),
];

Widget _strip(List<String> labels, int selected, {ValueChanged<int>? onTap}) =>
    MaterialApp(
      theme: appTheme,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: MoveStrip(labels: labels, selected: selected, onTap: onTap),
        ),
      ),
    );

void main() {
  setUp(() {});

  testWidgets('moveLabel numbers only White moves', (tester) async {
    expect(moveLabel(0, 'e4'), '1. e4');
    expect(moveLabel(1, 'e5'), 'e5');
    expect(moveLabel(2, 'Nf3'), '2. Nf3');
  });

  testWidgets('starts at the left edge and does not scroll while it fits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (var selected = 0; selected <= 4; selected++) {
      await tester.pumpWidget(_strip(_labels(4), selected));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('1. x1')).dx,
        closeTo(20, 1),
        reason: 'selected $selected',
      );
    }
  });

  testWidgets('centers the current move once the strip overflows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final labels = _labels(60);
    await tester.pumpWidget(_strip(labels, 1));
    await tester.pumpAndSettle();
    // Early moves are before the middle: still at the start.
    expect(tester.getTopLeft(find.text(labels[0])).dx, closeTo(20, 1));

    for (final ply in [20, 30, 40]) {
      await tester.pumpWidget(_strip(labels, ply));
      await tester.pumpAndSettle();
      final center = tester.getCenter(find.text(labels[ply - 1])).dx;
      expect(center, closeTo(200, 2), reason: 'ply $ply');
    }
  });

  testWidgets('the last move cannot scroll past the end', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final labels = _labels(60);
    await tester.pumpWidget(_strip(labels, 60));
    await tester.pumpAndSettle();
    final right = tester.getTopRight(find.text(labels.last)).dx;
    expect(right, closeTo(380, 2)); // 20px end padding, nothing beyond
  });

  testWidgets('highlights only the selected move and reports taps', (
    tester,
  ) async {
    int? tapped;
    await tester.pumpWidget(
      _strip(_labels(4), 2, onTap: (ply) => tapped = ply),
    );
    final selected = tester.widget<Text>(find.text('x2'));
    final other = tester.widget<Text>(find.text('2. x3'));
    expect(selected.style!.fontWeight, FontWeight.w800);
    expect(other.style!.fontWeight, FontWeight.w600);
    expect(selected.style!.color, isNot(other.style!.color));

    await tester.tap(find.text('2. x3'));
    expect(tapped, 3);
  });

  testWidgets('shows the empty text with no moves', (tester) async {
    await tester.pumpWidget(_strip(const [], 0));
    expect(find.text('No moves yet'), findsOneWidget);
  });

  testWidgets('keeps up as moves are added in a live game', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var labels = _labels(2);
    await tester.pumpWidget(_strip(labels, labels.length));
    for (var n = 3; n <= 50; n++) {
      labels = _labels(n);
      await tester.pumpWidget(_strip(labels, n));
      await tester.pumpAndSettle();
    }
    // At the end of a live game the newest move is fully visible.
    final box = tester.getRect(find.text(labels.last));
    expect(box.right, lessThanOrEqualTo(400));
    expect(box.left, greaterThanOrEqualTo(0));
  });
}
