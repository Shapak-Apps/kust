import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'package:kust/core/error_log.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const _prefix = 'sounds/';
  static const List<String> _sounds = [
    'move.wav',
    'move-opponent.wav',
    'capture.wav',
    'check.wav',
    'castle.wav',
    'promote.wav',
    'illegal.wav',
    'tenseconds.wav',
    'game-start.wav',
    'game-end.wav',
    'game-win.wav',
    'game-draw.wav',
    'correct.wav',
  ];

  static final AudioContext _noFocusCtx = AudioContext(
    android: const AudioContextAndroid(
      audioFocus: AndroidAudioFocus.none,
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.sonification,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  final Map<String, AudioPlayer> _players = {};
  bool soundEnabled = true;
  bool hapticsEnabled = true;
  bool _warmedUp = false;
  Future<void>? _warmupFuture;

  Future<void> warmUp() {
    if (_warmedUp) return Future.value();
    return _warmupFuture ??= _doWarmUp();
  }

  Future<void> _doWarmUp() async {
    try {
      await AudioPlayer.global.setAudioContext(_noFocusCtx);
    } catch (_) {}
    await Future.wait(_sounds.map(_prepare));
    _warmedUp = true;
  }

  Future<void> _prepare(String name) async {
    try {
      // A fresh id each launch: after a hot restart the old players still
      // exist on the platform side under the old ids.
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1.0);
      try {
        await player.setAudioContext(_noFocusCtx);
      } catch (_) {}
      await player
          .setSource(AssetSource('$_prefix$name'))
          .timeout(const Duration(seconds: 5));
      _players[name] = player;
    } catch (e, st) {
      ErrorLog.record(e, st);
    }
  }

  Future<void> _play(String name) async {
    if (!soundEnabled) return;
    try {
      if (!_warmedUp) await warmUp();
      // One that failed to load gets another try, instead of staying silent.
      if (_players[name] == null) await _prepare(name);
      final player = _players[name];
      if (player == null) return;
      await player.stop();
      await player.resume();
    } catch (_) {}
  }

  Future<void> playSfx(String fileName) => _play(fileName);

  Future<void> playJingle(
    String fileName, {
    Duration delay = Duration.zero,
  }) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    await _play(fileName);
  }

  void buzz({bool heavy = false}) {
    if (!hapticsEnabled) return;
    try {
      if (heavy) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  void buzzMedium() {
    if (!hapticsEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _players.clear();
    _warmedUp = false;
    _warmupFuture = null;
  }
}
