import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:kust/core/storage/puzzle_progress_store.dart';
import 'package:kust/features/puzzles/puzzle_data.dart';

const _a = PuzzleEntry(
  id: 'a',
  fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
  moves: ['a1a8'],
  rating: 1000,
);
const _b = PuzzleEntry(
  id: 'b',
  fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
  moves: ['a1a8'],
  rating: 1000,
);

void main() {
  late Directory dir;
  late Box<dynamic> box;
  late PuzzleProgressStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kust_puzzle_test');
    Hive.init(dir.path);
    box = await Hive.openBox('puzzles');
    store = PuzzleProgressStore.withBox(box);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('empty store has defaults', () {
    final p = store.load();
    expect(p.solved, isEmpty);
    expect(p.revealed, isEmpty);
    expect(p.rating, 1000);
  });

  test('solved and revealed are tracked separately', () async {
    await store.recordSolved(_a, clean: true);
    await store.recordRevealed(_b);
    final p = store.load();
    expect(p.isSolved('a'), isTrue);
    expect(p.isRevealed('a'), isFalse);
    expect(p.isSolved('b'), isFalse);
    expect(p.isRevealed('b'), isTrue);
    expect(p.isCompleted('b'), isTrue);
  });

  test('solving a revealed puzzle later marks it solved', () async {
    await store.recordRevealed(_a);
    await store.recordSolved(_a, clean: true);
    final p = store.load();
    expect(p.isSolved('a'), isTrue);
    expect(p.isRevealed('a'), isFalse);
  });

  test('only the first attempt changes the rating', () async {
    await store.recordMistake(_a);
    final afterMistake = store.load().rating;
    expect(afterMistake, lessThan(1000));
    await store.recordSolved(_a, clean: false);
    expect(store.load().rating, afterMistake);
  });

  test('progress survives reopening the box', () async {
    await store.recordSolved(_a, clean: true);
    await store.recordRevealed(_b);
    await box.close();
    final reopened = PuzzleProgressStore.withBox(await Hive.openBox('puzzles'));
    final p = reopened.load();
    expect(p.solved, {'a'});
    expect(p.revealed, {'b'});
  });

  test('corrupt stored data falls back to defaults', () async {
    await box.put('progress_test', {'solved': 'oops', 'rating': 'x'});
    final p = store.load();
    expect(p.solved, isEmpty);
  });
}
