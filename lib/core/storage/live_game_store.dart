import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/storage/app_storage.dart';

/// A game that was still being played, kept so it can be picked up again
/// after the app was closed or killed.
@immutable
class LiveGame {
  const LiveGame({
    required this.isLocal,
    required this.playerIsWhite,
    required this.practice,
    required this.uciMoves,
    required this.savedAt,
    this.botId,
    this.baseMinutes,
    this.incrementSeconds = 0,
    this.whiteMs = 0,
    this.blackMs = 0,
  });

  final bool isLocal;
  final String? botId;
  final bool playerIsWhite;
  final bool practice;
  final List<String> uciMoves;
  final int savedAt;

  /// The clock the game started with, if any.
  final int? baseMinutes;
  final int incrementSeconds;

  /// Time left on each clock, in milliseconds.
  final int whiteMs;
  final int blackMs;

  Map<String, dynamic> toMap() => {
    'v': 1,
    'local': isLocal,
    'bot': botId,
    'white': playerIsWhite,
    'practice': practice,
    'moves': uciMoves,
    'at': savedAt,
    'base': baseMinutes,
    'inc': incrementSeconds,
    'wms': whiteMs,
    'bms': blackMs,
  };

  /// Null when [raw] is not a game this version understands.
  static LiveGame? tryFromMap(Object? raw) {
    if (raw is! Map) return null;
    try {
      final moves = raw['moves'];
      if (raw['v'] != 1 || moves is! List) return null;
      return LiveGame(
        isLocal: raw['local'] == true,
        botId: raw['bot'] as String?,
        playerIsWhite: raw['white'] != false,
        practice: raw['practice'] == true,
        uciMoves: [for (final m in moves) m as String],
        savedAt: raw['at'] as int,
        baseMinutes: raw['base'] as int?,
        incrementSeconds: (raw['inc'] as int?) ?? 0,
        whiteMs: (raw['wms'] as int?) ?? 0,
        blackMs: (raw['bms'] as int?) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The one game in progress, if any.
class LiveGameStore {
  LiveGameStore._() : _boxOverride = null;

  @visibleForTesting
  LiveGameStore.withBox(Box<dynamic> box) : _boxOverride = box;

  static final LiveGameStore instance = LiveGameStore._();

  /// Off in tests that play moves on a fake clock: a save started there
  /// never finishes, and would keep the box from closing.
  @visibleForTesting
  static bool enabled = true;

  static const String _key = 'live_game';

  /// Older games are not offered any more.
  static const Duration maxAge = Duration(days: 7);

  final Box<dynamic>? _boxOverride;

  Box<dynamic>? get _box {
    if (_boxOverride != null) return _boxOverride;
    return Hive.isBoxOpen(AppStorage.userBoxName)
        ? Hive.box(AppStorage.userBoxName)
        : null;
  }

  ValueListenable<Box<dynamic>>? listenable() => _box?.listenable(keys: [_key]);

  /// The game to continue, or null: none saved, too old, or unreadable.
  LiveGame? get({DateTime? now}) {
    final game = LiveGame.tryFromMap(_box?.get(_key));
    if (game == null) return null;
    final age = (now ?? DateTime.now()).millisecondsSinceEpoch - game.savedAt;
    return age > maxAge.inMilliseconds ? null : game;
  }

  Future<void> save(LiveGame game) async {
    if (enabled) await _box?.put(_key, game.toMap());
  }

  Future<void> clear() async {
    final box = _box;
    if (enabled && box != null && box.containsKey(_key)) {
      await box.delete(_key);
    }
  }
}
