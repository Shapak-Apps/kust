# UI polish plan: make Küşt feel like Chess.com / TakeTakeTake

Source: a Gemini teardown of screen recordings of both apps (2026-11-25), checked
against our code. **No new features.** Only how existing things look, move and
respond. Written by Opus for Sonnet to execute.

## Ground rules (read first)

- **Workflow per phase:** one GitHub issue → branch off `dev` → PR into `dev`
  with `Closes #N` → squash-merge → close the issue. After each phase, open a
  `dev` → `main` PR and merge it with a **merge commit** (keep `dev`).
  Repo: `Shapak-Apps/kust`.
- **Smallest complete change** (ponytail). Change shared widgets in `lib/ui/`
  first so every screen picks the change up. Don't restyle screen by screen
  what a shared widget can carry.
- **Never run device builds.** The user runs `flutter run` and presses `R`.
  Check with `dart analyze lib` and `flutter test -j 1 <dirs>` (the PC has 5 GB
  of RAM; never run the whole suite in one go). Tests that pin old sizes or
  colours get updated to the new values, not deleted.
- **Copy the feel, not the brand.** Do not use Chess.com's green `#81B64C`,
  TakeTakeTake's purple `#5E35FF`, their logos, piece sets, board textures or
  sounds. Küşt keeps its gold `KustTokens.gold` (`#FFBB00`), its own green 3D
  button, its own boards and pieces. We take sizes, spacing, timings, motion
  and feedback.
- Respect reduced motion: wrap every new duration in `motion(context, …)`
  (`lib/ui/motion.dart`).
- Commit trailer: `Co-Authored-By: Claude <noreply@anthropic.com>` (or the
  attribution the session gives). PR body ends with the Claude Code line.
- New user-facing strings go into en/ru/tk `.arb`. Run `flutter gen-l10n`. Add
  the Turkmen drafts to `l10n/REVIEW_tk.md`.

## What we already match (leave alone)

- The board is edge to edge. Coordinates are inside the squares. The legal-move
  dot is ≈14 px at 18% black and captures are rings, which matches both apps.
- Tab switches are already instant. Pressing a 3D button already sinks it onto
  its lip (`KustButton3D`, 70 ms).
- Dark surfaces are warm and not pure black (`#1C1A18`), in the same family as
  Chess.com.

---

## Phase 1: Tokens (one PR; everything else builds on it)

File: `lib/ui/tokens.dart`.

1. **Surfaces: three clear layers in dark** (Chess.com has page `#302E2B`, card
   `#262522`, raised `#3D3B38`; TTT has page `#121214`, card `#1E1E22`, chip
   `#2A2A30`). Ours are too close together (`bg #1C1A18`, `surface #221F1C`,
   `surfaceAlt #2A2724`), so cards barely separate from the page. Change dark to:
   - `bg` `#1C1A18` (unchanged)
   - `surface` `#262320` (cards, rows in a container, sheets)
   - `surfaceAlt` `#34302C` (chips, secondary buttons, selected pills, inputs)
   - `line` `#332F2B` (1 px hairlines between rows)
   - `muted` `#A09D97` (secondary text needs more contrast; the teardown's
     secondary greys are `#A09E9A` / `#A0A0A8`)

   Light theme: leave it, or nudge `surfaceAlt` so it stays distinct. Check it
   by eye in the light-theme tests only.
