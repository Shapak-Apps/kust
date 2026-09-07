import 'dart:async';
import 'dart:io';

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

class ChessEngine {
  ChessEngine._();

  static final ChessEngine instance = ChessEngine._();

  Stockfish? _engine;
  StreamSubscription<String>? _stdoutSubscription;
  final List<void Function(String)> _listeners = [];

  bool _ready = false;
  Future<void>? _startFuture;

  bool get isReady => _ready;

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

  void setSkillLevel(int level, {int? elo}) {
    final clampedLevel = level.clamp(0, 20);
    _send('setoption name Skill Level value $clampedLevel');

    if (elo != null) {
      _send('setoption name UCI_LimitStrength value true');
      _send('setoption name UCI_Elo value ${elo.clamp(1300, 3100)}');
    } else {
      _send('setoption name UCI_LimitStrength value false');
    }
  }

  Future<String> bestMoveForFen(
    String fen, {
    Duration thinkTime = const Duration(milliseconds: 700),
  }) async {
    if (!_ready) await start();

    _send('position fen $fen');
    _send('go movetime ${thinkTime.inMilliseconds}');

    final line = await _waitForLine((line) => line.startsWith('bestmove '));
    return line.split(' ')[1];
  }

  Future<String> evaluateBestHint(
    String fen, {
    required int currentSkill,
    required int currentElo,
  }) async {
    if (!_ready) await start();

    setSkillLevel(20);
    final move = await bestMoveForFen(
      fen,
      thinkTime: const Duration(milliseconds: 1500),
    );
    setSkillLevel(currentSkill, elo: currentElo);

    return move;
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
