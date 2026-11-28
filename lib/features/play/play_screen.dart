import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/server_config.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/live_game_store.dart';
import 'package:kust/features/game/time_control.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/game/game_args.dart';
import 'package:kust/features/play/bot_card.dart';
import 'package:kust/features/play/pick_opponent_modal.dart';
import 'package:kust/features/play/pick_side_modal.dart';
import 'package:kust/features/play/pick_time_modal.dart';
import 'package:kust/features/play/play_mode_modal.dart';
import 'package:kust/features/players/notifications_screen.dart';
import 'package:kust/features/puzzles/daily_card.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_logo.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/board_thumbnail.dart';
import 'package:kust/widgets/more_sheet.dart';
import 'package:kust/l10n/app_locale.dart';

/// Kept for the puzzle screens that still reference it.
const Color kAccentColor = KustTokens.gold;

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  /// Whether the list has moved under the top bar. Only then is there
  /// anything to blur, so the bar stays solid (and cheap) at the top.
  final ValueNotifier<bool> _scrolled = ValueNotifier(false);

  @override
  void dispose() {
    _scrolled.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcome());
  }

  Future<void> _showWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('welcome_modal_shown') ?? false) return;
    if (!mounted) return;
    await prefs.setBool('welcome_modal_shown', true);
    if (!mounted) return;

    showKustSheet<void>(
      context,
      builder: (sheetContext) {
        final k = sheetContext.k;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The bots around one board: who you will be playing.
            ClipRSuperellipse(
              borderRadius: BorderRadius.circular(KustSpace.rCard),
              child: Image.asset(
                'assets/images/welcome.webp',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(sheetContext.t.welcomeTitle, style: k.display),
            const SizedBox(height: 8),
            Text(
              sheetContext.t.welcomeSub,
              style: k.body.copyWith(color: k.muted),
            ),
            const SizedBox(height: 24),
            KustButton(
              label: sheetContext.t.letsPlay,
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showPlayChooser() {
    PlayModeModal.show(
      context,
      onBots: () {
        if (!mounted) return;
        _startGame();
      },
      onLocal: () {
        if (!mounted) return;
        PickTimeControlModal.show(
          context,
          onPick: (timeControl) {
            if (!mounted) return;
            context.go(
              '/game',
              extra: GameArgs(
                playerSide: Side.white,
                isLocal: true,
                timeControl: timeControl,
              ),
            );
          },
        );
      },
    );
  }

  /// Picks up the saved game, with the bot it was played against.
  void _continueGame(LiveGame saved) {
    Bot? bot;
    if (!saved.isLocal) {
      for (final b in [...kInternationalBots, ...kTkmBots]) {
        if (b.id == saved.botId) bot = b;
      }
      if (bot == null) {
        LiveGameStore.instance.clear();
        return;
      }
    }
    final base = saved.baseMinutes;
    context.go(
      '/game',
      extra: GameArgs(
        bot: bot,
        playerSide: saved.playerIsWhite ? Side.white : Side.black,
        isLocal: saved.isLocal,
        practiceMode: saved.practice,
        timeControl: base == null
            ? null
            : TimeControl(
                baseMinutes: base,
                incrementSeconds: saved.incrementSeconds,
              ),
        resume: saved,
      ),
    );
  }

  void _startGame() {
    PickOpponentModal.show(
      context,
      onPlay: (bot, side, practiceMode, timeControl) {
        if (!mounted) return;

        context.go(
          '/game',
          extra: GameArgs(
            bot: bot,
            playerSide: side,
            practiceMode: practiceMode,
            timeControl: timeControl,
          ),
        );
      },
    );
  }

  void _startGameWithBot(Bot bot) {
    PickSideModal.show(
      context,
      bot: bot,
      onPlay: (side, practiceMode, timeControl) {
        if (!mounted) return;
        context.go(
          '/game',
          extra: GameArgs(
            bot: bot,
            playerSide: side,
            practiceMode: practiceMode,
            timeControl: timeControl,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ValueListenableBuilder(
      valueListenable: AppStorage.instance.nameListenable(),
      builder: (context, _, _) {
        final name = AppStorage.instance.displayName(context.t);
        return _page(context, k, name);
      },
    );
  }

  Widget _page(BuildContext context, KustTokens k, String name) {
    return ColoredBox(
      color: k.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.depth == 0) _scrolled.value = n.metrics.pixels > 0;
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  // Room for the see-through top bar laid over the list.
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          MediaQuery.paddingOf(context).top +
                          KustTopBar.barHeight,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _ContinueCard(onContinue: _continueGame),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: ValueListenableBuilder(
                        valueListenable:
                            LiveGameStore.instance.listenable() ??
                            ValueNotifier(null),
                        builder: (context, _, _) =>
                            _HeroCard(name: name, onPlay: _showPlayChooser),
                      ),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(child: DailyPuzzleCard()),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: KustSectionLabel(context.t.challengeBot),
                    ),
                  ),
                  _botGrid(kInternationalBots),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: KustSectionLabel(context.t.newStudents),
                    ),
                  ),
                  _botGrid(kTkmBots),
                  SliverToBoxAdapter(
                    child: SizedBox(height: 24 + KustNavBar.clearance(context)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _scrolled,
              builder: (context, scrolled, _) => KustTopBar(
                translucent: scrolled,
                title: 'Küşt',
                brand: const KustLogo(height: 22),
                // My avatar, and beside it the bell for what is waiting.
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A guest sees a plain person and is taken to sign up.
                    ValueListenableBuilder<AuthState>(
                      valueListenable: AuthService.instance.state,
                      builder: (context, auth, _) {
                        final guest =
                            ServerConfig.enabled &&
                            auth.status == AuthStatus.signedOut;
                        return Semantics(
                          button: true,
                          label: guest
                              ? context.t.createAccount
                              : context.t.profile,
                          child: Pressable(
                            onTap: () =>
                                context.push(guest ? '/register' : '/profile'),
                            child: PlayerAvatar(
                              name: guest ? null : name,
                              photo: guest
                                  ? null
                                  : AppStorage.instance.photoPath != null
                                  ? FileImage(
                                      io.File(AppStorage.instance.photoPath!),
                                    )
                                  : avatarImage(
                                      avatarUrlFor(auth.account?.avatarKey),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    const NotificationsBell(),
                  ],
                ),
                trailing: [
                  KustIconButton(
                    icon: Icons.tune_rounded,
                    label: context.t.settings,
                    onTap: () => showSettingsSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botGrid(List<Bot> bots) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      sliver: SliverGrid.builder(
        itemCount: bots.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 158,
        ),
        itemBuilder: (context, i) => RepaintBoundary(
          child: BotCard(bot: bots[i], onTap: () => _startGameWithBot(bots[i])),
        ),
      ),
    );
  }
}

/// "Continue your game": shown while a game was left unfinished.
/// The game left unfinished: its position on a small board, who it is
/// against and whose move it is, a Continue button, and an ✕ that removes
/// it (with Undo).
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.onContinue});

  final void Function(LiveGame game) onContinue;

  void _remove(BuildContext context, LiveGame game) {
    final store = LiveGameStore.instance;
    store.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.t.gameRemoved),
          action: SnackBarAction(
            label: context.t.undo,
            onPressed: () => store.save(game),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final listenable = LiveGameStore.instance.listenable();
    if (listenable == null) return const SizedBox.shrink();
    return ValueListenableBuilder(
      valueListenable: listenable,
      builder: (context, _, _) {
        final game = LiveGameStore.instance.get();
        if (game == null) return const SizedBox.shrink();
        final k = context.k;
        final t = context.t;
        Bot? bot;
        for (final b in [...kInternationalBots, ...kTkmBots]) {
          if (b.id == game.botId) bot = b;
        }
        if (!game.isLocal && bot == null) return const SizedBox.shrink();
        Position position = Chess.initial;
        try {
          for (final uci in game.uciMoves) {
            position = position.play(NormalMove.fromUci(uci));
          }
        } catch (_) {
          return const SizedBox.shrink();
        }
        final playerSide = game.playerIsWhite ? Side.white : Side.black;
        final who = game.isLocal ? t.passAndPlay : t.vsBot(bot!.name);
        final turn = game.isLocal
            ? (position.turn == Side.white ? t.whiteName : t.blackName)
            : null;
        final mine = game.isLocal || position.turn == playerSide;
        final toMove = game.isLocal
            ? t.sideToMove(turn!)
            : position.turn == playerSide
            ? t.yourMove
            : t.sideToMove(bot!.name);
        // No card: a section of the page like the rest, its title with a
        // close button, the game in a row, and a full-width Continue.
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.continueGame,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k.section,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: t.discardGame,
                    excludeSemantics: true,
                    child: Pressable(
                      onTap: () => _remove(context, game),
                      child: SizedBox.square(
                        dimension: 36,
                        child: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: k.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Pressable(
                onTap: () => onContinue(game),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: BoardThumbnail(
                        position: position,
                        flipped: !game.isLocal && playerSide == Side.black,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            who,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: k.rowTitle,
                          ),
                          const SizedBox(height: 6),
                          // The move, then whose turn in its own pill: two
                          // things side by side, no dot between them.
                          Row(
                            children: [
                              Text(
                                t.reviewMoveNo((game.uciMoves.length + 1) ~/ 2),
                                style: k.caption,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: squircle(
                                    10,
                                    color: mine
                                        ? k.success.withValues(alpha: 0.16)
                                        : k.surfaceAlt,
                                  ),
                                  child: Text(
                                    toMove,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: k.captionStrong.copyWith(
                                      color: mine ? k.success : k.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              KustButton(
                label: t.continueButton,
                icon: Icons.play_arrow_rounded,
                onTap: () => onContinue(game),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.name, required this.onPlay});

  /// The player's name, for the greeting.
  final String name;

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final total = kInternationalBots.length + kTkmBots.length;

    // No card around it: the greeting and Play stand on the page.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.helloName(name),
            style: k.caption.copyWith(
              color: k.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(context.t.readyForGame, style: k.title),
          const SizedBox(height: 4),
          ValueListenableBuilder(
            valueListenable: AppStorage.instance.botProgressListenable(),
            builder: (context, _, _) => ValueListenableBuilder(
              valueListenable: PlayerRatingStore.instance.listenable(),
              builder: (context, _, _) => Text(
                context.t.ratingBots(
                  PlayerRatingStore.instance.rating,
                  AppStorage.instance.beatenBotIds.length,
                  total,
                ),
                style: k.body.copyWith(color: k.muted),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // A game waiting to be continued takes the green button; a new
          // one is the quieter choice then.
          if (LiveGameStore.instance.get() == null)
            KustButton3D(
              label: context.t.playAGame,
              icon: Icons.play_arrow_rounded,
              expand: true,
              onTap: onPlay,
            )
          else
            KustButton(
              label: context.t.playAGame,
              icon: Icons.add_rounded,
              style: KustButtonStyle.secondary,
              onTap: onPlay,
            ),
        ],
      ),
    );
  }
}
