import 'dart:ui' as ui;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import 'package:kust/core/settings.dart';
import 'package:kust/features/game/chess/board/board_geometry.dart';
import 'package:kust/features/game/chess/board/chess_board.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/chess_helpers.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';

/// The PGN of a game in progress or just finished, with `*` as the result
/// while it is still going.
String livePgn(GameState g, {DateTime? date}) {
  final day = date ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final isLocal = g.mode == GameMode.local;
  final bot = g.bot?.name ?? 'Bot';
  final playerWhite = g.playerSide == Side.white;
  final white = isLocal ? 'White' : (playerWhite ? 'Player' : bot);
  final black = isLocal ? 'Black' : (playerWhite ? bot : 'Player');
  final result = gameResultToken(g);

  final headers = <String, String>{
    'Event': isLocal ? 'Pass and play' : 'Game against bot',
    'Site': 'Küşt',
    'Date': '${day.year}.${two(day.month)}.${two(day.day)}',
    'White': white,
    'Black': black,
    'Result': result,
    if (!isLocal && g.bot != null)
      (playerWhite ? 'BlackElo' : 'WhiteElo'): '${g.bot!.elo}',
  };
  final moves = StringBuffer();
  for (var i = 0; i < g.moves.length; i++) {
    if (i.isEven) moves.write('${i ~/ 2 + 1}. ');
    moves.write('${g.moves[i].san} ');
  }
  moves.write(result);
  final head = headers.entries.map(
    (e) =>
        '[${e.key} "${e.value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"]',
  );
  return '${head.join('\n')}\n\n$moves\n';
}

/// `1-0`, `0-1`, `1/2-1/2`, or `*` for a game still going.
String gameResultToken(GameState g) {
  Side? winner;
  switch (g.status) {
    case GameStatus.checkmate:
      winner = g.position.turn.opposite;
    case GameStatus.draw:
      return '1/2-1/2';
    case GameStatus.resigned:
      winner = g.playerSide.opposite;
    case GameStatus.timeout:
      final text = g.endReason ?? '';
      if (g.mode == GameMode.local) {
        winner = text.startsWith('White') ? Side.white : Side.black;
      } else {
        winner = text.startsWith('You') ? g.playerSide : g.playerSide.opposite;
      }
    case GameStatus.loading:
    case GameStatus.playing:
      return '*';
  }
  return winner == Side.white ? '1-0' : '0-1';
}

/// Draws [position] as a PNG, [size] pixels square, in the board colours
/// and piece set picked in settings, seen from black when [flipped].
Future<Uint8List> boardPng(
  Position position, {
  bool flipped = false,
  List<Square> highlight = const [],
  int size = 1024,
}) async {
  final square = size / 8;
  final theme = AppSettings.instance.boardTheme.value;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..isAntiAlias = false;

  Offset originOf(Square s) {
    final col = flipped ? 7 - fileOf(s) : fileOf(s);
    final row = flipped ? rankOf(s) : 7 - rankOf(s);
    return Offset(col * square, row * square);
  }

  for (final s in Square.values) {
    final light = (fileOf(s) + rankOf(s)).isOdd;
    var colour = light ? theme.light : theme.dark;
    if (highlight.contains(s)) {
      colour = Color.alphaBlend(kLastMoveHighlight, colour);
    }
    paint.color = colour;
    canvas.drawRect(originOf(s) & Size(square, square), paint);
  }

  // File letters along the bottom row, rank numbers down the left column,
  // each in the colour of the other kind of square, as on the board.
  Color labelOn(int file, int rank) =>
      (file + rank).isOdd ? theme.dark : theme.light;
  final bottomRank = flipped ? 7 : 0;
  final leftFile = flipped ? 7 : 0;
  for (var i = 0; i < 8; i++) {
    final file = flipped ? 7 - i : i;
    final rank = flipped ? i : 7 - i;
    _label(
      canvas,
      String.fromCharCode(97 + file),
      Offset((i + 1) * square - square * 0.06, size - square * 0.04),
      square,
      labelOn(file, bottomRank),
      alignRight: true,
    );
    _label(
      canvas,
      '${rank + 1}',
      Offset(square * 0.05, i * square + square * 0.03),
      square,
      labelOn(leftFile, rank),
    );
  }

  final inset = square * 0.02;
  for (final s in Square.values) {
    final piece = position.board.pieceAt(s);
    if (piece == null) continue;
    final rect = (originOf(s) & Size(square, square)).deflate(inset);
    await _drawPiece(canvas, assetForPiece(piece), rect);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

void _label(
  Canvas canvas,
  String text,
  Offset at,
  double square,
  Color colour, {
  bool alignRight = false,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: square * 0.16,
        fontWeight: FontWeight.w700,
        color: colour,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = alignRight ? at.dx - painter.width : at.dx;
  final dy = alignRight ? at.dy - painter.height : at.dy;
  painter.paint(canvas, Offset(dx, dy));
  painter.dispose();
}

Future<void> _drawPiece(Canvas canvas, String asset, Rect rect) async {
  if (asset.endsWith('.svg')) {
    final info = await vg.loadPicture(SvgAssetLoader(asset), null);
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width / info.size.width, rect.height / info.size.height);
    canvas.drawPicture(info.picture);
    canvas.restore();
    info.picture.dispose();
    return;
  }
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: rect.width.round(),
  );
  final image = (await codec.getNextFrame()).image;
  canvas.drawImageRect(
    image,
    Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
    rect,
    Paint()..filterQuality = FilterQuality.medium,
  );
  image.dispose();
  codec.dispose();
}

/// The export choices for one game: share the board as an image, or copy
/// its FEN or PGN.
Future<void> showExportSheet(
  BuildContext context, {
  required Position position,
  required bool flipped,
  required String pgn,
  List<Square> highlight = const [],
}) {
  return showKustSheet<void>(
    context,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KustSheetHeader(title: 'Export game'),
        KustOption(
          title: 'Board image',
          subtitle: 'Share the position as a PNG',
          leading: const KustIconTile(Icons.image_outlined),
          onTap: () async {
            Navigator.pop(sheetContext);
            final png = await boardPng(
              position,
              flipped: flipped,
              highlight: highlight,
            );
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile.fromData(png, mimeType: 'image/png')],
                fileNameOverrides: const ['kust-position.png'],
                text: position.fen,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        KustOption(
          title: 'Copy FEN',
          subtitle: 'This position, for any chess app',
          leading: const KustIconTile(Icons.grid_on_rounded),
          onTap: () => _copy(sheetContext, position.fen, 'FEN copied'),
        ),
        const SizedBox(height: 8),
        KustOption(
          title: 'Copy PGN',
          subtitle: 'Every move of the game',
          leading: const KustIconTile(Icons.notes_rounded),
          onTap: () => _copy(sheetContext, pgn, 'PGN copied'),
        ),
        const SizedBox(height: 8),
        KustOption(
          title: 'Share PGN',
          subtitle: 'Send the game to another app',
          leading: const KustIconTile(Icons.ios_share_rounded),
          onTap: () {
            Navigator.pop(sheetContext);
            SharePlus.instance.share(ShareParams(text: pgn));
          },
        ),
      ],
    ),
  );
}

Future<void> _copy(BuildContext context, String text, String done) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  Navigator.pop(context);
  await Clipboard.setData(ClipboardData(text: text));
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(done)));
}
