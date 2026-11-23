import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/server_config.dart';
import 'package:kust/core/net/token_storage.dart';

enum AuthStatus { unknown, signedOut, signedIn }

@immutable
class AuthState {
  const AuthState(this.status, [this.account]);

  final AuthStatus status;
  final Account? account;

  bool get isSignedIn => status == AuthStatus.signedIn;
  bool get isVerified => isSignedIn && (account?.emailVerified ?? false);
}

class AuthService {
  AuthService({
    required this.api,
    required this.storage,
    required this.cache,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static AuthService? _instance;

  static AuthService get instance => _instance ??= AuthService(
    api: ApiClient(baseUrl: ServerConfig.apiUrl),
    storage: SecureTokenStorage(),
    cache: HiveAccountCache(),
  );

  final ApiClient api;
  final TokenStorage storage;
  final AccountCache cache;
  final DateTime Function() _now;

  final ValueNotifier<AuthState> _state = ValueNotifier(
    const AuthState(AuthStatus.unknown),
  );

  String? _access;
  DateTime _accessExpiry = DateTime.fromMillisecondsSinceEpoch(0);
  Future<String>? _refreshing;

  ValueListenable<AuthState> get state => _state;

  Future<void> restore() async {
    final refresh = await storage.read();
    if (refresh == null) {
      _state.value = const AuthState(AuthStatus.signedOut);
      return;
    }
    final cached = cache.read();
    _state.value = cached == null
        ? const AuthState(AuthStatus.unknown)
        : AuthState(AuthStatus.signedIn, cached);
    try {
      await _refresh();
    } on ApiException {
      if (_state.value.status == AuthStatus.unknown) {
        _state.value = const AuthState(AuthStatus.signedOut);
      }
    }
  }

  Future<Account> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final json = await api.post(
      '/v1/auth/register',
      body: {'email': email, 'username': username, 'password': password},
    );
    return _applySession(json);
  }

  Future<Account> login({
    required String identifier,
    required String password,
  }) async {
    final json = await api.post(
      '/v1/auth/login',
      body: {'identifier': identifier, 'password': password},
    );
    return _applySession(json);
  }

  Future<void> logout() async {
    final refresh = await storage.read();
    await _signOutLocal();
    if (refresh != null) {
      try {
        await api.post('/v1/auth/logout', body: {'refresh_token': refresh});
      } on ApiException {
        return;
      }
    }
  }

  Future<Account> verifyEmail(String code) async {
    final json = await authed(
      (token) =>
          api.post('/v1/auth/verify-email', body: {'code': code}, token: token),
    );
    return _setAccount(Account.fromJson(json['user'] as Map<String, dynamic>));
  }

  Future<int> resendCode() async {
    final json = await authed(
      (token) => api.post('/v1/auth/resend-code', token: token),
    );
    return (json['retry_after'] as num?)?.toInt() ?? 60;
  }

  /// Why [username] can't be had ('taken', 'reserved', ...), or null when
  /// it is free. Answers are kept, so typing back and forth over the same
  /// names asks the server once: a taken name stays taken for the session,
  /// a free one is trusted for [_freeFor] (someone may take it; sign-up
  /// checks again anyway). Two asks for one name share one request.
  Future<String?> usernameProblem(String username) {
    final known = _usernameAnswers[username];
    if (known != null &&
        (known.problem != null || _now().difference(known.at) < _freeFor)) {
      return Future.value(known.problem);
    }
    // A block body: returning the removed future would make it wait on
    // itself.
    return _usernameAsks[username] ??= _askUsername(username).whenComplete(() {
      _usernameAsks.remove(username);
    });
  }

  static const Duration _freeFor = Duration(seconds: 30);
  final Map<String, ({String? problem, DateTime at})> _usernameAnswers = {};
  final Map<String, Future<String?>> _usernameAsks = {};

  Future<String?> _askUsername(String username) async {
    final json = await api.get(
      '/v1/auth/username-available',
      query: {'u': username},
    );
    final problem = json['available'] == true
        ? null
        : (json['reason'] as String?) ?? 'taken';
    if (_usernameAnswers.length >= 500) _usernameAnswers.clear();
    _usernameAnswers[username] = (problem: problem, at: _now());
    return problem;
  }

  Future<Account> refreshAccount() async {
    final json = await authed((token) => api.get('/v1/me', token: token));
    return _setAccount(Account.fromJson(json['user'] as Map<String, dynamic>));
  }

  Future<Account> updateProfile({
    String? displayName,
    String? bio,
    String? country,
    int? rating,
  }) async {
    final json = await authed(
      (token) => api.patch(
        '/v1/me',
        token: token,
        body: {
          'display_name': ?displayName,
          'bio': ?bio,
          'country': ?country,
          'rating': ?rating,
        },
      ),
    );
    return _setAccount(Account.fromJson(json['user'] as Map<String, dynamic>));
  }

  /// Uploads the profile photo (a small JPEG made by the picker) and keeps
  /// the account it comes back with.
  Future<Account> uploadAvatar(List<int> jpeg) async {
    final json = await authed(
      (token) => api.putBytes(
        '/v1/me/avatar',
        bytes: jpeg,
        contentType: 'image/jpeg',
        token: token,
      ),
    );
    return _setAccount(Account.fromJson(json['user'] as Map<String, dynamic>));
  }

  Future<Account> removeAvatar() async {
    final json = await authed(
      (token) => api.delete('/v1/me/avatar', token: token),
    );
    return _setAccount(Account.fromJson(json['user'] as Map<String, dynamic>));
  }

  Future<Map<String, dynamic>> authed(
    Future<Map<String, dynamic>> Function(String token) call,
  ) async {
    var token = await _ensureAccess();
    try {
      return await call(token);
    } on ApiException catch (e) {
      if (e.status != 401) rethrow;
      token = await _refresh();
      return call(token);
    }
  }

  Future<String?> accessToken() async {
    if (!_state.value.isSignedIn && _state.value.status != AuthStatus.unknown) {
      return null;
    }
    try {
      return await _ensureAccess();
    } on ApiException {
      return null;
    }
  }

  Future<String> _ensureAccess() async {
    final token = _access;
    if (token != null && _now().isBefore(_accessExpiry)) return token;
    return _refresh();
  }

  Future<String> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String> _doRefresh() async {
    final refresh = await storage.read();
    if (refresh == null) {
      await _signOutLocal();
      throw const ApiException(
        code: 'signed_out',
        message: 'Sign in again.',
        status: 401,
      );
    }
    try {
      final json = await api.post(
        '/v1/auth/refresh',
        body: {'refresh_token': refresh},
      );
      await _applySession(json);
      return _access!;
    } on ApiException catch (e) {
      if (e.status == 401) await _signOutLocal();
      rethrow;
    }
  }

  Future<Account> _applySession(Map<String, dynamic> json) async {
    final account = Account.fromJson(json['user'] as Map<String, dynamic>);
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 900;
    _access = json['access_token'] as String;
    _accessExpiry = _now().add(
      Duration(seconds: expiresIn > 60 ? expiresIn - 30 : expiresIn ~/ 2),
    );
    await storage.write(json['refresh_token'] as String);
    return _setAccount(account);
  }

  Future<Account> _setAccount(Account account) async {
    await cache.write(account);
    _state.value = AuthState(AuthStatus.signedIn, account);
    return account;
  }

  Future<void> _signOutLocal() async {
    _access = null;
    _accessExpiry = DateTime.fromMillisecondsSinceEpoch(0);
    await storage.clear();
    await cache.clear();
    _state.value = const AuthState(AuthStatus.signedOut);
  }
}
