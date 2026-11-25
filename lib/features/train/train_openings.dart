import 'package:dartchess/dartchess.dart';
import 'package:flutter/painting.dart' show Color;

import 'package:kust/l10n/app_locale.dart';

/// What kind of weapon an opening is, for the filters.
enum OpeningKind { opening, defense, gambit, attack }

/// One way an opening goes, as moves in SAN from the start position.
class TrainLine {
  const TrainLine(this.en, this.ru, this.san);

  final String en;
  final String ru;
  final List<String> san;

  /// English names for English; Russian ones for Russian and Turkmen, as
  /// with the opening book.
  String nameIn(AppL10n t) => t.localeName == 'en' ? en : ru;

  /// The positions of the line: the start, then one after each move.
  List<Position> get positions {
    Position p = Chess.initial;
    final out = [p];
    for (final s in san) {
      p = p.play(p.parseSan(s)!);
      out.add(p);
    }
    return out;
  }

  /// The squares of the move that ends the line, to mark on the board.
  List<Square> get lastSquares {
    final positions = this.positions;
    final move = positions[positions.length - 2].parseSan(san.last);
    return move is NormalMove ? [move.from, move.to] : const [];
  }

  /// The moves in dartchess UCI (castling as king takes rook), as saved
  /// games keep them.
  List<String> get uci {
    Position p = Chess.initial;
    final out = <String>[];
    for (final s in san) {
      final move = p.parseSan(s)!;
      out.add(move.uci);
      p = p.play(move);
    }
    return out;
  }
}

/// An opening to learn and practise: which side plays it, where it comes
/// from, and its lines, the most played first (three at most).
class TrainOpening {
  const TrainOpening({
    required this.id,
    required this.en,
    required this.ru,
    required this.kind,
    required this.side,
    required this.origin,
    required this.originRu,
    required this.flag,
    required this.lines,
  });

  final String id;
  final String en;
  final String ru;
  final OpeningKind kind;

  /// The side the player takes when practising it.
  final Side side;

  /// Who it is named after or who first played it, and when, in English
  /// and in Russian (also shown in Turkmen, as with the names).
  final String origin;
  final String originRu;

  /// A flag emoji for [origin], or empty.
  final String flag;
  final List<TrainLine> lines;

  String nameIn(AppL10n t) => t.localeName == 'en' ? en : ru;

  /// The name without the word its kind chip already says ("Caro-Kann"
  /// beside DEFENCE, not "Caro-Kann Defence"), where it still reads as a
  /// name; otherwise the full name ("Queen's Gambit" stays).
  String shortNameIn(AppL10n t) {
    final short = _short[id];
    if (short == null) return nameIn(t);
    return t.localeName == 'en' ? short.$1 : short.$2;
  }

  static const Map<String, (String, String)> _short = {
    'fried_liver': ('Fried Liver', 'Фегателло'),
    'sicilian': ('Sicilian', 'Сицилианская'),
    'french': ('French', 'Французская'),
    'caro_kann': ('Caro-Kann', 'Каро — Канн'),
    'kings_indian': ('King’s Indian', 'Староиндийская'),
    'scandinavian': ('Scandinavian', 'Скандинавская'),
    'budapest': ('Budapest', 'Будапештский'),
    'pirc': ('Pirc', 'Пирц'),
    'dutch': ('Dutch', 'Голландская'),
    'nimzo': ('Nimzo-Indian', 'Нимцо-индийская'),
  };

  String originIn(AppL10n t) => t.localeName == 'en' ? origin : originRu;

  String descriptionIn(AppL10n t) => switch (id) {
    'italian' => t.opItalianD,
    'ruy_lopez' => t.opRuyLopezD,
    'london' => t.opLondonD,
    'queens_gambit' => t.opQueensGambitD,
    'kings_gambit' => t.opKingsGambitD,
    'fried_liver' => t.opFriedLiverD,
    'sicilian' => t.opSicilianD,
    'french' => t.opFrenchD,
    'caro_kann' => t.opCaroKannD,
    'kings_indian' => t.opKingsIndianD,
    'scandinavian' => t.opScandinavianD,
    'budapest' => t.opBudapestD,
    'vienna' => t.opViennaD,
    'pirc' => t.opPircD,
    'dutch' => t.opDutchD,
    'nimzo' => t.opNimzoD,
    _ => '',
  };
}

