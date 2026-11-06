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

/// Whether [side] is the player in a game against a bot.
bool _isYou(GameState g, Side side) =>
    g.mode == GameMode.bot && side == g.playerSide;

/// "You won the game." or "{name} won the game.", for the checkmate dialog.
String wonGameMessage(AppL10n t, GameState g, Side winner) =>
    _isYou(g, winner) ? t.youWonGame : t.wonTheGame(sideName(t, g, winner));

/// The message under "Draw" or "Time out" when a game ends that way.
String endMessage(AppL10n t, GameState g) {
  if (g.status == GameStatus.timeout) {
    final loser = g.flagFell;
    if (loser == null) return t.gameEndedOnTime;
    final winner = loser.opposite;
    return _isYou(g, winner)
        ? t.youWonOnTime
        : t.endTimeWon(sideName(t, g, winner));
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
