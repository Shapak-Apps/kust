import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/net/presence.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_text_field.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/kust_list_row.dart';
import 'package:kust/ui/press_highlight.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/ui/skeleton.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key, this.repository, this.presence});

  final PlayersRepository? repository;
  final PresenceService? presence;

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<Player> _players = const [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _fromCache = false;
  ApiException? _error;
  int _generation = 0;

  /// Friend requests waiting for me, and my friends: shown above everyone
  /// while not searching.
  List<Player> _incoming = const [];
  List<Player> _friends = const [];

  PlayersRepository get _repo =>
      widget.repository ?? PlayersRepository.instance;
  PresenceService get _presence => widget.presence ?? PresenceService.instance;

  @override
  void initState() {
    super.initState();
    final cached = _repo.cached();
    if (cached != null) {
      _players = cached.players;
      _fromCache = true;
    }
    _scroll.addListener(_onScroll);
    _load();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final f = await _repo.friends();
      if (!mounted) return;
      setState(() {
        _incoming = f.incoming;
        _friends = f.friends;
      });
    } on ApiException {
      // The list of everyone still works; friends show next time.
    }
  }

  /// Accepts or declines a request right in the list.
  Future<void> _answer(Player player, bool accept) async {
    setState(
      () => _incoming = [
        for (final p in _incoming)
          if (p.username != player.username) p,
      ],
    );
    try {
      if (accept) {
        await _repo.addFriend(player.username);
      } else {
        await _repo.removeFriend(player.username);
      }
    } on ApiException {
      // Shown again by the reload below if it didn't go through.
    }
    await _loadFriends();
  }

  Future<void> _refresh() => Future.wait([_load(), _loadFriends()]);

  Future<void> _open(Player player) async {
    // Me: my own profile, never the view others get of me.
    final me = AuthService.instance.state.value.account?.username;
    await context.push(
      player.username == me ? '/profile' : '/player/${player.username}',
      extra: player,
    );
    // Back from a profile: a request may have been sent or answered there.
    if (mounted) _loadFriends();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim().toLowerCase();

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) _loadMore();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final query = _query;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repo.fetch(query: query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _players = page.players;
        _cursor = page.nextCursor;
        _fromCache = false;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || generation != _generation) return;
      if (_redirectFor(e)) return;
      final cached = _repo.cached();
      setState(() {
        _loading = false;
        _cursor = null;
        if (e.isNetwork && cached != null) {
          _fromCache = true;
          _players = _filterLocally(cached.players, query);
        } else {
          _players = const [];
          _error = e;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore || _loading || _fromCache) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.fetch(query: _query, cursor: cursor);
      if (!mounted || generation != _generation) return;
      setState(() {
        _players = [..._players, ...page.players];
        _cursor = page.nextCursor;
      });
    } on ApiException {
      if (mounted) setState(() => _cursor = null);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  bool _redirectFor(ApiException e) {
    if (e.code == 'email_not_verified') {
      context.pushReplacement('/verify');
      return true;
    }
    if (e.status == 401) {
      context.pushReplacement('/login');
      return true;
    }
    return false;
  }

  List<Player> _filterLocally(List<Player> players, String query) {
    if (query.isEmpty) return players;
    return players
        .where(
          (p) =>
              p.username.startsWith(query) ||
              p.displayName.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = context.k;
    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          FeltHeader(
            title: t.playersTitle,
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/play'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: KustTextField(
              controller: _search,
              maxLength: 30,
              hint: t.playersSearch,
              onChanged: _onSearchChanged,
              action: TextInputAction.search,
            ),
          ),
          if (_fromCache && _players.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(t.playersSaved, style: k.caption),
              ),
            ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final t = context.t;
    final k = context.k;
    if (_loading && _players.isEmpty) {
      return const KustSkeletonRows();
    }
    if (_error != null && _players.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!.isNetwork ? t.noInternet : t.playersLoadFailed,
                textAlign: TextAlign.center,
                style: k.body.copyWith(color: k.muted),
              ),
              const SizedBox(height: 16),
              KustButton(
                label: t.retry,
                expand: false,
                style: KustButtonStyle.secondary,
                onTap: _load,
              ),
            ],
          ),
        ),
      );
    }
    final sections =
        _query.isEmpty && (_incoming.isNotEmpty || _friends.isNotEmpty);
    if (_players.isEmpty && !sections) {
      return Center(
        child: Text(t.playersEmpty, style: k.body.copyWith(color: k.muted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: _presence.online,
        builder: (context, online, _) {
          Widget tile(Player p, {Widget? trailing}) => PlayerTile(
            player: p,
            online: online.contains(p.username),
            onTap: () => _open(p),
            trailing: trailing,
          );
          final rows = <Widget>[
            if (sections && _incoming.isNotEmpty) ...[
              _SectionLabel('${t.friendRequests} · ${_incoming.length}'),
              for (final p in _incoming)
                FriendRequestCard(
                  player: p,
                  onOpen: () => _open(p),
                  onAnswer: (accept) => _answer(p, accept),
                ),
            ],
            if (sections && _friends.isNotEmpty) ...[
              _SectionLabel(t.friendsSection),
              for (final p in _friends) tile(p),
            ],
            if (sections && _players.isNotEmpty)
              _SectionLabel(t.everyonePlayers),
            for (final p in _players) tile(p),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ];
          return ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: rows,
          );
        },
      ),
    );
  }
}

/// A small title over a part of the list.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Text(
        text.toUpperCase(),
        style: k.caption.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class PlayerTile extends StatelessWidget {
  const PlayerTile({
    super.key,
    required this.player,
    this.online = false,
    this.onTap,
    this.trailing,
  });

  final Player player;
  final bool online;

  /// Opens their profile.
  final VoidCallback? onTap;

  /// In place of the rating, such as accept and decline.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return KustListRow(
      onTap: onTap,
      leading: OnlineDot(
        online: online,
        child: PlayerAvatar(
          size: 36,
          name: player.displayName,
          photo: avatarImage(avatarUrlFor(player.avatarKey)),
        ),
      ),
      // The name with the country's flag after it.
      title: Row(
        children: [
          Flexible(
            child: Text(
              player.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: k.rowTitle,
            ),
          ),
          if (player.country != null) ...[
            const SizedBox(width: 6),
            CountryFlag(player.country!, height: 14),
          ],
        ],
      ),
      meta: Text(
        '@${player.username}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: k.caption,
      ),
      trailing: trailing ?? Text('${player.rating}', style: k.number),
    );
  }
}

/// A friend request: who, with their flag and rating, a line saying what
/// they want, and Accept / Decline under it. Tapping the person opens
/// their profile.
class FriendRequestCard extends StatelessWidget {
  const FriendRequestCard({
    super.key,
    required this.player,
    required this.onOpen,
    required this.onAnswer,
  });

  final Player player;
  final VoidCallback onOpen;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: squircle(KustSpace.rCard, color: k.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PressHighlight(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                PlayerAvatar(
                  size: 48,
                  name: player.displayName,
                  photo: avatarImage(avatarUrlFor(player.avatarKey)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              player.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: k.body.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (player.country != null) ...[
                            const SizedBox(width: 6),
                            CountryFlag(player.country!, height: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${player.username} · ${player.rating}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: k.caption,
                      ),
                      const SizedBox(height: 2),
                      Text(t.wantsToBeFriend, style: k.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: KustButton(
                  label: t.friendAccept,
                  height: 40,
                  onTap: () => onAnswer(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KustButton(
                  label: t.friendDecline,
                  height: 40,
                  style: KustButtonStyle.secondary,
                  onTap: () => onAnswer(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
