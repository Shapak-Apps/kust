import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/live_game_store.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/game/game_args.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/features/train/train_openings.dart';

/// Which lines the player has practised, kept as "opening:index".
class TrainProgress {
  TrainProgress._();
  static final TrainProgress instance = TrainProgress._();

  static const String _key = 'train_tried';

  Box<dynamic> get _box => Hive.box(AppStorage.userBoxName);

  ValueListenable<Box<dynamic>> listenable() => _box.listenable(keys: [_key]);

  Set<String> get _tried {
    final raw = AppStorage.isReady ? _box.get(_key) : null;
    return raw is List ? raw.whereType<String>().toSet() : <String>{};
  }

  bool tried(TrainOpening o, int line) => _tried.contains('${o.id}:$line');

  int triedCount(TrainOpening o) => [
    for (var i = 0; i < o.lines.length; i++)
      if (tried(o, i)) i,
  ].length;

  Future<void> markTried(TrainOpening o, int line) async {
    if (!AppStorage.isReady) return;
    await _box.put(_key, [..._tried, '${o.id}:$line']);
  }
}

/// The bot closest to the player's rating, to practise against.
Bot trainBot() {
  final rating = AppStorage.isReady
      ? PlayerRatingStore.instance.rating
      : PlayerRatingStore.startRating;
  return kInternationalBots.reduce(
    (a, b) => (a.elo - rating).abs() <= (b.elo - rating).abs() ? a : b,
  );
}

/// Starts a practice game against [trainBot] from the end of line [index]
/// of [opening], the player on the opening's side.
void practiseLine(BuildContext context, TrainOpening opening, int index) {
  final bot = trainBot();
  TrainProgress.instance.markTried(opening, index);
  context.push(
    '/game',
    extra: GameArgs(
      bot: bot,
      playerSide: opening.side,
      practiceMode: true,
      fromLine: true,
      resume: LiveGame(
        isLocal: false,
        botId: bot.id,
        playerIsWhite: opening.side == Side.white,
        practice: true,
        uciMoves: opening.lines[index].uci,
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ),
  );
}
