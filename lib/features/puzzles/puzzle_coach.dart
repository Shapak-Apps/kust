/// What the coach is reacting to.
enum CoachMood { thinking, mistake, solved, revealed }

/// A sum of the id's characters, steady between runs, so a puzzle gets the
/// same wording every time it is opened.
int coachSeed(String puzzleId) =>
    puzzleId.codeUnits.fold(0, (sum, unit) => sum + unit);

const Map<String, List<String>> _thinking = {
  'mateIn1': [
    'One move ends the game. Can you see it?',
    'Find the move that mates right now.',
    'The king has no way out. Close the door!',
  ],
  'mateIn2': [
    'Can you force mate in two moves?',
    'Start with a check or a strong threat.',
    'Two moves to mate. Which one comes first?',
  ],
  'mateIn3': [
    'Mate in three. Think forcing moves.',
    'Checks first, then see where the king goes.',
  ],
  'fork': [
    'Find a move that attacks two pieces at once.',
    'Can you spot a fork?',
    'One piece, two targets. Where does it land?',
  ],
  'pin': [
    'A piece cannot move. Can you use that?',
    'Look for a pinned piece and pile on.',
    'What is stuck in front of its king?',
  ],
  'endgame': [
    'Few pieces, big ideas. Take your time.',
    'In the endgame your king is a fighter.',
    'Careful moves win this one.',
  ],
};

const List<String> _thinkingOther = [
  'Look for checks, captures and threats first.',
  'What is hanging? Take your time.',
  'The best move is usually forcing.',
];

const List<String> _mistake = [
  'Close, but not quite. Try another move.',
  'Not this one. Think about checks and captures.',
  'Hmm, look again. You can do this!',
  'That lets them off. What else is there?',
];

const List<String> _solved = [
  'Nice work! On to the next one.',
  'You saw it. Well played!',
  'Sharp eyes. That was clean.',
  'Another knot woven. Keep going!',
];

const List<String> _revealed = [
  'Study it, then try it yourself.',
  'Now you know. Hit Retry!',
  'Watch how the pieces work together.',
];

/// The second line of the coach's bubble. It depends on the puzzle's theme
/// and on [mood]; [seed] picks one of several lines, and a mistake count can
/// be added to it so repeated mistakes get different words.
String coachTip({
  required CoachMood mood,
  required String theme,
  required int seed,
}) {
  final lines = switch (mood) {
    CoachMood.thinking => _thinking[theme] ?? _thinkingOther,
    CoachMood.mistake => _mistake,
    CoachMood.solved => _solved,
    CoachMood.revealed => _revealed,
  };
  return lines[seed.abs() % lines.length];
}
