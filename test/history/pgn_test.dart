import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/features/history/pgn.dart';

GameRecord _game({
  String result = GameRecord.win,
  bool isLocal = false,
  bool playerIsWhite = true,
  String? timeControl,
  bool practice = false,
}) => GameRecord(
  id: '1',
  playedAt: DateTime(2026, 10, 5).millisecondsSinceEpoch,
  isLocal: isLocal,
  result: result,
  reason: '',
  playerIsWhite: playerIsWhite,
  uciMoves: const ['e2e4', 'e7e5', 'g1f3'],
  sanMoves: const ['e4', 'e5', 'Nf3'],
  botName: isLocal ? null : 'Karl',
  botElo: isLocal ? null : 1000,
  timeControl: timeControl,
  practice: practice,
);

void main() {
  group('pgnResult', () {
    test('bot games depend on the side the player had', () {
      expect(pgnResult(_game()), '1-0');
      expect(pgnResult(_game(result: GameRecord.loss)), '0-1');
      expect(pgnResult(_game(playerIsWhite: false)), '0-1');
      expect(
        pgnResult(_game(playerIsWhite: false, result: GameRecord.loss)),
        '1-0',
      );
      expect(pgnResult(_game(result: GameRecord.draw)), '1/2-1/2');
    });

    test('local games use the winning colour', () {
      expect(
        pgnResult(_game(isLocal: true, result: GameRecord.whiteWon)),
        '1-0',
      );
      expect(
        pgnResult(_game(isLocal: true, result: GameRecord.blackWon)),
        '0-1',
      );
    });
  });

  group('buildPgn', () {
    test('writes headers and numbered moves', () {
      final pgn = buildPgn(_game(timeControl: '5+2'));
      expect(pgn, contains('[Site "Küşt"]'));
      expect(pgn, contains('[Date "2026.10.05"]'));
      expect(pgn, contains('[White "Player"]'));
      expect(pgn, contains('[Black "Karl"]'));
      expect(pgn, contains('[BlackElo "1000"]'));
      expect(pgn, contains('[TimeControl "300+2"]'));
      expect(pgn, contains('[Result "1-0"]'));
      expect(pgn, endsWith('1. e4 e5 2. Nf3 1-0\n'));
    });

    test('puts the bot on white when the player is black', () {
      final pgn = buildPgn(_game(playerIsWhite: false));
      expect(pgn, contains('[White "Karl"]'));
      expect(pgn, contains('[Black "Player"]'));
      expect(pgn, contains('[WhiteElo "1000"]'));
    });

    test('local games have no engine tags', () {
      final pgn = buildPgn(_game(isLocal: true, result: GameRecord.whiteWon));
      expect(pgn, contains('[White "White"]'));
      expect(pgn, isNot(contains('Elo')));
    });

    test('a game with no moves still produces a result', () {
      final empty = GameRecord(
        id: 'x',
        playedAt: 0,
        isLocal: true,
        result: GameRecord.whiteWon,
        reason: '',
        playerIsWhite: true,
        uciMoves: const [],
        sanMoves: const [],
      );
      expect(buildPgn(empty), endsWith('\n\n1-0\n'));
    });
  });

  group('HistoryStats', () {
    test('counts bot games only and computes the win rate', () {
      final stats = HistoryStats.from([
        _game(),
        _game(),
        _game(result: GameRecord.loss),
        _game(result: GameRecord.draw),
        _game(isLocal: true, result: GameRecord.whiteWon),
      ]);
      expect(stats.total, 4);
      expect(stats.wins, 2);
      expect(stats.losses, 1);
      expect(stats.draws, 1);
      expect(stats.winRate, 50);
    });

    test('practice games are not rated, so they are not counted', () {
      final stats = HistoryStats.from([
        _game(),
        _game(practice: true),
        _game(practice: true, result: GameRecord.loss),
      ]);
      expect(stats.total, 1);
      expect(stats.wins, 1);
      expect(stats.winRate, 100);
    });

    test('no games means no win rate', () {
      expect(HistoryStats.from(const []).winRate, isNull);
    });
  });
}
