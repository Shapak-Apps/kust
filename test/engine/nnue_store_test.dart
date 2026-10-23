import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/nnue_store.dart';

String _nameFor(List<int> bytes) =>
    'nn-${sha256.convert(bytes).toString().substring(0, 12)}.nnue';

void main() {
  late Directory dir;
  late HttpServer server;
  late Map<String, List<int>> served;
  var hits = 0;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_nnue_test');
    served = {};
    hits = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      hits++;
      final name = request.uri.pathSegments.last;
      final body = served[name];
      if (body == null) {
        request.response.statusCode = 404;
      } else {
        request.response.add(body);
      }
      request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await dir.delete(recursive: true);
  });

  NnueStore store() => NnueStore(baseUrl: 'http://127.0.0.1:${server.port}/nn');

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

  test('ensure downloads, verifies and keeps no partial file', () async {
    final bytes = utf8.encode('good network');
    final name = _nameFor(bytes);
    served[name] = bytes;

    final path = await store().ensure(name, dir.path);
    expect(File(path).readAsBytesSync(), bytes);
    expect(File('$path.part').existsSync(), isFalse);
  });

  test('ensure reuses a valid file without downloading', () async {
    final bytes = utf8.encode('cached network');
    final name = _nameFor(bytes);
    File('${dir.path}/$name').writeAsBytesSync(bytes);

    await store().ensure(name, dir.path);
    expect(hits, 0);
  });

  test('ensure replaces a corrupt file', () async {
    final bytes = utf8.encode('fresh network');
    final name = _nameFor(bytes);
    served[name] = bytes;
    File('${dir.path}/$name').writeAsBytesSync(utf8.encode('corrupt'));

    final path = await store().ensure(name, dir.path);
    expect(File(path).readAsBytesSync(), bytes);
  });

  test('ensure fails when the download does not match its name', () async {
    final name = _nameFor(utf8.encode('what we expected'));
    served[name] = utf8.encode('something else');

    await expectLater(
      store().ensure(name, dir.path, attempts: 1),
      throwsA(isA<NnueException>()),
    );
    expect(File('${dir.path}/$name').existsSync(), isFalse);
    expect(File('${dir.path}/$name.part').existsSync(), isFalse);
  });

  test('ensure fails cleanly on a 404', () async {
    await expectLater(
      store().ensure('nn-000000000000.nnue', dir.path, attempts: 1),
      throwsA(isA<NnueException>()),
    );
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
