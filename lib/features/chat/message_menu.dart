import 'dart:async';
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
/// it (gliding to where everything fits), a bar of reactions unrolls from
/// the message's side with its emojis popping in one after another, and a
/// compact card of actions opens downward like a curtain.
///
/// It is a layer over the screen, not a new page, so the keyboard stays
/// open while it shows. Only clip, opacity, scale and position animate, from
/// one controller, with no blur: cheap enough for 60 fps.
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
  double belowBubble = 0,
}) {
  HapticFeedback.mediumImpact();
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _MessageMenu(
      bubbleRect: bubbleRect,
      bubble: bubble,
      mine: mine,
      reactions: reactions,
      myReaction: myReaction,
      onReact: onReact,
      actions: actions,
      header: header,
      belowBubble: belowBubble,
      onClosed: () {
        entry.remove();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return done.future;
}

class _MessageMenu extends StatefulWidget {
  const _MessageMenu({
    required this.bubbleRect,
    required this.bubble,
    required this.mine,
    required this.reactions,
    required this.myReaction,
    required this.onReact,
    required this.actions,
    required this.onClosed,
    required this.belowBubble,
    this.header,
  });

  final Rect bubbleRect;
  final Widget bubble;
  final bool mine;
  final List<String> reactions;
  final String? myReaction;
  final ValueChanged<String> onReact;
  final List<MessageMenuAction> actions;
  final Widget? header;

  /// What hangs under the bubble (its reactions), kept clear by the card.
  final double belowBubble;
  final VoidCallback onClosed;

  @override
  State<_MessageMenu> createState() => _MessageMenuState();
}

class _MessageMenuState extends State<_MessageMenu>
    with SingleTickerProviderStateMixin {
  static const double _margin = 8;
  static const double _gap = 8;
  static const double _emoji = 42;
  static const double _barPad = 5;
  static const double _barHeight = _emoji + _barPad * 2;
  static const double _menuWidth = 200;
  static const double _rowHeight = 44;
  static const double _headerHeight = 38;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 150),
  )..forward();
  bool _closing = false;

  Future<void> _close([VoidCallback? then]) async {
    if (_closing) return;
    _closing = true;
    await _c.reverse();
    widget.onClosed();
    then?.call();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _part(double from, double to, Curve curve) =>
      CurvedAnimation(
        parent: _c,
        curve: Interval(from, to, curve: curve),
        reverseCurve: Curves.easeInCubic,
      );

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final media = MediaQuery.of(context);
    final size = media.size;
    final mine = widget.mine;
    final rect = widget.bubbleRect;

    // The room there is: below the status bar, above the gesture bar or the
    // keyboard (which stays open), with a margin all round.
    final top = media.padding.top + _margin;
    final bottom =
        size.height -
        math.max(media.padding.bottom, media.viewInsets.bottom) -
        _margin;
    final menuHeight =
        (widget.header == null ? 0 : _headerHeight) +
        widget.actions.length * _rowHeight +
        8;
    final barWidth = math.min(
      size.width - _margin * 2,
      widget.reactions.length * _emoji + _barPad * 2,
    );

    // As on Telegram the message doesn't move: it is only raised above
    // the dim. The bar sits just over it (or under, near the top), and the
    // card opens beside it on the free side, growing up from it when it is
    // low on the screen and down when it is high. A message too wide to
    // leave room beside gets the card under it (or over the bar).
    final below = rect.bottom + widget.belowBubble;
    final barAbove = rect.top - _gap - _barHeight >= top;
    final barTop = (barAbove ? rect.top - _gap - _barHeight : below + _gap)
        .clamp(top, bottom - _barHeight);
    double side(double width) => mine
        ? (rect.right - width).clamp(_margin, size.width - width - _margin)
        : rect.left.clamp(_margin, size.width - width - _margin);
    final barLeft = side(barWidth);

    final room = mine ? rect.left - _margin : size.width - rect.right - _margin;
    final beside = room >= _menuWidth + _gap;
    final low = rect.center.dy > (top + bottom) / 2;
    final double menuLeft;
    final double menuTop;
    final Alignment opensFrom;
    if (beside) {
      menuLeft = mine ? rect.left - _gap - _menuWidth : rect.right + _gap;
      menuTop = (low ? below - menuHeight : rect.top).clamp(
        top,
        bottom - menuHeight,
      );
      opensFrom = mine
          ? (low ? Alignment.bottomRight : Alignment.topRight)
          : (low ? Alignment.bottomLeft : Alignment.topLeft);
    } else {
      menuLeft = side(_menuWidth);
      final under = (barAbove ? below : barTop + _barHeight) + _gap;
      final over = (barAbove ? barTop : rect.top) - _gap - menuHeight;
      menuTop = (under + menuHeight <= bottom ? under : over).clamp(
        top,
        bottom - menuHeight,
      );
      final down = menuTop >= rect.top;
      opensFrom = mine
          ? (down ? Alignment.topRight : Alignment.bottomRight)
          : (down ? Alignment.topLeft : Alignment.bottomLeft);
    }
    final from = mine ? Alignment.centerRight : Alignment.centerLeft;

    final fade = _part(0, 0.6, Curves.easeOut);
    final unroll = _part(0.05, 0.75, Curves.easeOutCubic);
    final open = _part(0.1, 1, Curves.easeOutBack);

    final layer = Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // The chat, dimmed; a tap anywhere outside closes.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: FadeTransition(
                opacity: fade,
                child: const ColoredBox(color: Color(0x80000000)),
              ),
            ),
          ),
          // The message, where it is, raised above the dim.
          Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            child: IgnorePointer(child: RepaintBoundary(child: widget.bubble)),
          ),
          // The reactions: the bar unrolls from the message's side and the
          // emojis pop in one after another, like a ripple.
          Positioned(
            left: barLeft,
            top: barTop,
            width: barWidth,
            height: _barHeight,
            child: FadeTransition(
              opacity: fade,
              child: AnimatedBuilder(
                animation: unroll,
                builder: (context, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(_barHeight / 2),
                  child: Align(
                    alignment: from,
                    widthFactor: 0.35 + 0.65 * unroll.value,
                    child: child,
                  ),
                ),
                child: Container(
                  width: barWidth,
                  padding: const EdgeInsets.all(_barPad),
                  decoration: BoxDecoration(
                    color: k.surface,
                    borderRadius: BorderRadius.circular(_barHeight / 2),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    reverse: mine,
                    child: Row(
                      children: [
                        for (var i = 0; i < widget.reactions.length; i++)
                          _EmojiButton(
                            emoji: widget.reactions[i],
                            chosen: widget.reactions[i] == widget.myReaction,
                            animation: _part(
                              (0.12 + i * 0.06).clamp(0, 0.7),
                              (0.5 + i * 0.06).clamp(0.4, 1),
                              Curves.easeOutBack,
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              final e = widget.reactions[i];
                              _close(() => widget.onReact(e));
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // The actions: a compact card opening downward like a curtain
          // from under the message.
          Positioned(
            left: menuLeft,
            top: menuTop,
            width: _menuWidth,
            child: FadeTransition(
              opacity: fade,
              // Grows out of the corner nearest the message.
              child: ScaleTransition(
                scale: Tween(begin: 0.5, end: 1.0).animate(open),
                alignment: opensFrom,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: k.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.header != null) ...[
                        SizedBox(
                          height: _headerHeight - 6,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: widget.header,
                            ),
                          ),
                        ),
                        Container(
                          height: 6,
                          color: k.bg.withValues(alpha: 0.55),
                        ),
                      ],
                      for (final a in widget.actions)
                        InkWell(
                          onTap: () => _close(a.onTap),
                          child: SizedBox(
                            height: _rowHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    a.icon,
                                    size: 20,
                                    color: a.danger ? k.danger : k.ink,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    a.label,
                                    style: k.body.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
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
    // The phone's back closes the menu (when the app has a router).
    if (Router.maybeOf(context) == null) return layer;
    return BackButtonListener(
      onBackButtonPressed: () async {
        unawaited(_close());
        return true;
      },
      child: layer,
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
          width: _MessageMenuState._emoji,
          height: _MessageMenuState._emoji,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: chosen ? KustTokens.gold.withValues(alpha: 0.25) : null,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 25)),
        ),
      ),
    );
  }
}
