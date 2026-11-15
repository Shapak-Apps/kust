// Builds assets/openings/openings.tsv from the lichess opening list.
//
// The list (CC0) is https://github.com/lichess-org/chess-openings, copied to
// tools/openings/src/. Each line becomes one row: the position after the
// line's moves, its English name and its Russian name. Russian names are put
// together from tools/openings/ru_names.tsv, part by part; a name stops at
// its last part with a translation, so it never mixes the two languages.
//
//     dart run tools/openings/build_openings.dart

import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;

/// Must match `openingKey` in lib/features/game/chess/openings.dart.
String openingKey(Position p) => p.fen.split(' ').take(3).join(' ');

/// "Sicilian Defense: Najdorf Variation, English Attack" ->
/// ["Sicilian Defense", "Najdorf Variation", "English Attack"].
List<String> nameParts(String name) =>
    name.split(RegExp(r': |, ')).map((s) => s.trim()).toList();

/// The Russian name, or null when even the first part has no translation.
String? russian(String name, Map<String, String> ru) {
  final parts = nameParts(name);
  final out = <String>[];
  for (final p in parts) {
    final t = ru[p];
    if (t == null) break;
    out.add(t);
  }
  if (out.isEmpty) return null;
  if (out.length == 1) return out.first;
  // Russian keeps only the family capitalised: "…: вариант Найдорфа".
  final rest = out.skip(1).map((s) => s[0].toLowerCase() + s.substring(1));
  return '${out.first}: ${rest.join(', ')}';
}

void main() {
  final dir = File(Platform.script.toFilePath()).parent.path;
  final ru = <String, String>{};
  for (final line in File('$dir/ru_names.tsv').readAsLinesSync()) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final [en, r] = line.split('\t');
    ru[en] = r;
  }

  final rows = <String, String>{};
  var full = 0, total = 0;
  final missing = <String>{};
  for (final f in 'abcde'.split('')) {
    for (final line in File('$dir/src/$f.tsv').readAsLinesSync().skip(1)) {
      if (line.isEmpty) continue;
      final [_, name, pgn] = line.split('\t');
      Position pos = Chess.initial;
      for (final san in pgn.split(' ')) {
        if (RegExp(r'^\d+\.$').hasMatch(san)) continue;
        pos = pos.play(pos.parseSan(san)!);
      }
      final r = russian(name, ru);
      if (r == null) throw StateError('No Russian family name for "$name"');
      total++;
      if (nameParts(name).every(ru.containsKey)) {
        full++;
      } else {
        missing.addAll(nameParts(name).where((p) => !ru.containsKey(p)));
      }
      // The first name for a position wins: lichess lists the main name first.
      rows.putIfAbsent(openingKey(pos), () => '$name\t$r');
    }
  }

  final out = File('$dir/../../assets/openings/openings.tsv');
  out.writeAsStringSync(
    rows.entries.map((e) => '${e.key}\t${e.value}\n').join(),
  );
  stdout.writeln(
    '${rows.length} positions; $full of $total names fully in Russian, '
    '${missing.length} parts still untranslated.',
  );
}
