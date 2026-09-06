import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockfish/stockfish.dart';

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
    _engine = await stockfishAsync();

    _stdoutSubscription = _engine!.stdout.listen((line) {
      for (final listener in List.of(_listeners)) {
        listener(line);
      }
    });

    _send('uci');
    await _waitForLine((line) => line == 'uciok');

    _send('isready');
    await _waitForLine((line) => line == 'readyok');

    _ready = true;
  }

  void setSkillLevel(int level) {
    final clamped = level.clamp(0, 20);
    _send('setoption name Skill Level value $clamped');
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
