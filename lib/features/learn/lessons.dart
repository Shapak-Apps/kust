import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/features/learn/lesson_task.dart';
import 'package:kust/l10n/app_locale.dart';

/// One lesson: a short introduction and a few tasks on the board.
class Lesson {
  const Lesson({
    required this.id,
    required this.icon,
    required this.tasks,
    this.piece,
  });

  /// Stable name, saved with the progress.
  final String id;
  final IconData icon;
  final List<LessonTask> tasks;

  /// The piece the lesson is about, shown in its header.
  final Role? piece;

  String title(AppL10n t) => switch (id) {
    'pawn' => t.lessonPawnTitle,
    'rook' => t.lessonRookTitle,
    'bishop' => t.lessonBishopTitle,
    'queen' => t.lessonQueenTitle,
    'knight' => t.lessonKnightTitle,
    'king' => t.lessonKingTitle,
    'values' => t.lessonValuesTitle,
    'check' => t.lessonCheckTitle,
    'special' => t.lessonSpecialTitle,
    'mate' => t.lessonMateTitle,
    _ => t.lessonFirstMatesTitle,
  };

  String intro(AppL10n t) => switch (id) {
    'pawn' => t.lessonPawnIntro,
    'rook' => t.lessonRookIntro,
    'bishop' => t.lessonBishopIntro,
    'queen' => t.lessonQueenIntro,
    'knight' => t.lessonKnightIntro,
    'king' => t.lessonKingIntro,
    'values' => t.lessonValuesIntro,
    'check' => t.lessonCheckIntro,
    'special' => t.lessonSpecialIntro,
    'mate' => t.lessonMateIntro,
    _ => t.lessonFirstMatesIntro,
  };
}

String pieceName(AppL10n t, Role role) => switch (role) {
  Role.king => t.pieceKing,
  Role.queen => t.pieceQueen,
  Role.rook => t.pieceRook,
  Role.bishop => t.pieceBishop,
  Role.knight => t.pieceKnight,
  Role.pawn => t.piecePawn,
};

/// The prompt of [task], in the language in use.
String taskPrompt(AppL10n t, LessonTask task) => switch (task.kind) {
  TaskKind.collect =>
    task.targets.length == 1
        ? t.taskCollectOne(pieceName(t, task.piece ?? Role.pawn))
        : t.taskCollectMany(pieceName(t, task.piece ?? Role.pawn)),
  TaskKind.capture => t.taskCapture,
  TaskKind.bestCapture => t.taskBestCapture,
  TaskKind.check => t.taskCheck,
  TaskKind.mate => t.taskMate,
  TaskKind.escape => t.taskEscape,
  TaskKind.escapeCapture => t.taskEscapeCapture,
  TaskKind.castleKing => t.taskCastleKing,
  TaskKind.castleQueen => t.taskCastleQueen,
  TaskKind.enPassant => t.taskEnPassant,
  TaskKind.promote => t.taskPromote,
};

Set<Square> _sq(String names) => {
  for (final n in names.split(' ')) Square.fromName(n),
};

