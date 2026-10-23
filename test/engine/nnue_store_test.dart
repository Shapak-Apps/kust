import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/nnue_store.dart';

String _nameFor(List<int> bytes) =>
    'nn-${sha256.convert(bytes).toString().substring(0, 12)}.nnue';

/// Serves in-memory assets, so no real bundle or network is involved.
class _FakeBundle extends CachingAssetBundle {
  final Map<String, List<int>> assets = {};
  int loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    final data = assets[key];
    if (data == null) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(data));
  }
}

void main() {
  late Directory dir;
  late _FakeBundle bundle;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_nnue_test');
    bundle = _FakeBundle();
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  /// Registers [bytes] as gzip pieces of [chunk] bytes under [name].
  void addNetwork(String name, List<int> bytes, {int chunk = 1 << 30}) {
    var n = 0;
    for (var i = 0; i < bytes.length || n == 0; i += chunk) {
      final end = (i + chunk).clamp(0, bytes.length);
      bundle.assets['assets/engine/$name.$n.gz'] = gzip.encode(
        bytes.sublist(i, end),
      );
      n++;
    }
  }

  NnueStore store() => NnueStore(
    bundle: bundle,
    listParts: (name) async => [
      for (final key in bundle.assets.keys)
        if (key.startsWith('assets/engine/$name.')) key,
    ],
  );

  test('verify accepts matching content and rejects anything else', () async {
    final bytes = utf8.encode('network contents');
    final name = _nameFor(bytes);
    final file = File('${dir.path}/$name')..writeAsBytesSync(bytes);
    expect(await NnueStore.verify(file, name), isTrue);

    file.writeAsBytesSync(utf8.encode('tampered'));
    expect(await NnueStore.verify(file, name), isFalse);
    expect(await NnueStore.verify(File('${dir.path}/missing'), name), isFalse);
    expect(await NnueStore.verify(file, 'not-a-network.bin'), isFalse);
  });

  test('ensure unpacks pieces in numeric order and verifies', () async {
    // 12 pieces so that piece 10 would sort before piece 2 as text.
    final bytes = List<int>.generate(1200, (i) => (i * 7) % 251);
    final name = _nameFor(bytes);
    addNetwork(name, bytes, chunk: 100);

    final path = await store().ensure(name, dir.path);
    expect(File(path).readAsBytesSync(), bytes);
    expect(File('$path.part').existsSync(), isFalse);
  });

  test('ensure trusts an already verified file without unpacking', () async {
    final bytes = utf8.encode('cached network');
    final name = _nameFor(bytes);
    addNetwork(name, bytes);

    await store().ensure(name, dir.path);
    final loadsAfterFirst = bundle.loads;
    await store().ensure(name, dir.path);
    expect(bundle.loads, loadsAfterFirst);
  });

  test('ensure unpacks again when the file was damaged', () async {
    final bytes = utf8.encode('fresh network');
    final name = _nameFor(bytes);
    addNetwork(name, bytes);

    final path = await store().ensure(name, dir.path);
    File(path).writeAsBytesSync(utf8.encode('x'));
    await store().ensure(name, dir.path);
    expect(File(path).readAsBytesSync(), bytes);
  });

  test('ensure fails when the pieces do not match the name', () async {
    final name = _nameFor(utf8.encode('what we expected'));
    addNetwork(name, utf8.encode('something else'));

    await expectLater(
      store().ensure(name, dir.path),
      throwsA(isA<NnueException>()),
    );
    expect(File('${dir.path}/$name').existsSync(), isFalse);
    expect(File('${dir.path}/$name.part').existsSync(), isFalse);
  });

  test('ensure fails clearly when the build has no engine files', () async {
    await expectLater(
      store().ensure('nn-000000000000.nnue', dir.path),
      throwsA(isA<NnueException>()),
    );
  });

  test('the packed networks in assets/engine match their names', () async {
    for (final name in ['nn-c288c895ea92.nnue', 'nn-37f18f62d772.nnue']) {
      final pieces =
          Directory('assets/engine')
              .listSync()
              .whereType<File>()
              .where((f) => f.path.contains('$name.'))
              .toList()
            ..sort((a, b) {
              int n(File f) =>
                  int.parse(f.path.split('.').reversed.elementAt(1));
              return n(a).compareTo(n(b));
            });
      expect(pieces, isNotEmpty, reason: name);
      final all = BytesBuilder(copy: false);
      for (final piece in pieces) {
        all.add(gzip.decode(piece.readAsBytesSync()));
      }
      final digest = sha256.convert(all.takeBytes()).toString();
      expect(digest.substring(0, 12), name.substring(3, 15));
    }
  });

  test('engine start fails with a typed error and can be retried', () async {
    // The test host is not Android or iOS, so the engine is unsupported.
    final engine = ChessEngine.instance;
    await expectLater(
      engine.start(),
      throwsA(isA<EngineUnavailableException>()),
    );
    // The failure is not cached: a second call fails again instead of hanging
    // on, or reusing, the first attempt.
    await expectLater(
      engine.start(),
      throwsA(isA<EngineUnavailableException>()),
    );
    expect(engine.isReady, isFalse);
    await expectLater(
      engine.bestMoveForFen('8/8/8/8/8/8/8/8 w - - 0 1'),
      throwsA(isA<EngineUnavailableException>()),
    );
  });
}
