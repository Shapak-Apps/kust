import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// Label for the move at [index] (0 is White's first move): White's moves
/// carry their move number, Black's do not.
String moveLabel(int index, String san) =>
    index.isEven ? '${index ~/ 2 + 1}. $san' : san;

/// One-line scrolling list of moves, shared by live games and replays.
///
/// The list starts at the left edge. The current move is highlighted in
/// gold; as play goes on the strip only starts to scroll once the current
/// move would pass the middle, and from then on keeps it centered.
class MoveStrip extends StatefulWidget {
  const MoveStrip({
    super.key,
    required this.labels,
    required this.selected,
    this.onTap,
    this.emptyText = 'No moves yet',
  });

  /// One label per move, see [moveLabel].
  final List<String> labels;

  /// The highlighted move as a 1-based ply (1 is White's first move), or 0
  /// for none.
  final int selected;

  /// Called with the ply of a tapped move. Moves are not tappable when null.
  final ValueChanged<int>? onTap;

  final String emptyText;

  static const double height = 36;

  @override
  State<MoveStrip> createState() => _MoveStripState();
}

class _MoveStripState extends State<MoveStrip> {
  final ScrollController _scroll = ScrollController();
  List<GlobalKey> _keys = const [];

  @override
  void initState() {
    super.initState();
    _syncKeys();
    _centerSelected(animate: false);
  }

  @override
  void didUpdateWidget(MoveStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (oldWidget.selected != widget.selected ||
        oldWidget.labels.length != widget.labels.length) {
      _centerSelected();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _syncKeys() {
    if (_keys.length == widget.labels.length) return;
    _keys = [
      for (var i = 0; i < widget.labels.length; i++)
        i < _keys.length ? _keys[i] : GlobalKey(),
    ];
  }

  /// Scrolls the selected move toward the middle. Scroll limits stop it at
  /// the start, so nothing moves until the move passes the center.
  void _centerSelected({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ply = widget.selected;
      if (!mounted || ply < 1 || ply > _keys.length) return;
      final box = _keys[ply - 1].currentContext?.findRenderObject();
      if (box == null || !_scroll.hasClients) return;
      final position = _scroll.position;
      // Offset that puts the move in the middle, held inside the scroll
      // limits so the start and end of the strip never overscroll.
      final offset = RenderAbstractViewport.of(box)
          .getOffsetToReveal(box, 0.5)
          .offset
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      if (animate) {
        _scroll.animateTo(
          offset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scroll.jumpTo(offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    if (widget.labels.isEmpty) {
      return SizedBox(
        width: double.infinity,
        height: MoveStrip.height,
        child: Center(child: Text(widget.emptyText, style: k.caption)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Pure gold is hard to read on the light background.
    final gold = isDark ? k.accent : const Color(0xFFD99B00);

    // Always the full width, so the moves start at the left edge even in a
    // column that centers its children.
    return SizedBox(
      width: double.infinity,
      height: MoveStrip.height,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            for (var i = 0; i < widget.labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              KeyedSubtree(
                key: _keys[i],
                child: _MoveText(
                  label: widget.labels[i],
                  selected: widget.selected == i + 1,
                  color: widget.selected == i + 1 ? gold : k.muted,
                  onTap: widget.onTap == null
                      ? null
                      : () => widget.onTap!(i + 1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoveText extends StatelessWidget {
  const _MoveText({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Center(
      child: Text(
        label,
        style: context.k.body.copyWith(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: color,
        ),
      ),
    );
    if (onTap == null) return text;
    return Pressable(onTap: onTap, scale: 0.95, child: text);
  }
}
