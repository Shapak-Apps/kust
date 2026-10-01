import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stockfish/stockfish.dart';

const _nnueBig = 'nn-c288c895ea92.nnue';
const _nnueSmall = 'nn-37f18f62d772.nnue';

Future<String> _extractNnue(String assetName, String dirPath) async {
  final file = File('$dirPath/$assetName');
  if (!await file.exists()) {
    final bytes = await rootBundle.load('assets/nnue/$assetName');
    await file.writeAsBytes(bytes.buffer.asUint8List());
  }
  return file.path;
}

class EvalScore {
  const EvalScore({this.cp, this.mate});

  final int? cp;

  final int? mate;

  double get whiteShare {
    if (mate != null) return mate! > 0 ? 1.0 : 0.0;
    final pawns = (cp ?? 0) / 100.0;
    return 1.0 / (1.0 + math.exp(-pawns / 3.0));
  }

  String get label {
    if (mate != null) {
      final n = mate!.abs();
      return mate! > 0 ? '+M$n' : '-M$n';
    }
    final pawns = (cp ?? 0) / 100.0;
    final s = pawns.toStringAsFixed(2);
    return pawns > 0 ? '+$s' : s;
  }
}

class MoveAnalysis {
  const MoveAnalysis({
    required this.bestUci,
    required this.bestCp,
    required this.playedCp,
  });

  final String bestUci;
  final int bestCp;
  final int playedCp;
}

class _Scored {
  const _Scored(this.uci, this.cp);

  final String uci;
  final int cp;
}

class ChessEngine {
  ChessEngine._();

  static final ChessEngine instance = ChessEngine._();

  static const int _mateCp = 100000;
  static final RegExp _scoreRe = RegExp(r'score (cp|mate) (-?\d+)');

  Stockfish? _engine;
  StreamSubscription<String>? _stdoutSubscription;
  final List<void Function(String)> _listeners = [];

  bool _ready = false;
  Future<void>? _startFuture;

  Future<void> _chain = Future.value();

  int _lastSkill = 20;
  int? _lastUciElo;
  String? _lastScoreLine;

  bool get isReady => _ready;

