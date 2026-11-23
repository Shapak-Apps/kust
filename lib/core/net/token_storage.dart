import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/storage/app_storage.dart';

abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'kust_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

class MemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

abstract class AccountCache {
  Account? read();
  Future<void> write(Account account);
  Future<void> clear();
}

class HiveAccountCache implements AccountCache {
  static const String _key = 'account';

  Box get _box => Hive.box(AppStorage.userBoxName);

  @override
  Account? read() {
    final raw = _box.get(_key);
    if (raw is! String) return null;
    try {
      return Account.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(Account account) =>
      _box.put(_key, jsonEncode(account.toJson()));

  @override
  Future<void> clear() => _box.delete(_key);
}

class MemoryAccountCache implements AccountCache {
  Account? account;

  @override
  Account? read() => account;

  @override
  Future<void> write(Account value) async => account = value;

  @override
  Future<void> clear() async => account = null;
}
