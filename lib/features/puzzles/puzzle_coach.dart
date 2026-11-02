import 'package:kust/l10n/app_locale.dart';

/// What the coach is reacting to.
enum CoachMood { thinking, mistake, solved, revealed }

/// A sum of the id's characters, steady between runs, so a puzzle gets the
/// same wording every time it is opened.
int coachSeed(String puzzleId) =>
    puzzleId.codeUnits.fold(0, (sum, unit) => sum + unit);

/// The second line of the coach's bubble. It depends on the puzzle's theme
/// and on [mood]; [seed] picks one of several lines, and a mistake count can
/// be added to it so repeated mistakes get different words.
String coachTip({
  required CoachMood mood,
  required String theme,
  required int seed,
  AppL10n? t,
}) {
  t ??= AppText.now;
  // Each message holds its lines, one per row.
  final lines = switch (mood) {
    CoachMood.thinking => switch (theme) {
      'mateIn1' => t.coachMateIn1,
      'mateIn2' => t.coachMateIn2,
      'mateIn3' => t.coachMateIn3,
      'fork' => t.coachFork,
      'pin' => t.coachPin,
      'endgame' => t.coachEndgame,
      _ => t.coachGeneric,
    },
    CoachMood.mistake => t.coachWrong,
    CoachMood.solved => t.coachCorrect,
    CoachMood.revealed => t.coachRetry,
  }.split('\n');
  return lines[seed.abs() % lines.length];
}

/// Height of the person standing on the board, in the puzzle screen.
const double coachFigureHeight = 100;

/// Height of the fixed slot above the board that holds the coach and its
/// bubble.
///
/// The bubble is a title line and up to two lines of tip: about 64 px of text
/// at normal size, plus 21 px of padding and 14 px of gap above the board. The
/// text grows with the system text size, so the slot grows with it once the
/// bubble is taller than the person. It stays fixed while the words change, so
/// the board never moves.
double coachSlotHeight(double textScale) {
  final bubble = 64 * textScale.clamp(1.0, 2.0).toDouble() + 21 + 14;
  return bubble > coachFigureHeight ? bubble : coachFigureHeight;
}
