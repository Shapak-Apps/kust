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
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/more_sheet.dart';

/// Kept for the puzzle screens that still reference it.
const Color kAccentColor = KustTokens.gold;

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
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
            Text('Welcome to Küşt', style: k.display),
            const SizedBox(height: 8),
            Text(
              'Play bots, solve puzzles and get better one move at a time.',
              style: k.body.copyWith(color: k.muted),
            ),
            const SizedBox(height: 24),
            KustButton(
              label: 'Let’s play',
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
      child: Column(
        children: [
          KustTopBar(
            large: true,
            title: 'Play',
            subtitle: 'Hello, $name',
            trailing: [
              KustIconButton(
                icon: Icons.tune_rounded,
                label: 'Settings',
                onTap: () => showSettingsSheet(context),
              ),
            ],
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _HeroCard(onPlay: _showPlayChooser),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(child: DailyPuzzleCard()),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(child: AchievementsCard()),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: KustSectionLabel('Challenge a bot'),
                  ),
                ),
                _botGrid(kInternationalBots),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: KustSectionLabel('New students from Turkmenistan'),
                  ),
                ),
                _botGrid(kTkmBots),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      24 + KustNavBar.clearance(context),
                    ),
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
              ],
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
  const _HeroCard({required this.onPlay});

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
            'Ready for a game?',
            style: k.title.copyWith(color: k.accentInk),
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder(
            valueListenable: AppStorage.instance.botProgressListenable(),
            builder: (context, _, _) => ValueListenableBuilder(
              valueListenable: PlayerRatingStore.instance.listenable(),
              builder: (context, _, _) => Text(
                'Rating ${PlayerRatingStore.instance.rating} · '
                'Bots beaten ${AppStorage.instance.beatenBotIds.length} of $total',
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
                    'Play a game',
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
