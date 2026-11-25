import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/net/presence.dart';
import 'package:kust/features/players/players_screen.dart' show PlayerTile;
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_text_field.dart';
import 'package:kust/ui/skeleton.dart';
import 'package:kust/ui/tokens.dart';

/// My friends, all of them, with a search over their names. Each opens
/// their profile.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _search = TextEditingController();
  final _repo = PlayersRepository.instance;

  @override
  void initState() {
    super.initState();
    // The cached list shows at once; a fresh one replaces it quietly.
    _repo.friends().catchError(
      (Object _) => (
        friends: const <Player>[],
        incoming: const <Player>[],
        outgoing: const <Player>[],
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Player> _filter(List<Player> all) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final p in all)
        if (p.username.contains(q) || p.displayName.toLowerCase().contains(q))
          p,
    ];
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
            title: t.friendFriends,
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/profile'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: KustTextField(
              controller: _search,
              maxLength: 30,
              hint: t.friendsSearch,
              onChanged: (_) => setState(() {}),
              action: TextInputAction.search,
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<Player>?>(
              valueListenable: _repo.friendsCache,
              builder: (context, all, _) {
                if (all == null) return const KustSkeletonRows();
                final shown = _filter(all);
                if (shown.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        all.isEmpty ? t.noFriendsYet : t.playersEmpty,
                        textAlign: TextAlign.center,
                        style: k.body.copyWith(color: k.muted),
                      ),
                    ),
                  );
                }
                return ValueListenableBuilder<Set<String>>(
                  valueListenable: PresenceService.instance.online,
                  builder: (context, online, _) => ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final p = shown[i];
                      return PlayerTile(
                        player: p,
                        online: online.contains(p.username),
                        onTap: () =>
                            context.push('/player/${p.username}', extra: p),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
