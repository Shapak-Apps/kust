import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/features/profile/profile_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/board_banner.dart';

/// Another player's profile, opened by tapping them anywhere: their board
/// banner and photo, name, flag, rating and bio, then what can be done with
/// them: become friends, and (soon) send a message.
class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({
    super.key,
    required this.username,
    this.initial,
    this.repository,
  });

  final String username;

  /// What the list already knew, shown at once while the rest loads.
  final Player? initial;
  final PlayersRepository? repository;

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  late Player? _player = widget.initial;

  /// Known at once when they are in my cached friends (or asked me), so
  /// Message works before the profile has loaded.
  late Friendship? _friendship = _repo.knownFriendship(widget.username);
  bool _busy = false;
  bool _missing = false;

  /// Their newest games and how many in all; their achievements. Null
  /// while loading.
  List<GameRecord>? _games;
  int _gamesTotal = 0;
  Map<String, DateTime>? _achievements;

  PlayersRepository get _repo =>
      widget.repository ?? PlayersRepository.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _loadGames();
    try {
      final got = await _repo.player(widget.username);
      if (!mounted) return;
      setState(() {
        _player = got.player;
        _friendship = got.friendship;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 404) setState(() => _missing = true);
    }
  }

  Future<void> _loadGames() async {
    try {
      final games = await _repo.games(widget.username, limit: 5);
      if (mounted) {
        setState(() {
          _games = games.games;
          _gamesTotal = games.total;
        });
      }
    } on ApiException {
      if (mounted) setState(() => _games = const []);
    }
    try {
      final unlocked = await _repo.achievements(widget.username);
      if (mounted) setState(() => _achievements = unlocked);
    } on ApiException {
      if (mounted) setState(() => _achievements = const {});
    }
  }

  /// Runs a friend action, showing its answer at once and undoing it if the
  /// server says no.
  Future<void> _act(Future<Friendship> Function() call) async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      final now = await call();
      if (mounted) setState(() => _friendship = now);
      unawaited(_repo.refreshIncoming()); // the cached friends follow
    } on ApiException catch (e) {
      if (mounted) {
        _say(e.isNetwork ? context.t.noInternet : context.t.genericError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Friendship> _remove() async {
    await _repo.removeFriend(widget.username);
    return Friendship.none;
  }

  void _confirmRemove() {
    final t = context.t;
    final name = _player?.displayName ?? widget.username;
    showKustSheet<void>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KustSheetHeader(title: t.friendRemoveTitle(name)),
          KustButton(
            label: t.friendRemove,
            style: KustButtonStyle.danger,
            onTap: () {
              Navigator.of(sheet).pop();
              _act(_remove);
            },
          ),
          const SizedBox(height: 8),
          KustButton(
            label: t.keep,
            style: KustButtonStyle.outline,
            onTap: () => Navigator.of(sheet).pop(),
          ),
        ],
      ),
    );
  }

  void _say(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final player = _player;
    final square = MediaQuery.sizeOf(context).width / BoardBanner.files;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: k.bg,
        body: Stack(
          children: [
            if (_missing && player == null)
              Center(
                child: Text(
                  t.playerMissing,
                  style: k.body.copyWith(color: k.muted),
                ),
              )
            else
              ListView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 32,
                ),
                children: [
                  Stack(
                    children: [
                      Column(
                        children: [
                          BoardBanner(height: square * 2),
                          const SizedBox(height: 60),
                        ],
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 0,
                        child: _identity(context, k, player),
                      ),
                    ],
                  ),
                  if (player != null && player.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Text(player.bio, style: k.body),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _stats(context, k, player),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _actions(context),
                  ),
                  ..._history(context, k),
                  ..._badges(context, k),
                ],
              ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x99000000), Color(0x00000000)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/players'),
                          tooltip: t.back,
                          color: Colors.white,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        if (_friendship == Friendship.friends)
                          IconButton(
                            onPressed: _confirmRemove,
                            tooltip: t.friendRemove,
                            color: Colors.white,
                            icon: const Icon(Icons.more_vert_rounded),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identity(BuildContext context, KustTokens k, Player? player) {
    final name = player?.displayName ?? widget.username;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: k.bg, width: 3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: PlayerAvatar(
            size: 88,
            name: name,
            photo: avatarImage(avatarUrlFor(player?.avatarKey)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The flag goes with the name.
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k.title,
                    ),
                  ),
                  if (player?.country != null) ...[
                    const SizedBox(width: 8),
                    CountryFlag(player!.country!, height: 22),
                  ],
                ],
              ),
              Text(
                '@${widget.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: k.body.copyWith(color: k.muted),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stats(BuildContext context, KustTokens k, Player? player) {
    final t = context.t;
    final joined = player?.createdAt?.toLocal();
    // Spread across the whole width: first at the left edge, last at the
    // right.
    Widget stat(String value, String label) => Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: k.body.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label, style: k.caption),
        ],
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (joined != null)
          stat(
            '${t.dateShort(t.monthsShort.split(',')[joined.month - 1], joined.day)} '
            '${joined.year}',
            t.joined,
          ),
        stat(player == null ? '–' : '${player.rating}', t.rating),
        stat(_games == null ? '–' : '$_gamesTotal', t.games),
      ],
    );
  }

  /// The friend button, which says where things stand, and Message.
  /// As on chess.com: the friend button on top while there is something to
  /// do (add, sent, accept), then Message and Challenge side by side.
  /// Friends need no friend button: Message turns green, Challenge stays
  /// gold. (Removing a friend is in the ⋮ menu at the top.)
  Widget _actions(BuildContext context) {
    final t = context.t;
    final friendship = _friendship;
    final friends = friendship == Friendship.friends;
    final busy = _busy || friendship == null;
    final message = KustButton(
      label: t.messageButton,
      icon: Icons.chat_bubble_outline_rounded,
      style: friends ? KustButtonStyle.primary : KustButtonStyle.secondary,
      // Friends chat; anyone else is told to add them first.
      onTap: () => friends
          ? context.push('/chat/${widget.username}', extra: _player)
          : _say(t.chatFriendsOnly),
    );
    final challenge = KustButton(
      label: t.challengeButton,
      icon: Icons.sports_esports_rounded,
      style: KustButtonStyle.gold,
      onTap: () => _say(t.challengeSoon),
    );
    final Widget? top = switch (friendship) {
      Friendship.friends => null,
      Friendship.incoming => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.wantsToBeFriend, style: context.k.caption),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: KustButton(
                  label: t.friendAccept,
                  icon: Icons.check_rounded,
                  onTap: busy
                      ? null
                      : () => _act(() => _repo.addFriend(widget.username)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KustButton(
                  label: t.friendDecline,
                  style: KustButtonStyle.secondary,
                  onTap: busy ? null : () => _act(_remove),
                ),
              ),
            ],
          ),
        ],
      ),
      // Sent stays sent: it can't be taken back from here.
      Friendship.outgoing => KustButton(
        label: t.friendSent,
        icon: Icons.check_rounded,
        style: KustButtonStyle.secondary,
        onTap: null,
      ),
      _ => KustButton(
        label: t.friendAdd,
        icon: Icons.person_add_alt_1_rounded,
        onTap: busy ? null : () => _act(() => _repo.addFriend(widget.username)),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (top != null) ...[top, const SizedBox(height: 10)],
        Row(
          children: [
            Expanded(child: message),
            const SizedBox(width: 10),
            Expanded(child: challenge),
          ],
        ),
      ],
    );
  }

  Widget _title(
    KustTokens k,
    String title,
    String count, {
    VoidCallback? onViewAll,
  }) => Padding(
    padding: EdgeInsets.fromLTRB(20, 22, onViewAll == null ? 20 : 8, 6),
    child: Row(
      children: [
        Text(title, style: k.title.copyWith(fontSize: 20, height: 1.2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: k.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count,
            style: k.caption.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (onViewAll != null) ...[
          const Spacer(),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(context.t.viewAll, maxLines: 1),
          ),
        ],
      ],
    ),
  );

  /// Their newest games; each opens for watching.
  List<Widget> _history(BuildContext context, KustTokens k) {
    final games = _games;
    return [
      _title(
        k,
        context.t.gameHistory,
        '$_gamesTotal',
        // The last five here; all of them a tap away.
        onViewAll: _gamesTotal > 5
            ? () => context.push('/player/${widget.username}/games')
            : null,
      ),
      if (games == null)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (games.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            context.t.histNoGames,
            style: k.body.copyWith(color: k.muted),
          ),
        )
      else
        for (final (i, game) in games.indexed) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: k.line),
          GameTile(game: game, readOnly: true),
        ],
    ];
  }

  /// Their achievements, earned ones first and in colour.
  List<Widget> _badges(BuildContext context, KustTokens k) {
    final unlocked = _achievements ?? const <String, DateTime>{};
    final sorted = [
      ...kAchievements.where((a) => unlocked.containsKey(a.id)),
      ...kAchievements.where((a) => !unlocked.containsKey(a.id)),
    ];
    return [
      _title(
        k,
        context.t.achievements,
        '${unlocked.length}/${kAchievements.length}',
      ),
      SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) => AchievementBadge(
            achievement: sorted[i],
            earned: unlocked.containsKey(sorted[i].id),
          ),
        ),
      ),
    ];
  }
}

/// All of another player's games (up to the 200 the server keeps), each
/// opening for watching.
class PlayerGamesScreen extends StatefulWidget {
  const PlayerGamesScreen({super.key, required this.username});

  final String username;

  @override
  State<PlayerGamesScreen> createState() => _PlayerGamesScreenState();
}

class _PlayerGamesScreenState extends State<PlayerGamesScreen> {
  List<GameRecord>? _games;

  @override
  void initState() {
    super.initState();
    PlayersRepository.instance
        .games(widget.username, limit: 200)
        .then((g) {
          if (mounted) setState(() => _games = g.games);
        })
        .catchError((Object _) {
          if (mounted) setState(() => _games = const []);
        });
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final games = _games;
    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          FeltHeader(title: context.t.gameHistory, onBack: () => context.pop()),
          Expanded(
            child: games == null
                ? const Center(child: CircularProgressIndicator())
                : games.isEmpty
                ? Center(
                    child: Text(
                      context.t.histNoGames,
                      style: k.body.copyWith(color: k.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: games.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, thickness: 1, color: k.line),
                    itemBuilder: (context, i) =>
                        GameTile(game: games[i], readOnly: true),
                  ),
          ),
        ],
      ),
    );
  }
}
