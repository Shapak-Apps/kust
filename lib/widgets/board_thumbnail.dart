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
                  final key =
                      '${position.fen}|$flipped|${highlight.join(',')}|'
                      '${theme.name}|${set.name}|$px';
                  final ready = _drawn[key];
                  if (ready != null) {
                    return RawImage(image: ready, fit: BoxFit.cover);
                  }
                  final drawing = _drawing.putIfAbsent(
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
