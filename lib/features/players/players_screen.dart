import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/net/presence.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_text_field.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/offline_bar.dart';

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

  PlayersRepository get _repo => widget.repository ?? PlayersRepository.instance;
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
            onBack: () => context.canPop() ? context.pop() : context.go('/play'),
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
          const SafeArea(top: false, child: OfflineBar()),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final t = context.t;
    final k = context.k;
    if (_loading && _players.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
    if (_players.isEmpty) {
      return Center(
        child: Text(t.playersEmpty, style: k.body.copyWith(color: k.muted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: _presence.online,
        builder: (context, online, _) => ListView.separated(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: _players.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (_, _) =>
              Divider(height: 1, thickness: 1, color: k.line, indent: 76),
          itemBuilder: (context, i) {
            if (i >= _players.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final player = _players[i];
            return PlayerTile(
              player: player,
              online: online.contains(player.username),
            );
          },
        ),
      ),
    );
  }
}

class PlayerTile extends StatelessWidget {
  const PlayerTile({super.key, required this.player, this.online = false});

  final Player player;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              PlayerAvatar(size: 44, name: player.displayName),
              if (online)
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: k.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: k.bg, width: 2.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: k.body.copyWith(fontWeight: FontWeight.w800),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '@${player.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: k.caption,
                      ),
                    ),
                    if (player.country != null) ...[
                      const SizedBox(width: 8),
                      CountryFlag(player.country!, height: 14),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${player.rating}',
            style: k.body.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
