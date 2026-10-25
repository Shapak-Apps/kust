import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stockfish/stockfish.dart';

import 'package:kust/features/game/chess/bot_policy.dart';
import 'package:kust/features/game/chess/nnue_store.dart';

const _nnueBig = 'nn-c288c895ea92.nnue';
const _nnueSmall = 'nn-37f18f62d772.nnue';

/// The engine cannot be used right now (unsupported platform, missing
/// network files, crashed or unresponsive process).
class EngineUnavailableException implements Exception {
  const EngineUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'EngineUnavailableException: $message';
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
    this.secondBestCp,
  });

  final String bestUci;
  final int bestCp;
  final int playedCp;
  final int? secondBestCp;
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
  static final RegExp _multiPvRe = RegExp(r' multipv (\d+)');
  static final RegExp _pvMoveRe = RegExp(r' pv (\S+)');

  /// Stockfish only ships native code for these platforms.
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// How long a command may stay unanswered beyond its own think time.
  static const Duration _responseGrace = Duration(seconds: 10);

  Stockfish? _engine;
  StreamSubscription<String>? _stdoutSubscription;
  final List<void Function(String)> _listeners = [];
  final List<Completer<String>> _waiters = [];

  bool _ready = false;

  /// Mirrors [isReady] so the UI can react to the engine starting up.
  static final ValueNotifier<bool> readyNotifier = ValueNotifier(false);
  Future<void>? _startFuture;

  Future<void> _chain = Future.value();

  int _lastSkill = 20;
  int? _lastUciElo;
  String? _lastScoreLine;
  final Map<int, String> _scoreLines = {};

  bool get isReady => _ready;

  Future<T> _run<T>(Future<T> Function() op) {
    final result = _chain.then((_) => op());
    _chain = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Starts the engine. A failed start is not cached, so calling again
  /// retries from scratch.
  Future<void> start() {
    if (_ready) return Future.value();
    return _startFuture ??= _start().catchError((Object error) {
      _teardown();
      throw error is EngineUnavailableException
          ? error
          : EngineUnavailableException('$error');
    });
  }

  void warmUp() {
    start().ignore();
  }

  Future<void> _start() async {
    if (!isSupported) {
      throw const EngineUnavailableException(
        'The engine is not available on this platform',
      );
    }

    final dir = await getApplicationSupportDirectory();
    final store = NnueStore();
    final String bigPath;
    final String smallPath;
    try {
      smallPath = await store.ensure(
        _nnueSmall,
        dir.path,
        progressFrom: 0,
        progressTo: 0.05,
      );
      bigPath = await store.ensure(
        _nnueBig,
        dir.path,
        progressFrom: 0.05,
        progressTo: 1,
      );
    } finally {
      NnueStore.progress.value = null;
    }

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
    readyNotifier.value = true;
  }

  void _onLine(String line) {
    if (line.startsWith('info ')) {
      if (line.contains(' score ') &&
          !line.contains(' lowerbound') &&
          !line.contains(' upperbound')) {
        final pvMatch = _multiPvRe.firstMatch(line);
        final pvIndex = pvMatch == null ? 1 : int.parse(pvMatch.group(1)!);
        _scoreLines[pvIndex] = line;
        if (pvIndex == 1) _lastScoreLine = line;
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

  /// The best [lines] moves of [fen] with their scores, from a search that
  /// stops at [depth] or [thinkTime], whichever comes first.
  Future<List<CandidateMove>> candidateMoves(
    String fen, {
    required int lines,
    required int depth,
    required Duration thinkTime,
  }) {
    return _run(() async {
      if (!_ready) await start();
      final top = await _searchTop(fen, thinkTime, lines, depth: depth);
      return [for (final line in top) CandidateMove(line.uci, line.cp)];
    });
  }

  Future<String> _search(String fen, Duration thinkTime) async {
    if (!_ready) await start();

    _send('position fen $fen');
    _send('go movetime ${thinkTime.inMilliseconds}');

    final line = await _waitForBestMove(thinkTime);
    final parts = line.split(' ');
    return parts.length > 1 ? parts[1] : '(none)';
  }

  /// Waits for `bestmove`. If the engine goes silent it is torn down so the
  /// next call starts a fresh process instead of hanging forever.
  Future<String> _waitForBestMove(Duration thinkTime) async {
    try {
      return await _waitForLine(
        (line) => line.startsWith('bestmove '),
        timeout: thinkTime + _responseGrace,
      );
    } on TimeoutException {
      _teardown();
      throw const EngineUnavailableException('The engine stopped responding');
    }
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
    await _waitForBestMove(thinkTime);

    final score = _parseScore(_lastScoreLine);
    if (score == null) return null;

    final whiteToMove = fen.split(' ')[1] == 'w';
    final whiteValue = whiteToMove ? score.value : -score.value;

    return score.mate ? EvalScore(mate: whiteValue) : EvalScore(cp: whiteValue);
  }

  Future<String> evaluateBestHint(String fen) {
    return _run<String>(() async {
      if (!_ready) await start();
      return _atFullStrength<String>(
        () => _search(fen, const Duration(milliseconds: 1000)),
      );
    });
  }

  /// How deep a move is rated at most. Deep enough to rate it right; on a
  /// fast phone the search ends here, well before its time is up.
  static const int analysisDepth = 12;

  /// Rates [playedUci] against the best move in [beforeFen].
  ///
  /// Both scores come from searches of the same position, from the same
  /// side's point of view: the best two moves first, then, if the played move
  /// was not one of them, that move alone (`searchmoves`). The second search
  /// starts from what the first one already found, so it is quick, and the
  /// two scores can be compared. [afterFen] is only a fallback.
  Future<MoveAnalysis?> analyzeMove({
    required String beforeFen,
    required String playedUci,
    required String afterFen,
    Duration thinkTime = const Duration(milliseconds: 400),
    int depth = analysisDepth,
    bool Function()? isStale,
  }) {
    return _run<MoveAnalysis?>(() async {
      if (isStale != null && isStale()) return null;
      if (!_ready) await start();
      return _atFullStrength<MoveAnalysis?>(() async {
        final top = await _searchTop(beforeFen, thinkTime, 2, depth: depth);
        if (top.isEmpty) return null;

        final best = top.first;
        final secondBestCp = top.length > 1 ? top[1].cp : null;

        final knownPlayedCp = _cpForUci(top, playedUci);
        final int playedCp;
        if (knownPlayedCp != null) {
          playedCp = knownPlayedCp;
        } else {
          if (isStale != null && isStale()) return null;
          final only = await _searchTop(
            beforeFen,
            thinkTime,
            1,
            depth: depth,
            searchMove: playedUci,
          );
          if (only.isNotEmpty && only.first.uci == playedUci) {
            playedCp = only.first.cp;
          } else {
            final reply = await _searchScored(afterFen, thinkTime);
            if (reply == null) return null;
            playedCp = -reply.cp;
          }
        }

        return MoveAnalysis(
          bestUci: best.uci,
          bestCp: best.cp,
          playedCp: playedCp,
          secondBestCp: secondBestCp,
        );
      });
    });
  }

  int? _cpForUci(List<_Scored> lines, String uci) {
    for (final line in lines) {
      if (line.uci == uci) return line.cp;
    }
    return null;
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
    final lines = await _searchTop(fen, thinkTime, 1);
    return lines.isEmpty ? null : lines.first;
  }

  /// The UCI `go` line for a search that stops at [thinkTime] or [depth],
  /// whichever comes first, limited to [searchMove] when given.
  @visibleForTesting
  static String goCommand(
    Duration thinkTime, {
    int? depth,
    String? searchMove,
  }) => [
    'go',
    if (depth != null) 'depth $depth',
    'movetime ${thinkTime.inMilliseconds}',
    // searchmoves takes the rest of the line, so it goes last.
    if (searchMove != null) 'searchmoves $searchMove',
  ].join(' ');

  /// The best [lines] moves of [fen] with their scores. The search stops at
  /// [thinkTime] or at [depth], whichever comes first; [searchMove] limits it
  /// to that one move.
  Future<List<_Scored>> _searchTop(
    String fen,
    Duration thinkTime,
    int lines, {
    int? depth,
    String? searchMove,
  }) async {
    _scoreLines.clear();
    _lastScoreLine = null;
    _send('setoption name MultiPV value $lines');
    _send('position fen $fen');
    _send(goCommand(thinkTime, depth: depth, searchMove: searchMove));

    final line = await _waitForBestMove(thinkTime);
    _send('setoption name MultiPV value 1');

    final parts = line.split(' ');
    if (parts.length < 2 || parts[1] == '(none)') return const [];

    final results = <_Scored>[];
    for (var index = 1; index <= lines; index++) {
      final info = _scoreLines[index];
      if (info == null) break;

      final score = _parseScore(info);
      final pvMatch = _pvMoveRe.firstMatch(info);
      if (score == null || pvMatch == null) break;

      final cp = score.mate
          ? (score.value > 0 ? _mateCp : -_mateCp)
          : score.value;
      results.add(_Scored(pvMatch.group(1)!, cp));
    }
    return results;
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

  void dispose() => _teardown();

  /// Drops the process and fails everything still waiting on it.
  void _teardown() {
    _ready = false;
    readyNotifier.value = false;
    _startFuture = null;
    _lastScoreLine = null;
    _scoreLines.clear();
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    _listeners.clear();
    for (final waiter in List.of(_waiters)) {
      if (!waiter.isCompleted) {
        waiter.completeError(
          const EngineUnavailableException('The engine was shut down'),
        );
      }
    }
    _waiters.clear();
    try {
      _engine?.dispose();
    } catch (_) {}
    _engine = null;
  }

  void _send(String command) {
    final engine = _engine;
    if (engine == null) {
      throw StateError('ChessEngine.start() must be called first');
    }
    engine.stdin = command;
  }

  Future<String> _waitForLine(
    bool Function(String line) matcher, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    final completer = Completer<String>();
    _waiters.add(completer);

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
    return completer.future
        .timeout(
          timeout,
          onTimeout: () {
            _listeners.remove(listener);
            throw TimeoutException('No response from the engine', timeout);
          },
        )
        .whenComplete(() => _waiters.remove(completer));
  }
}

final chessEngineProvider = Provider<ChessEngine>((ref) {
  ref.keepAlive();
  return ChessEngine.instance;
});
