import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'ffi.dart';
import 'stockfish_state.dart';

final _logger = Logger('Stockfish');

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

class Stockfish {
  final Completer<Stockfish>? completer;

  final _state = _StockfishState();
  final _stdoutController = StreamController<String>.broadcast();
  final _mainPort = ReceivePort();
  final _stdoutPort = ReceivePort();

  late StreamSubscription _mainSubscription;
  late StreamSubscription _stdoutSubscription;

  static String? _nnueDirectory;

  static void setNnueDirectory(String path) {
    _nnueDirectory = path;
  }

  Stockfish._({this.completer}) {
    _mainSubscription =
        _mainPort.listen((message) => _cleanUp(message is int ? message : 1));
    _stdoutSubscription = _stdoutPort.listen((message) {
      if (message is String) {
        _logger.finest('stdout: $message');
        _stdoutController.sink.add(message);
      }
    });
    _init();
  }

  Future<void> _init() async {
    String bigPath;
    String smallPath;

    try {
      final dir = _nnueDirectory ?? Directory.systemTemp.path;
      bigPath = await _extractNnue(_nnueBig, dir);
      smallPath = await _extractNnue(_nnueSmall, dir);
    } catch (e) {
      _logger.severe('Failed to extract NNUE files: $e');
      _cleanUp(1);
      return;
    }

    final success = await compute(
      _spawnIsolates,
      [_mainPort.sendPort, _stdoutPort.sendPort],
    );

    if (!success) {
      _logger.severe('Failed to spawn Stockfish isolates');
      _cleanUp(1);
      return;
    }

    for (final line in [
      'setoption name EvalFile value $bigPath',
      'setoption name EvalFileSmall value $smallPath',
      'isready',
    ]) {
      final pointer = '$line\n'.toNativeUtf8();
      nativeStdinWrite(pointer);
      calloc.free(pointer);
    }

    _stdoutController.stream
        .firstWhere((line) => line.trim() == 'readyok')
        .then((_) {
      _state._setValue(StockfishState.ready);
      completer?.complete(this);
    });
  }

  static Stockfish? _instance;

  factory Stockfish() {
    if (_instance != null) {
      throw StateError('Multiple instances are not supported, yet.');
    }
    _instance = Stockfish._();
    return _instance!;
  }

  ValueListenable<StockfishState> get state => _state;

  Stream<String> get stdout => _stdoutController.stream;

  set stdin(String line) {
    final stateValue = _state.value;
    if (stateValue != StockfishState.ready) {
      throw StateError('Stockfish is not ready ($stateValue)');
    }
    final pointer = '$line\n'.toNativeUtf8();
    nativeStdinWrite(pointer);
    calloc.free(pointer);
  }

  void dispose() {
    stdin = 'quit';
  }

  void _cleanUp(int exitCode) {
    _stdoutController.close();
    _mainSubscription.cancel();
    _stdoutSubscription.cancel();
    _state._setValue(
        exitCode == 0 ? StockfishState.disposed : StockfishState.error);
    _instance = null;
  }
}

Future<Stockfish> stockfishAsync() {
  if (Stockfish._instance != null) {
    return Future.error(StateError('Only one instance can be used at a time'));
  }
  final completer = Completer<Stockfish>();
  Stockfish._instance = Stockfish._(completer: completer);
  return completer.future;
}

class _StockfishState extends ChangeNotifier
    implements ValueListenable<StockfishState> {
  StockfishState _value = StockfishState.starting;

  @override
  StockfishState get value => _value;

  void _setValue(StockfishState v) {
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }
}

void _isolateMain(SendPort mainPort) {
  final exitCode = nativeMain();
  mainPort.send(exitCode);
}

void _isolateStdout(SendPort stdoutPort) {
  String previous = '';
  while (true) {
    final pointer = nativeStdoutRead();
    if (pointer.address == 0) return;
    final data = previous + pointer.toDartString();
    final lines = data.split('\n');
    previous = lines.removeLast();
    for (final line in lines) {
      stdoutPort.send(line);
    }
  }
}

Future<bool> _spawnIsolates(List<SendPort> mainAndStdout) async {
  final initResult = nativeInit();
  if (initResult != 0) {
    _logger.severe('initResult=$initResult');
    return false;
  }
  try {
    await Isolate.spawn(_isolateStdout, mainAndStdout[1]);
  } catch (e) {
    _logger.severe('Failed to spawn stdout isolate: $e');
    return false;
  }
  try {
    await Isolate.spawn(_isolateMain, mainAndStdout[0]);
  } catch (e) {
    _logger.severe('Failed to spawn main isolate: $e');
    return false;
  }
  return true;
}
