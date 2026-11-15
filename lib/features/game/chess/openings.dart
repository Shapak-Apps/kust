import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';

import 'package:kust/l10n/app_locale.dart';

/// A named opening from the lichess list, built into
/// assets/openings/openings.tsv by tools/openings/build_openings.dart.
class Opening {
  const Opening(this.en, this.ru);

  final String en;
  final String ru;

  /// English names for English; Russian ones for Russian and Turkmen.
  String nameIn(AppL10n t) => t.localeName == 'en' ? en : ru;
}

/// Board, side to move and castling: the same key the build tool writes.
/// En passant is left out so move orders that transpose still match.
String openingKey(Position p) => p.fen.split(' ').take(3).join(' ');

Map<String, Opening> parseOpenings(String tsv) => {
  for (final line in tsv.split('\n'))
    if (line.isNotEmpty)
      line.split('\t')[0]: Opening(line.split('\t')[1], line.split('\t')[2]),
};

Future<Map<String, Opening>>? _book;
Map<String, Opening>? _loaded;

/// Every known opening position, loaded once; main starts it at launch.
Future<Map<String, Opening>> openingBook() => _book ??= rootBundle
    .loadString('assets/openings/openings.tsv')
    .then((tsv) => _loaded = parseOpenings(tsv));

/// The book if [openingBook] has finished loading, for code that must not wait.
Map<String, Opening>? get loadedOpeningBook => _loaded;

/// The name of the last known opening position in [positions].
Opening? openingOf(Map<String, Opening> book, Iterable<Position> positions) {
  Opening? found;
  for (final p in positions) {
    found = book[openingKey(p)] ?? found;
  }
  return found;
}

/// Whether the move at [ply] is a book move: it and every move before it
/// reach known opening positions. [positions] starts with the initial one.
bool isBookMove(Map<String, Opening> book, List<Position> positions, int ply) =>
    positions.skip(1).take(ply).every((p) => book.containsKey(openingKey(p)));
