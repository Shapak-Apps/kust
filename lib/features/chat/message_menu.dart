import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/ui/tokens.dart';

/// One row of the menu card.
class MessageMenuAction {
  const MessageMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

/// Telegram's hold menu: the chat dims, the held message is lifted above
/// it (gliding to where everything fits), a bar of reactions pops in over
/// it one emoji after another, and a card of actions opens under it.
///
/// Only opacity, scale and position animate, all from one controller, with
/// no blur: cheap enough for 60 fps on modest phones.
Future<void> showMessageMenu(
  BuildContext context, {
  required Rect bubbleRect,
  required Widget bubble,
  required bool mine,
  required List<String> reactions,
  required String? myReaction,
  required ValueChanged<String> onReact,
  required List<MessageMenuAction> actions,
  Widget? header,
}) {
  HapticFeedback.mediumImpact();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, animation, _) => _MessageMenu(
        animation: animation,
        bubbleRect: bubbleRect,
        bubble: bubble,
        mine: mine,
        reactions: reactions,
        myReaction: myReaction,
        onReact: onReact,
        actions: actions,
        header: header,
      ),
    ),
  );
}

class _MessageMenu extends StatelessWidget {
  const _MessageMenu({
    required this.animation,
    required this.bubbleRect,
    required this.bubble,
    required this.mine,
    required this.reactions,
    required this.myReaction,
    required this.onReact,
    required this.actions,
    this.header,
  });

  final Animation<double> animation;
  final Rect bubbleRect;
  final Widget bubble;
  final bool mine;
  final List<String> reactions;
  final String? myReaction;
  final ValueChanged<String> onReact;
  final List<MessageMenuAction> actions;
  final Widget? header;

  static const double _margin = 8;
  static const double _gap = 8;
  static const double _emoji = 44;
  static const double _barPad = 6;
  static const double _barHeight = _emoji + _barPad * 2;
  static const double _menuWidth = 232;
  static const double _rowHeight = 48;
  static const double _headerHeight = 40;

  void _close(BuildContext context, [VoidCallback? then]) {
    Navigator.of(context).pop();
    // After the menu has started to go, so the next screen or sheet opens
    // on a calm chat.
    if (then != null) Future.microtask(then);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final media = MediaQuery.of(context);
    final size = media.size;

    // The room there is: below the status bar, above the gesture bar or
    // the keyboard, with a margin all round.
    final top = media.padding.top + _margin;
    final bottom =
        size.height -
        math.max(media.padding.bottom, media.viewInsets.bottom) -
        _margin;
    final menuHeight =
        (header == null ? 0 : _headerHeight) + actions.length * _rowHeight + 12;
    final barWidth = math.min(
      size.width - _margin * 2,
      reactions.length * _emoji + _barPad * 2,
    );

    // Bar, bubble and card stacked: where the bubble must sit so all three
    // fit, as close as can be to where it already is.
    final h = bubbleRect.height;
    final need = _barHeight + _gap + h + _gap + menuHeight;
    final fits = need <= bottom - top;
    final double barTop;
    final double bubbleTop;
    final double menuTop;
    if (fits) {
      barTop = (bubbleRect.top - _barHeight - _gap).clamp(top, bottom - need);
      bubbleTop = barTop + _barHeight + _gap;
      menuTop = bubbleTop + h + _gap;
    } else {
      // A message taller than the screen: it stays put, and the bar and
      // the card float over it, centred.
      bubbleTop = bubbleRect.top;
      final rest = _barHeight + _gap + menuHeight;
      barTop = ((top + bottom - rest) / 2).clamp(top, bottom - rest);
      menuTop = barTop + _barHeight + _gap;
    }

    // Lined up with the message's own side, kept on screen.
    double side(double width) => mine
        ? (bubbleRect.right - width).clamp(
            _margin,
            size.width - width - _margin,
          )
        : bubbleRect.left.clamp(_margin, size.width - width - _margin);
    final barLeft = side(barWidth);
    final menuLeft = side(_menuWidth);

    final ease = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final pop = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.15, 1, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInCubic,
    );
    final origin = mine ? Alignment.topRight : Alignment.topLeft;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // The chat, dimmed; a tap anywhere outside closes.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _close(context),
              child: FadeTransition(
                opacity: ease,
                child: const ColoredBox(color: Color(0x8C000000)),
              ),
            ),
          ),
          // The message, lifted and gliding to its place.
          AnimatedBuilder(
            animation: ease,
            builder: (context, child) => Positioned(
              left: bubbleRect.left,
              top: bubbleRect.top + (bubbleTop - bubbleRect.top) * ease.value,
              width: bubbleRect.width,
              child: child!,
            ),
            child: IgnorePointer(child: RepaintBoundary(child: bubble)),
          ),
          // The reactions, the emojis popping in one after another.
          Positioned(
            left: barLeft,
            top: barTop,
            width: barWidth,
            height: _barHeight,
            child: FadeTransition(
              opacity: ease,
              child: ScaleTransition(
                scale: Tween(begin: 0.6, end: 1.0).animate(pop),
                alignment: mine ? Alignment.bottomRight : Alignment.bottomLeft,
                child: Container(
                  padding: const EdgeInsets.all(_barPad),
                  decoration: BoxDecoration(
                    color: k.surface,
                    borderRadius: BorderRadius.circular(_barHeight / 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Row(
                      children: [
                        for (var i = 0; i < reactions.length; i++)
                          _EmojiButton(
                            emoji: reactions[i],
                            chosen: reactions[i] == myReaction,
                            animation: CurvedAnimation(
                              parent: animation,
                              curve: Interval(
                                (0.2 + i * 0.07).clamp(0, 0.8),
                                (0.55 + i * 0.07).clamp(0.4, 1),
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _close(context, () => onReact(reactions[i]));
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // The actions, opening from the message's corner.
          Positioned(
            left: menuLeft,
            top: menuTop,
            width: _menuWidth,
            child: FadeTransition(
              opacity: ease,
              child: ScaleTransition(
                scale: Tween(begin: 0.85, end: 1.0).animate(ease),
                alignment: origin,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: k.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (header != null) ...[
                        SizedBox(
                          height: _headerHeight - 6,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: header,
                            ),
                          ),
                        ),
                        Container(
                          height: 6,
                          color: k.bg.withValues(alpha: 0.5),
                        ),
                      ],
                      for (final a in actions)
                        InkWell(
                          onTap: () => _close(context, a.onTap),
                          child: SizedBox(
                            height: _rowHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    a.icon,
                                    size: 22,
                                    color: a.danger ? k.danger : k.ink,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    a.label,
                                    style: k.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: a.danger ? k.danger : k.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.chosen,
    required this.animation,
    required this.onTap,
  });

  final String emoji;
  final bool chosen;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ScaleTransition(
        scale: animation,
        child: Container(
          width: _MessageMenu._emoji,
          height: _MessageMenu._emoji,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: chosen ? KustTokens.gold.withValues(alpha: 0.25) : null,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}
