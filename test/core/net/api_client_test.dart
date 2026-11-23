import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/net/api_client.dart';

import 'fake_adapter.dart';

void main() {
  test('get returns the decoded object and sends token and query', () async {
    final t = testApi((o) => jsonBody({'ok': true}));
    final json = await t.api.get(
      '/v1/players',
      query: {'q': 'ab', 'limit': '5'},
      token: 'tok',
    );
    expect(json, {'ok': true});
    final sent = t.adapter.requests.single;
    expect(sent.method, 'GET');
    expect(sent.uri.path, '/v1/players');
    expect(sent.uri.queryParameters, {'q': 'ab', 'limit': '5'});
    expect(sent.headers['Authorization'], 'Bearer tok');
  });

  test('post sends a JSON body without a token', () async {
    final t = testApi((o) => jsonBody({'id': 1}, status: 201));
    final json = await t.api.post('/v1/auth/login', body: {'a': 'b'});
    expect(json, {'id': 1});
    final sent = t.adapter.requests.single;
    expect(sent.method, 'POST');
    expect(sent.data, {'a': 'b'});
    expect(sent.headers.containsKey('Authorization'), isFalse);
  });

  test('patch uses the PATCH method', () async {
    final t = testApi((o) => jsonBody({'user': {}}));
    await t.api.patch('/v1/me', body: {'bio': 'x'}, token: 't');
    expect(t.adapter.requests.single.method, 'PATCH');
  });

  test('an empty success body becomes an empty map', () async {
    final t = testApi((o) => emptyBody(204));
    expect(await t.api.post('/v1/auth/logout', body: {}), isEmpty);
  });

  test('server errors keep code, message, status and retry_after', () async {
    final t = testApi(
      (o) => jsonBody({
        'error': {
          'code': 'resend_wait',
          'message': 'Wait a moment.',
          'retry_after': 42,
        },
      }, status: 429),
    );
    await expectLater(
      t.api.post('/v1/auth/resend-code'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'resend_wait')
            .having((e) => e.message, 'message', 'Wait a moment.')
            .having((e) => e.status, 'status', 429)
            .having((e) => e.retryAfter, 'retryAfter', 42)
            .having((e) => e.isNetwork, 'isNetwork', isFalse),
      ),
    );
  });

  test('an error without the usual body gets an http code', () async {
    final t = testApi((o) => textBody('Bad gateway', 502));
    await expectLater(
      t.api.get('/v1/me'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'http_502')
            .having((e) => e.status, 'status', 502),
      ),
    );
  });

  test('a success that is not an object is a bad response', () async {
    final t = testApi((o) => jsonBody([1, 2, 3]));
    await expectLater(
      t.api.get('/v1/me'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiException.badResponseCode,
        ),
      ),
    );
  });

  test('connection failures become network errors', () async {
    final t = testApi(networkDown);
    await expectLater(
      t.api.get('/v1/me'),
      throwsA(
        isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', true),
      ),
    );
  });

  test('timeouts become network errors', () async {
    final t = testApi(
      (o) => throw DioException(
        requestOptions: o,
        type: DioExceptionType.receiveTimeout,
      ),
    );
    await expectLater(
      t.api.get('/v1/me'),
      throwsA(
        isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', true),
      ),
    );
  });

  test('ping is true only for a 200 from /healthz', () async {
    var status = 200;
    final t = testApi((o) => jsonBody({'status': 'ok'}, status: status));
    expect(await t.api.ping(), isTrue);
    expect(t.adapter.requests.single.uri.path, '/healthz');
    status = 503;
    expect(await t.api.ping(), isFalse);
  });

  test('ping is false when the network is down', () async {
    final t = testApi(networkDown);
    expect(await t.api.ping(), isFalse);
  });
}
