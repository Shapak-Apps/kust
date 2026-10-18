import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:Kust/core/storage/puzzle_progress_store.dart';
import 'package:Kust/features/game/chess/sound_service.dart';
import 'package:Kust/features/game/chess/board/board_geometry.dart';
import 'package:Kust/features/puzzles/puzzle_board.dart';
import 'package:Kust/features/puzzles/puzzle_data.dart';

const Duration _opponentDelay = Duration(milliseconds: 350);
const Duration _mistakeDelay = Duration(milliseconds: 700);
const Color _accentColor = Color(0xFFFFBB00);

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key, required this.level, required this.index});

  final int level;
  final int index;

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  PuzzleEntry? _puzzle;
  int _puzzleCount = 0;
  int _index = 0;

  final List<Position> _positions = [];
  final List<NormalMove?> _lastMoves = [];
  int _ply = 0;
  int _step = 0;
  int _mistakes = 0;
  int _hintLevel = 0;
  bool _busy = false;
  bool _solved = false;
  bool _mistakeFlash = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final level = await PuzzleRepository.instance.loadLevel(widget.level);
    if (!mounted || level.puzzles.isEmpty) return;

    final index = widget.index.clamp(0, level.puzzles.length - 1).toInt();
    final puzzle = level.puzzles[index];

    setState(() {
      _puzzle = puzzle;
      _puzzleCount = level.puzzles.length;
      _index = index;
      _positions
        ..clear()
        ..add(Chess.fromSetup(Setup.parseFen(puzzle.fen)));
      _lastMoves
        ..clear()
        ..add(null);
      _ply = 0;
    });
  }

  Position get _position => _positions[_ply];

  bool get _atTip => _ply == _positions.length - 1;

  Side get _startTurn => _positions.first.turn;

  NormalMove? get _expectedMove {
    final puzzle = _puzzle;
    if (puzzle == null || _step >= puzzle.moves.length) return null;
    return _parseUci(puzzle.moves[_step], _position);
  }

  NormalMove? _parseUci(String uci, Position position) {
    if (uci.length < 4) return null;
    final from = squareAt(uci.codeUnitAt(0) - 97, int.parse(uci[1]) - 1);
    var to = squareAt(uci.codeUnitAt(2) - 97, int.parse(uci[3]) - 1);

    if (position.board.pieceAt(from)?.role == Role.king) {
      if (from == Square.e1 && to == Square.g1) {
        to = Square.h1;
      } else if (from == Square.e1 && to == Square.c1) {
        to = Square.a1;
      } else if (from == Square.e8 && to == Square.g8) {
        to = Square.h8;
      } else if (from == Square.e8 && to == Square.c8) {
        to = Square.a8;
      }
    }

    return NormalMove(from: from, to: to, promotion: _roleFor(uci));
  }

  Role? _roleFor(String uci) {
    if (uci.length < 5) return null;
    switch (uci[4]) {
      case 'q':
        return Role.queen;
      case 'r':
        return Role.rook;
      case 'b':
        return Role.bishop;
      case 'n':
        return Role.knight;
    }
    return null;
  }

  bool _sameMove(NormalMove expected, NormalMove played) {
    if (expected.from != played.from || expected.to != played.to) return false;
    return expected.promotion == null || expected.promotion == played.promotion;
  }

  void _applyMove(NormalMove move) {
    final next = _position.play(move);
    _positions.removeRange(_ply + 1, _positions.length);
    _lastMoves.removeRange(_ply + 1, _lastMoves.length);
    _positions.add(next);
    _lastMoves.add(move);
    _ply = _positions.length - 1;
  }

  void _playMoveFeedback(Position before, NormalMove move, Position after, bool isUser) {
    final piece = before.board.pieceAt(move.from);
    final target = before.board.pieceAt(move.to);
    final isCastle =
        piece?.role == Role.king && target != null && target.color == piece?.color;
    final isCapture = target != null && !isCastle;
    final isCheck = after.isCheck;

    String sound;
    if (isCastle) {
      sound = 'castle.wav';
    } else if (move.promotion != null) {
      sound = 'promote.wav';
    } else if (isCapture) {
      sound = 'capture.wav';
    } else {
      sound = isUser ? 'move.wav' : 'move-opponent.wav';
    }

    SoundService.instance.playSfx(isCheck ? 'check.wav' : sound);

    if (isCapture || isCheck) {
      SoundService.instance.buzz(heavy: true);
    } else {
      SoundService.instance.buzz();
    }
  }

  void _onUserMove(NormalMove move) {
    final puzzle = _puzzle;
    if (puzzle == null || _busy || _solved) return;

    if (!_atTip) {
      setState(() => _ply = _positions.length - 1);
      return;
    }

    final expected = _expectedMove;
    if (expected == null || !_sameMove(expected, move)) {
      _onMistake(puzzle);
      return;
    }

    final before = _position;
    _playMoveFeedback(before, move, before.play(move), true);

    setState(() {
      _applyMove(move);
      _hintLevel = 0;
    });
    _step++;

    if (_step >= puzzle.moves.length) {
      _onSolved(puzzle);
      return;
    }

    _busy = true;
    _timer = Timer(_opponentDelay, () => _playOpponent(puzzle));
  }

  void _playOpponent(PuzzleEntry puzzle) {
    if (!mounted) return;
    final reply = _parseUci(puzzle.moves[_step], _position);
    if (reply == null) {
      setState(() => _busy = false);
      return;
    }

    final before = _position;
    _playMoveFeedback(before, reply, before.play(reply), false);

    setState(() {
      _applyMove(reply);
      _busy = false;
    });
    _step++;

    if (_step >= puzzle.moves.length) {
      _onSolved(puzzle);
    }
  }

  void _onMistake(PuzzleEntry puzzle) {
    _mistakes++;
    SoundService.instance.playSfx('illegal.wav');
    SoundService.instance.buzz(heavy: true);
    if (_mistakes == 1) {
      unawaited(PuzzleProgressStore.instance.recordMistake(puzzle));
    }

    setState(() {
      _mistakeFlash = true;
      _busy = true;
    });

    _timer = Timer(_mistakeDelay, () {
      if (!mounted) return;
      setState(() {
        _mistakeFlash = false;
        _busy = false;
      });
    });
  }

  void _onSolved(PuzzleEntry puzzle) {
    _busy = false;
    SoundService.instance.playJingle('game-win.wav');
    SoundService.instance.buzzMedium();
    if (mounted) setState(() => _solved = true);
    unawaited(
      PuzzleProgressStore.instance.recordSolved(
        puzzle,
        clean: _mistakes == 0,
      ),
    );
  }

  void _onHint() {
    if (_busy || _solved || !_atTip || _hintLevel >= 2) return;
    setState(() => _hintLevel++);
  }

  void _back() {
    if (_busy || _ply == 0) return;
    setState(() => _ply--);
  }

  void _forward() {
    if (_busy || _atTip) return;
    setState(() => _ply++);
  }

  String get _statusText {
    if (_solved) return 'Puzzle solved!';
    if (_mistakeFlash) return 'Not that one';
    return _position.turn == Side.white ? 'White to move' : 'Black to move';
  }

  void _exit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/puzzles');
    }
  }

  void _nextPuzzle(BuildContext context) {
    if (_index + 1 < _puzzleCount) {
      context.pushReplacement('/puzzle/${widget.level}/${_index + 1}');
    } else {
      _exit(context);
    }
  }

  void _showSettingsSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Puzzle settings coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    final hintFrom = _atTip && !_solved && _hintLevel >= 1
        ? _expectedMove?.from
        : null;
    final hintTo = _atTip && !_solved && _hintLevel >= 2
        ? _expectedMove?.to
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _exit(context),
        ),
        centerTitle: true,
        title: Text(
          'Puzzles #${widget.level}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _accentColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _showSettingsSoon(context),
          ),
        ],
      ),
      body: puzzle == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _StatusLine(
                      text: _statusText,
                      whiteToMove: _position.turn == Side.white,
                      highlight: _solved
                          ? const Color(0xFF3CB371)
                          : _mistakeFlash
                          ? Colors.redAccent
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: PuzzleBoard(
                          position: _position,
                          flipped: _startTurn == Side.black,
                          interactive: _atTip && !_busy && !_solved,
                          onMove: _onUserMove,
                          lastMove: _lastMoves[_ply],
                          hintFrom: hintFrom,
                          hintTo: hintTo,
                        ),
                      ),
                    ),
                  ),
                  if (_solved)
                    _SolvedBar(
                      hasNext: _index + 1 < _puzzleCount,
                      onNext: () => _nextPuzzle(context),
                    )
                  else
                    _ControlBar(
                      canHint: _atTip && !_busy && _hintLevel < 2,
                      canBack: _ply > 0 && !_busy,
                      canForward: !_atTip && !_busy,
                      onHint: _onHint,
                      onBack: _back,
                      onForward: _forward,
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.text,
    required this.whiteToMove,
    this.highlight,
  });

  final String text;
  final bool whiteToMove;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: whiteToMove ? Colors.white : Colors.black,
            border: Border.all(color: Colors.black54, width: 1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: highlight ?? scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.canHint,
    required this.canBack,
    required this.canForward,
    required this.onHint,
    required this.onBack,
    required this.onForward,
  });

  final bool canHint;
  final bool canBack;
  final bool canForward;
  final VoidCallback onHint;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          _ControlButton(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            enabled: canHint,
            onTap: onHint,
          ),
          _ControlButton(
            icon: Icons.arrow_back_ios_new_rounded,
            label: 'Back',
            enabled: canBack,
            onTap: onBack,
          ),
          _ControlButton(
            icon: Icons.arrow_forward_ios_rounded,
            label: 'Forward',
            enabled: canForward,
            onTap: onForward,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = enabled ? scheme.onSurface : scheme.outline;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolvedBar extends StatelessWidget {
  const _SolvedBar({required this.hasNext, required this.onNext});

  final bool hasNext;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFBB00),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            hasNext ? 'Next puzzle' : 'Back to puzzles',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