  Future<T> _run<T>(Future<T> Function() op) {
    final result = _chain.then((_) => op());
    _chain = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> start() {
    if (_ready) return Future.value();
    return _startFuture ??= _start();
  }

  void warmUp() {
    start().ignore();
  }

  Future<void> _start() async {
    final dir = await getApplicationSupportDirectory();
    final bigPath = await _extractNnue(_nnueBig, dir.path);
    final smallPath = await _extractNnue(_nnueSmall, dir.path);

    Stockfish.setNnueDirectory(dir.path);
    _engine = await stockfishAsync();

    _stdoutSubscription = _engine!.stdout.listen(_onLine);

    _send('uci');
    await _waitForLine((line) => line == 'uciok');

    _send('setoption name Threads value 2');
    _send('setoption name Hash value 32');
    _send('setoption name Move Overhead value 50');
    _send('setoption name EvalFile value $bigPath');
    _send('setoption name EvalFileSmall value $smallPath');
    _send('isready');
    await _waitForLine((line) => line == 'readyok');

    _ready = true;
  }

  void _onLine(String line) {
    if (line.startsWith('info ')) {
      if (line.contains(' score ') &&
          !line.contains(' lowerbound') &&
          !line.contains(' upperbound')) {
        _lastScoreLine = line;
      }
      return;
    }
    if (_listeners.isEmpty) return;
    for (final listener in List.of(_listeners)) {
      listener(line);
    }
  }

  void setSkillLevel(int level, {int? uciElo}) {
    _lastSkill = level;
    _lastUciElo = uciElo;

    final clampedLevel = level.clamp(0, 20);
    _send('setoption name Skill Level value $clampedLevel');

    if (uciElo != null) {
      _send('setoption name UCI_LimitStrength value true');
      _send('setoption name UCI_Elo value ${uciElo.clamp(1320, 3190)}');
    } else {
      _send('setoption name UCI_LimitStrength value false');
    }
  }

  Future<String> bestMoveForFen(
    String fen, {
    Duration thinkTime = const Duration(milliseconds: 700),
  }) {
    return _run(() => _search(fen, thinkTime));
  }

  Future<String> _search(String fen, Duration thinkTime) async {
    if (!_ready) await start();

    _send('position fen $fen');
    _send('go movetime ${thinkTime.inMilliseconds}');

    final line = await _waitForLine((line) => line.startsWith('bestmove '));
    return line.split(' ')[1];
  }

  Future<EvalScore?> evaluateFen(
    String fen, {
    Duration thinkTime = const Duration(milliseconds: 250),
    bool Function()? isStale,
  }) {
    return _run<EvalScore?>(() async {
      if (isStale != null && isStale()) return null;
      if (!_ready) await start();
      return _atFullStrength<EvalScore?>(() => _evaluate(fen, thinkTime));
    });
  }

  Future<EvalScore?> _evaluate(String fen, Duration thinkTime) async {
    _lastScoreLine = null;
    _send('position fen $fen');
    _send('go movetime ${thinkTime.inMilliseconds}');
    await _waitForLine((line) => line.startsWith('bestmove '));

    final score = _parseScore(_lastScoreLine);
    if (score == null) return null;

    final whiteToMove = fen.split(' ')[1] == 'w';
    final whiteValue = whiteToMove ? score.value : -score.value;

    return score.mate
        ? EvalScore(mate: whiteValue)
        : EvalScore(cp: whiteValue);
  }

  Future<String> evaluateBestHint(String fen) {
    return _run<String>(() async {
      if (!_ready) await start();
      return _atFullStrength<String>(
        () => _search(fen, const Duration(milliseconds: 1000)),
      );
    });
  }

  Future<MoveAnalysis?> analyzeMove({
    required String beforeFen,
    required String playedUci,
    required String afterFen,
    Duration thinkTime = const Duration(milliseconds: 450),
    bool Function()? isStale,
  }) {
    return _run<MoveAnalysis?>(() async {
      if (isStale != null && isStale()) return null;
      if (!_ready) await start();
      return _atFullStrength<MoveAnalysis?>(() async {
        final best = await _searchScored(beforeFen, thinkTime);
        if (best == null || best.uci == '(none)') return null;
        if (best.uci == playedUci) {
          return MoveAnalysis(
            bestUci: best.uci,
            bestCp: best.cp,
            playedCp: best.cp,
          );
        }
        if (isStale != null && isStale()) return null;
        final reply = await _searchScored(afterFen, thinkTime);
        if (reply == null) return null;
        return MoveAnalysis(
          bestUci: best.uci,
          bestCp: best.cp,
          playedCp: -reply.cp,
        );
      });
    });
  }

  Future<T> _atFullStrength<T>(Future<T> Function() op) async {
    final skill = _lastSkill;
    final elo = _lastUciElo;
    if (skill == 20 && elo == null) return op();
    setSkillLevel(20);
    try {
      return await op();
    } finally {
      setSkillLevel(skill, uciElo: elo);
    }
  }

  Future<_Scored?> _searchScored(String fen, Duration thinkTime) async {
    _lastScoreLine = null;
    _send('position fen $fen');
    _send('go movetime ${thinkTime.inMilliseconds}');

    final line = await _waitForLine((l) => l.startsWith('bestmove '));
    final parts = line.split(' ');
    final uci = parts.length > 1 ? parts[1] : '(none)';

    final score = _parseScore(_lastScoreLine);
    if (score == null) return null;

    final cp = score.mate
        ? (score.value > 0 ? _mateCp : -_mateCp)
        : score.value;
    return _Scored(uci, cp);
  }

  ({bool mate, int value})? _parseScore(String? line) {
    if (line == null) return null;
    final match = _scoreRe.firstMatch(line);
    if (match == null) return null;
    return (mate: match.group(1) == 'mate', value: int.parse(match.group(2)!));
  }

  void stopThinking() {
    if (!_ready) return;
    _send('stop');
  }

  void dispose() {
    _ready = false;
    _startFuture = null;
    _lastScoreLine = null;
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    _listeners.clear();
    _engine?.dispose();
    _engine = null;
  }

  void _send(String command) {
    final engine = _engine;
    if (engine == null) {
      throw StateError('ChessEngine.start() must be called first');
    }
    engine.stdin = command;
  }

  Future<String> _waitForLine(bool Function(String line) matcher) {
    final completer = Completer<String>();

    late void Function(String) listener;
    listener = (line) {
      if (matcher(line)) {
        _listeners.remove(listener);
        if (!completer.isCompleted) {
          completer.complete(line);
        }
      }
    };

    _listeners.add(listener);
    return completer.future;
  }
}

final chessEngineProvider = Provider<ChessEngine>((ref) {
  ref.keepAlive();
  return ChessEngine.instance;
});
