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

/// The result screen's headline and how the game ended: ("You won!",
/// "by checkmate"), ("Draw", "by stalemate"), or ("White won", "on time")
/// in pass and play.
(String, String) resultHeadline(AppL10n t, GameState g) {
  final Side? winner = switch (g.status) {
    GameStatus.checkmate => g.position.turn.opposite,
    GameStatus.resigned =>
      g.mode == GameMode.local
          ? g.resignedSide?.opposite
          : g.playerSide.opposite,
    GameStatus.timeout => g.flagFell?.opposite,
    _ => null,
  };
  final title = winner == null
      ? t.resultDraw
      : g.mode == GameMode.local
      ? (winner == Side.white ? t.resultWhiteWon : t.resultBlackWon)
      : (winner == g.playerSide ? t.youWonTitle : t.youLostTitle);
  final how = switch (g.status) {
    GameStatus.checkmate => t.byCheckmate,
    GameStatus.resigned => t.byResignation,
    GameStatus.timeout => winner == null ? t.byTimeNoMate : t.byTimeout,
    _ => switch (g.endReason) {
      EndReason.stalemate => t.byStalemate,
      EndReason.fiftyMove => t.byFiftyMove,
      EndReason.insufficientMaterial => t.byInsufficient,
      EndReason.repetition => t.byRepetition,
      EndReason.timeNoMate => t.byTimeNoMate,
      _ => t.byAgreement,
    },
  };
  return (title, how);
}
