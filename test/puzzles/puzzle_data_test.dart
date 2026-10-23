import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/puzzles/puzzle_data.dart';

const _mateFen = '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1';

Map<String, dynamic> _json({Object? fen, Object? moves, Object? id = 'p1'}) => {
  'id': id,
  'fen': fen ?? _mateFen,
  'moves': moves ?? ['a1a8'],
  'rating': 800,
  'theme': 'mateIn1',
};

void main() {
  group('PuzzleEntry.tryParse', () {
    test('parses a valid puzzle', () {
      final entry = PuzzleEntry.tryParse(_json());
      expect(entry, isNotNull);
      expect(entry!.id, 'p1');
      expect(entry.lines, [
        ['a1a8'],
      ]);
    });

    test('theme is optional', () {
      final json = _json()..remove('theme');
      expect(PuzzleEntry.tryParse(json)?.theme, 'tactic');
    });

    test('rejects missing fields and wrong types', () {
      expect(PuzzleEntry.tryParse(null), isNull);
      expect(PuzzleEntry.tryParse(_json(id: null)), isNull);
      expect(PuzzleEntry.tryParse(_json(moves: [])), isNull);
      expect(PuzzleEntry.tryParse(_json(moves: 'a1a8')), isNull);
      expect(PuzzleEntry.tryParse(_json(moves: [1, 2])), isNull);
      expect(PuzzleEntry.tryParse(_json()..['rating'] = '800'), isNull);
    });

    test('rejects invalid FEN', () {
      expect(PuzzleEntry.tryParse(_json(fen: 'not a fen')), isNull);
    });

    test('rejects illegal or malformed solution moves', () {
      expect(PuzzleEntry.tryParse(_json(moves: ['a1a9'])), isNull);
      expect(PuzzleEntry.tryParse(_json(moves: ['a1b3'])), isNull);
      expect(PuzzleEntry.tryParse(_json(moves: ['zz'])), isNull);
    });

    test('rejects illegal alternative lines', () {
      final json = _json()
        ..['alternatives'] = [
          ['a1a5', 'a1a2'],
        ];
      expect(PuzzleEntry.tryParse(json), isNull);
    });
  });

  group('PuzzleLevel.fromJson', () {
    test('skips malformed and duplicate puzzles', () {
      final level = PuzzleLevel.fromJson({
        'level': 1,
        'puzzles': [_json(), _json(fen: 'bad', id: 'p2'), _json(), 5],
      });
      expect(level.puzzles.length, 1);
      expect(level.skipped, 3);
    });

    test('empty level is allowed', () {
      final level = PuzzleLevel.fromJson({'level': 1, 'puzzles': []});
      expect(level.puzzles, isEmpty);
    });

    test('invalid structure throws', () {
      expect(
        () => PuzzleLevel.fromJson({'level': 1}),
        throwsA(isA<PuzzleDataException>()),
      );
    });
  });
}
