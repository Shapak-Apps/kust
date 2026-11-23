import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/storage/app_storage.dart';

class PlayersPage {
  const PlayersPage({required this.players, required this.nextCursor});

  final List<Player> players;
  final String? nextCursor;
}

class CachedPlayers {
  const CachedPlayers(this.players, this.savedAt);

  final List<Player> players;
  final DateTime savedAt;
}

abstract class PlayersCache {
  CachedPlayers? read();
  Future<void> write(List<Player> players, DateTime at);
  Future<void> clear();
}

class HivePlayersCache implements PlayersCache {
  static const String _key = 'players_cache';

  Box get _box => Hive.box(AppStorage.userBoxName);

  @override
  CachedPlayers? read() {
    final raw = _box.get(_key);
    if (raw is! String) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = (json['players'] as List)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList();
      return CachedPlayers(
        list,
        DateTime.fromMillisecondsSinceEpoch(json['saved_at'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(List<Player> players, DateTime at) => _box.put(
    _key,
    jsonEncode({
      'saved_at': at.millisecondsSinceEpoch,
      'players': players.map((p) => p.toJson()).toList(),
    }),
  );

  @override
  Future<void> clear() => _box.delete(_key);
}

class MemoryPlayersCache implements PlayersCache {
  CachedPlayers? value;

  @override
  CachedPlayers? read() => value;

  @override
  Future<void> write(List<Player> players, DateTime at) async =>
      value = CachedPlayers(players, at);

  @override
  Future<void> clear() async => value = null;
}

class PlayersRepository {
  PlayersRepository({
    required this.auth,
    required this.cache,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static PlayersRepository? _instance;

  static PlayersRepository get instance => _instance ??= PlayersRepository(
    auth: AuthService.instance,
    cache: HivePlayersCache(),
  );

  final AuthService auth;
  final PlayersCache cache;
  final DateTime Function() _now;

  CachedPlayers? cached() => cache.read();

  Future<PlayersPage> fetch({String query = '', String? cursor}) async {
    final params = <String, String>{'limit': '30'};
    if (query.isNotEmpty) params['q'] = query;
    if (cursor != null) params['cursor'] = cursor;
    final json = await auth.authed(
      (token) => auth.api.get('/v1/players', query: params, token: token),
    );
    final players = (json['players'] as List)
        .map((p) => Player.fromJson(p as Map<String, dynamic>))
        .toList();
    final next = json['next_cursor'];
    final page = PlayersPage(
      players: players,
      nextCursor: next is String && next.isNotEmpty ? next : null,
    );
    if (query.isEmpty && cursor == null) {
      await cache.write(players, _now());
    }
    return page;
  }

  Future<void> clearCache() => cache.clear();
}
