import 'package:kust/core/storage/game_history_store.dart';

/// PGN result token for [game]: `1-0`, `0-1` or `1/2-1/2`.
String pgnResult(GameRecord game) {
  if (game.result == GameRecord.draw) return '1/2-1/2';
  final whiteWon = game.isLocal
      ? game.result == GameRecord.whiteWon
      : (game.result == GameRecord.win) == game.playerIsWhite;
  return whiteWon ? '1-0' : '0-1';
}

/// Standard PGN text for a saved game, ready to paste into other chess tools.
String buildPgn(GameRecord game) {
  final date = game.date;
  String two(int n) => n.toString().padLeft(2, '0');

  final String white;
  final String black;
  if (game.isLocal) {
    white = 'White';
    black = 'Black';
  } else {
    final bot = game.botName ?? 'Bot';
    white = game.playerIsWhite ? 'Player' : bot;
    black = game.playerIsWhite ? bot : 'Player';
  }

  final headers = <String, String>{
    'Event': game.isLocal ? 'Pass and play' : 'Game against bot',
    'Site': 'Küşt',
    'Date': '${date.year}.${two(date.month)}.${two(date.day)}',
    'White': white,
    'Black': black,
    'Result': pgnResult(game),
    if (game.botElo != null)
      (game.playerIsWhite ? 'BlackElo' : 'WhiteElo'): '${game.botElo}',
    if (game.timeControl != null)
      'TimeControl': _timeControl(game.timeControl!),
  };

  final moves = StringBuffer();
  for (var i = 0; i < game.sanMoves.length; i++) {
    if (i.isEven) moves.write('${i ~/ 2 + 1}. ');
    moves.write('${game.sanMoves[i]} ');
  }
  moves.write(pgnResult(game));

  final head = headers.entries.map((e) => '[${e.key} "${_escape(e.value)}"]');
  return '${head.join('\n')}\n\n$moves\n';
}

/// `5+2` (minutes+seconds) becomes PGN's `300+2`.
String _timeControl(String stored) {
  final parts = stored.split('+');
  final minutes = int.tryParse(parts.first);
  if (minutes == null) return '-';
  final increment = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return '${minutes * 60}+$increment';
}

String _escape(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

/// Win/loss/draw totals over rated and unrated bot games.
class HistoryStats {
  const HistoryStats({
    required this.total,
    required this.wins,
    required this.losses,
    required this.draws,
  });

  factory HistoryStats.from(Iterable<GameRecord> games) {
    var total = 0, wins = 0, losses = 0, draws = 0;
    for (final g in games) {
      if (g.isLocal) continue;
      total++;
      switch (g.result) {
        case GameRecord.win:
          wins++;
        case GameRecord.loss:
          losses++;
        default:
          draws++;
      }
    }
    return HistoryStats(total: total, wins: wins, losses: losses, draws: draws);
  }

  final int total;
  final int wins;
  final int losses;
  final int draws;

  /// Share of bot games won, 0..100, or null with no games.
  int? get winRate => total == 0 ? null : (wins * 100 / total).round();
}