/// The lessons, from the first pawn move to simple checkmates. White always
/// plays, from the bottom of the board.
final List<Lesson> kLessons = [
  Lesson(
    id: 'pawn',
    icon: Icons.person_outline_rounded,
    piece: Role.pawn,
    tasks: [
      LessonTask(
        fen: '7k/8/8/8/8/8/4P3/K7 w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.pawn,
        targets: _sq('e4'),
      ),
      LessonTask(
        fen: '7k/8/8/8/3P4/8/8/K7 w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.pawn,
        targets: _sq('d6'),
      ),
      LessonTask(
        fen: '7k/8/8/2p5/3P4/8/8/K7 w - - 0 1',
        kind: TaskKind.capture,
        targets: _sq('c5'),
      ),
      LessonTask(
        fen: '7k/8/8/3pp3/3P4/8/8/K7 w - - 0 1',
        kind: TaskKind.bestCapture,
        targets: _sq('e5'),
      ),
    ],
  ),
  Lesson(
    id: 'rook',
    icon: Icons.castle_outlined,
    piece: Role.rook,
    tasks: [
      LessonTask(
        fen: '7k/8/8/8/8/8/8/R6K w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.rook,
        targets: _sq('a6'),
      ),
      LessonTask(
        fen: '7k/8/8/8/8/8/8/R6K w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.rook,
        targets: _sq('a5 e5'),
      ),
      LessonTask(
        fen: '7k/8/8/p3p3/8/8/8/R6K w - - 0 1',
        kind: TaskKind.capture,
        targets: _sq('a5 e5'),
      ),
    ],
  ),
  Lesson(
    id: 'bishop',
    icon: Icons.change_history_rounded,
    piece: Role.bishop,
    tasks: [
      LessonTask(
        fen: '7k/8/8/8/8/8/8/2B4K w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.bishop,
        targets: _sq('g5'),
      ),
      LessonTask(
        fen: '7k/8/8/8/8/8/8/2B4K w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.bishop,
        targets: _sq('g5 e7'),
      ),
      LessonTask(
        fen: '7k/4p3/8/6p1/8/8/8/2B4K w - - 0 1',
        kind: TaskKind.capture,
        targets: _sq('g5 e7'),
      ),
    ],
  ),
  Lesson(
    id: 'queen',
    icon: Icons.workspace_premium_outlined,
    piece: Role.queen,
    tasks: [
      LessonTask(
        fen: '7k/8/8/8/8/8/8/K2Q4 w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.queen,
        targets: _sq('d5'),
      ),
      LessonTask(
        fen: '7k/8/8/8/8/8/8/K2Q4 w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.queen,
        targets: _sq('d5 g5'),
      ),
      LessonTask(
        fen: '8/7k/8/8/3p2p1/8/8/K2Q4 w - - 0 1',
        kind: TaskKind.capture,
        targets: _sq('d4 g4'),
      ),
    ],
  ),
  Lesson(
    id: 'knight',
    icon: Icons.bolt_rounded,
    piece: Role.knight,
    tasks: [
      LessonTask(
        fen: '7k/8/8/8/8/8/8/K5N1 w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.knight,
        targets: _sq('f3 d4'),
      ),
      LessonTask(
        fen: '7k/8/8/8/8/PPP5/PNP5/K7 w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.knight,
        targets: _sq('d3'),
      ),
      LessonTask(
        fen: '7k/8/8/4p3/8/5p2/8/K5N1 w - - 0 1',
        kind: TaskKind.capture,
        targets: _sq('f3 e5'),
      ),
    ],
  ),
  Lesson(
    id: 'king',
    icon: Icons.shield_outlined,
    piece: Role.king,
    tasks: [
      LessonTask(
        fen: '7k/8/8/8/8/8/8/4K3 w - - 0 1',
        kind: TaskKind.collect,
        piece: Role.king,
        targets: _sq('e2 d3 c4'),
      ),
      LessonTask(
        fen: '7k/8/8/8/8/8/4p3/4K3 w - - 0 1',
        kind: TaskKind.capture,
        targets: _sq('e2'),
      ),
    ],
  ),
  Lesson(
    id: 'values',
    icon: Icons.balance_rounded,
    tasks: [
      LessonTask(
        fen: '7k/8/4p3/5q2/3N4/8/8/K7 w - - 0 1',
        kind: TaskKind.bestCapture,
        targets: _sq('f5'),
      ),
      LessonTask(
        fen: '7k/4q3/8/8/8/8/8/1n2R1K1 w - - 0 1',
        kind: TaskKind.bestCapture,
        targets: _sq('e7'),
      ),
    ],
  ),
  Lesson(
    id: 'check',
    icon: Icons.warning_amber_rounded,
    tasks: [
      LessonTask(fen: '4k3/8/8/8/8/8/8/R3K3 w - - 0 1', kind: TaskKind.check),
      LessonTask(fen: '4r2k/8/8/8/8/8/8/4K3 w - - 0 1', kind: TaskKind.escape),
      LessonTask(
        fen: '7k/8/8/8/8/5n2/6P1/4K3 w - - 0 1',
        kind: TaskKind.escapeCapture,
        targets: _sq('f3'),
      ),
    ],
  ),
  Lesson(
    id: 'special',
    icon: Icons.auto_awesome_outlined,
    tasks: [
      LessonTask(
        fen: '4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1',
        kind: TaskKind.castleKing,
      ),
      LessonTask(
        fen: '4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1',
        kind: TaskKind.castleQueen,
      ),
      LessonTask(
        fen: '7k/8/8/3pP3/8/8/8/K7 w - d6 0 1',
        kind: TaskKind.enPassant,
        targets: _sq('d6'),
      ),
      LessonTask(fen: '7k/4P3/8/8/8/8/8/K7 w - - 0 1', kind: TaskKind.promote),
    ],
  ),
  Lesson(
    id: 'mate',
    icon: Icons.flag_outlined,
    tasks: [
      LessonTask(fen: '7k/8/6K1/8/8/8/8/R7 w - - 0 1', kind: TaskKind.mate),
      LessonTask(fen: '7k/8/6K1/8/8/8/8/2Q5 w - - 0 1', kind: TaskKind.mate),
    ],
  ),
  Lesson(
    id: 'firstMates',
    icon: Icons.emoji_events_outlined,
    tasks: [
      LessonTask(fen: '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1', kind: TaskKind.mate),
      LessonTask(fen: '7k/R7/8/8/8/8/8/1R5K w - - 0 1', kind: TaskKind.mate),
      LessonTask(fen: '7k/8/6K1/8/8/8/8/2Q5 w - - 0 1', kind: TaskKind.mate),
    ],
  ),
];

