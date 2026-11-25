import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/ui/game_player_bar.dart';

void main() {
  testWidgets('every captured-piece figurine loads and draws', (tester) async {
    final assets = [
      for (final side in Side.values)
        for (final role in [
          Role.pawn,
          Role.knight,
          Role.bishop,
          Role.rook,
          Role.queen,
        ])
          capturedAsset(Piece(color: side, role: role)),
    ];
    for (final a in assets) {
      final loader = SvgAssetLoader(a);
      final info = await tester.runAsync(() => vg.loadPicture(loader, null));
      expect(info!.size, const Size(19, 19), reason: a);
      info.picture.dispose();
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Row(children: [for (final a in assets) SvgPicture.asset(a)]),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
