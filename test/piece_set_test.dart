import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/piece_set.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/chess_helpers.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/theme.dart';
import 'package:kust/widgets/more_sheet.dart';

void main() {
  tearDown(() {
    AppSettings.instance.pieceSet.value = PieceSet.defaultSet;
  });

  group('sets', () {
    test('there are four, the classic one and three new ones', () {
      expect(PieceSet.values.map((s) => s.label), [
        'Classic',
        'Shaded',
        'Neo',
        'Modern',
      ]);
      expect(PieceSet.classic.asset('w', 'K'), 'assets/pieces/wK.svg');
      expect(PieceSet.neo.asset('b', 'N'), 'assets/pieces/neo/bN.svg');
    });

    test('every piece of every set is bundled and is a square svg', () {
      final pubspec = io.File('pubspec.yaml').readAsStringSync();
      for (final set in PieceSet.values) {
        expect(set.assets, hasLength(12));
        for (final asset in set.assets) {
          final file = io.File(asset);
          expect(file.existsSync(), isTrue, reason: asset);
          final text = file.readAsStringSync();
          expect(text, contains('<svg'), reason: asset);
          expect(
            text,
            anyOf(
              contains('viewBox="0 0 45 45"'),
              contains('viewBox="2 1.5 41 41"'),
              contains('viewBox="0 0 100 100"'),
            ),
            reason: asset,
          );
          final folder = asset.substring(0, asset.lastIndexOf('/') + 1);
          expect(pubspec, contains('- $folder\n'), reason: folder);
        }
      }
    });

    test('gradient ids are unique to each piece, so pieces never clash', () {
      final ids = <String>{};
      for (final set in PieceSet.values.where((s) => s != PieceSet.classic)) {
        for (final asset in set.assets) {
          final text = io.File(asset).readAsStringSync();
          for (final m in RegExp(r'id="([^"]+)"').allMatches(text)) {
            expect(ids.add(m.group(1)!), isTrue, reason: m.group(1));
          }
        }
      }
    });

    test('a saved name maps back to its set, anything else to the default', () {
      for (final s in PieceSet.values) {
        expect(PieceSet.fromName(s.name), s);
      }
      expect(PieceSet.fromName(null), PieceSet.defaultSet);
      expect(PieceSet.fromName('glass'), PieceSet.defaultSet);
    });

    testWidgets('every piece parses and draws', (tester) async {
      for (final set in PieceSet.values) {
        for (final asset in set.assets) {
          final text = io.File(asset).readAsStringSync();
          await tester.pumpWidget(
            Center(
              child: SizedBox.square(
                dimension: 64,
                child: SvgPicture.string(text),
              ),
            ),
          );
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: asset);
        }
      }
    });
  });

  group('settings', () {
    test('the choice is saved, loaded again and used for pieces', () async {
      SharedPreferences.setMockInitialValues({'piece_set': 'modern'});
      final s = AppSettings.instance;
      await s.load();
      expect(s.pieceSet.value, PieceSet.modern);
      expect(
        assetForPiece(const Piece(color: Side.black, role: Role.queen)),
        'assets/pieces/modern/bQ.svg',
      );

      await s.setPieceSet(PieceSet.classic);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('piece_set'), 'classic');
      expect(
        assetForPiece(const Piece(color: Side.white, role: Role.king)),
        'assets/pieces/wK.svg',
      );

      SharedPreferences.setMockInitialValues({});
      await s.load();
      expect(s.pieceSet.value, PieceSet.defaultSet);
    });

    testWidgets('the settings sheet lists the sets and picks one', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() => AppSettings.instance.load());
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showSettingsSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('PIECES'), findsOneWidget);
      expect(find.byType(PieceSetSwatch), findsNWidgets(4));
      bool selected(PieceSet set) => tester
          .widget<PieceSetSwatch>(
            find.byWidgetPredicate((w) => w is PieceSetSwatch && w.set == set),
          )
          .selected;
      expect(selected(PieceSet.shaded), isTrue);

      await tester.ensureVisible(find.text('Neo'));
      await tester.tap(find.text('Neo'));
      await tester.pumpAndSettle();
      expect(AppSettings.instance.pieceSet.value, PieceSet.neo);
      expect(selected(PieceSet.neo), isTrue);
      expect(selected(PieceSet.shaded), isFalse);
    });

    testWidgets('a board on screen redraws with the new set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: Scaffold(
            body: SizedBox.square(
              dimension: 320,
              child: PuzzleBoard(
                position: Chess.initial,
                flipped: false,
                interactive: false,
                onMove: (_) {},
              ),
            ),
          ),
        ),
      );
      String firstPiece() =>
          (tester
                      .widgetList<SvgPicture>(find.byType(SvgPicture))
                      .first
                      .bytesLoader
                  as SvgAssetLoader)
              .assetName;
      expect(firstPiece(), startsWith('assets/pieces/shaded/'));
      AppSettings.instance.pieceSet.value = PieceSet.modern;
      await tester.pump();
      expect(firstPiece(), startsWith('assets/pieces/modern/'));
    });
  });
}
