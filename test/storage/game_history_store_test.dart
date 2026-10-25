import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/core/storage/player_rating_store.dart';

GameRecord _game(String id, int at) => GameRecord(
  id: id,
  playedAt: at,
  isLocal: false,
  result: GameRecord.win,
  reason: 'Checkmate',
  playerIsWhite: true,
  uciMoves: const ['e2e4', 'e7e5'],
  sanMoves: const ['e4', 'e5'],
  botId: 'karl',
  botName: 'Karl',
  botElo: 1000,
  ratingChange: 12,
);

void main() {
  late Directory dir;
  late Box<dynamic> box;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_store_test');
    Hive.init(dir.path);
    box = await Hive.openBox('t');
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  group('GameHistoryStore', () {
    test('round-trips a record and lists newest first', () async {
      final store = GameHistoryStore.withBox(box);
      await store.add(_game('a', 100));
      await store.add(_game('b', 300));
      await store.add(_game('c', 200));

      expect(store.all().map((g) => g.id), ['b', 'c', 'a']);
      final loaded = store.byId('b')!;
      expect(loaded.uciMoves, ['e2e4', 'e7e5']);
      expect(loaded.botName, 'Karl');
      expect(loaded.ratingChange, 12);
    });

    test('stores accuracy and updates it later', () async {
      final store = GameHistoryStore.withBox(box);
      await store.add(_game('a', 1));
      expect(store.byId('a')!.accuracy, isNull);

      await store.setAccuracy('a', 71.6);
      expect(store.byId('a')!.accuracy, closeTo(71.6, 0.001));
      // Worked out at the end of the game, but not yet revealed in History.
      expect(store.byId('a')!.analyzed, isFalse);
      await store.setAccuracy('a', 71.6, analyzed: true);
      expect(store.byId('a')!.analyzed, isTrue);
      // A later update without the flag keeps it.
      await store.setAccuracy('a', 71.6);
      expect(store.byId('a')!.analyzed, isTrue);
      // The rest of the game is untouched.
      expect(store.byId('a')!.uciMoves, ['e2e4', 'e7e5']);

      // A deleted game is not brought back by a late analysis result.
      await store.delete('a');
      await store.setAccuracy('a', 50);
      expect(store.byId('a'), isNull);
    });

    test('skips unreadable entries instead of failing', () async {
      final store = GameHistoryStore.withBox(box);
      await store.add(_game('ok', 1));
      await box.put('bad1', 'nonsense');
      await box.put('bad2', {'id': 1});
      expect(store.all().map((g) => g.id), ['ok']);
      expect(store.byId('bad1'), isNull);
    });

    test('deletes and caps the number of games', () async {
      final store = GameHistoryStore.withBox(box);
      for (var i = 0; i < GameHistoryStore.maxGames + 5; i++) {
        await store.add(_game('g$i', i));
      }
      final all = store.all();
      expect(all.length, GameHistoryStore.maxGames);
      expect(all.first.id, 'g${GameHistoryStore.maxGames + 4}');

      await store.delete(all.first.id);
      expect(store.all().length, GameHistoryStore.maxGames - 1);
    });
  });

  group('PlayerRatingStore', () {
    test('starts at 1200', () {
      expect(PlayerRatingStore.withBox(box).rating, 1200);
    });

    test('equal opponents move the rating by half of K', () {
      expect(
        PlayerRatingStore.delta(rating: 1200, opponent: 1200, score: 1),
        16,
      );
      expect(
        PlayerRatingStore.delta(rating: 1200, opponent: 1200, score: 0),
        -16,
      );
      expect(
        PlayerRatingStore.delta(rating: 1200, opponent: 1200, score: 0.5),
        0,
      );
    });

    test('beating a stronger bot is worth more', () {
      final up = PlayerRatingStore.delta(
        rating: 1200,
        opponent: 1600,
        score: 1,
      );
      final down = PlayerRatingStore.delta(
        rating: 1200,
        opponent: 800,
        score: 1,
      );
      expect(up, greaterThan(down));
    });

    test('record persists and never drops below the floor', () async {
      final store = PlayerRatingStore.withBox(box);
      final change = await store.record(opponent: 1200, score: 1);
      expect(change, 16);
      expect(store.rating, 1216);

      await box.put('player_rating', PlayerRatingStore.minRating);
      await store.record(opponent: 3000, score: 0);
      expect(store.rating, PlayerRatingStore.minRating);
    });
  });
}
