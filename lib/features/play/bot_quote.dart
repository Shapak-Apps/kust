import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/play/bot_voice.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/puzzles/speech_bubble.dart';
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
      height: 22,
      child: AnimatedSwitcher(
        // Pops in over 180 ms, fades out over 150.
        duration: const Duration(milliseconds: 180),
        reverseDuration: const Duration(milliseconds: 150),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            alignment: Alignment.centerLeft,
            scale: Tween(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        ),
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
                child: _Remark(text),
              ),
      ),
    );
  }
}

/// What a bot says in the game: a light bubble with dark words, its tail
/// pointing back at the avatar.
class _Remark extends StatelessWidget {
  const _Remark(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: const Size(6, 10), painter: _TailPainter()),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: squircle(10, color: const Color(0xFFF2F0EA)),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17181A),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height)
        ..close(),
      Paint()..color = const Color(0xFFF2F0EA),
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
}

/// The opponent's portrait with what it says, like a message from it, in
/// the app's one bubble style.
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
    return Semantics(
      label: '$name: $text',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRSuperellipse(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              image,
              width: 68,
              height: 68,
              cacheWidth: 204,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SpeechBubble(
              child: Text(
                text,
                style: k.body.copyWith(
                  color: BubbleColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