/// A stage of the climb: a run of lessons on one theme.
class Camp {
  const Camp({required this.id, required this.first, required this.last});

  final String id;

  /// Indexes in [kLessons], both included.
  final int first;
  final int last;

  int get length => last - first + 1;

  bool get isSummit => id == 'mate';

  String title(AppL10n t) => switch (id) {
    'pieces' => t.campPiecesTitle,
    'rules' => t.campRulesTitle,
    _ => t.campMateTitle,
  };

  String subtitle(AppL10n t) => switch (id) {
    'pieces' => t.campPiecesSub,
    'rules' => t.campRulesSub,
    _ => t.campMateSub,
  };

  /// "CAMP 1", "CAMP 2", then "SUMMIT".
  String label(AppL10n t) =>
      isSummit ? t.summitLabel : t.campLabel(kCamps.indexOf(this) + 1);

  static Camp of(int lessonIndex) =>
      kCamps.firstWhere((c) => lessonIndex >= c.first && lessonIndex <= c.last);
}

const List<Camp> kCamps = [
  Camp(id: 'pieces', first: 0, last: 5),
  Camp(id: 'rules', first: 6, last: 8),
  Camp(id: 'mate', first: 9, last: 10),
];

/// The turned-ivory 3D picture of a piece, as used on the Learn map and in
/// the lessons. 100 wide and 135 tall.
String learnPieceAsset(Role role) => switch (role) {
  Role.pawn => 'assets/pieces/learn/P.svg',
  Role.rook => 'assets/pieces/learn/R.svg',
  Role.knight => 'assets/pieces/learn/N.svg',
  Role.bishop => 'assets/pieces/learn/B.svg',
  Role.queen => 'assets/pieces/learn/Q.svg',
  Role.king => 'assets/pieces/learn/K.svg',
};

/// A 3D piece standing [height] tall.
class LearnPiece extends StatelessWidget {
  const LearnPiece(this.role, {super.key, required this.height});

  final Role role;
  final double height;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    learnPieceAsset(role),
    height: height,
    width: height * 100 / 135,
  );
}
