import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/achievements/achievements_card.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/game/game_args.dart';
import 'package:kust/features/play/bot_card.dart';
import 'package:kust/features/play/pick_opponent_modal.dart';
import 'package:kust/features/play/pick_side_modal.dart';
import 'package:kust/features/play/pick_time_modal.dart';
import 'package:kust/features/play/play_mode_modal.dart';
import 'package:kust/features/puzzles/daily_card.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_logo.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/tokens.dart';
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: k.accent,
                borderRadius: BorderRadius.circular(KustSpace.rMedium),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: k.accentInk),
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

  void _startGame() {
    PickOpponentModal.show(
      context,
      onPlay: (bot, side, practiceMode) {
        if (!mounted) return;

        context.go(
          '/game',
          extra: GameArgs(
            bot: bot,
            playerSide: side,
            practiceMode: practiceMode,
          ),
        );
      },
    );
  }

  void _startGameWithBot(Bot bot) {
    PickSideModal.show(
      context,
      bot: bot,
      onPlay: (side, practiceMode) {
        if (!mounted) return;
        context.go(
          '/game',
          extra: GameArgs(
            bot: bot,
            playerSide: side,
            practiceMode: practiceMode,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final name = AppStorage.instance.guestName;

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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(KustSpace.rMedium),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.asset(
                            'assets/images/banner.png',
                            fit: BoxFit.cover,
                            cacheWidth: 900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _HeroCard(name: name, onPlay: _showPlayChooser),
                    ),
                  ),
                  // Daily puzzle and achievements, side by side.
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(child: DailyPuzzleCard()),
                          SizedBox(width: 10),
                          Expanded(child: AchievementsCard()),
                        ],
                      ),
                    ),
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
                leading: PlayerAvatar(name: name),
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
          mainAxisExtent: 132,
        ),
        itemBuilder: (context, i) => RepaintBoundary(
          child: BotCard(bot: bots[i], onTap: () => _startGameWithBot(bots[i])),
        ),
      ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: k.accent,
        borderRadius: BorderRadius.circular(KustSpace.rLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.helloName(name),
            style: k.caption.copyWith(
              color: k.accentInk.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.t.readyForGame,
            style: k.title.copyWith(color: k.accentInk),
          ),
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
                style: k.body.copyWith(
                  color: k.accentInk.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onPlay,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: k.accentInk,
                borderRadius: BorderRadius.circular(KustSpace.rMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: k.accent),
                  const SizedBox(width: 6),
                  Text(
                    context.t.playAGame,
                    style: k.body.copyWith(
                      color: k.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
