import 'dart:convert';

import 'package:flutter/services.dart';

class PuzzleEntry {
  const PuzzleEntry({
    required this.id,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.theme,
  });

  factory PuzzleEntry.fromJson(Map<String, dynamic> json) {
    return PuzzleEntry(
      id: json['id'] as String,
      fen: json['fen'] as String,
      moves: (json['moves'] as List<dynamic>).cast<String>(),
      rating: json['rating'] as int,
      theme: json['theme'] as String,
    );
  }

  final String id;
  final String fen;
  final List<String> moves;
  final int rating;
  final String theme;
}

class PuzzleLevel {
  const PuzzleLevel({required this.level, required this.puzzles});

  factory PuzzleLevel.fromJson(Map<String, dynamic> json) {
    final puzzles = (json['puzzles'] as List<dynamic>)
        .map((entry) => PuzzleEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
    return PuzzleLevel(level: json['level'] as int, puzzles: puzzles);
  }

  final int level;
  final List<PuzzleEntry> puzzles;
}

class PuzzleRepository {
  PuzzleRepository._();
  static final PuzzleRepository instance = PuzzleRepository._();

  final Map<int, PuzzleLevel> _cache = {};

  Future<PuzzleLevel> loadLevel(int level) async {
    final cached = _cache[level];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/puzzles/level$level.json');
    final parsed = PuzzleLevel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    _cache[level] = parsed;
    return parsed;
  }
}
