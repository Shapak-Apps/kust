import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/net/chat_repository.dart';
import 'package:kust/features/players/players_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/player_avatar.dart';
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
          builder: (context, waiting, _) =>
              ValueListenableBuilder<List<ChatSummary>>(
                valueListenable: ChatRepository.instance.summaries,
                builder: (context, chats, _) {
                  // Requests waiting, and chats with something unread.
                  final count =
                      waiting.length + chats.where((c) => c.unread > 0).length;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      KustIconButton(
                        icon: count == 0
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_rounded,
                        label: context.t.notifications,
                        onTap: () => context.push('/notifications'),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: IgnorePointer(
                            // A true circle for one digit, a pill for "9+".
                            child: Container(
                              width: count > 9 ? null : 20,
                              height: 20,
                              padding: count > 9
                                  ? const EdgeInsets.symmetric(horizontal: 5)
                                  : null,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: k.danger,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: k.bg, width: 2),
                              ),
                              child: Text(
                                count > 9 ? '9+' : '$count',
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
                  );
                },
              ),
        );
      },
    );
  }
}

/// What is waiting for the player: new messages (each opens its chat) and
/// friend requests (accept or decline; the person opens their profile).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  PlayersRepository get _repo => PlayersRepository.instance;
  ChatRepository get _chats => ChatRepository.instance;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() =>
      Future.wait([_repo.refreshIncoming(), _chats.refreshUnread()]);

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

  Widget _label(KustTokens k, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      text.toUpperCase(),
      style: k.caption.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    ),
  );

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
              onRefresh: _refresh,
              child: ValueListenableBuilder<List<Player>>(
                valueListenable: _repo.incoming,
                builder: (context, waiting, _) =>
                    ValueListenableBuilder<List<ChatSummary>>(
                      valueListenable: _chats.summaries,
                      builder: (context, chats, _) {
                        final texts = [
                          for (final c in chats)
                            if (c.unread > 0) c,
                        ];
                        return LayoutBuilder(
                          builder: (context, box) => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              if (waiting.isEmpty && texts.isEmpty)
                                // In the middle of the screen, still pullable.
                                Container(
                                  height: box.maxHeight - 32,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
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
                                ),
                              if (texts.isNotEmpty) ...[
                                _label(k, t.chatsTitle),
                                for (final c in texts)
                                  _MessageNotice(
                                    chat: c,
                                    onTap: () async {
                                      await context.push(
                                        '/chat/${c.player.username}',
                                        extra: c.player,
                                      );
                                      _refresh();
                                    },
                                  ),
                              ],
                              if (waiting.isNotEmpty) ...[
                                _label(k, t.friendRequests),
                                for (final p in waiting)
                                  FriendRequestCard(
                                    player: p,
                                    onOpen: () => context.push(
                                      '/player/${p.username}',
                                      extra: p,
                                    ),
                                    onAnswer: (accept) => _answer(p, accept),
                                  ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "merdan texted you": who, their last message, how many, and the time.
/// Tapping opens the chat.
class _MessageNotice extends StatelessWidget {
  const _MessageNotice({required this.chat, required this.onTap});

  final ChatSummary chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final p = chat.player;
    final d = chat.last.createdAt;
    final when =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            PlayerAvatar(
              size: 48,
              name: p.displayName,
              photo: avatarImage(avatarUrlFor(p.avatarKey)),
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
                          t.chatTextedYou(p.displayName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: k.body.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (p.country != null) ...[
                        const SizedBox(width: 6),
                        CountryFlag(p.country!, height: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.last.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(when, style: k.caption.copyWith(color: KustTokens.gold)),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3CB77C),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '${chat.unread}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