2. **Type scale.** Keep the four existing getters and add the ones both apps
   use:
   - `section` 17/700, letterSpacing −0.2 (section headers: "Friends",
     "Game history")
   - `rowTitle` 15/600 (list-row names)
   - `number` = `rowTitle` with `fontFeatures: [FontFeature.tabularFigures()]`
     (ratings, clocks, counters, so digits don't jitter)

   `caption` stays 12, but weight 500 for meta lines. Add `captionStrong` 12/600
   if something needs the old one.
3. **Radii.** Add `KustSpace.rCard = 12` (both apps use 10–14). Make `rSheet` 20
   (TTT sheets have 20 at the top; ours is 28). Keep `rSmall` 12 and `rMedium` 16
   for anything that isn't a card.
4. Add `KustSpace.row = 56` (standard list-row height) and
   `KustSpace.topBar = 52`.

Done when: `dart analyze` is clean, `test/ui`, `test/ui_kit_test.dart` and
`test/board_theme_test.dart` pass, and the token names are documented in
comments.

## Phase 2: Shared components (one PR)

All under `lib/ui/`. Each item says the target values.

1. **`KustTopBar`** (pushed screens, not `large`):
   - Height 52. The back button sits at the left edge.
   - **Title left-aligned**, 16 px after the back icon, 18/700. The optional
     subtitle goes under it at 12/500 muted. Chess.com does this on every pushed
     screen; centred titles are what makes ours look like a template.
   - Trailing icons are 22 px with an 8 px gap.
   - Long titles: use the same `FittedBox(scaleDown)` trick as `FeltHeader`.
   - Check the screens that pass `brand:` still centre it.
2. **`KustButton3D`:** radius 16 → 12, lip 4 px (check the current value; keep
   4), default height 52 → 50, label 17/700. Press: sink the lip fully in 70 ms
   on pointer down, spring back in 120 ms `easeOutBack` on up. The disabled
   state keeps the lip, but greyed.
3. **`KustButton` secondary/outline:** height 48 (`expand` ones 50 to match the
   3D button when they are stacked), radius 12, fill `surfaceAlt`, label
   15/700.
4. **Row press feedback, the single biggest "feel" item.** Add
   `lib/ui/press_highlight.dart`, a `PressHighlight` widget:
   - On pointer **down**: an instant `Colors.white` overlay at 6% (dark) / black
     4% (light).
   - On up/cancel: fade out over 120 ms.
   - No scale. Rows don't shrink in either app.

   Use it for list rows and cards instead of `Pressable`'s 0.97 scale: history
   rows, friend rows, player rows, chat rows, settings rows, notifications,
   `KustTile`. Keep `Pressable` for buttons and icons.
5. **`KustTile`:** height 72 → 64, radius `rCard`, icon box 44 → 40, title
   `rowTitle`.
6. **Sheets (`kust_sheet.dart`):** open 300 → 240 ms `easeOutCubic`, close
   220 → 180 ms `easeInCubic`, top radius `rSheet` (20). The grabber stays
   (36×4).
7. **Dialogs:** wherever `showDialog` is used for small cards (the game-start
   card in `game_result_dialog.dart`, confirmations), animate scale 0.94 → 1
   plus fade in 200 ms `easeOutCubic`. Add `showKustDialog()` in `lib/ui/` and
   switch the callers.
8. **Page transitions (`lib/theme.dart`):** on Android/Linux/Windows, replace
   `CupertinoPageTransitionsBuilder` with a custom builder:
   - The new page slides in from 100% → 0 over **280 ms `easeOutCubic`**.
   - The page underneath shifts 0 → −20% and dims 8%.
   - Pop: 220 ms `easeInCubic`.

   Keep Cupertino on iOS/macOS for the swipe-back gesture. (Cupertino's default
   is ≈400 ms with a heavy parallax, which feels slow next to Chess.com's
   ≈250–300 ms.)
9. **Loading, the next biggest "feel" item.** Neither app ever shows a bare
   spinner on an empty page. We have 16 `CircularProgressIndicator`s.
   - Add `lib/ui/skeleton.dart`:
     - `KustSkeleton` is a rounded rect in `surfaceAlt` on `surface`, with a
       slow 1.2 s opacity pulse between 0.55 and 1 (no shimmer gradient).
     - `KustSkeletonRows(count, avatar: true)` matches a 56 px list row: a 36 px
       avatar, two text bars (60% and 35% wide), and a small right block.
   - Add `KustLoader`, a 28 px 2×2 checker of four squares that light up in turn
     (gold and `muted`, 600 ms cycle), for full-screen waits with no list shape.
   - Replace the spinners:
     - lists (history, player games, friends/players, chats, notifications,
       profile sections) → `KustSkeletonRows`;
     - full screens (profile loading, online game loading) → `KustLoader`;
     - spinners **inside buttons** and the 12 px reconnecting spinner stay.

Done when: `test/ui`, `test/history`, `test/players`, `test/profile` (if
present), `test/chat` and `test/online` pass. Tests that waited with
`pumpAndSettle` on a screen that now pulses forever must pump fixed durations
instead (the same fix as in `test/online/online_game_test.dart`).

## Phase 3: List rows and cards across screens (one PR)

Target row, from Chess.com's game history / friends: **56 px tall, 16 px side
padding, 1 px `line` divider, avatar 36 px square radius 4**. The name is
`rowTitle` with the rating `(1200)` after it at 14/500 muted. The meta line is
12/500 muted. Right-side actions sit in a 36 px box.

Apply to:
- `lib/features/history/history_screen.dart`: the game row. Currently ≈72 px
  with a 44 px avatar; go to 56/36. The result badge is a 20×20 square, radius
  4. The accuracy % is `number` 15/700. Keep the time-control icon at 18 px.
- Friends list, players list, chat list, notifications: the same row recipe.
- Profile sections ("Friends", "Game history", "Achievements") on both the own
  and the friend profile: section header `section` 17/700, "View all" 14/600
  gold, a 12 px gap to the content, 24 px between sections.
- Cards (home/play tiles, stat blocks on the profile): radius `rCard`, fill
  `surface`, no border unless it's a selected state, 16 px inner padding.

Done when: the history, players and chat tests pass, and every list screen uses
one row widget. If two features copy-paste the same row, extract
`lib/ui/kust_list_row.dart` with leading / title / trailing / meta slots.

## Phase 4: Game screen (one PR)

Files: `lib/features/game/game_screen.dart` and
`lib/features/online/online_game_screen.dart` (keep them alike: both use
`ChessBoard`).

1. **Player bars:** a 40 px square avatar (radius 4), name 15/600, rating 13/500
   muted, flag 14 px. Below the name: captured pieces at 14 px, with the
   material lead `+N` 13/700 muted after them. Bar height 56, 12 px side
   padding.
2. **One clock widget** shared by both screens: move `_ClockChip` (game_screen,
   ≈line 1088) to `lib/ui/game_clock.dart` and use it in the online screen too.
   - Box height 40, min width 96, radius 6, value `number` 20/700.
   - Active: light fill (`#F2F0EA`) with dark text.
   - Idle: `surfaceAlt` fill with muted text.
   - **Under 20 s on the active side:** fill `danger`, white text, and a 1 Hz
     pulse (opacity 1 → 0.75).
   - Under 10 s show tenths (`0:09.4`).
   - The clock icon shows only on the active clock.
3. **Move strip (`lib/ui/move_strip.dart`):** height 36 → 40. The current move
   is a pill (`surfaceAlt`, radius 4, 6×2 padding, ink text 14/700) instead of
   gold text. Other moves are 14/600 muted. Keep the auto-centring.
4. **Piece glide:** `glideDuration` in `chess_board.dart` is
   `(150 + 28·d).clamp(170, 320)`. Both apps glide in ≈140–180 ms, so change it
   to `(110 + 22·d).clamp(130, 210)` with curve `easeOutCubic` (check the
   current curve). The captured piece vanishes as the mover arrives (we already
   fade it; keep it under 120 ms).
5. **Check:** the king's square gets a radial red (`#E5484D`, 0.8 → 0) behind
   the king instead of a flat tint, faded in over 150 ms. Mate: the same, but
   solid. Look at `_checkColor` / `checkedKing` handling first; only change the
   paint.
6. **Action bar (`KustActionBar`):** keep 72 px. Labels 11/600, icons 24 px,
   disabled at 35% opacity. At most 5 items on any screen (replay already
   moved Flip into settings).
7. **Bot speech bubble (`lib/features/puzzles/speech_bubble.dart` /
   `bot_quote.dart`):** a light bubble (`#F2F0EA`) with dark text 14/600, radius
   10, and a tail pointing at the bot's avatar. Pop in with scale 0.9 → 1 plus
   fade over 180 ms `easeOutBack`; hold; fade out over 150 ms.

Done when: test/game, test/online and test/play pass.

## Phase 5: Rewarding moments (one PR)

1. **Counting numbers:** add `lib/ui/count_up.dart` (`CountUp(from, to)`),
   400 ms `easeOutCubic`, tabular digits. Use it for:
   - the rating and `+N` on `GameResultScreen` (`_RatingAndAccuracy`);
   - puzzle rating changes;
   - achievement / progress counters.
2. **Progress bars** (puzzle goal, loom progress, achievements): fill animates
   from the old value to the new one over 400 ms `easeOutCubic`, never jumps.
   Track `surfaceAlt`, height 10, radius 5.
3. **Puzzle solved:** use the board's `badge` (`PuzzleBoard.badge`) to pop a
   small `+N` gold chip on the final square (scale 0.6 → 1, 200 ms
   `easeOutBack`). The "Next puzzle" 3D button slides up 12 px and fades in over
   200 ms. Coach lines already exist (`coachCorrect` etc.); make sure the coach
   bubble changes text with a 150 ms cross-fade, not a cut.
4. **Waiting for a friend to accept a challenge**
   (`online_game_screen.dart`, pending state): instead of plain text, show the
   board blurred (`ImageFiltered`, sigma 8) with a 48 px white piece silhouette
   cycling queen → knight → bishop every 600 ms (fade/scale 0.9 → 1), and
   "Waiting for {name}…" under it. Cancel stays.

Done when: test/puzzles, test/online, test/achievements and test/game pass.

## Phase 6: Splash exit (small, last)

`lib/ui/kust_splash.dart`: when the splash ends, fade it out over 250 ms while
the mark scales 1 → 1.06, so it dissolves into the first screen instead of
cutting. Nothing else changes.

---

## Order and size

| Phase | What | Size | Depends on |
|---|---|---|---|
| 1 | Tokens + Inter font | S | none |
| 2 | Shared components, skeletons, transitions | L | 1 |
| 3 | List rows and cards | M | 1, 2 (`PressHighlight`, row widget) |
| 4 | Game screen | M | 1 |
| 5 | Rewarding moments | M | 2 (`CountUp` lives in ui) |
| 6 | Splash exit | S | none |

Phases 3 and 4 touch different files and can run in parallel after phase 2.

## Decided: Inter (user said yes, 2026-11-25). Part of phase 1.

- Replace the platform default (Roboto) with **Inter**, bundled as an asset,
  not fetched at runtime (no `google_fonts` package).
- Download the official release from the Inter GitHub repo
  (`rsms/inter`, latest 4.x release zip), into its own empty folder in the
  scratchpad. Take only `InterVariable.ttf` and `InterVariable-Italic.ttf`
  (≈800 KB together). Put them in `assets/fonts/` and add `LICENSE.txt` (OFL)
  beside them. Ask the user before the download, naming the file and its size.
- `pubspec.yaml`: add a `fonts:` entry, family `Inter`, with the two files
  (`style: italic` on the second).
- `lib/theme.dart`: set `fontFamily: 'Inter'` on both themes. Check that the
  weights 500/600/700/800 render as different weights; variable fonts honour
  `FontWeight` in Flutter.
- Inter is a little wider than Roboto. Run `test/l10n` and the screen tests
  for overflow. Fix overflows by letting the text shrink or wrap, not by
  cutting letter spacing.
- Turkmen check: ý ň ş ž ç ä ö ü must render (Inter covers Latin Extended-A
  and Cyrillic).

## How to verify each phase (no device)

- `dart analyze lib` is clean.
- `flutter test -j 1` on the dirs listed in the phase, plus `test/ui`.
- In the PR description, list the exact values changed (old → new) so the user
  can check on the phone after pressing `R`.
