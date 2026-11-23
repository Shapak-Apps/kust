# Küşt — full audit and improvement plan (planning only)

You are a principal mobile engineer, chess-software expert and product designer. You are auditing **Küşt**, a production Flutter chess app, and your job is to produce a **complete, prioritized, executable plan**. **Do not change any code, do not create branches, issues or PRs, do not run builds that modify files.** Read, run read-only commands (analyze, tests), and write the plan. Another model will execute your plan later, task by task, so every task must be self-contained and precise.

## The project

- Repo: `/home/merdan/projects/kust`, GitHub `Shapak-Apps/kust`, branches `dev` (work) and `main` (released). App version 3.0.0+6.
- Flutter 3.47 / Dart 3.13, Android and iOS, portrait only, dark-only UI (`AppSettings.forceDark = true`; the light theme code still exists).
- State: Riverpod (`ChessController` Notifier, `chessControllerProvider`), routing: go_router, storage: Hive CE + SharedPreferences, chess rules: `dartchess` (owns legality, FEN, PGN), engine: Stockfish over UCI (`lib/features/game/chess/chess_engine.dart`), stops when the app is hidden. Sounds: audioplayers. SVG: flutter_svg.
- Localization: gen-l10n, ARB files `lib/l10n/app_{en,ru,tk}.arb`, `AppL10n`, `context.t`. Turkmen strings that need a native check are listed in `l10n/REVIEW_tk.md`. Turkmen glossary decisions: a piece is "çöp", checkmate "Şahmat", chess "küşt", always polite "siz".
- Main areas:
  - Play: home (`lib/features/play/`), bots with personalities and chat (`bots.dart`, `bot_voice.dart`, `bot_quote.dart`, `bot_policy.dart` for human-like strength and thinking time), pass and play, clocks, premoves, practice mode with move ratings, hints, undo, show best, end-of-game animation, result dialog.
  - Game review (`lib/features/review/`) and history/replay (`lib/features/history/`), accuracy, export (PNG/FEN/PGN).
  - Puzzles: carpet "loom" map, levels, daily puzzle, coach (`lib/features/puzzles/`).
  - Learn: garden map with isometric tiles (`lib/features/learn/garden_map.dart`), 11 lessons with tasks (`lessons.dart`, `lesson_task.dart`), lesson screen with coach, stars, progress (`learn_progress.dart`), 3D ivory piece SVGs in `assets/pieces/learn/`.
  - Onboarding (`lib/features/onboarding/`), achievements, settings sheet (`lib/widgets/more_sheet.dart`), shell and Spotify-style bottom bar (`lib/widgets/app_shell.dart`, `lib/ui/kust_nav_bar.dart`), UI kit in `lib/ui/` (tokens, KustButton, KustButton3D, KustOption, sheets, top bar).
- Tests: ~365 in `test/`. Run `flutter analyze` and `flutter test` (read-only; they must not modify tracked files).
- Team workflow the executor must follow: every change = a GitHub issue, a branch off `dev`, a PR into `dev` with "Closes #N"; releases are a PR `dev` → `main`. Never commit `assets/engine/*.gz`. Tests and analyze must stay green.

## What to do

1. **Map the codebase.** Read the structure and the key files above. Note size hot spots (very long files such as `chess_controller.dart`, `game_screen.dart`) and how state flows between the engine, the controller and the board.
2. **Run** `flutter analyze` and `flutter test` and record the results.
3. **Audit across every dimension below.** For each finding, verify it in the code (cite `file:line`), and say how it shows up for a user. Do not report guesses as facts; mark anything unverified as "suspected" and say how to confirm it.

### Audit dimensions

**A. Correctness and chess rules**
- Move legality, castling (including "castle on rook" setting), en passant, promotion (auto-queen vs choice), check/checkmate/stalemate, threefold repetition, fifty-move rule, insufficient material, draw on time with insufficient material, flag fall, resign/abort in bot and pass-and-play games, undo/takeback interactions with clocks, premoves and bot thinking.
- Result recording: history, PGN result tokens, ratings, accuracy, achievements — are all consistent for every way a game can end?
- Race conditions: engine replies arriving after undo/new game/leave, stale analysis results, timers firing after dispose, app backgrounding mid-search.

