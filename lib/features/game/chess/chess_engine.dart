import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockfish/stockfish.dart';

class ChessEngine {
  ChessEngine._();

  static final ChessEngine instance = ChessEngine._();

  Stockfish? _engine;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> start() async {
    if (_ready) return;

    _engine = await stockfishAsync();

    _send('uci');
    await _waitFor((line) => line == 'uciok');

    _send('isready');
    await _waitFor((line) => line == 'readyok');

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
    _send('position fen $fen');
    _send('go movetime ${thinkTime.inMilliseconds}');

    final line = await _waitFor((line) => line.startsWith('bestmove '));
    return line.split(' ')[1];
  }

  void stopThinking() {
    if (!_ready) return;
    _send('stop');
  }

  void dispose() {
    _ready = false;
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

  Future<String> _waitFor(bool Function(String line) matcher) {
    final engine = _engine;
    if (engine == null) {
      throw StateError('ChessEngine.start() must be called first');
    }
    return engine.stdout.firstWhere(matcher);
  }
}

final chessEngineProvider = Provider<ChessEngine>((ref) {
  return ChessEngine.instance;
});
