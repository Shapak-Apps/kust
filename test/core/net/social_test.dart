import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/net/token_storage.dart';

import 'fake_adapter.dart';

Map<String, dynamic> _player(String username, {String? avatar}) => {
  'id': 'id-$username',
  'username': username,
  'display_name': username.toUpperCase(),
  'bio': '',
  'country': null,
  'avatar_key': avatar,
  'rating': 1500,
  'created_at': '2026-11-01T10:00:00Z',
};

Map<String, dynamic> _session() => {
  'user': {..._player('me'), 'email': 'me@example.com', 'email_verified': true},
  'access_token': 'a',
  'refresh_token': 'r',
  'expires_in': 900,
};

void main() {
  late FakeAdapter adapter;
  late AuthService auth;
  late PlayersRepository repo;

  setUp(() async {
    final t = testApi((o) {
      return switch ('${o.method} ${o.path}') {
        'POST /v1/auth/login' => jsonBody(_session()),
        'GET /v1/players/bob' => jsonBody({
          'player': _player('bob', avatar: 'avatars/x/y.jpg'),
          'friendship': 'incoming',
        }),
        'POST /v1/friends/bob' => jsonBody({'friendship': 'friends'}),
        'DELETE /v1/friends/bob' => jsonBody({'friendship': 'none'}),
        'GET /v1/friends' => jsonBody({
          'friends': [_player('ann')],
          'incoming': [_player('bob')],
          'outgoing': [],
        }),
        'GET /v1/players/bob/games' => jsonBody({
          'games': [
            {
              'id': 'g1',
              'playedAt': 1763900000000,
              'result': 'win',
              'uci': ['e2e4'],
              'san': ['e4'],
              'botName': 'Mark',
            },
            {'broken': true},
          ],
          'total': 7,
        }),
        'GET /v1/players/bob/achievements' => jsonBody({
          'achievements': {'firstMove': 1763900000000},
        }),
        'PUT /v1/me/avatar' => jsonBody({
          'user': {
            ..._session()['user'] as Map<String, dynamic>,
            'avatar_key': 'avatars/me/new.jpg',
          },
        }),
        _ => jsonBody({
          'error': {'code': 'not_found'},
        }, status: 404),
      };
    });
    adapter = t.adapter;
    auth = AuthService(
      api: t.api,
      storage: MemoryTokenStorage(),
      cache: MemoryAccountCache(),
    );
    repo = PlayersRepository(auth: auth, cache: MemoryPlayersCache());
    await auth.login(identifier: 'me', password: 'Password123');
  });

  test('a player comes with how they stand to me', () async {
    final got = await repo.player('bob');
    expect(got.player.username, 'bob');
    expect(got.player.avatarKey, 'avatars/x/y.jpg');
    expect(got.player.createdAt, DateTime.utc(2026, 11, 1, 10));
    expect(got.friendship, Friendship.incoming);
  });

  test('friend requests: add, remove, and the lists', () async {
    expect(await repo.addFriend('bob'), Friendship.friends);
    await repo.removeFriend('bob');
    final f = await repo.friends();
    expect(f.friends.single.username, 'ann');
    expect(f.incoming.single.username, 'bob');
    expect(f.outgoing, isEmpty);
    expect(Friendship.parse('nonsense'), Friendship.none);
  });

  test('the photo goes up as raw JPEG bytes with a token', () async {
    final account = await auth.uploadAvatar([0xff, 0xd8, 0xff, 1, 2, 3]);
    expect(account.avatarKey, 'avatars/me/new.jpg');
    final put = adapter.requests.last;
    expect(put.method, 'PUT');
    expect(put.headers['Content-Type'] ?? put.contentType, 'image/jpeg');
    expect(put.headers['Authorization'], 'Bearer a');
    expect(adapter.streamed.last, [0xff, 0xd8, 0xff, 1, 2, 3]);
  });

  test("another player's games and achievements", () async {
    final g = await repo.games('bob', limit: 10);
    expect(g.total, 7);
    expect(g.games.single.id, 'g1');
    expect(g.games.single.botName, 'Mark');
    expect(adapter.requests.last.queryParameters['limit'], '10');
    final a = await repo.achievements('bob');
    expect(a['firstMove'], DateTime.fromMillisecondsSinceEpoch(1763900000000));
  });

  test('reading friends fills the bell count', () async {
    expect(repo.incoming.value, isEmpty);
    await repo.refreshIncoming();
    expect(repo.incoming.value.single.username, 'bob');
  });
}