/// Each kind's colour, for its label.
Color kindColor(OpeningKind kind) => switch (kind) {
  OpeningKind.opening => const Color(0xFF4CAF50),
  OpeningKind.defense => const Color(0xFF4D8EDB),
  OpeningKind.gambit => const Color(0xFFE5484D),
  OpeningKind.attack => const Color(0xFFF08A24),
};

String kindLabel(AppL10n t, OpeningKind kind) => switch (kind) {
  OpeningKind.opening => t.kindOpening,
  OpeningKind.defense => t.kindDefense,
  OpeningKind.gambit => t.kindGambit,
  OpeningKind.attack => t.kindAttack,
};

const List<TrainOpening> kTrainOpenings = [
  TrainOpening(
    id: 'italian',
    en: 'Italian Game',
    ru: 'Итальянская партия',
    kind: OpeningKind.opening,
    side: Side.white,
    origin: 'Giulio Polerio & Gioachino Greco, 1600s',
    originRu: 'Джулио Полерио и Джоакино Греко, 1600-е',
    flag: '🇮🇹',
    lines: [
      TrainLine('Giuoco Pianissimo', 'Джуоко пьяниссимо', [
        'e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Bc5', 'c3', 'Nf6', //
        'd3', 'd6', 'O-O', 'O-O',
      ]),
      TrainLine('Two Knights Defence', 'Защита двух коней', [
        'e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Nf6', 'd3', 'Be7', //
        'O-O', 'O-O',
      ]),
      TrainLine('Evans Gambit', 'Гамбит Эванса', [
        'e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Bc5', 'b4', 'Bxb4', //
        'c3', 'Ba5', 'd4',
      ]),
    ],
  ),
  TrainOpening(
    id: 'ruy_lopez',
    en: 'Ruy Lopez',
    ru: 'Испанская партия',
    kind: OpeningKind.opening,
    side: Side.white,
    origin: 'Ruy López de Segura, 1561',
    originRu: 'Руй Лопес де Сегура, 1561',
    flag: '🇪🇸',
    lines: [
      TrainLine('Closed Ruy Lopez', 'Закрытый вариант', [
        'e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6', 'Ba4', 'Nf6', //
        'O-O', 'Be7', 'Re1', 'b5', 'Bb3', 'd6', 'c3', 'O-O',
      ]),
      TrainLine('Berlin Defence', 'Берлинская защита', [
        'e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'Nf6', 'O-O', 'Nxe4', //
        'd4', 'Nd6', 'Bxc6', 'dxc6', 'dxe5', 'Nf5', 'Qxd8+', 'Kxd8',
      ]),
      TrainLine('Exchange Variation', 'Разменный вариант', [
        'e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6', 'Bxc6', 'dxc6', //
        'O-O', 'f6', 'd4',
      ]),
    ],
  ),
  TrainOpening(
    id: 'london',
    en: 'London System',
    ru: 'Лондонская система',
    kind: OpeningKind.opening,
    side: Side.white,
    origin: 'London tournament, 1922',
    originRu: 'Лондонский турнир, 1922',
    flag: '🇬🇧',
    lines: [
      TrainLine('Against 1...d5', 'Против 1...d5', [
        'd4', 'd5', 'Bf4', 'Nf6', 'e3', 'e6', 'Nf3', 'c5', //
        'c3', 'Nc6', 'Nbd2', 'Bd6', 'Bg3', 'O-O', 'Bd3',
      ]),
      TrainLine(
        'Against the King’s Indian setup',
        'Против староиндийской схемы',
        [
          'd4', 'Nf6', 'Bf4', 'g6', 'e3', 'Bg7', 'Nf3', 'O-O', //
          'Be2', 'd6', 'h3',
        ],
      ),
      TrainLine('Jobava London', 'Лондон Жобавы', [
        'd4',
        'd5',
        'Nc3',
        'Nf6',
        'Bf4',
        'c5',
        'e3',
        'Nc6',
        'Nb5',
      ]),
    ],
  ),
  TrainOpening(
    id: 'queens_gambit',
    en: 'Queen’s Gambit',
    ru: 'Ферзевый гамбит',
    kind: OpeningKind.gambit,
    side: Side.white,
    origin: 'Göttingen manuscript, about 1490',
    originRu: 'Гёттингенская рукопись, около 1490',
    flag: '🇩🇪',
    lines: [
      TrainLine('Queen’s Gambit Declined', 'Отказанный ферзевый гамбит', [
        'd4', 'd5', 'c4', 'e6', 'Nc3', 'Nf6', 'Bg5', 'Be7', //
        'e3', 'O-O', 'Nf3', 'Nbd7',
      ]),
      TrainLine('Queen’s Gambit Accepted', 'Принятый ферзевый гамбит', [
        'd4', 'd5', 'c4', 'dxc4', 'Nf3', 'Nf6', 'e3', 'e6', //
        'Bxc4', 'c5', 'O-O', 'a6',
      ]),
      TrainLine('Slav Defence', 'Славянская защита', [
        'd4',
        'd5',
        'c4',
        'c6',
        'Nf3',
        'Nf6',
        'Nc3',
        'dxc4',
        'a4',
        'Bf5',
      ]),
    ],
  ),
  TrainOpening(
    id: 'kings_gambit',
    en: 'King’s Gambit',
    ru: 'Королевский гамбит',
    kind: OpeningKind.gambit,
    side: Side.white,
    origin: 'Giulio Polerio, 1590s',
    originRu: 'Джулио Полерио, 1590-е',
    flag: '🇮🇹',
    lines: [
      TrainLine('Kieseritzky Gambit', 'Гамбит Кизерицкого', [
        'e4',
        'e5',
        'f4',
        'exf4',
        'Nf3',
        'g5',
        'h4',
        'g4',
        'Ne5',
      ]),
      TrainLine('Fischer Defence', 'Защита Фишера', [
        'e4', 'e5', 'f4', 'exf4', 'Nf3', 'd6', 'd4', 'g5', //
        'h4', 'g4', 'Ng1',
      ]),
      TrainLine('Falkbeer Countergambit', 'Контргамбит Фалькбеера', [
        'e4',
        'e5',
        'f4',
        'd5',
        'exd5',
        'e4',
      ]),
    ],
  ),
  TrainOpening(
    id: 'fried_liver',
    en: 'Fried Liver Attack',
    ru: 'Атака Фегателло',
    kind: OpeningKind.attack,
    side: Side.white,
    origin: 'Giulio Polerio, before 1606',
    originRu: 'Джулио Полерио, до 1606',
    flag: '🇮🇹',
    lines: [
      TrainLine('Fried Liver', 'Фегателло', [
        'e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Nf6', 'Ng5', 'd5', //
        'exd5', 'Nxd5', 'Nxf7', 'Kxf7', 'Qf3+', 'Ke6', 'Nc3',
      ]),
      TrainLine('Lolli Attack', 'Атака Лолли', [
        'e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Nf6', 'Ng5', 'd5', //
        'exd5', 'Nxd5', 'd4',
      ]),
      TrainLine('Main line, 5...Na5', 'Главный вариант, 5...Ка5', [
        'e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Nf6', 'Ng5', 'd5', //
        'exd5', 'Na5', 'Bb5+', 'c6', 'dxc6', 'bxc6', 'Be2', 'h6',
      ]),
    ],
  ),
  TrainOpening(
    id: 'vienna',
    en: 'Vienna Game',
    ru: 'Венская партия',
    kind: OpeningKind.opening,
    side: Side.white,
    origin: 'Vienna chess players, 1850s',
    originRu: 'Венские шахматисты, 1850-е',
    flag: '🇦🇹',
    lines: [
      TrainLine('Vienna Gambit', 'Венский гамбит', [
        'e4',
        'e5',
        'Nc3',
        'Nf6',
        'f4',
        'd5',
        'fxe5',
        'Nxe4',
        'Nf3',
      ]),
      TrainLine('With 3.Bc4', 'С ходом 3.Сc4', [
        'e4',
        'e5',
        'Nc3',
        'Nc6',
        'Bc4',
        'Nf6',
        'd3',
        'Bc5',
      ]),
      TrainLine(
        'Frankenstein–Dracula Variation',
        'Вариант Франкенштейна — Дракулы',
        [
          'e4', 'e5', 'Nc3', 'Nf6', 'Bc4', 'Nxe4', 'Qh5', 'Nd6', //
          'Bb3', 'Nc6', 'Nb5', 'g6', 'Qf3', 'f5', 'Qd5', 'Qe7', //
          'Nxc7+', 'Kd8', 'Nxa8', 'b6',
        ],
      ),
    ],
  ),
  TrainOpening(
    id: 'sicilian',
    en: 'Sicilian Defence',
    ru: 'Сицилианская защита',
    kind: OpeningKind.defense,
    side: Side.black,
    origin: 'Giulio Polerio, 1594',
    originRu: 'Джулио Полерио, 1594',
    flag: '🇮🇹',
    lines: [
      TrainLine('Najdorf Variation', 'Вариант Найдорфа', [
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
      TrainLine('Dragon Variation', 'Вариант дракона', [
        'e4', 'c5', 'Nf3', 'd6', 'd4', 'cxd4', 'Nxd4', 'Nf6', //
        'Nc3', 'g6', 'Be3', 'Bg7', 'f3', 'O-O',
      ]),
      TrainLine('Against the Alapin', 'Против варианта Алапина', [
        'e4',
        'c5',
        'c3',
        'Nf6',
        'e5',
        'Nd5',
        'd4',
        'cxd4',
        'Nf3',
        'Nc6',
      ]),
    ],
  ),
  TrainOpening(
    id: 'french',
    en: 'French Defence',
    ru: 'Французская защита',
    kind: OpeningKind.defense,
    side: Side.black,
    origin: 'Paris v London by letter, 1834',
    originRu: 'Матч Париж — Лондон по переписке, 1834',
    flag: '🇫🇷',
    lines: [
      TrainLine('Winawer Variation', 'Вариант Винавера', [
        'e4', 'e6', 'd4', 'd5', 'Nc3', 'Bb4', 'e5', 'c5', //
        'a3', 'Bxc3+', 'bxc3', 'Ne7',
      ]),
      TrainLine('Advance Variation', 'Вариант продвижения', [
        'e4',
        'e6',
        'd4',
        'd5',
        'e5',
        'c5',
        'c3',
        'Nc6',
        'Nf3',
        'Qb6',
      ]),
      TrainLine('Tarrasch Variation', 'Вариант Тарраша', [
        'e4', 'e6', 'd4', 'd5', 'Nd2', 'Nf6', 'e5', 'Nfd7', //
        'Bd3', 'c5', 'c3', 'Nc6',
      ]),
    ],
  ),
  TrainOpening(
    id: 'caro_kann',
    en: 'Caro-Kann Defence',
    ru: 'Защита Каро — Канн',
    kind: OpeningKind.defense,
    side: Side.black,
    origin: 'Horatio Caro & Marcus Kann, 1886',
    originRu: 'Горацио Каро и Маркус Канн, 1886',
    flag: '🇬🇧🇦🇹',
    lines: [
      TrainLine('Classical Variation', 'Классический вариант', [
        'e4', 'c6', 'd4', 'd5', 'Nc3', 'dxe4', 'Nxe4', 'Bf5', //
        'Ng3', 'Bg6', 'h4', 'h6', 'Nf3', 'Nd7',
      ]),
      TrainLine('Advance Variation', 'Вариант продвижения', [
        'e4',
        'c6',
        'd4',
        'd5',
        'e5',
        'Bf5',
        'Nf3',
        'e6',
        'Be2',
        'c5',
      ]),
      TrainLine('Exchange Variation', 'Разменный вариант', [
        'e4', 'c6', 'd4', 'd5', 'exd5', 'cxd5', 'Bd3', 'Nc6', //
        'c3', 'Nf6', 'Bf4', 'Bg4',
      ]),
    ],
  ),
  TrainOpening(
    id: 'kings_indian',
    en: 'King’s Indian Defence',
    ru: 'Староиндийская защита',
    kind: OpeningKind.defense,
    side: Side.black,
    origin: 'David Bronstein & Isaac Boleslavsky, 1940s',
    originRu: 'Давид Бронштейн и Исаак Болеславский, 1940-е',
    flag: '',
    lines: [
      TrainLine('Classical Variation', 'Классическая система', [
        'd4', 'Nf6', 'c4', 'g6', 'Nc3', 'Bg7', 'e4', 'd6', //
        'Nf3', 'O-O', 'Be2', 'e5', 'O-O', 'Nc6', 'd5', 'Ne7',
      ]),
      TrainLine('Sämisch Variation', 'Система Земиша', [
        'd4', 'Nf6', 'c4', 'g6', 'Nc3', 'Bg7', 'e4', 'd6', //
        'f3', 'O-O', 'Be3', 'e5',
      ]),
      TrainLine('Four Pawns Attack', 'Атака четырёх пешек', [
        'd4', 'Nf6', 'c4', 'g6', 'Nc3', 'Bg7', 'e4', 'd6', //
        'f4', 'O-O', 'Nf3', 'c5',
      ]),
    ],
  ),
  TrainOpening(
    id: 'scandinavian',
    en: 'Scandinavian Defence',
    ru: 'Скандинавская защита',
    kind: OpeningKind.defense,
    side: Side.black,
    origin: 'Ludvig & Gustaf Collijn, 1900s',
    originRu: 'Людвиг и Густав Коллийн, 1900-е',
    flag: '🇸🇪',
    lines: [
      TrainLine('Main line, 3...Qa5', 'Главный вариант, 3...Фa5', [
        'e4',
        'd5',
        'exd5',
        'Qxd5',
        'Nc3',
        'Qa5',
        'd4',
        'Nf6',
        'Nf3',
        'c6',
      ]),
      TrainLine('3...Qd6', '3...Фd6', [
        'e4',
        'd5',
        'exd5',
        'Qxd5',
        'Nc3',
        'Qd6',
        'd4',
        'Nf6',
        'Nf3',
        'a6',
      ]),
      TrainLine('Modern Variation, 2...Nf6', 'Современный вариант, 2...Кf6', [
        'e4',
        'd5',
        'exd5',
        'Nf6',
        'd4',
        'Nxd5',
        'Nf3',
        'g6',
      ]),
    ],
  ),
  TrainOpening(
    id: 'budapest',
    en: 'Budapest Gambit',
    ru: 'Будапештский гамбит',
    kind: OpeningKind.gambit,
    side: Side.black,
    origin: 'Budapest tournament, 1896',
    originRu: 'Будапештский турнир, 1896',
    flag: '🇭🇺',
    lines: [
      TrainLine('Rubinstein Variation, 4.Bf4', 'Вариант Рубинштейна, 4.Сf4', [
        'd4',
        'Nf6',
        'c4',
        'e5',
        'dxe5',
        'Ng4',
        'Bf4',
        'Nc6',
        'Nf3',
        'Bb4+',
      ]),
      TrainLine('Adler Variation, 4.Nf3', 'Вариант Адлера, 4.Кf3', [
        'd4',
        'Nf6',
        'c4',
        'e5',
        'dxe5',
        'Ng4',
        'Nf3',
        'Bc5',
        'e3',
        'Nc6',
      ]),
      TrainLine('Fajarowicz Variation', 'Вариант Фаяровича', [
        'd4',
        'Nf6',
        'c4',
        'e5',
        'dxe5',
        'Ne4',
        'Nf3',
        'Nc6',
        'a3',
        'd6',
      ]),
    ],
  ),
  TrainOpening(
    id: 'pirc',
    en: 'Pirc Defence',
    ru: 'Защита Пирца',
    kind: OpeningKind.defense,
    side: Side.black,
    origin: 'Vasja Pirc, 1940s',
    originRu: 'Васья Пирц, 1940-е',
    flag: '🇸🇮',
    lines: [
      TrainLine('Classical Variation', 'Классический вариант', [
        'e4', 'd6', 'd4', 'Nf6', 'Nc3', 'g6', 'Nf3', 'Bg7', //
        'Be2', 'O-O', 'O-O', 'c6',
      ]),
      TrainLine('Austrian Attack', 'Австрийская атака', [
        'e4',
        'd6',
        'd4',
        'Nf6',
        'Nc3',
        'g6',
        'f4',
        'Bg7',
        'Nf3',
        'O-O',
      ]),
      TrainLine('150 Attack', 'Атака «150»', [
        'e4',
        'd6',
        'd4',
        'Nf6',
        'Nc3',
        'g6',
        'Be3',
        'Bg7',
        'Qd2',
        'c6',
      ]),
    ],
  ),
  TrainOpening(
    id: 'dutch',
    en: 'Dutch Defence',
    ru: 'Голландская защита',
    kind: OpeningKind.defense,
    side: Side.black,
    origin: 'Elias Stein, 1789',
    originRu: 'Элиас Стейн, 1789',
    flag: '🇳🇱',
    lines: [
      TrainLine('Leningrad Variation', 'Ленинградский вариант', [
        'd4', 'f5', 'g3', 'Nf6', 'Bg2', 'g6', 'Nf3', 'Bg7', //
        'O-O', 'O-O', 'c4', 'd6',
      ]),
      TrainLine('Stonewall', 'Каменная стена', [
        'd4', 'f5', 'c4', 'Nf6', 'g3', 'e6', 'Bg2', 'd5', //
        'Nf3', 'c6', 'O-O', 'Bd6',
      ]),
      TrainLine('Classical Variation', 'Классический вариант', [
        'd4', 'f5', 'c4', 'Nf6', 'g3', 'e6', 'Bg2', 'Be7', //
        'Nf3', 'O-O', 'O-O', 'd6',
      ]),
    ],
  ),
  TrainOpening(
    id: 'nimzo',
    en: 'Nimzo-Indian Defence',
    ru: 'Защита Нимцовича',
    kind: OpeningKind.defense,
    side: Side.black,
    origin: 'Aron Nimzowitsch, 1910s',
    originRu: 'Арон Нимцович, 1910-е',
    flag: '🇱🇻',
    lines: [
      TrainLine('Rubinstein Variation, 4.e3', 'Вариант Рубинштейна, 4.e3', [
        'd4', 'Nf6', 'c4', 'e6', 'Nc3', 'Bb4', 'e3', 'O-O', //
        'Bd3', 'd5', 'Nf3', 'c5', 'O-O',
      ]),
      TrainLine('Classical Variation, 4.Qc2', 'Классический вариант, 4.Фc2', [
        'd4', 'Nf6', 'c4', 'e6', 'Nc3', 'Bb4', 'Qc2', 'O-O', //
        'a3', 'Bxc3+', 'Qxc3', 'd5',
      ]),
      TrainLine('Sämisch Variation, 4.a3', 'Вариант Земиша, 4.a3', [
        'd4', 'Nf6', 'c4', 'e6', 'Nc3', 'Bb4', 'a3', 'Bxc3+', //
        'bxc3', 'c5', 'e3', 'Nc6',
      ]),
    ],
  ),
];
