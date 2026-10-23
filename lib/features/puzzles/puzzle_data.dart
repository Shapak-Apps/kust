import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';

/// Thrown when puzzle data cannot be loaded or contains nothing usable.
class PuzzleDataException implements Exception {
  const PuzzleDataException(this.message);

  final String message;

  @override
  String toString() => 'PuzzleDataException: $message';
}

/// Converts a UCI string into a move playable in [position].
///
/// Standard castling (`e1g1`) is translated to dartchess' king-takes-rook
/// form. Returns null when the string is malformed.
NormalMove? parsePuzzleUci(String uci, Position position) {
  final parsed = Move.parse(uci);
  if (parsed is! NormalMove) return null;

  var to = parsed.to;
  if (position.board.pieceAt(parsed.from)?.role == Role.king) {
    if (parsed.from == Square.e1 && to == Square.g1) {
      to = Square.h1;
    } else if (parsed.from == Square.e1 && to == Square.c1) {
      to = Square.a1;
    } else if (parsed.from == Square.e8 && to == Square.g8) {
      to = Square.h8;
    } else if (parsed.from == Square.e8 && to == Square.c8) {
      to = Square.a8;
    }
  }
  return NormalMove(from: parsed.from, to: to, promotion: parsed.promotion);
}

class PuzzleEntry {
  const PuzzleEntry({
    required this.id,
    required this.fen,
    required this.moves,
    required this.rating,
    this.theme = 'tactic',
    this.alternatives = const [],
  });

  /// Parses and validates a puzzle. Returns null if any required field is
  /// missing or malformed, the FEN is not a legal position, or a solution
  /// line contains an illegal move.
  static PuzzleEntry? tryParse(Object? json) {
    if (json is! Map) return null;
    try {
      final id = json['id'];
      final fen = json['fen'];
      final rating = json['rating'];
      final theme = json['theme'];
      if (id is! String || id.isEmpty) return null;
      if (fen is! String || rating is! int) return null;
      if (theme != null && theme is! String) return null;

      final moves = _stringList(json['moves']);
      if (moves == null || moves.isEmpty) return null;

      final alternatives = <List<String>>[];
      final rawAlternatives = json['alternatives'];
      if (rawAlternatives != null) {
        if (rawAlternatives is! List) return null;
        for (final line in rawAlternatives) {
          final parsed = _stringList(line);
          if (parsed == null || parsed.isEmpty) return null;
          alternatives.add(parsed);
        }
      }

      final entry = PuzzleEntry(
        id: id,
        fen: fen,
        moves: moves,
        rating: rating,
        theme: (theme as String?) ?? 'tactic',
        alternatives: alternatives,
      );
      return entry.isPlayable ? entry : null;
    } catch (_) {
      return null;
    }
  }

  static List<String>? _stringList(Object? value) {
    if (value is! List) return null;
    if (value.any((e) => e is! String)) return null;
    return value.cast<String>();
  }

  final String id;
  final String fen;

  /// The main solution line in UCI. Even indices are the solver's moves, odd
  /// indices are forced replies from the opponent.
  final List<String> moves;

  /// Other accepted solution lines, in the same format as [moves].
  final List<List<String>> alternatives;
  final int rating;
  final String theme;

  /// Every accepted solution line, main line first.
  List<List<String>> get lines => [moves, ...alternatives];

  /// Whether the FEN is valid and every line is legal when replayed.
  bool get isPlayable {
    final Position start;
    try {
      start = Chess.fromSetup(Setup.parseFen(fen));
    } catch (_) {
      return false;
    }
    for (final line in lines) {
      var position = start;
      for (final uci in line) {
        final move = parsePuzzleUci(uci, position);
        if (move == null || !position.isLegal(move)) return false;
        position = position.play(move);
      }
    }
    return true;
  }
}

class PuzzleLevel {
  const PuzzleLevel({
    required this.level,
    required this.puzzles,
    this.skipped = 0,
  });

  /// Parses a level, dropping malformed puzzles instead of failing the whole
  /// file. The number of dropped entries is available as [skipped].
  factory PuzzleLevel.fromJson(Map<String, dynamic> json) {
    final level = json['level'];
    final rawPuzzles = json['puzzles'];
    if (level is! int || rawPuzzles is! List) {
      throw const PuzzleDataException('Puzzle file has an invalid structure');
    }
    final puzzles = <PuzzleEntry>[];
    final seen = <String>{};
    var skipped = 0;
    for (final raw in rawPuzzles) {
      final entry = PuzzleEntry.tryParse(raw);
      if (entry == null || !seen.add(entry.id)) {
        skipped++;
        continue;
      }
      puzzles.add(entry);
    }
    return PuzzleLevel(level: level, puzzles: puzzles, skipped: skipped);
  }

  final int level;
  final List<PuzzleEntry> puzzles;
  final int skipped;
}

class PuzzleRepository {
  PuzzleRepository._();
  static final PuzzleRepository instance = PuzzleRepository._();

  final Map<int, PuzzleLevel> _cache = {};

  /// Loads a level from the bundled assets. Throws [PuzzleDataException] when
  /// the file is missing or unreadable; an empty level is returned as is.
  Future<PuzzleLevel> loadLevel(int level) async {
    final cached = _cache[level];
    if (cached != null) return cached;

    final String raw;
    try {
      raw = await rootBundle.loadString('assets/puzzles/level$level.json');
    } catch (_) {
      throw PuzzleDataException('Puzzle level $level is unavailable');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw PuzzleDataException('Puzzle level $level is corrupted');
    }
    if (decoded is! Map<String, dynamic>) {
      throw PuzzleDataException('Puzzle level $level is corrupted');
    }

    final parsed = PuzzleLevel.fromJson(decoded);
    _cache[level] = parsed;
    return parsed;
  }
}
