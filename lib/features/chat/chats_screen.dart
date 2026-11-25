import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/chat_repository.dart';
import 'package:kust/core/net/live_socket.dart';
import 'package:kust/core/net/presence.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/kust_list_row.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/ui/skeleton.dart';

/// The chat icon on Play, with the number of unread messages. Signed-in
/// players only.
class ChatsButton extends StatelessWidget {
  const ChatsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthService.instance.state,
      builder: (context, auth, _) {
        if (!auth.isVerified) return const SizedBox.shrink();
        return ValueListenableBuilder<int>(
          valueListenable: ChatRepository.instance.unread,
          builder: (context, unread, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              KustIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: context.t.chatsTitle,
                onTap: () => context.push('/chats'),
              ),
              if (unread > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: IgnorePointer(
                    child: Container(
                      width: unread > 9 ? null : 20,
                      height: 20,
                      padding: unread > 9
                          ? const EdgeInsets.symmetric(horizontal: 5)
                          : null,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: k.danger,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: k.bg, width: 2),
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
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

/// My conversations, the latest first: the friend, the last message and
/// when, and how many I haven't read.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<ChatSummary>? _chats;
  StreamSubscription<LiveEvent>? _sub;

  ChatRepository get _repo => ChatRepository.instance;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = _repo.changes.listen((e) {
      if (e.type == 'chat_message' || e.type == 'chat_read') _load();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final chats = await _repo.chats();
      if (mounted) setState(() => _chats = chats);
    } on ApiException {
      if (mounted) setState(() => _chats ??= const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final chats = _chats;
    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          FeltHeader(
            title: t.chatsTitle,
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/play'),
          ),
          Expanded(
            child: chats == null
                ? const KustSkeletonRows()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: LayoutBuilder(
                      builder: (context, box) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 4, bottom: 24),
                        children: [
                          if (chats.isEmpty)
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
                                    Icons.chat_bubble_outline_rounded,
                                    size: 48,
                                    color: k.muted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    t.chatsEmpty,
                                    textAlign: TextAlign.center,
                                    style: k.body.copyWith(color: k.muted),
                                  ),
                                ],
                              ),
                            )
                          else
                            for (final c in chats)
                              _ChatRow(
                                chat: c,
                                onTap: () async {
                                  await context.push(
                                    '/chat/${c.player.username}',
                                    extra: c.player,
                                  );
                                  _load();
                                },
                              ),
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

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.chat, required this.onTap});

  final ChatSummary chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final p = chat.player;
    final last = chat.last;
    final mine = last.from != p.username;
    final unread = chat.unread > 0;
    final now = DateTime.now();
    final d = last.createdAt;
    final when = d.year == now.year && d.month == now.month && d.day == now.day
        ? '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'
        : t.dateShort(t.monthsShort.split(',')[d.month - 1], d.day);
    return KustListRow(
      onTap: onTap,
      leading: ValueListenableBuilder<Set<String>>(
        valueListenable: PresenceService.instance.online,
        builder: (context, online, _) => OnlineDot(
          online: online.contains(p.username),
          child: PlayerAvatar(
            size: 36,
            name: p.displayName,
            photo: avatarImage(avatarUrlFor(p.avatarKey)),
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              p.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: k.rowTitle,
            ),
          ),
          if (p.country != null) ...[
            const SizedBox(width: 6),
            CountryFlag(p.country!, height: 14),
          ],
          const Spacer(),
          Text(
            when,
            style: k.caption.copyWith(
              color: unread ? KustTokens.gold : k.muted,
              fontWeight: unread ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
      meta: Row(
        children: [
          if (mine) ...[
            Icon(
              last.read ? Icons.done_all_rounded : Icons.done_rounded,
              size: 16,
              color: last.read ? KustTokens.gold : k.muted,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              last.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: k.caption.copyWith(
                fontSize: 13,
                color: unread ? k.ink : k.muted,
                fontWeight: unread ? FontWeight.w600 : null,
              ),
            ),
          ),
          if (unread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF3CB77C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${chat.unread}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
