import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/game_history_store.dart';

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

  /// One player and how they stand to me.
  Future<({Player player, Friendship friendship})> player(
    String username,
  ) async {
    final json = await auth.authed(
      (token) => auth.api.get('/v1/players/$username', token: token),
    );
    return (
      player: Player.fromJson(json['player'] as Map<String, dynamic>),
      friendship: Friendship.parse(json['friendship']),
    );
  }

  final Map<String, Future<String?>> _avatars = {};

  /// A player's photo key, asked once per run (for lists of games).
  Future<String?> avatarKeyOf(String username) =>
      _avatars[username] ??= player(username).then(
        (p) => p.player.avatarKey,
        onError: (_) {
          _avatars.remove(username);
          return null;
        },
      );

  /// Sends a friend request, or accepts theirs.
  Future<Friendship> addFriend(String username) async {
    final json = await auth.authed(
      (token) => auth.api.post('/v1/friends/$username', token: token),
    );
    return Friendship.parse(json['friendship']);
  }

  /// Cancels a request, declines one, or ends a friendship.
  Future<void> removeFriend(String username) => auth.authed(
    (token) => auth.api.delete('/v1/friends/$username', token: token),
  );

  /// A player's newest games, as their app recorded them, and how many
  /// they have in all.
  Future<({List<GameRecord> games, int total})> games(
    String username, {
    int limit = 20,
  }) async {
    final json = await auth.authed(
      (token) => auth.api.get(
        '/v1/players/$username/games',
        query: {'limit': '$limit'},
        token: token,
      ),
    );
    return (
      games: [
        for (final g in (json['games'] as List? ?? const []))
          ?GameRecord.tryFromMap(g),
      ],
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  /// A player's achievements and when each was unlocked.
  Future<Map<String, DateTime>> achievements(String username) async {
    final json = await auth.authed(
      (token) =>
          auth.api.get('/v1/players/$username/achievements', token: token),
    );
    final raw = json['achievements'];
    return {
      if (raw is Map)
        for (final e in raw.entries)
          if (e.key is String && e.value is num)
            e.key as String: DateTime.fromMillisecondsSinceEpoch(
              (e.value as num).toInt(),
            ),
    };
  }

  /// My friends as last fetched (null before the first time): shown at
  /// once while a fresh list loads, and used to know who is a friend.
  final ValueNotifier<List<Player>?> friendsCache = ValueNotifier(null);

  /// How [username] stands to me, as far as the cache knows.
  Friendship? knownFriendship(String username) {
    if (friendsCache.value?.any((p) => p.username == username) ?? false) {
      return Friendship.friends;
    }
    if (incoming.value.any((p) => p.username == username)) {
      return Friendship.incoming;
    }
    return null;
  }

  /// Friend requests waiting for me, for the bell on the home screen.
  /// Refreshed with [refreshIncoming] and whenever [friends] is read.
  final ValueNotifier<List<Player>> incoming = ValueNotifier(const []);

  Future<void> refreshIncoming() async {
    try {
      await friends();
    } on ApiException {
      // Kept as it was; tried again next time.
    }
  }

  /// My friends, the requests waiting for me, and the ones I sent.
  Future<({List<Player> friends, List<Player> incoming, List<Player> outgoing})>
  friends() async {
    final json = await auth.authed(
      (token) => auth.api.get('/v1/friends', token: token),
    );
    List<Player> list(String key) => [
      for (final p in (json[key] as List? ?? const []))
        Player.fromJson(p as Map<String, dynamic>),
    ];
    final waiting = list('incoming');
    incoming.value = waiting;
    final mine = list('friends');
    friendsCache.value = mine;
    return (friends: mine, incoming: waiting, outgoing: list('outgoing'));
  }
}
