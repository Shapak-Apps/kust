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

class ChessEngine {
  ChessEngine._();

  static final ChessEngine instance = ChessEngine._();

  Stockfish? _engine;
  StreamSubscription<String>? _stdoutSubscription;
  final List<void Function(String)> _listeners = [];

  bool _ready = false;
  Future<void>? _startFuture;

  Future<void> _chain = Future.value();

  int _lastSkill = 20;
  int? _lastUciElo;

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

  Future<void> _start() async {
    final dir = await getApplicationSupportDirectory();
    final bigPath = await _extractNnue(_nnueBig, dir.path);
    final smallPath = await _extractNnue(_nnueSmall, dir.path);

    Stockfish.setNnueDirectory(dir.path);
    _engine = await stockfishAsync();

    _stdoutSubscription = _engine!.stdout.listen((line) {
      for (final listener in List.of(_listeners)) {
        listener(line);
      }
    });

    _send('uci');
    await _waitForLine((line) => line == 'uciok');

    _send('setoption name EvalFile value $bigPath');
    _send('setoption name EvalFileSmall value $smallPath');
    _send('isready');
    await _waitForLine((line) => line == 'readyok');

    _ready = true;
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
    Duration thinkTime = const Duration(milliseconds: 350),
  }) {
    return _run(() => _evaluate(fen, thinkTime));
  }

  Future<EvalScore?> _evaluate(String fen, Duration thinkTime) async {
    if (!_ready) await start();

    String? lastScoreLine;
    void listener(String line) {
      if (line.startsWith('info ') && line.contains(' score ')) {
        lastScoreLine = line;
      }
    }

    _listeners.add(listener);
    _send('position fen $fen');
    _send('go movetime ${thinkTime.inMilliseconds}');
    try {
      await _waitForLine((line) => line.startsWith('bestmove '));
    } finally {
      _listeners.remove(listener);
    }

    if (lastScoreLine == null) return null;
    final match = RegExp(r'score (cp|mate) (-?\d+)').firstMatch(lastScoreLine!);
    if (match == null) return null;

    final value = int.parse(match.group(2)!);
    final whiteToMove = fen.split(' ')[1] == 'w';
    final whiteValue = whiteToMove ? value : -value;

    return match.group(1) == 'mate'
        ? EvalScore(mate: whiteValue)
        : EvalScore(cp: whiteValue);
  }

  Future<String> evaluateBestHint(String fen) {
    return _run(() async {
      final skill = _lastSkill;
      final elo = _lastUciElo;

      setSkillLevel(20);
      final move = await _search(fen, const Duration(milliseconds: 1500));
      setSkillLevel(skill, uciElo: elo);

      return move;
    });
  }

  void stopThinking() {
    if (!_ready) return;
    _send('stop');
  }

  void dispose() {
    _ready = false;
    _startFuture = null;
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
  return ChessEngine.instance;
});