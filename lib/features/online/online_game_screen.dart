import 'dart:async';
import 'dart:io' as io;
import 'dart:ui' show ImageFilter;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/live_socket.dart';
import 'package:kust/core/net/online_repository.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/chess_helpers.dart';
import 'package:kust/features/game/end_text.dart';
import 'package:kust/features/game/game_result_dialog.dart';
import 'package:kust/features/game/time_control.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/game_clock.dart';
import 'package:kust/ui/game_player_bar.dart';
import 'package:kust/ui/kust_action_bar.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/motion.dart';
import 'package:kust/ui/move_strip.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/piece_image.dart';
import 'package:kust/widgets/static_board.dart';
import 'package:kust/ui/skeleton.dart';

/// A live game with a friend, on the same board as a game against a bot
/// (no practice help): the same sounds, premoves, Back and Forward, Flip
/// and captured pieces. My moves go to the server; the friend's come back
/// over the socket. The server keeps the clocks and says how it ends.
class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({super.key, required this.gameId, this.repository});

  final int gameId;
  final OnlineRepository? repository;

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  OnlineRepository get _repo => widget.repository ?? OnlineRepository.instance;

  /// Kept from the start: `ref` can't be used while the screen closes.
  late final ChessController _chess = ref.read(
    chessControllerProvider.notifier,
  );

  OnlineGame? _game;
  Player? _opponent;
  bool _started = false;
  bool _ended = false;
  bool _saved = false;

  /// Seen while it was played, so its start and end are shown.
  bool _seenLive = false;
  StreamSubscription<OnlineGame>? _sub;

  String get _me => _repo.me ?? '';
  bool get _iAmWhite => _game?.white == _me;

  @override
  void initState() {
    super.initState();
    boardFlipped.value = false;
    _chess; // read now, while ref is usable
    _sub = _repo.changes.listen((g) {
      if (g.id == widget.gameId) _show(g);
    });
    LiveSocket.instance.state.addListener(_onLink);
    _load();
  }

  LiveState _link = LiveSocket.instance.state.value;

  /// Back online: whatever happened meanwhile comes from the server. A lost
  /// connection never ends the game; only the clock does.
  void _onLink() {
    final now = LiveSocket.instance.state.value;
    if (now == LiveState.connected && _link != LiveState.connected) _load();
    _link = now;
  }

  @override
  void dispose() {
    LiveSocket.instance.state.removeListener(_onLink);
    _sub?.cancel();
    final chess = _chess;
    chess.onOnlineMove = null;
    chess.onOnlineFlag = null;
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _show(await _repo.game(widget.gameId));
    } on ApiException {
      // Shown as loading until the socket brings it.
    }
  }

  /// The game as the server has it, brought onto the board.
  void _show(OnlineGame g) {
    if (!mounted) return;
    setState(() => _game = g);
    if (_opponent == null) _loadOpponent(g.opponentOf(_me));
    if (g.pending) return;
    final chess = _chess;
    final mine = g.white == _me ? Side.white : Side.black;
    final played = ref.read(chessControllerProvider).moves;
    final known = [for (final m in played) m.move.uci];
    final inStep =
        known.length <= g.moves.length &&
        Iterable.generate(known.length).every((i) => known[i] == g.moves[i]);
    if (!_started || !inStep) {
      // First time, or out of step: the server's game is the truth.
      _started = true;
      chess.onOnlineMove = _send;
      chess.onOnlineFlag = () => _repo.flag(g.id).then(_show, onError: (_) {});
      chess.startOnlineGame(
        playerSide: mine,
        timeControl: TimeControl(
          baseMinutes: g.baseMs ~/ 60000,
          incrementSeconds: g.incMs ~/ 1000,
        ),
        uciMoves: g.moves,
      );
    } else {
      for (final uci in g.moves.skip(known.length)) {
        chess.applyOnlineMove(uci);
      }
    }
    if (g.active && !_seenLive) {
      _seenLive = true;
      if (g.moves.isEmpty) {
        showGameStartModal(context, white: mine == Side.white);
      }
    }
    final clocks = g.clocksNow();
    chess.syncOnlineClocks(white: clocks.white, black: clocks.black);
    if (g.over && !_ended) {
      _ended = true;
      HapticFeedback.heavyImpact();
      chess.endOnline(
        winner: switch (g.result) {
          'white' => Side.white,
          'black' => Side.black,
          _ => null,
        },
        reason: g.reason ?? '',
      );
      _save(g);
      if (_seenLive) _showResult(g);
    }
  }

  /// The end, as after a bot game: the result, the rating of the moves,
  /// Review and Rematch.
  void _showResult(OnlineGame g) {
    final mate =
        ref.read(chessControllerProvider).status == GameStatus.checkmate;
    Future.delayed(Duration(milliseconds: mate ? 1800 : 400), () {
      if (!mounted) return;
      final texts = resultHeadline(
        context.t,
        ref.read(chessControllerProvider),
      );
      showGameResult(
        context,
        builder: (dialogContext) => GameResultScreen(
          title: texts.$1,
          message: texts.$2,
          onClose: () => Navigator.of(dialogContext).pop(),
          onReview: (id) {
            Navigator.of(dialogContext).pop();
            context.push('/review/$id');
          },
          onRematch: () {
            Navigator.of(dialogContext).pop();
            _rematch(g);
          },
        ),
      );
    });
  }

  /// The same game again, colours swapped.
  Future<void> _rematch(OnlineGame g) async {
    try {
      final next = await _repo.challenge(
        g.opponentOf(_me),
        baseMinutes: g.baseMs ~/ 60000,
        incrementSeconds: g.incMs ~/ 1000,
        side: _iAmWhite ? 'black' : 'white',
      );
      if (mounted) context.pushReplacement('/online/${next.id}');
    } on ApiException {
      // Nothing sent; the finished game stays.
    }
  }

  Future<void> _loadOpponent(String username) async {
    try {
      final got = await PlayersRepository.instance.player(username);
      if (mounted) setState(() => _opponent = got.player);
    } on ApiException {
      // The bar shows the username alone.
    }
  }

  /// My move (a premove too), as the board played it: to the server, with
  /// how it ends the game if it does.
  Future<void> _send(NormalMove move, int ply) async {
    final g = _game;
    if (g == null) return;
    final s = ref.read(chessControllerProvider);
    final end = switch (s.status) {
      GameStatus.checkmate => 'checkmate',
      GameStatus.draw =>
        s.endReason == EndReason.stalemate ? 'stalemate' : 'draw',
      _ => null,
    };
    try {
      _show(await _repo.move(g.id, ply, move.uci, end: end));
    } on ApiException {
      // Refused or offline: the server's game is put back on the board.
      await _load();
    }
  }

  /// Once over, the game joins my history like any other (and so my
  /// profile).
  Future<void> _save(OnlineGame g) async {
    if (_saved || g.moves.isEmpty || !AppStorage.isReady) return;
    _saved = true;
    final mine = _iAmWhite ? 'white' : 'black';
    final moves = ref.read(chessControllerProvider).moves;
    await GameHistoryStore.instance.add(
      GameRecord(
        id: 'online-${g.id}',
        playedAt: DateTime.now().millisecondsSinceEpoch,
        isLocal: false,
        result: g.result == 'draw'
            ? GameRecord.draw
            : g.result == mine
            ? GameRecord.win
            : GameRecord.loss,
        reason: g.reason ?? '',
        playerIsWhite: _iAmWhite,
        uciMoves: [for (final m in moves) m.move.uci],
        sanMoves: [for (final m in moves) m.san],
        botId: 'online',
        botName: g.opponentOf(_me),
        botElo: _opponent?.rating,
        timeControl: '${g.baseMs ~/ 60000}+${g.incMs ~/ 1000}',
      ),
    );
    if (mounted) _chess.markOnlineSaved('online-${g.id}', rate: _seenLive);
  }

  /// Resign and Offer a draw both ask first.
  void _confirm({
    required String title,
    required String subtitle,
    required String action,
    required bool danger,
    required Future<OnlineGame> Function() then,
  }) {
    final t = context.t;
    showKustSheet<void>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KustSheetHeader(title: title, subtitle: subtitle),
          KustButton(
            label: action,
            style: danger ? KustButtonStyle.danger : KustButtonStyle.primary,
            onTap: () {
              Navigator.of(sheet).pop();
              then().then(_show, onError: (_) {});
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

  Future<void> _cancel() async {
    final g = _game;
    if (g == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final text = context.t.onlineCancelled;
    try {
      await _repo.decline(g.id);
    } on ApiException {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go('/play');
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final g = _game;
    final opponent = g?.opponentOf(_me) ?? '';
    final s = ref.watch(chessControllerProvider);
    final cursor = s.analysisIndex ?? s.moves.length;
    return Scaffold(
      backgroundColor: k.bg,
      body: SafeArea(
        child: Column(
          children: [
            KustTopBar(
              // Just the friend's name: "Game with …" was cut short.
              title: g == null ? '' : opponent,
              subtitle: g == null
                  ? null
                  : TimeControl(
                      baseMinutes: g.baseMs ~/ 60000,
                      incrementSeconds: g.incMs ~/ 1000,
                    ).labelIn(t),
              leading: KustIconButton(
                icon: Icons.arrow_back_rounded,
                label: t.back,
                onTap: () =>
                    context.canPop() ? context.pop() : context.go('/play'),
              ),
              trailing: const [_Signal()],
            ),
            const _ReconnectingStrip(),
            if (g == null)
              const Expanded(child: Center(child: KustLoader()))
            else ...[
              if (!g.pending)
                MoveStrip(
                  labels: [
                    for (var i = 0; i < s.moves.length; i++)
                      moveLabel(i, s.moves[i].san),
                  ],
                  selected: cursor,
                  onTap: (ply) => _chess.jumpToMove(ply - 1),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = (box.maxHeight - 2 * 56 - 16).clamp(
                      0.0,
                      box.maxWidth,
                    );
                    return Center(
                      child: SizedBox(
                        width: side,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: boardFlipped,
                          builder: (context, flip, _) {
                            final top = _bar(
                              context,
                              g,
                              s,
                              white: !_iAmWhite != flip,
                            );
                            final bottom = _bar(
                              context,
                              g,
                              s,
                              white: _iAmWhite != flip,
                            );
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                top,
                                SizedBox(
                                  width: side,
                                  height: side,
                                  child: g.pending && g.challenger == _me
                                      // Waiting for the friend: the board
                                      // blurred, a piece changing over it.
                                      ? const _WaitingBoard()
                                      : g.pending
                                      ? StaticBoard(
                                          position: Chess.initial,
                                          flipped: !_iAmWhite,
                                        )
                                      : const ChessBoard(),
                                ),
                                bottom,
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              _footer(context, g, s),
            ],
          ],
        ),
      ),
    );
  }

  /// A player: photo, name, flag and captured pieces, and the clock
  /// (bright while it runs).
  Widget _bar(
    BuildContext context,
    OnlineGame g,
    GameState s, {
    required bool white,
  }) {
    final username = white ? g.white : g.black;
    final isMe = username == _me;
    final p = isMe ? null : _opponent;
    final side = white ? Side.white : Side.black;
    final left = white ? s.whiteTimeLeft : s.blackTimeLeft;
    final running =
        s.mode == GameMode.online &&
        s.status == GameStatus.playing &&
        g.active &&
        s.position.turn == side;
    // While a challenge waits, the board still holds the last game.
    final online = s.mode == GameMode.online && !g.pending;
    final rating = isMe
        ? AuthService.instance.state.value.account?.rating
        : p?.rating;
    return GamePlayerBar(
      avatar: PlayerAvatar(
        size: 40,
        name: p?.displayName ?? username,
        // Mine: the photo on this phone, else my account's.
        photo: isMe
            ? (AppStorage.isReady && AppStorage.instance.photoPath != null
                  ? FileImage(io.File(AppStorage.instance.photoPath!))
                  : avatarImage(
                      avatarUrlFor(
                        AuthService.instance.state.value.account?.avatarKey,
                      ),
                    ))
            : avatarImage(avatarUrlFor(p?.avatarKey)),
      ),
      name: username,
      flag: switch (isMe
          ? (AppStorage.isReady ? AppStorage.instance.country : null)
          : p?.country) {
        final c? => CountryFlag(c, height: 18),
        null => null,
      },
      rating: rating == null ? null : '$rating',
      captured: online ? piecesCapturedBy(side, s.moves) : const [],
      advantage: online ? boardMaterialAdvantageFor(s.position, side) : 0,
      clock: GameClock(
        time: g.pending ? Duration(milliseconds: g.baseMs) : left,
        active: running,
      ),
    );
  }

  Widget _footer(BuildContext context, OnlineGame g, GameState s) {
    final k = context.k;
    final t = context.t;
    final opponent = g.opponentOf(_me);
    Widget actions({bool playing = false}) => KustActionBar(
      actions: [
        if (playing) ...[
          KustAction(
            icon: Icons.handshake_outlined,
            label: t.onlineDraw,
            onTap: g.drawOffer == _me
                ? null
                : () => _confirm(
                    title: t.onlineOfferDraw,
                    subtitle: t.onlineOfferDrawSub(opponent),
                    action: t.onlineOfferDraw,
                    danger: false,
                    then: () => _repo.draw(g.id),
                  ),
          ),
          KustAction(
            icon: Icons.flag_outlined,
            label: t.resign,
            onTap: () => _confirm(
              title: t.resignTitle,
              subtitle: t.resignSubtitle,
              action: t.resign,
              danger: true,
              then: () => _repo.resign(g.id),
            ),
          ),
        ],
        KustAction(
          icon: Icons.chevron_left_rounded,
          label: t.back,
          onTap: s.analysisCursor > 0 ? _chess.analysisMoveBack : null,
        ),
        KustAction(
          icon: Icons.chevron_right_rounded,
          label: t.forward,
          onTap: s.analysisIndex != null ? _chess.analysisMoveNext : null,
        ),
        KustAction(
          icon: Icons.swap_vert_rounded,
          label: t.flipShort,
          onTap: () => boardFlipped.value = !boardFlipped.value,
        ),
      ],
    );

    if (g.pending && g.challenger == _me) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.onlineWaiting(opponent),
              textAlign: TextAlign.center,
              style: k.body.copyWith(color: k.muted),
            ),
            const SizedBox(height: 10),
            KustButton(
              label: t.onlineCancel,
              style: KustButtonStyle.secondary,
              onTap: _cancel,
            ),
          ],
        ),
      );
    }
    if (g.pending) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: KustButton(
                label: t.friendAccept,
                onTap: () => _repo.accept(g.id).then(_show, onError: (_) {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KustButton(
                label: t.friendDecline,
                style: KustButtonStyle.secondary,
                onTap: () => _repo.decline(g.id).then(_show, onError: (_) {}),
              ),
            ),
          ],
        ),
      );
    }
    if (g.active) {
      final theirOffer = g.drawOffer != null && g.drawOffer != _me;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Their draw offer, to answer.
            if (theirOffer)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.onlineDrawOffered(opponent),
                        style: k.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    KustIconButton(
                      icon: Icons.close_rounded,
                      label: t.friendDecline,
                      onTap: () =>
                          _repo.declineDraw(g.id).then(_show, onError: (_) {}),
                    ),
                    const SizedBox(width: 8),
                    KustIconButton(
                      icon: Icons.check_rounded,
                      label: t.friendAccept,
                      filled: true,
                      onTap: () =>
                          _repo.draw(g.id).then(_show, onError: (_) {}),
                    ),
                  ],
                ),
              ),
            actions(playing: true),
          ],
        ),
      );
    }
    final mine = _iAmWhite ? 'white' : 'black';
    final title = switch (g.status) {
      'declined' => t.onlineDeclined(opponent),
      'cancelled' => t.onlineCancelled,
      _ =>
        g.result == 'draw'
            ? t.onlineDraw
            : g.result == mine
            ? t.youWonTitle
            : t.youLostTitle,
    };
    final reason = switch (g.reason) {
      'checkmate' => t.byCheckmate,
      'resign' => t.byResignation,
      'timeout' => t.byTimeout,
      'stalemate' => t.byStalemate,
      'agreement' => t.byAgreement,
      'draw' => t.byInsufficient,
      _ => '',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seen ending live, the result screen said it already.
          if (!_seenLive)
            Text(
              title,
              textAlign: TextAlign.center,
              style: k.title.copyWith(fontWeight: FontWeight.w800),
            ),
          if (reason.isNotEmpty && !_seenLive)
            Text(
              reason,
              textAlign: TextAlign.center,
              style: k.body.copyWith(color: k.muted),
            ),
          const SizedBox(height: 8),
          if (s.moves.isNotEmpty) actions(),
        ],
      ),
    );
  }
}

