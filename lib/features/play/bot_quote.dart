import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/play/bot_voice.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/tokens.dart';

/// Shows [child] (the captured pieces under the bot's name) until the bot has
/// something to say; for a few seconds the line takes its place.
class BotQuoteSwitcher extends ConsumerStatefulWidget {
  const BotQuoteSwitcher({super.key, required this.bot, required this.child});

  final Bot bot;
  final Widget child;

  @override
  ConsumerState<BotQuoteSwitcher> createState() => _BotQuoteSwitcherState();
}

class _BotQuoteSwitcherState extends ConsumerState<BotQuoteSwitcher> {
  static const Duration _shown = Duration(milliseconds: 4200);

  String? _text;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _say(int seq) {
    final moment = ref.read(chessControllerProvider).botMoment;
    if (moment == null || !AppSettings.instance.botChat.value) return;
    _timer?.cancel();
    setState(() => _text = botLine(context.t, widget.bot, moment, seq));
    _timer = Timer(_shown, () {
      if (mounted) setState(() => _text = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(chessControllerProvider.select((g) => g.botMomentSeq), (
      prev,
      next,
    ) {
      if (next != prev) _say(next);
    });
    final text = _text;
    return SizedBox(
      height: 18,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previous, ?current],
        ),
        child: text == null
            ? Align(
                key: const ValueKey('captured'),
                alignment: Alignment.centerLeft,
                child: widget.child,
              )
            : Align(
                key: ValueKey(text),
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
      ),
    );
  }
}

/// The opponent's portrait with what it says, like a message from it.
class BotSays extends StatelessWidget {
  const BotSays({
    super.key,
    required this.name,
    required this.image,
    required this.text,
  });

  final String name;
  final String image;
  final String text;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            image,
            width: 68,
            height: 68,
            cacheWidth: 204,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: k.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: k.caption.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(text, style: k.body.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
