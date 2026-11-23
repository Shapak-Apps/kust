import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/live_socket.dart';

/// The message a reply answers, cut short.
@immutable
class ChatReply {
  const ChatReply({required this.id, required this.from, required this.body});

  final int id;
  final String from;
  final String body;

  static ChatReply? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return ChatReply(
      id: (json['id'] as num).toInt(),
      from: json['from'] as String,
      body: json['body'] as String,
    );
  }
}

/// One chat message. A message still on its way has a negative [id] and
/// [pending] set; one that failed to go has [failed].
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    required this.createdAt,
    this.replyTo,
    this.read = false,
    this.reactions = const {},
    this.pending = false,
    this.failed = false,
  });

  final int id;
  final String from;
  final String to;
  final String body;
  final DateTime createdAt;
  final ChatReply? replyTo;
  final bool read;

  /// Username → emoji.
  final Map<String, String> reactions;
  final bool pending;
  final bool failed;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] as num).toInt(),
    from: json['from'] as String,
    to: json['to'] as String,
    body: json['body'] as String,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    replyTo: ChatReply.fromJson(json['reply_to']),
    read: json['read'] == true,
    reactions: {
      for (final e in ((json['reactions'] as Map?) ?? const {}).entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
    },
  );

  ChatMessage copyWith({
    bool? read,
    Map<String, String>? reactions,
    bool? failed,
  }) => ChatMessage(
    id: id,
    from: from,
    to: to,
    body: body,
    createdAt: createdAt,
    replyTo: replyTo,
    read: read ?? this.read,
    reactions: reactions ?? this.reactions,
    pending: pending,
    failed: failed ?? this.failed,
  );
}

/// One conversation in the list.
@immutable
class ChatSummary {
  const ChatSummary({
    required this.player,
    required this.last,
    required this.unread,
  });

  final Player player;
  final ChatMessage last;
  final int unread;

  factory ChatSummary.fromJson(Map<String, dynamic> json) => ChatSummary(
    player: Player.fromJson(json['player'] as Map<String, dynamic>),
    last: ChatMessage.fromJson(json['last'] as Map<String, dynamic>),
    unread: (json['unread'] as num?)?.toInt() ?? 0,
  );
}

/// Chat with friends: the list of conversations, messages, sending,
/// reading and reactions; live changes come through the socket.
class ChatRepository {
  ChatRepository({required this.auth, LiveSocket? socket})
    : _socket = socket ?? LiveSocket.instance {
    _socket.events.listen(_onEvent);
  }

  static ChatRepository? _instance;
  static ChatRepository get instance =>
      _instance ??= ChatRepository(auth: AuthService.instance);

  final AuthService auth;
  final LiveSocket _socket;

  /// Messages I haven't read, across all chats: the badge on Play.
  final ValueNotifier<int> unread = ValueNotifier(0);

  /// The chat on screen, so its messages don't count as unread.
  String? openWith;

  final StreamController<LiveEvent> _changes = StreamController.broadcast();

  /// Live chat events: chat_message, chat_read, chat_reaction, and
  /// chat_resync after the connection comes back.
  Stream<LiveEvent> get changes => _changes.stream;

  String? get me => auth.state.value.account?.username;

  void _onEvent(LiveEvent e) {
    // Back online after a gap: whatever came meanwhile is fetched again.
    if (e.type == 'hello') {
      _changes.add(const LiveEvent('chat_resync', {}));
      unawaited(refreshUnread());
      return;
    }
    if (!e.type.startsWith('chat_')) return;
    _changes.add(e);
    if (e.type == 'chat_message' &&
        e.data['to'] == me &&
        e.data['from'] != openWith) {
      unread.value = unread.value + 1;
    }
  }

  Future<List<ChatSummary>> chats() async {
    final json = await auth.authed(
      (token) => auth.api.get('/v1/chats', token: token),
    );
    final list = [
      for (final c in (json['chats'] as List? ?? const []))
        ChatSummary.fromJson(c as Map<String, dynamic>),
    ];
    unread.value = list.fold(0, (sum, c) => sum + c.unread);
    return list;
  }

  /// Recounts the badge; quiet when offline or signed out.
  Future<void> refreshUnread() async {
    if (!auth.state.value.isVerified) {
      unread.value = 0;
      return;
    }
    try {
      await chats();
    } on ApiException {
      // Kept as it was.
    }
  }

  /// A page of messages with [username], newest first.
  Future<({List<ChatMessage> messages, bool more})> messages(
    String username, {
    int? before,
  }) async {
    final json = await auth.authed(
      (token) => auth.api.get(
        '/v1/chats/$username/messages',
        query: {'before': ?before?.toString()},
        token: token,
      ),
    );
    return (
      messages: [
        for (final m in (json['messages'] as List? ?? const []))
          ChatMessage.fromJson(m as Map<String, dynamic>),
      ],
      more: json['more'] == true,
    );
  }

  Future<ChatMessage> send(String username, String body, {int? replyTo}) async {
    final json = await auth.authed(
      (token) => auth.api.post(
        '/v1/chats/$username/messages',
        body: {'body': body, 'reply_to': ?replyTo},
        token: token,
      ),
    );
    return ChatMessage.fromJson(json['message'] as Map<String, dynamic>);
  }

  /// I've seen their messages up to [upTo].
  Future<void> markRead(String username, int upTo) async {
    try {
      await auth.authed(
        (token) => auth.api.post(
          '/v1/chats/$username/read',
          body: {'up_to': upTo},
          token: token,
        ),
      );
    } on ApiException {
      return;
    }
    unawaited(refreshUnread());
  }

  /// My reaction to [messageId]; an empty [emoji] takes it back.
  Future<void> react(int messageId, String emoji) => auth.authed(
    (token) => auth.api.put(
      '/v1/messages/$messageId/reaction',
      body: {'emoji': emoji},
      token: token,
    ),
  );
}
