import 'package:flutter/material.dart';
import 'package:Kust/features/play/app_bar.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kAccentColor = Color(0xFFFFBB00);

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

  void _openOpponentPicker() {
    PickOpponentModal.show(
      context,
      onPlay: (bot) {
        debugPrint('Selected ${bot.name} (${bot.elo} Elo)');

        // TODO : Navigate to the game screen with the selected bot
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello Guest!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
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
                    onPressed: _openOpponentPicker,
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
          ],
        ),
      ),
    );
  }
}
