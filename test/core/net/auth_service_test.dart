import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/token_storage.dart';

import 'fake_adapter.dart';

Map<String, dynamic> _user({bool verified = false}) => {
  'id': 'u1',
  'email': 'dev@example.com',
  'username': 'dev_one',
  'display_name': 'dev_one',
  'bio': '',
  'country': null,
  'rating': 1200,
  'email_verified': verified,
};

Map<String, dynamic> _session({
  String access = 'access-1',
  String refresh = 'refresh-1',
  bool verified = false,
  int expiresIn = 900,
}) => {
  'user': _user(verified: verified),
  'access_token': access,
  'refresh_token': refresh,
  'expires_in': expiresIn,
};

class _Rig {
  _Rig(FakeHandler handler) {
    final t = testApi(handler);
    adapter = t.adapter;
    storage = MemoryTokenStorage();
    cache = MemoryAccountCache();
    service = AuthService(
      api: t.api,
      storage: storage,
      cache: cache,
      now: () => clock,
    );
  }

  late final FakeAdapter adapter;
  late final MemoryTokenStorage storage;
  late final MemoryAccountCache cache;
  late final AuthService service;
  DateTime clock = DateTime(2026, 1, 1, 12);

  int count(String path) =>
      adapter.requests.where((r) => r.path == path).length;
}

