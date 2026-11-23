import 'dart:ui' as ui;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/core/board_theme.dart';
import 'package:kust/core/piece_set.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/features/game/game_export.dart';

/// A small board drawn once into an image and kept, for lists that scroll:
/// one picture to paint instead of 64 squares and their pieces each frame.
/// In the colours and pieces from settings.
class BoardThumbnail extends StatelessWidget {
  const BoardThumbnail({
    super.key,
    required this.position,
    this.flipped = false,
    this.highlight = const [],
    this.radius = 6,
  });

  final Position position;
  final bool flipped;
  final List<Square> highlight;
  final double radius;

  static final Map<String, ui.Image> _drawn = {};
  static final Map<String, Future<ui.Image>> _drawing = {};

  static String _key(
    Position position,
    bool flipped,
    List<Square> highlight,
    int px,
  ) {
    final s = AppSettings.instance;
    return '${position.fen}|$flipped|${highlight.join(',')}|'
        '${s.boardTheme.value.name}|${s.pieceSet.value.name}|$px';
  }

  static Future<ui.Image> _draw(
    Position position,
    bool flipped,
    List<Square> highlight,
    int px,
  ) {
    final key = _key(position, flipped, highlight, px);
    final ready = _drawn[key];
    if (ready != null) return Future.value(ready);
    return _drawing.putIfAbsent(
      key,
      () =>
          boardImage(
            position,
            flipped: flipped,
            highlight: highlight,
            size: px,
            labels: false,
          ).then((image) {
            _drawn[key] = image;
            _drawing.remove(key);
            return image;
          }),
    );
  }

  /// Draws the board a [BoardThumbnail] [width] wide will show, ahead of
  /// time, so it appears at once (e.g. while the splash plays).
  static Future<void> warm(
    Position position, {
    required double width,
    bool flipped = false,
    List<Square> highlight = const [],
  }) {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final dpr = views.isEmpty ? 3.0 : views.first.devicePixelRatio;
    final px = (width * dpr).round().clamp(64, 1024);
    return _draw(position, flipped, highlight, px);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: ValueListenableBuilder<BoardTheme>(
            valueListenable: s.boardTheme,
            builder: (context, theme, _) => ValueListenableBuilder<PieceSet>(
              valueListenable: s.pieceSet,
              builder: (context, set, _) => LayoutBuilder(
                builder: (context, box) {
                  final px = (box.maxWidth * dpr).round().clamp(64, 1024);
                  final key = _key(position, flipped, highlight, px);
                  final ready = _drawn[key];
                  if (ready != null) {
                    return RawImage(image: ready, fit: BoxFit.cover);
                  }
                  final drawing = _draw(position, flipped, highlight, px);
                  return FutureBuilder<ui.Image>(
                    future: drawing,
                    builder: (context, snap) => snap.data == null
                        ? ColoredBox(color: theme.dark)
                        : RawImage(image: snap.data, fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
