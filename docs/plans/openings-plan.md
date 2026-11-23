# Book moves and opening names

Goal: like chess.com, mark opening theory moves as **Book** in the game review and show the **opening name** ("Sicilian Defense: Najdorf Variation"). English UI shows English names; Russian and Turkmen UI show Russian names.

## Data

- Source: [lichess-org/chess-openings](https://github.com/lichess-org/chess-openings), CC0 (no attribution needed), five TSV files: 3,690 openings, 149 families, ~2,100 distinct variation parts, longest line 54 plies.
- New tool `tools/openings/build_openings.py` (same style as `tools/build_puzzles.py`): replays each PGN and writes `assets/openings/openings.tsv` with one row per opening: `position key \t ECO \t English name \t Russian name`. About 300 KB, plain text, no new Dart dependency.
- Position key: board, side to move and castling rights (the first three FEN fields). The en passant field is left out because python-chess and dartchess write it differently; collisions from that are practically impossible in openings.
- Lookup is by position, not by move order, so transpositions find their name (as chess.com does).

## Russian names

- No open Russian dataset exists, so we translate the parts once: `tools/openings/ru_names.tsv`, a map from English part to Russian part ("Sicilian Defense" → "Сицилианская защита", "Najdorf Variation" → "Вариант Найдорфа").
- First pass: all 149 families plus the ~430 variation parts that appear 3+ times. That covers most games people actually play.
- No mixed languages: if a variation part has no Russian yet, the name stops at the deepest fully translated part ("Сицилианская защита" instead of "Сицилианская защита: Najdorf…").
- The build tool prints how many names are fully translated, so we can fill gaps later.
- Language rule: `en` → English names; `ru` and `tk` → Russian names.

## App code

1. `lib/features/game/chess/openings.dart`: loads the asset once, lazily, into a `Map<String, Opening>`. `Opening? openingAt(Position)`, and `String name(AppL10n)` that picks English or Russian.
2. **Book quality**: add `MoveQuality.book` (chess.com's brown, `0xFFA88865`, a new `assets/icons/moves/book.svg`, label strings `qBook`). In `reviewGame`, a move is Book while every move so far, including this one, lands in a known opening position. The engine still analyses it, so accuracy numbers do not change.
3. Every place that switches on `MoveQuality` (`move_feedback.dart`, `chess_controller.dart` live badge, `replay_screen.dart`, the review counts table in `review_screen.dart`, the analyzer tests) gets the new value. Book counts as a good move and never as a mistake to retry.
4. **Opening name in the UI**: the review screen (under the accuracy summary) and the replay screen show the name of the last known position in the game. It is computed from the moves on the fly, so nothing new is stored and old games get names too.

Not doing: an opening explorer, win/draw stats per move, ECO codes on screen, names during a live game.

## Tests

- Lookup: 1.e4 e5 2.Nf3 Nc6 3.Bb5 → "Ruy Lopez" / "Испанская партия"; a transposed move order finds the same name.
- Review: the first moves of a known line are Book; the first move out of theory is rated by the engine as before.
- Turkmen UI shows the Russian name; a part without a translation falls back to the family.
- Build tool: a small Python test next to `tools/test_build_puzzles.py`.

## Shipping (each an issue → branch → PR into dev)

1. Data, build tool and `openings.dart` lookup with tests.
2. `MoveQuality.book` in the review and replay screens.
3. Opening name on the review and replay screens.
4. Russian translations of families and common variations (I draft them, a Russian reader checks them).

## Questions

- Turkmen label for the Book badge: "Teoriýa" (theory) or "Kitap" (book)? Default: "Teoriýa".
- Should the opening name also show during a live game, under the board? Default: no, review and replay only.
