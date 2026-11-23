import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/warm_up.dart';
import 'package:kust/features/train/train_openings.dart';
import 'package:kust/widgets/board_thumbnail.dart';

void main() {
  testWidgets('warmed boards show on the first frame', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    warmBeforeStart();
    await tester.runAsync(warmBoards);
    final o = kTrainOpenings.first;
    final main = o.lines.first;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1),
          child: Center(
            child: SizedBox(
              width: 132,
              child: BoardThumbnail(
                position: main.positions.last,
                flipped: o.side == Side.black,
                highlight: main.lastSquares,
              ),
            ),
          ),
        ),
      ),
    );
    // Drawn already: the picture, not the plain placeholder.
    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byType(FutureBuilder<dynamic>), findsNothing);
  });
}
