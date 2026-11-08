import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/play/bot_voice.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/l10n/gen/app_localizations.dart';

void main() {
  final bots = [...kInternationalBots, ...kTkmBots];

  for (final code in ['en', 'ru', 'tk']) {
    test('every bot has a greeting and lines for every moment ($code)', () {
      final t = lookupAppL10n(Locale(code));
      for (final bot in bots) {
        expect(botGreeting(t, bot), isNotEmpty, reason: bot.id);
        for (final moment in BotMoment.values) {
          final a = botLine(t, bot, moment, 0);
          final b = botLine(t, bot, moment, 1);
          expect(a, isNotEmpty, reason: '${bot.id} $moment');
          expect(b, isNotEmpty);
          expect(a, isNot(b), reason: 'two lines for ${bot.id} $moment');
        }
      }
    });
  }

  test('a finished game is a win, a loss or a draw for the bot', () {
    GameState game(GameStatus status, {Side? turn, Side? flag, Side? resign}) =>
        GameState(
          position: turn == Side.black
              ? Chess.fromSetup(
                  Setup.parseFen('8/8/8/8/8/8/8/K6k b - - 0 1'),
                  ignoreImpossibleCheck: true,
                )
              : Chess.initial,
          mode: GameMode.bot,
          bot: kInternationalBots.first,
          playerSide: Side.white,
          status: status,
          flagFell: flag,
          resignedSide: resign,
        );

    expect(botEndMoment(game(GameStatus.playing)), isNull);
    expect(botEndMoment(game(GameStatus.draw)), BotMoment.draw);
    // White (you) is mated: the bot won.
    expect(botEndMoment(game(GameStatus.checkmate)), BotMoment.win);
    // Black (the bot) is mated: the bot lost.
    expect(
      botEndMoment(game(GameStatus.checkmate, turn: Side.black)),
      BotMoment.loss,
    );
    expect(
      botEndMoment(game(GameStatus.timeout, flag: Side.black)),
      BotMoment.loss,
    );
    expect(
      botEndMoment(game(GameStatus.resigned, resign: Side.white)),
      BotMoment.win,
    );
  });
}
