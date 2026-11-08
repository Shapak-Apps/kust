import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/game_analyzer.dart';
import 'package:kust/features/game/chess/move_feedback.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/features/review/game_review.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// Finished reviews, kept while the app runs so reopening one is instant.
final Map<String, GameReviewData> _reviewCache = {};

Future<MoveAnalysis?> _engineAnalyze({
  required String beforeFen,
  required String playedUci,
  required String afterFen,
  required Duration thinkTime,
  bool Function()? isStale,
}) => ChessEngine.instance.analyzeMove(
  beforeFen: beforeFen,
  playedUci: playedUci,
  afterFen: afterFen,
  thinkTime: thinkTime,
  isStale: isStale,
);

/// What happened in a game: accuracy of both sides, who was winning when,
/// how many moves of each rating, and the few moves worth learning from.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.gameId,
    this.record,
    this.analyzer,
  });

  final String gameId;

  /// Use this game instead of looking [gameId] up (for tests).
  final GameRecord? record;

  /// Overrides the chess engine (for tests).
  final MoveAnalyzer? analyzer;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final GameRecord? _game =
      widget.record ?? GameHistoryStore.instance.byId(widget.gameId);

  GameReviewData? _data;
  int _percent = 0;
  bool _failed = false;
  bool _running = false;
  bool _disposed = false;

  bool get _canRate => widget.analyzer != null || ChessEngine.isSupported;

  @override
  void initState() {
    super.initState();
    _data = _reviewCache[widget.gameId];
    if (_data == null && _game != null && _canRate) _run();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _run() async {
    final game = _game;
    if (game == null || _running) return;
    setState(() {
      _running = true;
      _failed = false;
      _percent = 0;
    });
    try {
      final data = await reviewGame(
        game,
        analyze: widget.analyzer ?? _engineAnalyze,
        onProgress: (done, total) {
          if (_disposed) return;
          setState(() => _percent = (done * 100 / total).floor());
        },
        isStale: () => _disposed,
      );
      if (_disposed) return;
      if (data != null) _reviewCache[widget.gameId] = data;
      setState(() {
        _data = data;
        _failed = data == null;
        _running = false;
      });
    } catch (_) {
      if (_disposed) return;
      setState(() {
        _failed = true;
        _running = false;
      });
    }
  }

  void _openReplay([int ply = 0]) {
    final suffix = ply > 0 ? '?ply=$ply' : '';
    context.push('/history/${widget.gameId}$suffix');
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final game = _game;
    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          KustTopBar(
            title: context.t.reviewTitle,
            subtitle: game == null
                ? null
                : '${game.isLocal ? context.t.passAndPlay : context.t.vsBot(game.botName ?? 'Bot')}'
                      ' · ${describeResult(game, context.t)}',
            leading: KustIconButton(
              icon: Icons.arrow_back_rounded,
              label: context.t.back,
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/play'),
            ),
          ),
          Expanded(child: _body(context, game)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, GameRecord? game) {
    final k = context.k;
    if (game == null) return _Message(context.t.gameNotFound);
    if (!_canRate) return _Message(context.t.reviewNoEngine);
    final data = _data;
    if (data != null) {
      return _ReviewBody(game: game, data: data, onOpen: _openReplay);
    }
    if (_failed) {
      return _Message(
        game.uciMoves.length < 4
            ? context.t.reviewTooShort
            : context.t.reviewFailed,
        action: game.uciMoves.length < 4
            ? null
            : KustButton(label: context.t.retry, expand: false, onTap: _run),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _percent / 100,
                minHeight: 8,
                backgroundColor: k.line,
                color: k.accent,
              ),
            ),
            const SizedBox(height: 14),
            Text(context.t.reviewAnalyzing(_percent), style: k.body),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_rounded, size: 40, color: k.muted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: k.body.copyWith(color: k.muted),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.game,
    required this.data,
    required this.onOpen,
  });

  final GameRecord game;
  final GameReviewData data;
  final void Function([int ply]) onOpen;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final yourSide = game.playerIsWhite ? Side.white : Side.black;
    final names = {
      Side.white: game.isLocal
          ? t.whiteName
          : (game.playerIsWhite ? t.youName : game.botName ?? t.whiteName),
      Side.black: game.isLocal
          ? t.blackName
          : (game.playerIsWhite ? game.botName ?? t.blackName : t.youName),
    };
    // Against a bot your moves come first; in pass and play, White's.
    final first = game.isLocal || game.playerIsWhite ? Side.white : Side.black;
    final order = [first, first.opposite];
    final learn = game.isLocal
        ? [
            ...data.worst(Side.white, count: 2),
            ...data.worst(Side.black, count: 2),
          ]
        : data.worst(yourSide);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            for (final side in order) ...[
              if (side != order.first)
                Container(width: 1, height: 64, color: k.line),
              Expanded(
                child: _AccuracyCard(
                  name: names[side]!,
                  value: data.accuracy(side),
                  highlight: !game.isLocal && side == yourSide,
                ),
              ),
            ],
          ],
        ),
        Center(child: Text(t.reviewAccuracy, style: k.caption)),
        const SizedBox(height: 28),
        Text(t.reviewGraph, style: k.caption),
        const SizedBox(height: 10),
        _WinGraph(data: data, onTapPly: onOpen),
        const SizedBox(height: 28),
        _CountsCard(data: data, order: order, names: names),
        const SizedBox(height: 28),
        Text(t.reviewKeyTitle, style: k.title),
        const SizedBox(height: 4),
        if (learn.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: k.success, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(t.reviewNoBig, style: k.body)),
              ],
            ),
          )
        else
          for (var i = 0; i < learn.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: k.line),
            _KeyMoment(move: learn[i], onTap: () => onOpen(learn[i].ply)),
          ],
        const SizedBox(height: 28),
        KustButton(
          label: t.reviewOpenReplay,
          style: KustButtonStyle.green,
          onTap: () => onOpen(),
        ),
      ],
    );
  }
}

