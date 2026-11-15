import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/l10n/gen/app_localizations.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_name');
    Hive.init(dir.path);
    await AppStorage.init();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('the random guest name shows as "Player" in the app language', () {
    expect(
      AppStorage.instance.displayName(lookupAppL10n(const Locale('tk'))),
      'Oýunçy',
    );
    expect(
      AppStorage.instance.displayName(lookupAppL10n(const Locale('ru'))),
      'Игрок',
    );
  });

  test('a chosen name is trimmed, shortened and kept', () async {
    final t = lookupAppL10n(const Locale('en'));
    await AppStorage.instance.setGuestName('  Merdan  ');
    expect(AppStorage.instance.displayName(t), 'Merdan');

    await AppStorage.instance.setGuestName('A very long name indeed, yes');
    expect(AppStorage.instance.displayName(t).length, AppStorage.maxNameLength);

    await AppStorage.instance.setGuestName('   ');
    expect(AppStorage.instance.displayName(t).length, AppStorage.maxNameLength);
  });
}
