import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/features/history/pgn.dart';
import 'package:kust/features/puzzles/puzzle_board.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';

/// Positions reached by [uciMoves], starting from the initial position.
/// Stops at the first move that cannot be played, so a damaged record still
/// opens up to that point.
({List<Position> positions, List<NormalMove?> moves}) replayPositions(
  List<String> uciMoves,
) {
  final positions = <Position>[Chess.initial];
  final moves = <NormalMove?>[null];
  for (final uci in uciMoves) {
    final move = Move.parse(uci);
    final current = positions.last;
    if (move is! NormalMove || !current.isLegal(move)) break;
    positions.add(current.play(move));
    moves.add(move);
  }
  return (positions: positions, moves: moves);
}

class ReplayScreen extends StatefulWidget {
  const ReplayScreen({super.key, required this.gameId, this.record});

  final String gameId;

  /// Use this game instead of looking [gameId] up in the store (for tests).
  final GameRecord? record;

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  late final GameRecord? _game =
      widget.record ?? GameHistoryStore.instance.byId(widget.gameId);
  late final _replay = replayPositions(_game?.uciMoves ?? const []);
  final ScrollController _moveScroll = ScrollController();
  int _ply = 0;
  bool _playing = false;
  bool _fast = false;
  Timer? _timer;

  static const Duration _slowStep = Duration(milliseconds: 1000);
  static const Duration _fastStep = Duration(milliseconds: 450);

  int get _last => _replay.positions.length - 1;

  @override
  void dispose() {
    _timer?.cancel();
    _moveScroll.dispose();
    super.dispose();
  }

  void _go(int ply) {
    _stop();
    _show(ply);
  }

  void _show(int ply) {
    setState(() => _ply = ply.clamp(0, _last));
    _scrollToCurrent();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (_playing) setState(() => _playing = false);
  }

  /// Watch the game play out. Pressing play at the end starts over.
  void _togglePlay() {
    if (_playing) {
      _stop();
      return;
    }
    if (_last == 0) return;
    if (_ply >= _last) _show(0);
    setState(() => _playing = true);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(_fast ? _fastStep : _slowStep, (_) {
      if (_ply >= _last) {
        _stop();
        return;
      }
      _show(_ply + 1);
      if (_ply >= _last) _stop();
    });
  }

  void _toggleSpeed() {
    setState(() => _fast = !_fast);
    if (_playing) _schedule();
  }

  void _scrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_moveScroll.hasClients || _last == 0) return;
      final target = _moveScroll.position.maxScrollExtent * _ply / _last;
      _moveScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _copyPgn(GameRecord game) async {
    await Clipboard.setData(ClipboardData(text: buildPgn(game)));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('PGN copied')));
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
            title: game == null
                ? 'Game'
                : game.isLocal
                ? 'Pass & Play'
                : 'vs ${game.botName ?? 'Bot'}',
            subtitle: game == null
                ? null
                : '${describeResult(game)} · ${formatGameDate(game.date)}',
            leading: KustIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/history'),
            ),
            trailing: [
              if (game != null && game.sanMoves.isNotEmpty)
                KustIconButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy PGN',
                  onTap: () => _copyPgn(game),
                ),
            ],
          ),
          Expanded(
            child: game == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: k.muted,
                          ),
                          const SizedBox(height: 12),
                          Text('This game could not be found.', style: k.body),
                          const SizedBox(height: 20),
                          KustButton(
                            label: 'Back to history',
                            expand: false,
                            onTap: () => context.go('/history'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildReplay(context, game),
          ),
        ],
      ),
    );
  }

  Widget _buildReplay(BuildContext context, GameRecord game) {
    final k = context.k;
    final san = _ply == 0 || _ply > game.sanMoves.length
        ? 'Start position'
        : '${(_ply + 1) ~/ 2}${_ply.isOdd ? '.' : '...'} ${game.sanMoves[_ply - 1]}';

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PuzzleBoard(
                    position: _replay.positions[_ply],
                    flipped: !game.isLocal && !game.playerIsWhite,
                    interactive: false,
                    onMove: (_) {},
                    lastMove: _replay.moves[_ply],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              controller: _moveScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: game.sanMoves.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) => _MoveChip(
                label: i.isEven
                    ? '${i ~/ 2 + 1}. ${game.sanMoves[i]}'
                    : game.sanMoves[i],
                selected: _ply == i + 1,
                onTap: () => _go(i + 1),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(san, style: k.title),
          Text('Move $_ply of $_last', style: k.caption),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                KustIconButton(
                  icon: Icons.first_page_rounded,
                  label: 'First move',
                  size: 48,
                  onTap: _ply > 0 ? () => _go(0) : null,
                ),
                KustIconButton(
                  icon: Icons.chevron_left_rounded,
                  label: 'Previous move',
                  size: 48,
                  onTap: _ply > 0 ? () => _go(_ply - 1) : null,
                ),
                KustIconButton(
                  icon: _playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: _playing ? 'Pause' : 'Watch game',
                  size: 56,
                  filled: true,
                  onTap: _last == 0 ? null : _togglePlay,
                ),
                KustIconButton(
                  icon: Icons.chevron_right_rounded,
                  label: 'Next move',
                  size: 48,
                  onTap: _ply < _last ? () => _go(_ply + 1) : null,
                ),
                KustIconButton(
                  icon: Icons.last_page_rounded,
                  label: 'Last move',
                  size: 48,
                  onTap: _ply < _last ? () => _go(_last) : null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Pressable(
              onTap: _toggleSpeed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: k.surfaceAlt,
                  borderRadius: BorderRadius.circular(KustSpace.rSmall),
                ),
                child: Text(
                  _fast ? 'Speed 2x' : 'Speed 1x',
                  style: k.caption.copyWith(color: k.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveChip extends StatelessWidget {
  const _MoveChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? k.accent : k.surface,
          borderRadius: BorderRadius.circular(KustSpace.rSmall),
          border: Border.all(color: selected ? k.accent : k.line),
        ),
        child: Text(
          label,
          style: k.body.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? k.accentInk : k.ink,
          ),
        ),
      ),
    );
  }
}
