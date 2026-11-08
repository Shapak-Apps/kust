import 'package:dartchess/dartchess.dart';

import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/l10n/app_locale.dart';

/// Something in a game a bot may remark on.
enum BotMoment { blunder, brilliant, win, loss, draw }

/// What the bot says when you pick it.
String botGreeting(AppL10n t, Bot bot) => switch (bot.id) {
  'bahar' => t.botGreetBahar,
  'elizabeth' => t.botGreetElizabeth,
  'mark' => t.botGreetMark,
  'apex' => t.botGreetApex,
  'karl' => t.botGreetKarl,
  'enejan' => t.botGreetEnejan,
  'maya' => t.botGreetMaya,
  'yura' => t.botGreetYura,
  'berdi' => t.botGreetBerdi,
  _ => '',
};

/// A line for [bot] at [moment]. Each mood has a couple of lines for every
/// moment, kept in one string and told apart by `|`; [seed] picks one.
String botLine(AppL10n t, Bot bot, BotMoment moment, int seed) {
  final lines = switch ((bot.mood, moment)) {
    (BotMood.cheerful, BotMoment.blunder) => t.botCheerfulBlunder,
    (BotMood.cheerful, BotMoment.brilliant) => t.botCheerfulBrilliant,
    (BotMood.cheerful, BotMoment.win) => t.botCheerfulWin,
    (BotMood.cheerful, BotMoment.loss) => t.botCheerfulLoss,
    (BotMood.cheerful, BotMoment.draw) => t.botCheerfulDraw,
    (BotMood.calm, BotMoment.blunder) => t.botCalmBlunder,
    (BotMood.calm, BotMoment.brilliant) => t.botCalmBrilliant,
    (BotMood.calm, BotMoment.win) => t.botCalmWin,
    (BotMood.calm, BotMoment.loss) => t.botCalmLoss,
    (BotMood.calm, BotMoment.draw) => t.botCalmDraw,
    (BotMood.cocky, BotMoment.blunder) => t.botCockyBlunder,
    (BotMood.cocky, BotMoment.brilliant) => t.botCockyBrilliant,
    (BotMood.cocky, BotMoment.win) => t.botCockyWin,
    (BotMood.cocky, BotMoment.loss) => t.botCockyLoss,
    (BotMood.cocky, BotMoment.draw) => t.botCockyDraw,
    (BotMood.wise, BotMoment.blunder) => t.botWiseBlunder,
    (BotMood.wise, BotMoment.brilliant) => t.botWiseBrilliant,
    (BotMood.wise, BotMoment.win) => t.botWiseWin,
    (BotMood.wise, BotMoment.loss) => t.botWiseLoss,
    (BotMood.wise, BotMoment.draw) => t.botWiseDraw,
  }.split('|');
  return lines[seed.abs() % lines.length];
}

/// How a finished game against a bot looks to the bot, or null when the game
/// is not over or is not against a bot.
BotMoment? botEndMoment(GameState g) {
  if (g.mode != GameMode.bot || g.bot == null) return null;
  final Side? loser = switch (g.status) {
    GameStatus.draw => null,
    GameStatus.checkmate => g.position.turn,
    GameStatus.timeout => g.flagFell,
    GameStatus.resigned => g.resignedSide,
    _ => null,
  };
  if (g.status == GameStatus.draw) return BotMoment.draw;
  if (g.status == GameStatus.playing || g.status == GameStatus.loading) {
    return null;
  }
  if (loser == null) return null;
  return loser == g.playerSide ? BotMoment.win : BotMoment.loss;
}
