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

  test('against a bot: you won or lost, and how', () {
    final won = _game(mode: GameMode.bot, flagFell: Side.black);
    expect(resultHeadline(en, won), ('You won!', 'on time'));
    expect(resultHeadline(tk, won).$1, 'Siz ýeňdiňiz!');
    final lost = _game(mode: GameMode.bot, flagFell: Side.white);
    expect(resultHeadline(en, lost), ('You lost', 'on time'));
    final resigned = _game(mode: GameMode.bot, status: GameStatus.resigned);
    expect(resultHeadline(en, resigned), ('You lost', 'by resignation'));
  });

  test('checkmate: the side not to move won', () {
    // Black to move and mated: White, the player, won.
    final g = _game(mode: GameMode.bot, status: GameStatus.checkmate).copyWith(
      position: Chess.fromSetup(
        Setup.parseFen(
          'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
        ),
      ),
    );
    expect(resultHeadline(en, g), ('You lost', 'by checkmate'));
  });

  test('pass and play names the colour, never "you"', () {
    final g = _game(mode: GameMode.local, flagFell: Side.black);
    expect(resultHeadline(en, g), ('White won', 'on time'));
  });

  test('a draw says how', () {
    final g = _game(
      mode: GameMode.bot,
      status: GameStatus.draw,
    ).copyWith(endReason: EndReason.stalemate);
    expect(resultHeadline(en, g), ('Draw', 'by stalemate'));
  });
}