class _AccuracyCard extends StatelessWidget {
  const _AccuracyCard({
    required this.name,
    required this.value,
    required this.highlight,
  });

  final String name;
  final double? value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final v = value;
    final color = v == null
        ? k.muted
        : v >= 80
        ? k.success
        : v >= 55
        ? k.ink
        : k.danger;
    return Column(
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: k.caption.copyWith(
            color: highlight ? k.accent : k.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          v == null ? '–' : v.toStringAsFixed(1),
          style: k.display.copyWith(fontSize: 40, height: 1.05, color: color),
        ),
      ],
    );
  }
}

/// White's winning chance over the game: the light area is White's share.
/// Tapping it opens the replay at that move.
class _WinGraph extends StatelessWidget {
  const _WinGraph({required this.data, required this.onTapPly});

  final GameReviewData data;
  final void Function([int ply]) onTapPly;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          final n = data.moves.length;
          final ply = (d.localPosition.dx / box.maxWidth * n).round();
          onTapPly(ply.clamp(1, n));
        },
        child: SizedBox(
          height: 110,
          width: double.infinity,
          child: CustomPaint(
            painter: _WinGraphPainter(
              values: [50, for (final m in data.moves) m.whiteWin],
              errors: [
                for (final m in data.moves)
                  if (m.quality == MoveQuality.blunder ||
                      m.quality == MoveQuality.mistake)
                    (ply: m.ply, color: m.quality.color),
              ],
              dark: k.surfaceAlt,
              light: k.ink.withValues(alpha: 0.88),
              line: k.accent,
              mid: k.line,
            ),
          ),
        ),
      ),
    );
  }
}

class _WinGraphPainter extends CustomPainter {
  const _WinGraphPainter({
    required this.values,
    required this.errors,
    required this.dark,
    required this.light,
    required this.line,
    required this.mid,
  });

  final List<double> values;
  final List<({int ply, Color color})> errors;
  final Color dark;
  final Color light;
  final Color line;
  final Color mid;

  Offset _at(Size size, int i) => Offset(
    size.width * i / (values.length - 1).clamp(1, 1 << 30),
    size.height * (1 - values[i] / 100),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.save();
    canvas.clipRRect(box);
    canvas.drawRect(Offset.zero & size, Paint()..color = dark);

    final top = Path()..moveTo(0, size.height);
    for (var i = 0; i < values.length; i++) {
      final p = _at(size, i);
      top.lineTo(p.dx, p.dy);
    }
    top
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(top, Paint()..color = light);

    final stroke = Path()..moveTo(0, _at(size, 0).dy);
    for (var i = 1; i < values.length; i++) {
      final p = _at(size, i);
      stroke.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      stroke,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = mid
        ..strokeWidth = 1,
    );
    for (final e in errors) {
      if (e.ply >= values.length) continue;
      final p = _at(size, e.ply);
      canvas.drawCircle(p, 4, Paint()..color = e.color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WinGraphPainter old) =>
      old.values != values || old.light != light || old.dark != dark;
}

/// How many moves of each rating, for both sides.
class _CountsCard extends StatelessWidget {
  const _CountsCard({
    required this.data,
    required this.order,
    required this.names,
  });

  final GameReviewData data;
  final List<Side> order;
  final Map<Side, String> names;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final counts = {for (final s in order) s: data.counts(s)};
    final rows = [
      for (final q in MoveQuality.values)
        if (order.any((s) => (counts[s]![q] ?? 0) > 0)) q,
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(context.t.reviewMoves, style: k.caption)),
            for (final s in order)
              SizedBox(
                width: 76,
                child: Text(
                  names[s]!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: k.caption,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (final q in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                _QualityDot(quality: q, size: 31),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(q.label, style: k.body.copyWith(color: q.color)),
                ),
                for (final s in order)
                  SizedBox(
                    width: 76,
                    child: Text(
                      '${counts[s]![q] ?? 0}',
                      textAlign: TextAlign.center,
                      style: k.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: (counts[s]![q] ?? 0) == 0 ? k.muted : k.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The round badge of a rating, as on the board.
class _QualityDot extends StatelessWidget {
  const _QualityDot({required this.quality, required this.size});

  final MoveQuality quality;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: quality.color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        quality.asset,
        width: size * quality.iconScale * 1.3,
        height: size * quality.iconScale * 1.3,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}

class _KeyMoment extends StatelessWidget {
  const _KeyMoment({required this.move, required this.onTap});

  final ReviewedMove move;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _QualityDot(quality: move.quality, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t.reviewMoveNo(move.moveNumber)} · ${move.san}',
                    style: k.body.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    move.bestSan.isEmpty
                        ? move.quality.label
                        : '${move.quality.label} · ${t.reviewBestWas(move.bestSan)}',
                    style: k.caption.copyWith(color: move.quality.color),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: k.muted),
          ],
        ),
      ),
    );
  }
}
