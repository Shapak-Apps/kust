import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:kust/core/error_log.dart';
import 'package:kust/core/storage/app_storage.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_recovery');
    Hive.init(dir.path);
  });

  tearDown(() async {
    AppStorage.opener = Hive.openBox;
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('an unreadable box is reset and the app still starts', () async {
    final bots = await Hive.openBox(AppStorage.botProgressBoxName);
    await bots.put('beaten_x', true);
    await Hive.close();

    var failed = false;
    AppStorage.opener = (name) async {
      if (name == AppStorage.historyBoxName && !failed) {
        failed = true;
        throw const FileSystemException('unreadable');
      }
      return Hive.openBox(name);
    };

    await AppStorage.init();

    expect(AppStorage.resetBoxes, [AppStorage.historyBoxName]);
    expect(Hive.box(AppStorage.historyBoxName).isOpen, isTrue);
    expect(Hive.box(AppStorage.historyBoxName).isEmpty, isTrue);
    expect(Hive.box(AppStorage.botProgressBoxName).get('beaten_x'), isTrue);
  });

  test('a damaged file does not stop the app either', () async {
    File('${dir.path}/${AppStorage.historyBoxName}.hive')
        .writeAsBytesSync(List<int>.filled(64, 0xFF));
    await AppStorage.init();
    expect(Hive.box(AppStorage.historyBoxName).isOpen, isTrue);
  });

  test('ErrorLog keeps the last entries only', () {
    ErrorLog.entries.clear();
    for (var i = 0; i < ErrorLog.capacity + 5; i++) {
      ErrorLog.record('e$i', null);
    }
    expect(ErrorLog.entries.length, ErrorLog.capacity);
    expect(ErrorLog.entries.last, 'e${ErrorLog.capacity + 4}');
  });
}
