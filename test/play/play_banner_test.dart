import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/play/play_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';

void main() {
  late Directory dir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('kust_play');
    Hive.init(dir.path);
    await AppStorage.init();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  for (final entry in {'en': '', 'ru': '', 'tk': ''}.entries) {
    testWidgets('the home screen fits in ${entry.key}', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final errors = <String>[];
      final old = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      addTearDown(() => FlutterError.onError = old);
      await tester.pumpWidget(
        MaterialApp(
          theme: appDarkTheme,
          locale: Locale(entry.key),
          supportedLocales: kSupportedLocales,
          localizationsDelegates: kLocalizationDelegates,
          home: const Scaffold(body: PlayScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Image), findsWidgets);
      expect(errors, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
    });
  }
}