void main() {
  test('login stores the session and signs in', () async {
    final rig = _Rig((o) => jsonBody(_session()));
    final account = await rig.service.login(
      identifier: 'dev_one',
      password: 'password123',
    );
    expect(account.username, 'dev_one');
    expect(rig.service.state.value.isSignedIn, isTrue);
    expect(rig.service.state.value.isVerified, isFalse);
    expect(await rig.storage.read(), 'refresh-1');
    expect(rig.cache.read()?.email, 'dev@example.com');
    expect(rig.adapter.requests.single.data, {
      'identifier': 'dev_one',
      'password': 'password123',
    });
  });

  test('a wrong password throws and leaves the state alone', () async {
    final rig = _Rig(
      (o) => jsonBody({
        'error': {'code': 'invalid_credentials', 'message': 'no'},
      }, status: 401),
    );
    await expectLater(
      rig.service.login(identifier: 'x', password: 'y'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          'invalid_credentials',
        ),
      ),
    );
    expect(rig.service.state.value.status, AuthStatus.unknown);
    expect(await rig.storage.read(), isNull);
  });

  test('register sends the three fields and signs in', () async {
    final rig = _Rig((o) => jsonBody(_session(), status: 201));
    await rig.service.register(
      email: 'dev@example.com',
      username: 'dev_one',
      password: 'password123',
    );
    expect(rig.adapter.requests.single.path, '/v1/auth/register');
    expect(rig.adapter.requests.single.data, {
      'email': 'dev@example.com',
      'username': 'dev_one',
      'password': 'password123',
    });
    expect(rig.service.state.value.isSignedIn, isTrue);
  });

  test('verifyEmail marks the account verified', () async {
    final rig = _Rig((o) {
      if (o.path == '/v1/auth/verify-email') {
        return jsonBody({'user': _user(verified: true)});
      }
      return jsonBody(_session());
    });
    await rig.service.login(identifier: 'dev_one', password: 'password123');
    final account = await rig.service.verifyEmail('123456');
    expect(account.emailVerified, isTrue);
    expect(rig.service.state.value.isVerified, isTrue);
    final verify = rig.adapter.requests.last;
    expect(verify.headers['Authorization'], 'Bearer access-1');
    expect(verify.data, {'code': '123456'});
  });

  test('an expired access token is refreshed before the call', () async {
    final rig = _Rig((o) {
      if (o.path == '/v1/auth/refresh') {
        return jsonBody(_session(access: 'access-2', refresh: 'refresh-2'));
      }
      if (o.path == '/v1/me') return jsonBody({'user': _user()});
      return jsonBody(_session());
    });
    await rig.service.login(identifier: 'dev_one', password: 'password123');
    rig.clock = rig.clock.add(const Duration(minutes: 20));

    await rig.service.refreshAccount();

    expect(rig.count('/v1/auth/refresh'), 1);
    expect(
      rig.adapter.requests.last.headers['Authorization'],
      'Bearer access-2',
    );
    expect(await rig.storage.read(), 'refresh-2');
  });

  test('a 401 on a call refreshes once and retries', () async {
    var meCalls = 0;
    final rig = _Rig((o) {
      if (o.path == '/v1/auth/refresh') {
        return jsonBody(_session(access: 'access-2', refresh: 'refresh-2'));
      }
      if (o.path == '/v1/me') {
        meCalls++;
        if (meCalls == 1) {
          return jsonBody({
            'error': {'code': 'token_expired', 'message': 'expired'},
          }, status: 401);
        }
        return jsonBody({'user': _user()});
      }
      return jsonBody(_session());
    });
    await rig.service.login(identifier: 'dev_one', password: 'password123');

    await rig.service.refreshAccount();

    expect(meCalls, 2);
    expect(rig.count('/v1/auth/refresh'), 1);
  });

  test('two calls at once share one refresh', () async {
    final rig = _Rig((o) {
      if (o.path == '/v1/auth/refresh') {
        return jsonBody(_session(access: 'access-2', refresh: 'refresh-2'));
      }
      if (o.path == '/v1/me') return jsonBody({'user': _user()});
      return jsonBody(_session());
    });
    await rig.service.login(identifier: 'dev_one', password: 'password123');
    rig.clock = rig.clock.add(const Duration(hours: 1));

    await Future.wait([
      rig.service.refreshAccount(),
      rig.service.refreshAccount(),
    ]);

    expect(rig.count('/v1/auth/refresh'), 1);
  });

  test('a rejected refresh token signs the user out', () async {
    final rig = _Rig((o) {
      if (o.path == '/v1/auth/refresh') {
        return jsonBody({
          'error': {'code': 'refresh_reused', 'message': 'no'},
        }, status: 401);
      }
      return jsonBody(_session());
    });
    await rig.service.login(identifier: 'dev_one', password: 'password123');
    rig.clock = rig.clock.add(const Duration(hours: 1));

    await expectLater(
      rig.service.refreshAccount(),
      throwsA(isA<ApiException>()),
    );

    expect(rig.service.state.value.status, AuthStatus.signedOut);
    expect(await rig.storage.read(), isNull);
    expect(rig.cache.read(), isNull);
  });

  test('restore without a saved token is signed out', () async {
    final rig = _Rig((o) => jsonBody(_session()));
    await rig.service.restore();
    expect(rig.service.state.value.status, AuthStatus.signedOut);
    expect(rig.adapter.requests, isEmpty);
  });

  test('restore offline keeps the saved account signed in', () async {
    final rig = _Rig(networkDown);
    await rig.storage.write('refresh-1');
    await rig.cache.write(
      (await _Rig((o) => jsonBody(_session())).service
          .login(identifier: 'a', password: 'b')),
    );

    await rig.service.restore();

    expect(rig.service.state.value.isSignedIn, isTrue);
    expect(rig.service.state.value.account?.username, 'dev_one');
    expect(await rig.storage.read(), 'refresh-1');
  });

  test(
    'restore offline with nothing cached falls back to signed out',
    () async {
      final rig = _Rig(networkDown);
      await rig.storage.write('refresh-1');
      await rig.service.restore();
      expect(rig.service.state.value.status, AuthStatus.signedOut);
      expect(await rig.storage.read(), 'refresh-1');
    },
  );

  test('restore online refreshes the session', () async {
    final rig = _Rig(
      (o) => jsonBody(_session(access: 'a2', refresh: 'r2', verified: true)),
    );
    await rig.storage.write('refresh-1');
    await rig.service.restore();
    expect(rig.service.state.value.isVerified, isTrue);
    expect(await rig.storage.read(), 'r2');
  });

  test('logout clears everything and tells the server', () async {
    final rig = _Rig((o) {
      if (o.path == '/v1/auth/logout') return emptyBody(204);
      return jsonBody(_session());
    });
    await rig.service.login(identifier: 'dev_one', password: 'password123');
    await rig.service.logout();
    expect(rig.service.state.value.status, AuthStatus.signedOut);
    expect(await rig.storage.read(), isNull);
    expect(rig.cache.read(), isNull);
    final call = rig.adapter.requests.last;
    expect(call.path, '/v1/auth/logout');
    expect(call.data, {'refresh_token': 'refresh-1'});
  });

  test('logout still signs out locally when offline', () async {
    final rig = _Rig((o) {
      if (o.path == '/v1/auth/logout') networkDown(o);
      return jsonBody(_session());
    });
    await rig.service.login(identifier: 'dev_one', password: 'password123');
    await rig.service.logout();
    expect(rig.service.state.value.status, AuthStatus.signedOut);
  });

  test('usernameProblem reports availability reasons', () async {
    final rig = _Rig(
      (o) => jsonBody(
        o.queryParameters['u'] == 'free'
            ? {'available': true}
            : {'available': false, 'reason': 'taken'},
      ),
    );
    expect(await rig.service.usernameProblem('free'), isNull);
    expect(await rig.service.usernameProblem('used'), 'taken');
  });

  test('resendCode returns the wait the server asks for', () async {
    final rig = _Rig((o) {
      if (o.path == '/v1/auth/resend-code') {
        return jsonBody({'sent': true, 'retry_after': 60});
      }
      return jsonBody(_session());
    });
    await rig.service.login(identifier: 'dev_one', password: 'password123');
    expect(await rig.service.resendCode(), 60);
  });

  test('username checks are cached and shared', () async {
    final rig = _Rig(
      (o) => jsonBody(
        o.queryParameters['u'] == 'taken_one'
            ? {'available': false, 'reason': 'taken'}
            : {'available': true},
      ),
    );
    const path = '/v1/auth/username-available';
    // Two asks at once: one request.
    final both = await Future.wait([
      rig.service.usernameProblem('free_one'),
      rig.service.usernameProblem('free_one'),
    ]);
    expect(both, [null, null]);
    expect(rig.count(path), 1);
    // Asked again soon: from memory.
    expect(await rig.service.usernameProblem('free_one'), isNull);
    expect(rig.count(path), 1);
    // A free answer goes stale after 30 s; a taken one does not.
    expect(await rig.service.usernameProblem('taken_one'), 'taken');
    rig.clock = rig.clock.add(const Duration(minutes: 5));
    expect(await rig.service.usernameProblem('taken_one'), 'taken');
    expect(rig.count(path), 2);
    expect(await rig.service.usernameProblem('free_one'), isNull);
    expect(rig.count(path), 3);
  });
}
