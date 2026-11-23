import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/features/players/players_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';

/// The bell on the home screen, beside the avatar: a red count of what is
/// waiting (friend requests for now). Shown only to signed-in players.
class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthService.instance.state,
      builder: (context, auth, _) {
        if (!auth.isVerified) return const SizedBox.shrink();
        return ValueListenableBuilder<List<Player>>(
          valueListenable: PlayersRepository.instance.incoming,
          builder: (context, waiting, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              KustIconButton(
                icon: waiting.isEmpty
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_rounded,
                label: context.t.notifications,
                onTap: () => context.push('/notifications'),
              ),
              if (waiting.isNotEmpty)
                Positioned(
                  right: 2,
                  top: 2,
                  child: IgnorePointer(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: k.danger,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: k.bg, width: 2),
                      ),
                      child: Text(
                        waiting.length > 9 ? '9+' : '${waiting.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// What is waiting for the player: friend requests, each with accept and
/// decline; tapping one opens their profile.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  PlayersRepository get _repo => PlayersRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.refreshIncoming();
  }

  Future<void> _answer(Player player, bool accept) async {
    _repo.incoming.value = [
      for (final p in _repo.incoming.value)
        if (p.username != player.username) p,
    ];
    try {
      if (accept) {
        await _repo.addFriend(player.username);
      } else {
        await _repo.removeFriend(player.username);
      }
    } on ApiException {
      // Shown again by the refresh below if it didn't go through.
    }
    await _repo.refreshIncoming();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          FeltHeader(
            title: t.notifications,
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/play'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _repo.refreshIncoming,
              child: ValueListenableBuilder<List<Player>>(
                valueListenable: _repo.incoming,
                builder: (context, waiting, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  children: [
                    if (waiting.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: k.muted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.notifEmpty,
                              textAlign: TextAlign.center,
                              style: k.body.copyWith(color: k.muted),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          t.friendRequests.toUpperCase(),
                          style: k.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      for (final p in waiting)
                        PlayerTile(
                          player: p,
                          onTap: () =>
                              context.push('/player/${p.username}', extra: p),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _answer(p, true),
                                tooltip: t.friendAccept,
                                color: k.success,
                                icon: const Icon(Icons.check_circle_rounded),
                              ),
                              IconButton(
                                onPressed: () => _answer(p, false),
                                tooltip: t.friendDecline,
                                color: k.muted,
                                icon: const Icon(Icons.cancel_rounded),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
