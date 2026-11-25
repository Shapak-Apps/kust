import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/chat_repository.dart';
import 'package:kust/core/net/live_socket.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/net/presence.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/tokens.dart';

/// My bubbles: the app's deep green, with white text.
const Color _mine = Color(0xFF1E6B47);

/// The quick reactions, in the order they are offered.
const List<String> kQuickReactions = ['❤️', '😂', '👍', '😮', '😢', '🔥'];

/// A chat with one friend: messages newest at the bottom, the time and
/// ticks in each bubble, swipe a message right to reply, hold it for
/// reactions (double tap for ❤️), and the system keyboard's emojis.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.username,
    this.player,
    this.repository,
  });

  final String username;
  final Player? player;
  final ChatRepository? repository;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatRepository get _repo => widget.repository ?? ChatRepository.instance;

  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// Newest first: index 0 sits at the bottom.
  List<ChatMessage> _messages = [];
  Player? _player;
  bool _loading = true;
  bool _more = false;
  bool _loadingMore = false;
  ChatMessage? _replying;
  int _localId = 0;
  StreamSubscription<LiveEvent>? _sub;

  String get _me => _repo.me ?? '';

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _repo.openWith = widget.username;
    _input.addListener(() => setState(() {}));
    _scroll.addListener(_onScroll);
    _sub = _repo.changes.listen(_onLive);
    _load();
    if (_player == null) _loadPlayer();
  }

  @override
  void dispose() {
    if (_repo.openWith == widget.username) _repo.openWith = null;
    _sub?.cancel();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadPlayer() async {
    try {
      final got = await PlayersRepository.instance.player(widget.username);
      if (mounted) setState(() => _player = got.player);
    } on ApiException {
      // The header shows the username until then.
    }
  }

  Future<void> _load() async {
    try {
      final page = await _repo.messages(widget.username);
      if (!mounted) return;
      setState(() {
        // Messages still on their way stay at the bottom.
        _messages = [
          for (final m in _messages)
            if (m.id < 0) m,
          ...page.messages,
        ];
        _more = page.more;
        _loading = false;
      });
      _markRead();
    } on ApiException {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _loadOlder();
  }

  Future<void> _loadOlder() async {
    if (!_more || _loadingMore || _messages.isEmpty) return;
    _loadingMore = true;
    try {
      final oldest = _messages.lastWhere((m) => m.id > 0).id;
      final page = await _repo.messages(widget.username, before: oldest);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, ...page.messages];
        _more = page.more;
      });
    } on ApiException {
      // Tried again on the next scroll.
    } finally {
      _loadingMore = false;
    }
  }

  /// Their newest message is read, now that it is on screen.
  void _markRead() {
    final theirs = _messages.where(
      (m) => m.from == widget.username && m.id > 0,
    );
    if (theirs.isEmpty) return;
    final newest = theirs.first;
    if (!newest.read) unawaited(_repo.markRead(widget.username, newest.id));
  }

  bool _inThisChat(Map<String, dynamic> d) =>
      (d['from'] == widget.username && d['to'] == _me) ||
      (d['from'] == _me && d['to'] == widget.username);

  void _onLive(LiveEvent e) {
    final d = e.data;
    switch (e.type) {
      case 'chat_resync':
        _load();
      case 'chat_message':
        if (!_inThisChat(d)) return;
        final m = ChatMessage.fromJson(d);
        if (_messages.any((x) => x.id == m.id)) return;
        setState(() {
          // My own message from another phone, or theirs.
          _messages = [m, ..._messages];
        });
        if (m.from == widget.username) {
          HapticFeedback.selectionClick();
          _markRead();
        }
      case 'chat_read':
        if (d['by'] != widget.username || d['with'] != _me) return;
        final upTo = (d['up_to'] as num?)?.toInt() ?? 0;
        setState(() {
          _messages = [
            for (final m in _messages)
              m.from == _me && m.id > 0 && m.id <= upTo && !m.read
                  ? m.copyWith(read: true)
                  : m,
          ];
        });
      case 'chat_reaction':
        final id = (d['message_id'] as num?)?.toInt();
        final by = d['by'] as String?;
        final emoji = d['emoji'] as String? ?? '';
        if (id == null || by == null) return;
        _setReaction(id, by, emoji);
    }
  }

  void _setReaction(int id, String by, String emoji) {
    final i = _messages.indexWhere((m) => m.id == id);
    if (i < 0) return;
    final m = _messages[i];
    final reactions = {...m.reactions};
    if (emoji.isEmpty) {
      reactions.remove(by);
    } else {
      reactions[by] = emoji;
    }
    setState(() {
      _messages = [..._messages]..[i] = m.copyWith(reactions: reactions);
    });
  }

  /// Shown at once, sent behind; replaced by the server's copy.
  Future<void> _send({ChatMessage? retry}) async {
    final body = retry?.body ?? _input.text.trim();
    if (body.isEmpty) return;
    final reply = retry?.replyTo ?? _replyOf(_replying);
    final local = ChatMessage(
      id: --_localId,
      from: _me,
      to: widget.username,
      body: body,
      createdAt: DateTime.now(),
      replyTo: reply,
      pending: true,
    );
    HapticFeedback.lightImpact();
    setState(() {
      _messages = [
        local,
        for (final m in _messages)
          if (m.id != retry?.id) m,
      ];
      if (retry == null) {
        _input.clear();
        _replying = null;
      }
    });
    if (_scroll.hasClients) {
      unawaited(
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ),
      );
    }
    try {
      final sent = await _repo.send(widget.username, body, replyTo: reply?.id);
      if (!mounted) return;
      setState(() {
        final already = _messages.any((m) => m.id == sent.id);
        _messages = [
          for (final m in _messages)
            if (m.id == local.id) ...[if (!already) sent] else m,
        ];
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages = [
          for (final m in _messages)
            m.id == local.id ? m.copyWith(failed: true) : m,
        ];
      });
      if (e.code == 'not_friends') _say(context.t.chatFriendsOnly);
    }
  }

  ChatReply? _replyOf(ChatMessage? m) => m == null || m.id <= 0
      ? null
      : ChatReply(
          id: m.id,
          from: m.from,
          body: m.body.length > 120 ? '${m.body.substring(0, 120)}…' : m.body,
        );

  void _reply(ChatMessage m) {
    if (m.id <= 0) return;
    HapticFeedback.selectionClick();
    setState(() => _replying = m);
    _focus.requestFocus();
  }

  /// My reaction: the same emoji again takes it back.
  Future<void> _react(ChatMessage m, String emoji) async {
    if (m.id <= 0) return;
    HapticFeedback.selectionClick();
    final now = m.reactions[_me] == emoji ? '' : emoji;
    final before = m.reactions[_me] ?? '';
    _setReaction(m.id, _me, now);
    try {
      await _repo.react(m.id, now);
    } on ApiException {
      if (mounted) _setReaction(m.id, _me, before);
    }
  }

  void _menu(ChatMessage m) {
    if (m.id <= 0) return;
    HapticFeedback.mediumImpact();
    final t = context.t;
    final k = context.k;
    showKustSheet<void>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final e in kQuickReactions)
                GestureDetector(
                  onTap: () {
                    Navigator.of(sheet).pop();
                    _react(m, e);
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: m.reactions[_me] == e
                          ? KustTokens.gold.withValues(alpha: 0.25)
                          : k.surfaceAlt,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _MenuRow(
            icon: Icons.reply_rounded,
            label: t.chatReply,
            onTap: () {
              Navigator.of(sheet).pop();
              _reply(m);
            },
          ),
          _MenuRow(
            icon: Icons.copy_rounded,
            label: t.chatCopy,
            onTap: () {
              Navigator.of(sheet).pop();
              Clipboard.setData(ClipboardData(text: m.body));
              _say(t.chatCopied);
            },
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
    return Scaffold(
      backgroundColor: k.bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: _list(context),
            ),
          ),
          _composer(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final p = _player;
    final name = p?.displayName ?? widget.username;
    return Material(
      color: k.bg,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.only(left: 4, right: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: k.line)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/chats'),
                tooltip: t.back,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () =>
                      context.push('/player/${widget.username}', extra: p),
                  child: Row(
                    children: [
                      PlayerAvatar(
                        size: 38,
                        name: name,
                        photo: avatarImage(avatarUrlFor(p?.avatarKey)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: k.body.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (p?.country != null) ...[
                                  const SizedBox(width: 6),
                                  CountryFlag(p!.country!, height: 14),
                                ],
                              ],
                            ),
                            ValueListenableBuilder<Set<String>>(
                              valueListenable: PresenceService.instance.online,
                              builder: (context, online, _) {
                                final on = online.contains(widget.username);
                                return Text(
                                  on ? t.chatOnline : '@${widget.username}',
                                  maxLines: 1,
                                  style: k.caption.copyWith(
                                    color: on ? k.success : k.muted,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty) {
      // Nothing said yet: the note sits just above the input, as quiet text.
      return const Align(alignment: Alignment.bottomLeft, child: _BeKind());
    }
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final m = _messages[i];
        final newer = i > 0 ? _messages[i - 1] : null;
        final older = i + 1 < _messages.length ? _messages[i + 1] : null;
        // A run of messages from one person close in time sits tight.
        bool together(ChatMessage? a, ChatMessage? b) =>
            a != null &&
            b != null &&
            a.from == b.from &&
            a.createdAt.difference(b.createdAt).abs() <
                const Duration(minutes: 3);
        final newDay = older == null || !_sameDay(older.createdAt, m.createdAt);
        return Column(
          children: [
            if (newDay) _DayLabel(date: m.createdAt),
            Padding(
              padding: EdgeInsets.only(
                top: newDay || together(m, older) ? 2 : 10,
                bottom: (m.reactions.isNotEmpty) ? 14 : 0,
              ),
              child: _Swipe(
                onReply: () => _reply(m),
                child: _Bubble(
                  message: m,
                  mine: m.from == _me,
                  me: _me,
                  tail: !together(m, newer),
                  theirName: _player?.displayName ?? widget.username,
                  onLongPress: () => _menu(m),
                  onDoubleTap: () => _react(m, '❤️'),
                  onRetry: m.failed ? () => _send(retry: m) : null,
                  onReactionTap: () => _menu(m),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _composer(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final replying = _replying;
    final canSend = _input.text.trim().isNotEmpty;
    return Material(
      color: k.bg,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              child: replying == null
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 34,
                            decoration: BoxDecoration(
                              color: KustTokens.gold,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.chatReplyingTo(
                                    replying.from == _me
                                        ? t.chatYou
                                        : (_player?.displayName ??
                                              widget.username),
                                  ),
                                  style: k.caption.copyWith(
                                    color: KustTokens.gold,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  replying.body,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: k.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _replying = null),
                            icon: Icon(Icons.close_rounded, color: k.muted),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      style: k.body,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: t.chatHint,
                        hintStyle: k.body.copyWith(color: k.muted),
                        isDense: true,
                        filled: true,
                        fillColor: k.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: t.chatSend,
                    child: GestureDetector(
                      onTap: canSend ? _send : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: canSend
                              ? const Color(0xFF3CB77C)
                              : k.surfaceAlt,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: canSend ? Colors.white : k.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Before the first message: a quiet line asking to be kind.
class _BeKind extends StatelessWidget {
  const _BeKind();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Text(
        context.t.chatBeKind,
        style: k.body.copyWith(
          color: k.muted,
          fontWeight: FontWeight.w700,
          height: 1.45,
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _clock(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "Today", "Yesterday" or the date, between days.
class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final text = _sameDay(date, now)
        ? t.chatToday
        : _sameDay(date, yesterday)
        ? t.chatYesterday
        : '${t.dateShort(t.monthsShort.split(',')[date.month - 1], date.day)}'
              '${date.year == now.year ? '' : ' ${date.year}'}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: k.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: k.caption.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// Drag a message right to answer it: it follows the finger a little, a
/// reply arrow fades in, and past the line letting go replies.
class _Swipe extends StatefulWidget {
  const _Swipe({required this.child, required this.onReply});

  final Widget child;
  final VoidCallback onReply;

  @override
  State<_Swipe> createState() => _SwipeState();
}

class _SwipeState extends State<_Swipe> with SingleTickerProviderStateMixin {
  static const double _line = 56;
  static const double _max = 76;

  double _dx = 0;
  bool _armed = false;
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..addListener(() => setState(() => _dx = _from * (1 - _back.value)));
  double _from = 0;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final progress = (_dx / _line).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) {
        final next = (_dx + d.delta.dx).clamp(0.0, _max);
        final armed = next >= _line;
        if (armed && !_armed) HapticFeedback.selectionClick();
        setState(() {
          _dx = next;
          _armed = armed;
        });
      },
      onHorizontalDragEnd: (_) {
        if (_armed) widget.onReply();
        _armed = false;
        _from = _dx;
        _back.forward(from: 0);
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 4,
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: 0.6 + 0.4 * progress,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: k.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.reply_rounded, size: 18, color: k.ink),
                ),
              ),
            ),
          ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}

/// One message: on the right in green when mine, on the left otherwise;
/// the message it answers on top, the time and ticks in its corner, the
/// reactions hanging off its bottom edge.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.me,
    required this.tail,
    required this.theirName,
    required this.onLongPress,
    required this.onDoubleTap,
    required this.onReactionTap,
    this.onRetry,
  });

  final ChatMessage message;
  final bool mine;
  final String me;

  /// The last of a run: its corner on the sender's side is sharp.
  final bool tail;
  final String theirName;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;
  final VoidCallback onReactionTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final m = message;
    final fg = mine ? Colors.white : k.ink;
    final soft = mine ? Colors.white.withValues(alpha: 0.7) : k.muted;
    const r = Radius.circular(18);
    const sharp = Radius.circular(6);
    final radius = BorderRadius.only(
      topLeft: r,
      topRight: r,
      bottomLeft: !mine && tail ? sharp : r,
      bottomRight: mine && tail ? sharp : r,
    );
    final reply = m.replyTo;
    final timeStyle = k.caption.copyWith(fontSize: 11, color: soft);
    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_clock(m.createdAt), style: timeStyle),
        if (mine) ...[
          const SizedBox(width: 3),
          Icon(
            m.failed
                ? Icons.error_rounded
                : m.pending
                ? Icons.schedule_rounded
                : m.read
                ? Icons.done_all_rounded
                : Icons.done_rounded,
            size: 15,
            color: m.failed
                ? k.danger
                : m.read
                ? KustTokens.gold
                : soft,
          ),
        ],
      ],
    );
    final painter = TextPainter(
      text: TextSpan(text: _clock(m.createdAt), style: timeStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final timeWidth = painter.width;
    painter.dispose();
    final metaWidth = 8 + timeWidth + (mine ? 18 : 0);
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
      decoration: BoxDecoration(
        color: mine ? _mine : k.surface,
        borderRadius: radius,
      ),
      // As wide as its widest part (the quote or the text), text on the
      // left, time on the right.
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reply != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                decoration: BoxDecoration(
                  color: (mine ? Colors.black : k.ink).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                    left: BorderSide(color: KustTokens.gold, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reply.from == me ? t.chatYou : theirName,
                      style: k.caption.copyWith(
                        color: KustTokens.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      reply.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: k.caption.copyWith(color: soft),
                    ),
                  ],
                ),
              ),
            // As Telegram does: the time (and ticks) sit at the end of the
            // last line when they fit, else on a line of their own. An
            // invisible gap their width ends the text, so they never cover
            // it.
            Stack(
              children: [
                Text.rich(
                  TextSpan(
                    text: m.body,
                    children: [
                      WidgetSpan(child: SizedBox(width: metaWidth, height: 1)),
                    ],
                  ),
                  style: k.body.copyWith(color: fg, height: 1.3),
                ),
                Positioned(right: 0, bottom: 0, child: meta),
              ],
            ),
          ],
        ),
      ),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            onDoubleTap: onDoubleTap,
            onTap: onRetry,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                bubble,
                if (m.reactions.isNotEmpty)
                  Positioned(
                    bottom: -14,
                    right: mine ? null : -2,
                    left: mine ? -2 : null,
                    child: GestureDetector(
                      onTap: onReactionTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: k.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: k.bg, width: 2),
                        ),
                        child: Text(
                          m.reactions.values.toSet().join(' '),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (m.failed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.chatNotSent,
                style: k.caption.copyWith(color: k.danger),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: k.ink),
            const SizedBox(width: 14),
            Text(label, style: k.body.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