**B. Engine and performance**
- UI thread work during engine searches, board drag, animations, and scrolling (Learn garden map, Puzzles carpet, history list, review graph).
- Repaint boundaries, `CustomPainter.shouldRepaint`, image `cacheWidth`, raster cache use, blur/backdrop cost, startup time (asset loading, NNUE, Hive boxes), memory (piece SVGs, bot images).
- Target: steady 60 fps on a mid-range Android (Galaxy A57 class). List concrete measurement steps (`flutter run --profile`, DevTools timeline, `--trace-skia`), and for each suspected hot spot a specific fix.

**C. Product gaps and features**
- What a chess learner expects that is missing or weak: e.g. more lessons (tactics: forks, pins, skewers; opening principles; basic endgames), spaced practice of own mistakes, opening names, game review depth (best line, "retry this move"), puzzle variety, streaks/goals, notifications, online play readiness, cloud backup.
- Rank by impact for a beginner-to-intermediate audience in Turkmenistan and CIS, and by effort.

**D. UI/UX and design consistency**
- Consistency of the new design language (green 3D buttons `KustButton3D`, 3D ivory pieces, coach Bahar with speech bubbles, garden map) across Play, Puzzles, Review, History, Settings, sheets and dialogs. List screens that still use the old style and should be migrated.
- Typography, spacing, tap targets (≥48 px), text overflow in Russian and Turkmen on a 360 px wide phone, safe areas, empty states, loading and error states, haptics and sounds.
- Accessibility: semantics labels, contrast on dark surfaces, reduce-motion support, font scaling up to 1.3×.

**E. Localization**
- Missing or English-only strings, hard-coded text in widgets, ARB parity, plural forms, Turkmen terms against the glossary, strings in `l10n/REVIEW_tk.md` still unreviewed.

**F. Code health and architecture**
- Oversized files and classes to split (with a proposed split), duplicated widgets/painters (e.g. isometric tile painting in both `garden_map.dart` and onboarding), dead code, inconsistent naming, magic numbers that should be tokens, missing tests for critical logic (game end paths, bot policy, lesson tasks, review analysis).

**G. Reliability, data and release readiness**
- Hive migrations and corrupted-data handling, SharedPreferences keys, crash reporting (none yet?), logging, Play Store readiness (signing, app bundle, privacy policy, data safety, content rating, store listing in en/ru/tk), iOS readiness, app size.

## Output format (strictly)

Write the plan as one Markdown document with these sections:

1. **Summary** — 10 lines max: overall health, top 5 risks, top 5 opportunities.
2. **Analyze and test results** — what you ran and what it said.
3. **Findings** — a table per dimension (A–G): ID (e.g. A3), severity (critical / high / medium / low), evidence (`file:line`), user impact, confidence (verified / suspected).
4. **Execution plan** — ordered phases (Phase 1: critical fixes, Phase 2: performance, Phase 3: UX consistency, Phase 4: features, Phase 5: code health, Phase 6: release readiness). Each phase contains tasks. **Each task must have:**
   - ID and title (short imperative, matching a future GitHub issue title)
   - Finding IDs it resolves
   - Why it matters (1–2 lines)
   - Exact files to change and what to change in each (concrete enough that another model can implement without re-discovering it)
   - New strings needed in en/ru/tk (Turkmen marked "to review")
   - Tests to add or update (named test files and what each test asserts)
   - Acceptance criteria (observable, checkable)
   - Risk and how to verify on a device
   - Size estimate (S ≤ 1h, M ≤ half a day, L ≤ 2 days) and dependencies on other tasks
   - Tasks must be small enough to be one PR each.
5. **Do not do** — tempting changes that would hurt (e.g. heavy shader packages for blur, rewriting the engine wrapper without a measured problem).
6. **Open questions for the owner** — only decisions that truly need a human (product direction, paid services, store accounts).

Be specific and skeptical. Prefer fewer, high-value, verified tasks over a long list of generic advice. Do not write generic Flutter tips that are not tied to this codebase. Plan only — no code changes.
