import 'dart:async';

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

  static final AudioContext _noFocusCtx = AudioContext(
    android: const AudioContextAndroid(
      audioFocus: AndroidAudioFocus.none,
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.sonification,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  final List<AudioPlayer> _pool = [];
  int _cursor = 0;
  static const int _poolSize = 5;

  AudioPlayer? _jinglePlayer;

  bool _warmedUp = false;
  Future<void>? _warmupFuture;

  Future<void> warmUp() {
    if (_warmedUp) return Future.value();
    return _warmupFuture ??= _doWarmUp();
  }

  Future<void> _doWarmUp() async {
    try {
      await AudioPlayer.global.setAudioContext(_noFocusCtx);
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer(playerId: 'kust_sfx_$i');
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(1.0);
        try {
          await p.setAudioContext(_noFocusCtx);
        } catch (_) {}
        _pool.add(p);
      }
      _jinglePlayer = AudioPlayer(playerId: 'kust_jingle');
      await _jinglePlayer!.setReleaseMode(ReleaseMode.stop);
      await _jinglePlayer!.setVolume(1.0);
      try {
        await _jinglePlayer!.setAudioContext(_noFocusCtx);
      } catch (_) {}
      final cache = AudioCache(prefix: 'assets/$_prefix');
      for (final name in _precache) {
        try {
          await cache.load(name);
        } catch (_) {}
      }
      _warmedUp = true;
    } catch (_) {}
  }

  Future<void> playSfx(String fileName) async {
    try {
      await warmUp();
      final player = _pool.isEmpty ? null : _pool[_cursor++ % _pool.length];
      if (player == null) return;
      unawaited(
        player.play(AssetSource('$_prefix$fileName'), ctx: _noFocusCtx),
      );
    } catch (_) {}
  }

  Future<void> playJingle(String fileName) async {
    try {
      await warmUp();
      final player = _jinglePlayer ??= AudioPlayer(playerId: 'kust_jingle');
      await player.stop();
      await Future.delayed(const Duration(milliseconds: 250));
      await player.play(AssetSource('$_prefix$fileName'), ctx: _noFocusCtx);
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
