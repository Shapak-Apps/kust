import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _prefix = 'sounds/';
  static const List<String> _precache = [
    'move.mp3',
    'move-opponent.mp3',
    'capture.mp3',
    'check.mp3',
    'castle.mp3',
    'promote.mp3',
    'illegal.mp3',
    'tenseconds.mp3',
    'game-start.mp3',
    'game-end.mp3',
    'game-win.mp3',
    'game-draw.mp3',
  ];

  final List<AudioPlayer> _pool = [];
  int _cursor = 0;
  static const int _poolSize = 4;

  AudioPlayer? _jinglePlayer;

  bool _warmedUp = false;
  Future<void>? _warmupFuture;
  int _playToken = 0;

  Future<void> warmUp() {
    if (_warmedUp) return Future.value();
    return _warmupFuture ??= _doWarmUp();
  }

  Future<void> _doWarmUp() async {
    try {
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer(playerId: 'kust_sfx_$i');
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(1.0);
        _pool.add(p);
      }
      _jinglePlayer = AudioPlayer(playerId: 'kust_jingle');
      await _jinglePlayer!.setReleaseMode(ReleaseMode.stop);
      await _jinglePlayer!.setVolume(1.0);
      for (final name in _precache) {
        try {
          await AudioCache(prefix: 'assets/$_prefix').load(name);
        } catch (_) {}
      }
      try {
        await _pool.first.setSource(AssetSource('$_prefix${_precache.first}'));
      } catch (_) {}
      _warmedUp = true;
    } catch (_) {
      // Audio must never crash the game.
    }
  }

  Future<void> playSfx(String fileName) async {
    final token = ++_playToken;
    try {
      await warmUp();
      if (token != _playToken && _isMoveLike(fileName)) return;
      final player = _pool.isEmpty ? null : _pool[_cursor++ % _pool.length];
      if (player == null) return;
      await player.play(AssetSource('$_prefix$fileName'));
    } catch (_) {}
  }

  Future<void> playJingle(String fileName) async {
    try {
      await warmUp();
      final player = _jinglePlayer ??= AudioPlayer(playerId: 'kust_jingle');
      await player.stop();
      await player.play(AssetSource('$_prefix$fileName'));
    } catch (_) {}
  }

  void buzz({bool heavy = false}) {
    try {
      if (heavy) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  bool _isMoveLike(String fileName) =>
      fileName == 'move.mp3' ||
      fileName == 'move-opponent.mp3' ||
      fileName == 'capture.mp3';

  Future<void> dispose() async {
    for (final p in _pool) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _pool.clear();
    try {
      await _jinglePlayer?.dispose();
    } catch (_) {}
    _jinglePlayer = null;
    _warmedUp = false;
    _warmupFuture = null;
  }
}