/// The link to the server, top right, as on chess.com: four bars when
/// connected, bars filling over and over while reconnecting, one red bar
/// when offline.
class _Signal extends StatefulWidget {
  const _Signal();

  @override
  State<_Signal> createState() => _SignalState();
}

class _SignalState extends State<_Signal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ValueListenableBuilder<LiveState>(
      valueListenable: LiveSocket.instance.state,
      builder: (context, state, _) {
        final trying = state == LiveState.connecting;
        if (trying && !_c.isAnimating) _c.repeat();
        if (!trying && _c.isAnimating) _c.stop();
        return Semantics(
          label: state == LiveState.connected
              ? context.t.onlineConnection
              : context.t.onlineReconnecting,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final lit = switch (state) {
                  LiveState.connected => 4,
                  LiveState.connecting => 1 + (_c.value * 4).floor() % 4,
                  LiveState.idle => 1,
                };
                final on = switch (state) {
                  LiveState.connected => k.success,
                  LiveState.connecting => KustTokens.gold,
                  LiveState.idle => k.danger,
                };
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: 4,
                        height: 6.0 + i * 4,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: i < lit ? on : k.line,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Under the top bar while the link is down: says it is coming back.
class _ReconnectingStrip extends StatelessWidget {
  const _ReconnectingStrip();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ValueListenableBuilder<LiveState>(
      valueListenable: LiveSocket.instance.state,
      builder: (context, state, _) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: state == LiveState.connected
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: KustTokens.gold.withValues(alpha: 0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t.onlineReconnecting,
                      style: k.caption.copyWith(color: k.ink),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The board of a challenge not yet answered: blurred, with a piece over it
/// that turns into the next every 600 ms (queen, knight, bishop).
class _WaitingBoard extends StatefulWidget {
  const _WaitingBoard();

  @override
  State<_WaitingBoard> createState() => _WaitingBoardState();
}

class _WaitingBoardState extends State<_WaitingBoard> {
  static const _roles = ['Q', 'N', 'B'];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (mounted) setState(() => _i = (_i + 1) % _roles.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final set = AppSettings.instance.pieceSet.value;
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: StaticBoard(position: Chess.initial),
        ),
        AnimatedSwitcher(
          duration: motion(context, const Duration(milliseconds: 250)),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: PieceImage(
            set.asset('w', _roles[_i]),
            key: ValueKey(_i),
            width: 48,
            height: 48,
          ),
        ),
      ],
    );
  }
}
