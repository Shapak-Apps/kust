import 'package:kust/l10n/app_locale.dart';

/// The name shown for a puzzle's theme tag, e.g. `mateIn2` becomes "Mate in 2".
String puzzleThemeLabel(String theme, [AppL10n? t]) {
  t ??= AppText.now;
  if (theme.startsWith('mateIn')) {
    final n = int.tryParse(theme.substring('mateIn'.length));
    if (n != null) return t.themeMateIn(n);
  }
  return switch (theme) {
    'fork' => t.themeFork,
    'pin' => t.themePin,
    'endgame' => t.themeEndgame,
    _ => t.themeWinMaterial,
  };
}
