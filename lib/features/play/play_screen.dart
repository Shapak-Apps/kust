import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:Kust/features/play/app_bar.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';
import 'package:Kust/features/play/pick_side_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Kust/features/game/game_args.dart';

const Color kAccentColor = Color(0xFFFFBB00);

const List<Bot> _challengeBots = [
  Bot(name: 'Elizabeth', elo: 600, imagePath: 'assets/bots/Elizabeth.png'),
  Bot(name: 'Mark', elo: 700, imagePath: 'assets/bots/Mark.png'),
  Bot(name: 'Apex', elo: 800, imagePath: 'assets/bots/Apex.png'),
  Bot(name: 'Karl', elo: 1000, imagePath: 'assets/bots/Karl.png'),
  Bot(name: 'Maya', elo: 1200, imagePath: 'assets/bots/Maya.png'),
  Bot(name: 'Yura', elo: 1400, imagePath: 'assets/bots/Yura.png'),
];

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  Future<void> _showWelcomeDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('welcome_modal_shown') ?? false;

    if (alreadyShown || !mounted) return;

    await prefs.setBool('welcome_modal_shown', true);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);

        return Dialog(
          backgroundColor: theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: kAccentColor,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 34,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Welcome to Kust!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Everything is ready. Find an opponent, '
                  'play a game and start improving your chess.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.65,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Let’s play',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startGame() {
    PickOpponentModal.show(
      context,
      onPlay: (bot, side) {
        if (!mounted) return;

        context.go(
          '/game',
          extra: GameArgs(bot: bot, playerSide: side),
        );
      },
    );
  }

  void _startGameWithBot(Bot bot) {
    PickSideModal.show(
      context,
      bot: bot,
      onPlay: (side) {
        if (!mounted) return;

        context.go(
          '/game',
          extra: GameArgs(bot: bot, playerSide: side),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello Guest!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Expanded(
                    child: Text('You have played 10 games, wanna play again?'),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextButton(
                      onPressed: _startGame,
                      style: ButtonStyle(
                        minimumSize: WidgetStateProperty.all(
                          const Size(double.infinity, 50),
                        ),
                        backgroundColor: WidgetStateProperty.all(kAccentColor),
                        foregroundColor: WidgetStateProperty.all(Colors.black),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Play a game',
                        style: TextStyle(color: Color(0xFF181A1B)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                'Announcements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    'assets/images/banner.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Our bots wanna challenge you',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _challengeBots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.975,
                ),
                itemBuilder: (context, index) {
                  final bot = _challengeBots[index];
                  return _BotChallengeCard(
                    bot: bot,
                    onTap: () => _startGameWithBot(bot),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotChallengeCard extends StatelessWidget {
  const _BotChallengeCard({required this.bot, required this.onTap});

  final Bot bot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                bot.imagePath,
                height: 53,
                width: 53,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              bot.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: (theme.textTheme.titleSmall?.fontSize ?? 14) * 1.10,
              ),
            ),
            const SizedBox(height: 2),

            Text(
              '${bot.elo} Elo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) * 1.10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
