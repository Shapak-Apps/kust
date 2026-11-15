import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/openings.dart';
import 'package:kust/l10n/gen/app_localizations.dart';

List<Position> _play(List<String> san) {
  final out = <Position>[Chess.initial];
  for (final s in san) {
    out.add(out.last.play(out.last.parseSan(s)!));
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('finds the Ruy Lopez, in either move order', () async {
    final book = await openingBook();
    for (final line in [
      ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'],
      ['Nf3', 'Nc6', 'e4', 'e5', 'Bb5'],
    ]) {
      final o = openingOf(book, _play(line))!;
      expect(o.en, 'Ruy Lopez');
      expect(o.ru, 'Испанская партия');
    }
    final najdorf = openingOf(
      book,
      _play([
        'e4',
        'c5',
        'Nf3',
        'd6',
        'd4',
        'cxd4',
        'Nxd4',
        'Nf6',
        'Nc3',
        'a6',
      ]),
    )!;
    expect(najdorf.ru, 'Сицилианская защита: вариант Найдорфа');
  });

  test(
    'a move out of theory ends the book, and nothing after it is book',
    () async {
      final book = await openingBook();
      final p = _play(['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'Ke7', 'O-O', 'Kf6']);
      expect(
        [for (var i = 1; i < p.length; i++) isBookMove(book, p, i)],
        [
          true, true, true, true, true, false, false, false, //
        ],
      );
      // The name stays that of the last known position.
      expect(openingOf(book, p)!.en, 'Ruy Lopez');
    },
  );

  test('English names in English, Russian ones in Russian and Turkmen', () {
    const o = Opening('Sicilian Defense', 'Сицилианская защита');
    expect(o.nameIn(lookupAppL10n(const Locale('en'))), 'Sicilian Defense');
    expect(o.nameIn(lookupAppL10n(const Locale('ru'))), 'Сицилианская защита');
    expect(o.nameIn(lookupAppL10n(const Locale('tk'))), 'Сицилианская защита');
  });
}
