import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/profile/profile_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';
import 'package:kust/ui/kust_button.dart';

void main() {
  late Directory dir;
  final store = AppStorage.instance;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_profile');
    Hive.init(dir.path);
    await AppStorage.init();
    AppStorage.filesDir = dir.path;
  });

  tearDown(() async {
    AppStorage.filesDir = null;
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('a profile needs a name and a valid username', () async {
    expect(await store.saveProfile(name: ' ', username: 'abc', bio: ''), false);
    expect(
      await store.saveProfile(name: 'Ali', username: 'ab', bio: ''),
      false,
    );
    expect(
      await store.saveProfile(name: 'Ali', username: 'a b c', bio: ''),
      false,
    );
    expect(store.username, isNull);

    expect(
      await store.saveProfile(name: 'Ali', username: 'Ali_99', bio: ' Hi '),
      true,
    );
    expect(store.username, 'ali_99');
    expect(store.guestName, 'Ali');
    expect(store.bio, 'Hi');
  });

  test('a photo is copied in, and replaced or removed', () async {
    final picked = File('${dir.path}/picked.jpg')..writeAsBytesSync([1, 2, 3]);
    await store.setPhoto(picked.path);
    final first = store.photoPath!;
    expect(File(first).readAsBytesSync(), [1, 2, 3]);

    await Future<void>.delayed(const Duration(milliseconds: 2));
    await store.setPhoto(picked.path);
    expect(store.photoPath, isNot(first));
    expect(File(first).existsSync(), false);

    final second = store.photoPath!;
    await store.setPhoto(null);
    expect(store.photoPath, isNull);
    expect(File(second).existsSync(), false);
  });

  testWidgets('save stays off until the username is valid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationDelegates,
        home: const ProfileScreen(),
      ),
    );
    await tester.pump();
    KustButton save() => tester.widget(find.byType(KustButton));
    expect(save().onTap, isNull);
    await tester.enterText(find.byType(TextField).at(1), 'kust_fan');
    await tester.pump();
    expect(save().onTap, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
