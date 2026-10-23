import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/storage/app_storage.dart';

/// One finished game, as saved to the history.
@immutable
class GameRecord {
  const GameRecord({
    required this.id,
    required this.playedAt,
    required this.isLocal,
    required this.result,
    required this.reason,
    required this.playerIsWhite,
    required this.uciMoves,
    required this.sanMoves,
    this.botId,
    this.botName,
    this.botElo,
    this.practice = false,
    this.ratingChange,
    this.timeControl,
    this.accuracy,
  });

  /// Result values for bot games.
  static const win = 'win';
  static const loss = 'loss';
  static const draw = 'draw';

  /// Result values for local games.
  static const whiteWon = 'white';
  static const blackWon = 'black';

  final String id;
  final int playedAt;
  final bool isLocal;
  final String result;
  final String reason;
  final bool playerIsWhite;

  /// Moves in dartchess UCI form (castling is king-takes-rook), so they can be
  /// replayed with `Position.play`.
  final List<String> uciMoves;
  final List<String> sanMoves;
  final String? botId;
  final String? botName;
  final int? botElo;
  final bool practice;
  final int? ratingChange;
  final String? timeControl;

  /// Average accuracy of the player's moves, 0..100, or null when it was not
  /// (or could not be) worked out.
  final double? accuracy;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(playedAt);

  Map<String, Object?> toMap() => {
    'id': id,
    'playedAt': playedAt,
    'isLocal': isLocal,
    'result': result,
    'reason': reason,
    'playerIsWhite': playerIsWhite,
    'uci': uciMoves,
    'san': sanMoves,
    'botId': botId,
    'botName': botName,
    'botElo': botElo,
    'practice': practice,
    'ratingChange': ratingChange,
    'timeControl': timeControl,
    'accuracy': accuracy,
  };

  /// Returns null when [raw] is not a usable record.
  static GameRecord? tryFromMap(Object? raw) {
    if (raw is! Map) return null;
    try {
      final id = raw['id'];
      final playedAt = raw['playedAt'];
      final result = raw['result'];
      final uci = raw['uci'];
      final san = raw['san'];
      if (id is! String || playedAt is! int || result is! String) return null;
      if (uci is! List || san is! List) return null;
      if (uci.any((e) => e is! String) || san.any((e) => e is! String)) {
        return null;
      }
      return GameRecord(
        id: id,
        playedAt: playedAt,
        isLocal: raw['isLocal'] == true,
        result: result,
        reason: raw['reason'] is String ? raw['reason'] as String : '',
        playerIsWhite: raw['playerIsWhite'] != false,
        uciMoves: uci.cast<String>(),
        sanMoves: san.cast<String>(),
        botId: raw['botId'] as String?,
        botName: raw['botName'] as String?,
        botElo: raw['botElo'] as int?,
        practice: raw['practice'] == true,
        ratingChange: raw['ratingChange'] as int?,
        timeControl: raw['timeControl'] as String?,
        accuracy: (raw['accuracy'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

class GameHistoryStore {
  GameHistoryStore._() : _boxOverride = null;

  @visibleForTesting
  GameHistoryStore.withBox(Box<dynamic> box) : _boxOverride = box;

  static final GameHistoryStore instance = GameHistoryStore._();

  /// Oldest games are dropped beyond this many.
  static const int maxGames = 200;

  final Box<dynamic>? _boxOverride;

  Box<dynamic> get _box => _boxOverride ?? Hive.box(AppStorage.historyBoxName);

  ValueListenable<Box<dynamic>> listenable() => _box.listenable();

  /// All saved games, newest first. Unreadable entries are skipped.
  List<GameRecord> all() {
    final records = <GameRecord>[
      for (final value in _box.values) ?GameRecord.tryFromMap(value),
    ];
    records.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return records;
  }

  GameRecord? byId(String id) => GameRecord.tryFromMap(_box.get(id));

  Future<void> add(GameRecord record) async {
    await _box.put(record.id, record.toMap());
    final records = all();
    if (records.length > maxGames) {
      await _box.deleteAll(records.skip(maxGames).map((r) => r.id));
    }
  }

  /// Stores the accuracy of an already saved game. Does nothing when the game
  /// is gone (for example deleted while it was being analyzed).
  Future<void> setAccuracy(String id, double accuracy) async {
    final record = byId(id);
    if (record == null) return;
    await _box.put(id, {...record.toMap(), 'accuracy': accuracy});
  }

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();
}
