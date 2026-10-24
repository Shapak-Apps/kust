/// The name shown for a puzzle's theme tag, e.g. `mateIn2` becomes "Mate in 2".
String puzzleThemeLabel(String theme) {
  if (theme.startsWith('mateIn')) {
    return 'Mate in ${theme.substring('mateIn'.length)}';
  }
  return switch (theme) {
    'fork' => 'Fork',
    'pin' => 'Pin',
    'endgame' => 'Endgame',
    _ => 'Win material',
  };
}
