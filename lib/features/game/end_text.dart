import 'package:dartchess/dartchess.dart';

import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/l10n/app_locale.dart';

/// How [side] is called in the message of game [g]: White or Black in a pass
/// and play game, "You" or the bot's name against a bot.
String sideName(AppL10n t, GameState g, Side side) {
  if (g.mode == GameMode.local) {
    return side == Side.white ? t.whiteName : t.blackName;
  }
  return side == g.playerSide ? t.youName : (g.bot?.name ?? t.blackName);
}

/// The message under "Draw" or "Time out" when a game ends that way.
String endMessage(AppL10n t, GameState g) {
  if (g.status == GameStatus.timeout) {
    final loser = g.flagFell;
    return loser == null
        ? t.gameEndedOnTime
        : t.endTimeWon(sideName(t, g, loser.opposite));
  }
  return switch (g.endReason) {
    EndReason.stalemate => t.endStalemate,
    EndReason.fiftyMove => t.endFiftyMove,
    EndReason.insufficientMaterial => t.endInsufficient,
    EndReason.repetition => t.endRepetition,
    EndReason.timeNoMate => t.endTimeNoMate,
    _ => t.gameDrawn,
  };
}
