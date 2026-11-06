import 'package:dartchess/dartchess.dart';

import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/end_text.dart';
import 'package:kust/features/play/bots.dart';
import 'package:kust/l10n/app_locale.dart';

GameState _game({
  required GameMode mode,
  GameStatus status = GameStatus.timeout,
  Side player = Side.white,
  Side? flagFell,
}) => GameState(
  position: Chess.initial,
  mode: mode,
  bot: mode == GameMode.bot ? kInternationalBots.first : null,
  playerSide: player,
  status: status,
  flagFell: flagFell,
);

void main() {
  final tk = lookupAppL10n(const Locale('tk'));
  final en = lookupAppL10n(const Locale('en'));

  test('against a bot, the player winning is "Siz ýeňdiňiz."', () {
    final g = _game(mode: GameMode.bot, status: GameStatus.checkmate);
    expect(wonGameMessage(tk, g, Side.white), 'Siz ýeňdiňiz.');
    expect(wonGameMessage(en, g, Side.white), 'You won the game.');
  });

  test('against a bot, the bot winning is named', () {
    final g = _game(mode: GameMode.bot, status: GameStatus.checkmate);
    expect(
      wonGameMessage(tk, g, Side.black),
      '${kInternationalBots.first.name} ýeňdi.',
    );
  });

  test('pass and play names the colour, never "you"', () {
    final g = _game(mode: GameMode.local, status: GameStatus.checkmate);
    expect(wonGameMessage(tk, g, Side.white), 'Ak ýeňdi.');
    expect(wonGameMessage(tk, g, Side.black), 'Gara ýeňdi.');
  });

  test('a win on time: you, the bot, or a colour', () {
    final bot = _game(mode: GameMode.bot, flagFell: Side.black);
    expect(endMessage(tk, bot), 'Siz wagt boýunça ýeňdiňiz.');
    final lost = _game(mode: GameMode.bot, flagFell: Side.white);
    expect(
      endMessage(tk, lost),
      '${kInternationalBots.first.name} wagt boýunça ýeňdi.',
    );
    final local = _game(mode: GameMode.local, flagFell: Side.black);
    expect(endMessage(tk, local), 'Ak wagt boýunça ýeňdi.');
  });
}
