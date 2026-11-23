# Küşt 3.0.0 — audit and improvement plan

Audited at `main` = `dev` (version 3.0.0+6). Plan only: no code was changed. Line numbers are from this commit; if they have drifted, search for the quoted identifier.

## 1. Summary

**Health:** good. Analyzer is clean, all 365 tests pass, chess rules sit on `dartchess`, the board is already well isolated for repaints, and engine work is serialized and guarded against stale replies in most paths.

**Top 5 risks**
1. A corrupted Hive box stops the app on the splash screen forever; there are no global error handlers and no crash reporting (G1, G2).
2. Four different analysis settings rate the same game, so accuracy and move labels disagree between the result dialog, Review and Replay, and the same game is searched up to three times (A1, B4).
3. A search cut short when the app is hidden is still used: the bot can play a depth-1 move, and a move can get a wrong rating (A2).
4. The Learn garden map probably re-rasterizes about 25 blurred shadows on every scroll frame under Impeller (B1).
5. Game-ending paths (repetition, fifty-move, insufficient material, timeout draw, undo) have no controller tests (A7), and `chess_controller.dart` is 2141 lines (F1).

**Top 5 opportunities**
1. One persisted analysis per game: instant Review, consistent numbers, less battery (task 1.2).
2. Lessons beyond the rules: tactics, opening principles, basic endgames (4.4, 4.5).
3. Timed bot games and resuming an interrupted game (4.2, 4.3).
4. "Try again" on your mistakes in Review, then a mistakes trainer (4.6, 4.7).
5. One primary button style and a 360 px / large-font pass in Russian and Turkmen (3.1 to 3.4).

## 2. Analyze and test results

| Command | Result |
|---|---|
| `flutter analyze` | No issues found (14.9 s). |
| `flutter test` | 365 passed, 0 failed (73 s). |
| `git status` after both | Only `docs/` untracked; no tracked file changed. |

Not run: profile build, device timeline, release build. Everything in section B marked "suspected" needs task 2.1 first.

## 3. Findings

`cc.dart` = `lib/features/game/chess/chess_controller.dart`.

### A. Correctness and chess rules

| ID | Sev | Evidence | User impact | Confidence |
|---|---|---|---|---|
| A1 | high | Four think times for the same question: live feedback 700 ms + deeper check (`chess_engine.dart:316`), result-dialog accuracy 250 ms (`game_analyzer.dart:90`, `cc.dart:1724`), Review 200 ms (`review/game_review.dart:43`), Replay 400 ms (`history/replay_screen.dart:142`) | Dialog said 87.5 %, Review said 87.4 % for the same game (owner's screenshots). A move can be "Blunder" in one screen and "Mistake" in another. | verified |
| A2 | medium | `AppLifecycleListener(onHide: stopThinking)` (`chess_engine.dart:187`) and `game_screen.dart:96-100` send `stop`; the truncated `bestmove` and scores are then used by `_requestBotMove` (`cc.dart:1945-1961`) and `_analyzeMoveAt` (`cc.dart:880-960`) | Switch apps while the bot thinks: it may answer with a shallow, bad move. A move being rated at that moment can get a wrong label. | verified (code path); effect size suspected |
| A3 | medium | Clock charges wall time since `_lastTick` (`cc.dart:517-546`); on background only the engine is stopped (`game_screen.dart:96-100`). Clocks exist only in pass and play (`game_screen.dart:77-81` passes no time control to bot games) | In a timed pass-and-play game, a phone call makes the side to move lose on time. | verified |
| A4 | low | `evaluateBestHint` has no `isStale` (`chess_engine.dart:296-303`); `_cancelSuggestion` only sends `stop` when its search is the running one (`cc.dart:785-791`) | In practice mode with Show best on (default), moving quickly after the bot can delay the bot's next reply by up to 1 s. | verified |
| A5 | low | `_recordFinishedGame` writes the rating, then `if (_isDisposed) return;` before saving the game (`cc.dart:1651-1680`) | Rare: rating changes but the game is missing from History. | verified |
| A6 | medium | `_botRemarkOn` is only called from `_analyzeMoveAt` (`cc.dart:960`), which returns unless `practiceMode && moveFeedbackEnabled` (`cc.dart:866`) | In rated games the bot never reacts to your blunders or great moves; chat feels dead outside practice. | verified |
| A7 | medium | `grep -rl` in `test/`: `repetition` 0 files, `fiftyMove` 0, `insufficient` 0, `timeNoMate` 0, `undoLastMove` 0, `markBotBeaten` 0 | Regressions in how games end would ship unnoticed. | verified |
| A8 | low | `_computeAccuracy` (`cc.dart:1709`) keeps running when Review starts its own pass (`review_screen.dart:82`); both share the one engine queue | Review takes about twice as long right after a game. | verified (both run); slowdown suspected |

Checked and found correct: threefold repetition key uses dartchess's legal en-passant square (`position.dart:134`); undo is only possible while `status == playing` (`cc.dart:216`), so a game cannot be recorded twice; timeout with insufficient material is a draw (`cc.dart:575-587`); stale bot replies are dropped by `_moveRequestId`; resign records the right winner in both modes.

### B. Engine and performance

| ID | Sev | Evidence | User impact | Confidence |
|---|---|---|---|---|
| B1 | high | Garden map is one `CustomPaint(isComplex: true)` in a `RepaintBoundary` (`garden_map.dart`, `LearnMap.build`), with `MaskFilter.blur` shadows per tile and per prop (`garden_map.dart:184`, `:345`). Impeller has no picture raster cache, so scrolling replays every draw call each frame | Learn tab scroll below 60 fps on a mid-range phone (owner reported this for the previous map). | suspected; confirm with 2.1 |
| B2 | medium | `_marker` wraps `_Marker` in a `RepaintBoundary`, but the bobbing `Transform.translate` is inside it (`garden_map.dart:812-821`, `_MarkerState.build`) | The coach card (shadow, clip, image) repaints 60 times a second while Learn is open. | verified (code); cost suspected |
| B3 | medium | `BackdropFilter.grouped(ImageFilter.blur(16,16))` in the translucent top bar (`kust_top_bar.dart:146`), used on Play while scrolled (`play_screen.dart:246`) | Possible dropped frames scrolling the home screen. | suspected |
| B4 | medium | Review results live only in memory (`review_screen.dart:19`); Replay re-searches each move it shows (`replay_screen.dart:120-170`); accuracy is a third pass (A1) | Reopening Review after an app restart re-analyzes up to 160 plies; battery and waiting. | verified |
| B5 | low | Only the running search is stopped on hide; the `_run` chain keeps starting queued searches (`chess_engine.dart:113-117`, `:187`) | A long Review keeps the CPU busy in the background. | verified |
| B6 | low | `NnueStore.verify` hashes about 110 MB with `sha256.bind(file.openRead())` on the UI isolate (`nnue_store.dart:45-50`) | Jank on the very first launch only. | verified (code); cost suspected |

Already good: board uses `select` and seven repaint boundaries (`chess_board.dart:586-1022`); the Puzzles carpet is pre-rendered to an image (`loom.dart:61-75`); bot images use `cacheWidth`; the bottom bar has no blur.

### C. Product gaps

Ranked by impact for beginners and intermediates, with effort.

| ID | Gap | Evidence | Impact | Effort |
|---|---|---|---|---|
| C1 | Lessons stop at the rules: 11 lessons, 2 to 4 tasks each, nothing on tactics, openings or endgames | `learn/lessons.dart` (`kLessons`) | very high | L |
| C2 | Every lesson opens in any order, though tiles ahead look locked | `garden_map.dart` `_hit` calls `onOpen` for all tiles | medium | S |
| C3 | No timed games against bots | `game_screen.dart:77-81` | high | M |
| C4 | An interrupted game is lost when the app is killed | nothing persists a live game; `cc.dart` state is memory only | high | M |
| C5 | 100 puzzles in total | `assets/puzzles/level1..5.json` | high | L |
| C6 | Review shows mistakes but you cannot retry them | `review_screen.dart` `_KeyMoment` only opens Replay | high | M |
| C7 | No practice built from your own mistakes | none | high | L |
| C8 | No opening names | none | medium | M |
| C9 | No reminder for the daily puzzle or streak | no notification package | medium | M, needs a decision |
| C10 | Player name is a random English nickname and cannot be changed | `app_storage.dart:19-26`, `play_screen.dart:161` | medium | S |
| C11 | No backup or export of progress | none | low now | M |

### D. UI/UX and design consistency

| ID | Sev | Evidence | User impact | Confidence |
|---|---|---|---|---|
| D1 | medium | Gold `KustButton` is the main button in 13 files (27 uses); green `KustButton3D` in Learn, Puzzles home and onboarding (8 uses) | Two different "main button" looks; the app feels like two designs. | verified |
| D2 | medium | `_CampBanner` subtitle `maxLines: 1` with ellipsis (`learn_screen.dart:284`); owner's screenshot shows "Her çöpüň nähili göçýändigini …" | Turkmen text is cut off in the Learn header. | verified |
| D3 | low | `KustIconButton` default `size = 40` (`kust_top_bar.dart:168`); lesson hint button 40×40 (`lesson_screen.dart`, `_TopBar`) | Tap targets under 48 px. | verified |
| D4 | medium | No text-scale clamp in `app.dart` builder; many fixed-height rows | Large system fonts can overflow rows and buttons. | suspected; confirm with a 1.3× test |
| D5 | low | `disableAnimations` is read in 5 places only (grep); not in `garden_map.dart`, `lesson_screen.dart`, `kust_nav_bar.dart`, onboarding | "Remove animations" in system settings is ignored in the new screens. | verified |
| D6 | low | Tile tap target is a bare `GestureDetector` with `Semantics(label: '${i + 1}')` (`garden_map.dart` `_hit`) | No press feedback; screen readers hear only a number. | verified |
| D7 | medium | `assets/images/banner.png` has "Time to improve your chess" baked in (`play_screen.dart:190`) | English text on the home screen in Russian and Turkmen. | verified (owner's screenshot) |
| D8 | low | Splash and adaptive icon background are `#FFBB00` (`pubspec.yaml:46-58`) while the shell dropped yellow | Yellow flash at launch against a dark, green-accented app. | verified; a brand decision |

### E. Localization

| ID | Sev | Evidence | Impact | Confidence |
|---|---|---|---|---|
| E1 | medium | Turkmen uses "şahmat" (checkmate) for chess: `onbTitle` (`app_tk.arb:303`), `lvlBeginnerD` (`app_tk.arb:315`) | The first onboarding title reads "checkmate that helps you improve". | verified against the glossary |
| E2 | low | Guest names are English only (`app_storage.dart:19-26`) | "Salam, Guest Knight". | verified |
| E3 | medium | `l10n/REVIEW_tk.md` lists 301 table rows plus the Bot chat, Review, Learn, Learn redesign and Onboarding sections as unreviewed | Turkmen quality depends on a native pass. | verified |
| E4 | low | Launcher name is "Kust" (`AndroidManifest.xml:3`, `ios/Runner/Info.plist:10,18`) | The app's name is misspelt on the phone. | verified |
| E5 | low | Dead English `title` / `description` on `OnboardingLevel` (`onboarding_level.dart:11-31`) | None; confuses contributors. | verified |

ARB parity is exact (454 keys in each of en, ru, tk); no hard-coded UI text was found in widgets.

### F. Code health

| ID | Sev | Evidence | Impact | Confidence |
|---|---|---|---|---|
| F1 | medium | `chess_controller.dart` 2141 lines: clocks, premoves, feedback, suggestion, recording, bot loop in one class | Hard to change safely. | verified |
| F2 | low | Drag and tap logic lives twice: `chess_board.dart` (1670 lines) and `puzzle_board.dart` (705) | Fixes must be made twice. | verified |
| F3 | low | Isometric tile drawn twice: `garden_map.dart` `_diamond`/`_tile` and `onboarding_screen.dart` `_StagePainter` | Drift between the two. | verified |
| F4 | medium | Castling square mapping repeated at `cc.dart:645-655`, `678-688`, `1793-1799`, `1822-1829`, `2066-2075`, `2104-2110`, plus `engineUci` (`game_analyzer.dart:8`), `TaskRunner.landing` (`lesson_task.dart`), `game_review.dart` | A castling bug would need nine fixes. | verified |
| F5 | low | Dead code: `ChessEngine.bestMoveForFen` (no callers), light theme path behind `forceDark`, E5 | Noise. | verified |
| F6 | low | Four coach-with-bubble widgets: `lesson_screen.dart` `_Coach`, `onboarding_screen.dart` `_Coach`, `play/bot_quote.dart` `BotSays`, `puzzles/coach_bubble.dart` | Inconsistent sizes and styles. | verified |

### G. Reliability and release readiness

| ID | Sev | Evidence | Impact | Confidence |
|---|---|---|---|---|
| G1 | critical | `AppStorage.init()` opens four boxes with no try/catch (`app_storage.dart:31-37`), awaited before `runApp` (`main.dart:33-34`) | One unreadable box file and the app never leaves the splash screen. | verified (code); needs a corrupted-file test |
| G2 | high | No `FlutterError.onError`, `PlatformDispatcher.onError` or crash reporter in `main.dart` | Crashes in the field are invisible. | verified |
| G3 | medium | Release APK 98 MB per ABI; `assets/engine` is 73 MB; networks unpack to about 110 MB more on first run | Heavy download and storage for the target market. | verified |
| G4 | medium | No privacy policy, store listing text or screenshots in the repo | Blocks a Play Store submission. | verified |
| G5 | low | No schema version for Hive boxes or prefs keys (`learn_done`, `learn_stars`, `daily_*`, …) | Future data changes have no migration hook. | verified |
| G6 | low | `flutter_launcher_icons: ios: false` (`pubspec.yaml:43`) | iOS build has the default icon. | verified |

The manifest has no INTERNET permission, which is good for privacy and must be weighed in task 6.1.

## 4. Execution plan

Workflow for every task: issue, branch off `dev`, PR into `dev` with "Closes #N", `flutter analyze` and `flutter test` green. Never commit `assets/engine/*.gz`. After editing ARB files run `flutter gen-l10n`. Turkmen strings below are drafts **to review** and must be added to `l10n/REVIEW_tk.md`.

### Phase 1 — critical fixes

#### 1.1 Survive a damaged storage box and catch all errors
- **Resolves:** G1, part of G2.
- **Why:** today one bad file bricks the app; and no error is ever recorded.
- **Files:**
  - `lib/core/storage/app_storage.dart`: add `static Future<Box> _openSafe(String name)` that tries `Hive.openBox(name)`; on any error calls `Hive.deleteBoxFromDisk(name)` and opens again; `init()` uses it for all four boxes and records the names it had to reset in `static final List<String> resetBoxes`.
  - `lib/main.dart`: wrap the body in `runZonedGuarded`; set `FlutterError.onError` and `PlatformDispatcher.instance.onError` to a new `lib/core/error_log.dart` (`ErrorLog.record(error, stack)`, keeps the last 20 entries in memory and prints in debug). Keep `runApp` reachable even if `AppSettings.load()` throws (try/catch around it).
- **Strings:** none.
- **Tests:** `test/storage/app_storage_recovery_test.dart`: write garbage bytes to `<dir>/history.hive`, call `AppStorage.init()`, assert it completes, the box is open and empty, and `resetBoxes` contains `history`. A second test: `ErrorLog.record` keeps at most 20.
- **Acceptance:** with a garbage box file the app starts; other boxes keep their data.
- **Risk / device check:** data loss is limited to the damaged box. On a device: `adb shell run-as com.shapakapps.kust` and truncate a `.hive` file, relaunch.
- **Size:** S. **Depends on:** none.

#### 1.2 One analysis per game, stored and shared
- **Resolves:** A1, A8, B4.
- **Why:** consistent numbers everywhere, instant Review, a third of the engine work.
- **Files:**
  - New `lib/features/review/game_analysis_store.dart`: Hive box `analysis` (open it in `AppStorage.init` via `_openSafe`), value per game id = `{'v': 1, 'plies': [[bestUci, bestCp, playedCp, secondCp|null], …]}`; `get(id)`, `put(id, plies)`, `delete(id)`; cap at the same 200 games (delete with the history record in `GameHistoryStore.delete` / trimming).
  - New `lib/features/review/game_analysis_service.dart`: singleton with `ValueListenable<AnalysisProgress?> progressFor(id)` and `Future<GameReviewData?> analyze(GameRecord)`: returns stored data if present, otherwise runs `reviewGame` once (joins a run already in flight for that id), stores the result, and writes `accuracy` for the player's side with `GameHistoryStore.setAccuracy`. One constant `kAnalysisThinkTime = Duration(milliseconds: 300)` and `ChessEngine.analysisDepth` used by everyone.
  - `lib/features/review/game_review.dart`: make `ReviewedMove` buildable from a stored row (factor the classification out of the loop into `ReviewedMove.fromAnalysis(...)`), so stored rows rebuild `GameReviewData` without the engine.
  - `lib/features/game/chess/chess_controller.dart`: replace `_computeAccuracy` body with a call to `GameAnalysisService.instance.analyze(record)` and take `accuracy` from `data.accuracy(playerSide)`; keep `accuracyPending`. Do this for pass-and-play games too (no accuracy shown, but Review is then instant).
  - `lib/features/review/review_screen.dart`: drop `_reviewCache` and `_run`'s own `reviewGame`; listen to the service's progress and result.
- **Strings:** none.
- **Tests:** `test/review/game_analysis_service_test.dart` with a fake analyzer: (1) two concurrent `analyze` calls run the analyzer once per ply; (2) a second call after completion makes zero analyzer calls; (3) the accuracy written to history equals `data.accuracy(side)` to one decimal; (4) stored rows rebuild identical qualities. Update `test/review/game_review_test.dart` and `test/game/result_dialog_test.dart` for the new source.
- **Acceptance:** the accuracy in the result dialog and in Review are the same number; opening Review a second time (even after restart) shows results with no progress bar.
- **Risk / device check:** stored rows must tolerate older records without analysis. Play a 30-move game, compare dialog and Review, kill the app, reopen Review.
- **Size:** L. **Depends on:** 1.1 (`_openSafe`).

#### 1.3 Replay and History read the stored analysis
- **Resolves:** rest of A1, B4.
- **Files:** `lib/features/history/replay_screen.dart`: in `_reviewCurrent`, first look up the ply in `GameAnalysisStore`; only search when missing (and then with `kAnalysisThinkTime`). `lib/features/history/history_analysis.dart`: `start()` delegates to `GameAnalysisService.analyze`; keep the paced percentage.
- **Tests:** extend `test/history/replay_screen_test.dart`: with stored analysis the injected analyzer is never called and the badge matches the stored quality. Update `test/analysis/analysis_test.dart`.
- **Acceptance:** the badge on a move in Replay equals its label in Review for every ply.
- **Size:** M. **Depends on:** 1.2.

#### 1.4 Pause a timed pass-and-play game when the app is hidden
- **Resolves:** A3.
- **Files:** `lib/features/game/game_screen.dart` `didChangeAppLifecycleState`: on `hidden` or `paused`, also call `controller.pauseClock()` (it already no-ops unless `canPause`). The existing paused overlay then waits for Resume.
- **Strings:** none (reuses the pause UI).
- **Tests:** in `test/game/local_review_pause_test.dart`: start a 5-minute local game, call `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused)`, advance 10 s, resume the app; assert `state.paused` is true and White still has 5:00.
- **Acceptance:** backgrounding a timed local game never costs time.
- **Size:** S. **Depends on:** none.

#### 1.5 Never use a search that was cut short by backgrounding
- **Resolves:** A2, B5.
- **Files:**
  - `lib/features/game/chess/chess_engine.dart`: add `int _interruptions = 0`, `Completer<void>? _resumed`. Replace the lifecycle listener with `onHide: _onHide, onShow: _onShow`; `_onHide` increments `_interruptions`, creates `_resumed`, sends `stop`; `_onShow` completes it. In `_run`, `await _resumed?.future` before `op()`. In `_searchTop` and `_search`, capture `_interruptions` before `go` and throw a new `SearchInterruptedException` if it changed when `bestmove` arrives. Keep the public `stopThinking()` (user-initiated) as is: it must not count as an interruption.
  - `chess_controller.dart`: in `_requestBotMove` catch `SearchInterruptedException` → if `requestId == _moveRequestId`, call `_requestBotMove()` again (it will wait at the gate); in `_analyzeMoveAt`, `_refreshEvaluation`, `_refreshSuggestion`, `requestHint` treat it as "no result" (clear the busy flag). `GameAnalyzer`/`reviewGame`: retry the same ply once after an interruption.
  - `game_screen.dart:96-100`: remove the extra `stopEngineWork()` on pause (the engine handles it).
- **Tests:** `test/engine/interruption_test.dart` with a scripted fake Stockfish stream: hide during a search → the future fails with `SearchInterruptedException`; a queued op does not send `go` until `_onShow`. In `test/game/premove_test.dart` style: bot move request interrupted then resumed → exactly one bot move is played, from the second search.
- **Acceptance:** leaving and returning mid-think never produces an instant weak bot move; no searches start while hidden.
- **Risk:** deadlock if `onShow` never fires; add a safety: `_resumed` also completes when `start()` is called or after `AppLifecycleState.resumed`.
- **Size:** M. **Depends on:** none.

#### 1.6 Skip stale hint and suggestion searches
- **Resolves:** A4.
- **Files:** `chess_engine.dart` `evaluateBestHint(String fen, {bool Function()? isStale})`: return `'(none)'` at the start of the queued op when stale. `chess_controller.dart`: `_refreshSuggestion` passes `() => _isDisposed || id != _suggestId`; `requestHint` passes `() => _isDisposed || requestId != _moveRequestId`.
- **Tests:** `test/game/show_best_test.dart`: queue a suggestion behind a blocked evaluation, make a move, release; assert the fake engine never received the suggestion's `go`.
- **Size:** S. **Depends on:** none.

#### 1.7 Tests for every way a game can end
- **Resolves:** A7. No production change expected; if a test exposes a bug, fix it in the same PR and say so.
- **Files:** new `test/game/game_end_test.dart` using the `_FakeEngine` pattern from `test/game/premove_test.dart` (move it to `test/support/fake_engine.dart` and reuse). Cases, each asserting `status`, `endReason`, the saved `GameRecord.result`/`reason`, `gameResultToken`, and `ratingChange` (null in practice and local):
  1. threefold repetition by knight shuffles → draw / `repetition`;
  2. position with `halfmoves` 99 then a quiet move → draw / `fiftyMove`;
  3. K+B vs K after a capture → `insufficientMaterial`;
  4. stalemate;
  5. local timed game: flag falls with mating material → `timeout`, winner is the other side, PGN `1-0`/`0-1`;
  6. flag falls against a lone king → draw / `timeNoMate`;
  7. bot game: player resigns → loss, rating drops; bot checkmated in a rated game → `AppStorage.isBotBeaten` true; in practice → false;
  8. undo in practice after the bot's reply restores two plies and the repetition table (repeat case 1 across an undo).
- **Size:** M. **Depends on:** none (do before 5.2).

#### 1.8 Save the game before the rating
- **Resolves:** A5.
- **Files:** `chess_controller.dart` `_recordFinishedGame`: compute `delta` with `PlayerRatingStore.delta(...)` first (pure), save the `GameRecord` with that `ratingChange`, then `await PlayerRatingStore.instance.record(...)`; remove the early `return` between them (keep `_isDisposed` checks only around `state =`).
- **Tests:** in `game_end_test.dart`: dispose the container right after the game ends; both the history record and the new rating exist.
- **Size:** S. **Depends on:** 1.7.

### Phase 2 — performance

#### 2.1 Measure a baseline on a real phone (no code)
- **Why:** B1 to B3 are suspected, not measured.
- **Steps:** `flutter run --profile` on the Galaxy A57; DevTools → Performance, "Track widget builds" off. Record 10 s each: (a) scrolling Learn top to bottom, (b) Learn idle (marker bobbing), (c) scrolling Play with the top bar translucent, (d) dragging a piece in a bot game while the bot thinks, (e) Review screen during analysis, (f) Puzzles carpet scroll. Note average and worst UI and raster times and the share of frames over 16.6 ms. Also `flutter run --profile --trace-startup` for time to first frame.
- **Output:** a table committed as `docs/perf/baseline-3.0.0.md`. Tasks 2.2 to 2.4 run only where raster time exceeds 12 ms average or more than 5 % of frames miss.
- **Size:** S.

#### 2.2 Draw the garden map once, as an image
- **Resolves:** B1.
- **Files:** `lib/features/learn/garden_map.dart`: add `class _GardenArt` modelled on `_Layer`/`_RunnerArt` in `puzzles/loom.dart:61-110`: record `LearnMapPainter.paint` into a `ui.Picture`, `toImageSync(width*dpr, height*dpr)`, cache by `'$width@$dpr|$next|${stars}'` (keep 2 entries, dispose older images). `LearnMapPainter.paint` becomes `canvas.drawImageRect` when the image exists, with the old path as fallback. Replace `MaskFilter.blur` shadows with a `RadialGradient` oval (no blur pass) in `_tile` and `_shadow`.
- **Tests:** `test/learn/garden_art_test.dart`: same key returns the identical cached object; a changed `next` builds a new one; painting does not throw at 360×1700. Keep `learn_screen_test.dart` green.
- **Acceptance:** Learn scroll raster time under 8 ms average on the A57 (compare with 2.1); the map looks the same in a side-by-side screenshot.
- **Risk:** texture size: 1080×~4600 px ≈ 20 MB; if `toImageSync` fails fall back to the picture path.
- **Size:** M. **Depends on:** 2.1.

#### 2.3 Cheap marker animation and reduce-motion in Learn
- **Resolves:** B2, D5 (Learn part).
- **Files:** `garden_map.dart`: move the `RepaintBoundary` inside `_MarkerState.build` around `card` (child of the `Transform`), so only the transform changes per frame; stop `_bob` when `MediaQuery.of(context).disableAnimations`. `lesson_screen.dart` (`_PopStar`, `_DoneBadge`) and `onboarding_screen.dart` (`_ReadyStep` rise): jump to the end state when animations are disabled. `kust_nav_bar.dart`: skip the icon pop likewise.
- **Tests:** `learn_screen_test.dart`: with `MediaQueryData(disableAnimations: true)` the marker's controller is not animating (`tester.hasRunningAnimations` false after a pump).
- **Size:** S. **Depends on:** none.

#### 2.4 Top bar blur only if it is cheap
- **Resolves:** B3.
- **Files:** only if 2.1(c) misses budget: `lib/ui/kust_top_bar.dart`: replace the `BackdropFilter` with a solid `k.bg` at 0.94 alpha plus the existing hairline; drop `BackdropGroup` from `app_shell.dart`.
- **Tests:** existing `ui_kit_test.dart` stays green.
- **Size:** S. **Depends on:** 2.1.

#### 2.5 Verify the networks off the UI isolate
- **Resolves:** B6.
- **Files:** `lib/features/game/chess/nnue_store.dart` `verify`: run the hash inside `Isolate.run(() => sha256.convert(File(path).readAsBytesSync()))` is too memory hungry for 100 MB; instead `Isolate.run` a function that reads the file in 1 MB chunks through a `sha256.startChunkedConversion` sink.
- **Tests:** `test/engine/nnue_store_test.dart` already covers verify; keep green.
- **Size:** S.

### Phase 3 — UX consistency

#### 3.1 One main button style
- **Resolves:** D1. **Needs the owner's answer to question 1; default below.**
- **Default:** the single main action of a screen or sheet uses `KustButton3D` (green); `KustButton` keeps `secondary`, `outline` and `green`-flat styles for everything else; `KustButtonStyle.primary` (gold) is removed.
- **Files:** switch the primary `KustButton(` to `KustButton3D(expand: true, …)` in: `play/pick_opponent_modal.dart`, `play/pick_time_modal.dart`, `play/pick_side_modal.dart`, `play/play_screen.dart` (`_HeroCard` button; also recolour the hero card from gold to `k.surface` with a green button), `game/game_result_dialog.dart` (Rematch), `puzzles/puzzle_game_screen.dart` (`_FinishedBar` next), `puzzles/woven_dialog.dart`, `history/history_screen.dart` (empty state), `game/game_screen.dart` (sheets' confirm buttons stay `KustButton` secondary). Then delete the `primary` case in `lib/ui/kust_button.dart` and make `secondary` the default.
- **Tests:** update finders in `test/ui_kit_test.dart`, `test/game/result_dialog_test.dart`, `test/puzzles/*` that look for `KustButton`.
- **Acceptance:** no gold-filled button remains (`grep -rn "KustButtonStyle.primary" lib` is empty).
- **Size:** M.

#### 3.2 No cut-off text at 360 px in Russian and Turkmen
- **Resolves:** D2.
- **Files:** `learn/learn_screen.dart` `_CampBanner`: subtitle in a `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft)`; `_UpNextCard` title likewise. Shorten `campPiecesSub` in tk to "Her çöp nähili göçýär" (to review).
- **Tests:** new `test/l10n/overflow_test.dart`: for `ru` and `tk` at 360×740, pump `LearnScreen`, `LessonScreen('pawn')` intro and task, `ReviewScreen` (fake data), `PickOpponentModal`, `GameResultContent`; assert `tester.takeException()` is null and no `Text` widget with `overflow: ellipsis` has `didExceedMaxLines` for the header keys.
- **Size:** M.

#### 3.3 48 px tap targets
- **Resolves:** D3.
- **Files:** `lib/ui/kust_top_bar.dart` `KustIconButton`: keep the 40 px visual but wrap in a 48×48 `SizedBox` with `HitTestBehavior.opaque`; `learn/lesson_screen.dart` `_TopBar` hint button likewise.
- **Tests:** `ui_kit_test.dart`: `tester.getSize(find.byType(KustIconButton))` ≥ 48×48.
- **Size:** S.

#### 3.4 Large fonts up to 1.3×
- **Resolves:** D4.
- **Files:** `lib/app.dart` builder: wrap `child` in `MediaQuery(data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)))`. Then fix what the test finds (likely `KustOption` min height, `_PlayerBar`, bottom bar labels: wrap labels in `FittedBox`).
- **Tests:** extend `overflow_test.dart` with `textScaler: TextScaler.linear(1.3)` for the same screens in `tk`.
- **Size:** M. **Depends on:** 3.2.

#### 3.5 Lesson tiles: press feedback, labels, and order
- **Resolves:** D6, C2.
- **Files:** `garden_map.dart` `_hit`: use `Pressable` (scale 0.96) and `Semantics(button: true, label: '${t.lessonLabel(i+1)}, ${lesson.title(t)}')`. In `LearnScreen._open`: if `index > next` show a `KustSheet` with the lock message and a button to open the next lesson instead.
- **Strings:** `lessonLocked` — en "Finish lesson {n} first." / ru "Сначала пройдите урок {n}." / tk "Ilki {n}-nji sapagy tamamlaň." (to review).
- **Tests:** `learn_screen_test.dart`: tapping tile 5 with nothing done shows the sheet, not the route; tapping tile 1 opens it; a finished lesson reopens.
- **Size:** S.

#### 3.6 Home banner without baked-in English
- **Resolves:** D7.
- **Files:** `play/play_screen.dart` near line 190: replace `banner.png` with a widget: `KustLogo` plus `Text(t.homeBannerLine)` over a plain panel with a `LearnPiece(Role.knight)`; delete `assets/images/banner.png` if unused elsewhere (the README uses the GitHub raw URL of this file, so keep the file and only stop bundling it by moving it to `docs/`).
- **Strings:** `homeBannerLine` — en "Time to improve your chess" / ru "Пора играть лучше" / tk "Küşt oýnuňyzy gowulandyrmagyň wagty" (to review).
- **Tests:** `test/l10n/l10n_test.dart`: in `tk` the Play screen shows the Turkmen line.
- **Size:** S.

#### 3.7 One coach bubble widget
- **Resolves:** F6.
- **Files:** new `lib/ui/coach_bubble.dart` `CoachSays({image, name?, text, note?, noteColor?, size = 72})`; replace `_Coach` in `lesson_screen.dart` and `onboarding_screen.dart` and `BotSays` in `play/bot_quote.dart` (keep `BotSays` as a thin wrapper to avoid touching callers).
- **Tests:** `test/ui/coach_bubble_test.dart`: renders text and note; long text wraps without overflow at 360 px.
- **Size:** S.

### Phase 4 — features (in order of value)

#### 4.1 Bot reactions in rated games, with no extra engine work
- **Resolves:** A6.
- **Files:** `chess_controller.dart`: keep `int? _lastBotBestCp`. In `_requestBotMove` after `candidateMoves`, `best = candidates.first.cp` (bot's view). If `_lastBotBestCp != null` and not in practice-with-feedback: `best - _lastBotBestCp >= 300` → `_remark(BotMoment.blunder)`; `<= -300` → `_remark(BotMoment.brilliant)`. Refactor `_botRemarkOn` so both paths share the 6-ply cooldown and the 70 % chance. Reset in `startGame`.
- **Tests:** `test/game/bot_voice_test.dart`: fake engine returns +50 then +450 → `botMoment == blunder` and `botMomentSeq` grew; with the cooldown a second swing two plies later does not fire.
- **Size:** S.

#### 4.2 Timed games against bots
- **Resolves:** C3.
- **Files:** `play/pick_opponent_modal.dart`: add a time row (`KustSegmented`: No clock, 3+2, 5 min, 10 min) and pass a `TimeControl?` through `onPlay`; `play/play_screen.dart` puts it in `GameArgs.timeControl`; `game/game_screen.dart:77-81` passes `timeControl: widget.timeControl` to `startGame`; rematch too. `chess_controller.dart`: start the clock on the first move rather than at `startGame` for bot games (set `_lastTick` in `_playPlayerMove`/bot move when `moves.length == 0`), and in `_flagFell` for bot games add `_moveRequestId++; _engine.stopThinking()`. `BotPolicy.moveDelay` already honours `clockLeft`.
- **Strings:** `timeLabel` — en "Time" / ru "Время" / tk "Wagt" (to review).
- **Tests:** `game_end_test.dart`: player's flag falls in a bot game → loss, rating drops; bot's flag falls → win and bot marked beaten; with a lone king → draw. `bot_policy_test.dart` already covers the clock cap.
- **Size:** M. **Depends on:** 1.7.

#### 4.3 Continue an interrupted game
- **Resolves:** C4.
- **Files:** new `lib/core/storage/live_game_store.dart` (user box key `live_game`: mode, botId, playerSide, practice, timeControl, uci moves, clocks, savedAt). `chess_controller.dart`: write after every move, clear on game end, abort and resign; add `Future<bool> resume(LiveGame)` that replays the moves with `Position.play`, rebuilds `history`, `moves` (SAN via `moveToSan`), repetitions and clocks, then asks the bot to move if it is its turn. `play/play_screen.dart`: a "Continue your game" card above the hero when one exists and is younger than 7 days.
- **Strings:** `continueGame` — en "Continue your game" / ru "Продолжить партию" / tk "Oýny dowam et"; `continueGameSub` — en "vs {name}, move {n}" / ru "против {name}, ход {n}" / tk "{name} garşy, {n}-nji göçüm" (to review).
- **Tests:** `test/game/live_game_test.dart`: play 6 plies, new container, `resume` → same FEN, same SAN list, same side to move; finishing the game clears the store; a damaged entry is ignored.
- **Size:** M. **Depends on:** 1.7.

#### 4.4 Camp 3 "Tactics": forks, pins, skewers, discovered attacks
- **Resolves:** C1.
- **Files:** `learn/lesson_task.dart`: new `TaskKind.bestMove` with `solution` (UCI list; first is shown by the hint) — any listed move is `done`, others `wrong`. `learn/lessons.dart`: 4 lessons × 5 tasks, a new `Camp(id: 'tactics', …)` placed before the checkmate camp (shift indexes; `LearnMapLayout._run` must grow to cover 15 tiles). Author positions so the solution wins material in one move.
- **Strings:** titles and intros for 4 lessons, `taskFork` "Attack two pieces at once", `taskPin` "Pin the piece to its king", `taskSkewer` "Attack the king and win the piece behind it", `taskDiscovered` "Move one piece to uncover an attack", `campTacticsTitle` "Tactics", `campTacticsSub` "Win material with simple tricks" — with ru and tk drafts (tk to review; use glossary "çöp", "şa", "şah").
- **Tests:** `test/learn/lessons_test.dart`: for every `bestMove` task the solution is legal; after it, a 1-ply material count (using piece values 1/3/3/5/9) shows the opponent cannot avoid losing at least 2 points, checked by brute force over all replies with dartchess; no non-solution move achieves the same (uniqueness). Existing "every task solvable by hints" must cover the new kind.
- **Size:** L. **Depends on:** 3.5.

#### 4.5 Opening principles and basic endgames
- **Resolves:** C1.
- **Files:** `lessons.dart`: camp "First moves" (control the centre, develop knights and bishops, castle early: tasks reuse `collect`/`castleKing`/`bestMove` from the start position) and camp "Endgames" (queen + king mate in ≤3 as a multi-move task, ladder mate in 2, king opposition to promote). Needs `TaskKind.mateIn(n)` where Black replies with the first legal move from a scripted list; extend `TaskRunner` with `replies`.
- **Strings:** titles, intros, prompts in three languages (tk to review).
- **Tests:** scripted solutions reach mate; every Black reply in the script is legal.
- **Size:** L. **Depends on:** 4.4.

#### 4.6 "Try again" on your mistakes in Review
- **Resolves:** C6.
- **Files:** new `lib/features/review/retry_screen.dart` (route `/review/:id/retry/:ply`): shows the position before the mistake on `PuzzleBoard`, coach line, the player moves; correct = stored `bestUci` (or any move whose stored analysis is within 0.03 expected points, if `secondCp` qualifies); wrong → shake and try again; "Show answer". `review_screen.dart` `_KeyMoment`: add a "Try again" button next to the chevron.
- **Strings:** `retryTitle` "What should you have played?" / "Как нужно было сыграть?" / "Näme göçmelidiňiz?"; `retryRight` "That's the move!" / "Верный ход!" / "Dogry göçüm!"; `retryShow` "Show answer" / "Показать ответ" / "Jogaby görkez" (tk to review).
- **Tests:** `test/review/retry_screen_test.dart`: best move → success text; another move → stays; Show answer draws the arrow.
- **Size:** M. **Depends on:** 1.2.

#### 4.7 Mistakes trainer
- **Resolves:** C7.
- **Files:** new `lib/features/review/mistakes_store.dart`: on each stored analysis, add the player's blunders and mistakes (fen, bestUci, gameId, ply, solved count); a "Your mistakes" card on the Puzzles screen opening them one by one with the 4.6 screen; a position leaves the deck after two correct answers on different days.
- **Strings:** `mistakesTitle` "Your mistakes" / "Ваши ошибки" / "Siziň ýalňyşlyklaryňyz"; `mistakesCount` "{n} to practise" / "{n} для тренировки" / "{n} türgenleşik" (tk to review).
- **Tests:** store adds, dedupes by fen, retires after two solves.
- **Size:** L. **Depends on:** 4.6.

#### 4.8 Opening names
- **Resolves:** C8.
- **Files:** new asset `assets/openings/eco.tsv` (about 300 common lines: ECO, English name, UCI moves; from the CC0 lichess `chess-openings` data), `lib/features/game/openings.dart` (longest-prefix match on UCI moves); show under the move strip in `game_screen.dart` during the first 20 plies, and in History rows and the Review subtitle. Names stay in English/Latin (standard practice); only the label is translated.
- **Tests:** `test/game/openings_test.dart`: `e2e4 e7e5 g1f3 b8c6 f1c4` → "Italian Game"; unknown line → null; the file parses fully.
- **Size:** M.

#### 4.9 More puzzles
- **Resolves:** C5.
- **Files:** `tools/import_puzzles.py`: filter the CC0 Lichess puzzle CSV by theme and rating into the existing `levelN.json` shape; grow each level from 20 to 60 and add levels 6 to 8 (skewers, discovered attacks, endgames). `puzzles/loom.dart` already supports N levels via `kLoomLevels`; add three göl charts or reuse with new colours.
- **Tests:** `test/puzzles/bundled_data_test.dart` already validates every bundled puzzle; extend counts.
- **Size:** L. **Needs the owner's answer to question 4 (carpet length).**

#### 4.10 Player name
- **Resolves:** C10, E2.
- **Files:** `core/storage/app_storage.dart`: `setGuestName`; localized default "Player" when the stored name is one of `_guestNames`; `widgets/more_sheet.dart`: a "Your name" row opening a small text sheet (max 16 chars).
- **Strings:** `yourName` "Your name" / "Ваше имя" / "Adyňyz"; `defaultPlayerName` "Player" / "Игрок" / "Oýunçy" (tk to review).
- **Tests:** store round-trip; Play greeting shows the new name.
- **Size:** S.

### Phase 5 — code health

#### 5.1 One home for castling squares
- **Resolves:** F4.
- **Files:** new `lib/features/game/chess/castling.dart`: `bool isCastle(Position before, NormalMove m)`, `Square kingLanding(NormalMove m, Position before)`, `NormalMove toDartchess(NormalMove kingTwoStep, Position before)`, `String engineUci(NormalMove, Position)`. Replace the six blocks in `chess_controller.dart` (see F4 lines), `game_analyzer.dart:8-31`, `lesson_task.dart` `TaskRunner.landing`, `review/game_review.dart` best-move conversion, `puzzle_board.dart` `_displayCastleTarget`.
- **Tests:** `test/game/castling_test.dart`: all four castles both ways; a king move e1→f1 is not a castle; existing suites stay green.
- **Size:** S. **Depends on:** 1.7.

#### 5.2 Split the chess controller
- **Resolves:** F1. Behaviour must not change.
- **Files:** extract plain classes used by `ChessController` (not new providers): `game_clock.dart` (lines ~463-570), `game_recorder.dart` (`_recordFinishedGame`, ~1615-1742), `move_feedback_runner.dart` (`_analyzeMoveAt`, suggestion, hint, ~780-990 and 1744-1782), `premove_controller.dart` (~1241-1340). Move `GameState` to `game_state.dart`. Target: `chess_controller.dart` under 900 lines.
- **Tests:** none new; `game_end_test.dart`, `premove_test.dart`, `show_best_test.dart`, `local_review_pause_test.dart` are the safety net.
- **Size:** L (do as 3 PRs: state file, clock + recorder, feedback + premoves). **Depends on:** 1.2, 1.7, 5.1.

#### 5.3 Shared isometric tile painter
- **Resolves:** F3.
- **Files:** new `lib/ui/iso_tile.dart` (`IsoTile.diamond`, `IsoTile.paint(canvas, center, width, colors, depth)`); use it in `garden_map.dart` and `onboarding_screen.dart`.
- **Tests:** golden-free: paint into a `PictureRecorder` without throwing for three colour sets.
- **Size:** S. **Depends on:** 2.2.

#### 5.4 Remove dead code
- **Resolves:** F5, E5.
- **Files:** delete `ChessEngine.bestMoveForFen`; remove `title`/`description` fields from `OnboardingLevel`; decide with the owner (question 2) whether to delete the light theme (`KustTokens.light`, `appTheme`, theme rows in `more_sheet.dart`, `themeMode` in settings); note that many tests pump `appTheme`, so switch them to `appDarkTheme` first.
- **Size:** S to M.

### Phase 6 — release readiness

#### 6.1 Crash reporting
- **Resolves:** G2. **Needs the owner's answer to question 3** (it adds the INTERNET permission and changes the privacy statement).
- **Files (if approved, Sentry suggested: no Google services needed):** `pubspec.yaml` add `sentry_flutter`; `main.dart` init with DSN from `--dart-define=SENTRY_DSN`, disabled when empty; route `ErrorLog.record` to it; no user identifiers, no breadcrumbs with moves.
- **Tests:** `ErrorLog` forwards when a reporter is set.
- **Size:** S. **Depends on:** 1.1.

#### 6.2 The name "Küşt" on the launcher
- **Resolves:** E4.
- **Files:** `android/app/src/main/AndroidManifest.xml:3` `android:label="Küşt"`; `ios/Runner/Info.plist` `CFBundleDisplayName` → `Küşt` (keep `CFBundleName` ASCII).
- **Device check:** the icon label on the home screen.
- **Size:** S.

#### 6.3 Turkmen says "küşt" for chess
- **Resolves:** E1.
- **Files:** `lib/l10n/app_tk.arb`: `onbTitle` → "Gowulaşmaga kömek edýän küşt"; `lvlBeginnerD` → "Men küşt öwrenip ýaňy başladym."; mirror in `l10n/REVIEW_tk.md`. Grep every `şahmat` (13 lines) and keep it only where it means checkmate.
- **Tests:** `test/l10n/l10n_test.dart`: update the expected Turkmen onboarding title; add a guard test that `onbTitle` in tk contains "küşt".
- **Size:** S.

#### 6.4 Smaller download: can we ship one network?
- **Resolves:** G3. A spike with a written result, then a go/no-go.
- **Steps:** build with only the small network (`EvalFileSmall`) and check whether the bundled Stockfish runs without the big one; if it does, compare 200 move ratings from stored games between both setups at `analysisDepth` 12 (labels should match in ≥ 97 %). Report APK size and the comparison in `docs/perf/nnue-size.md`.
- **Size:** M.

#### 6.5 Store listing and privacy policy
- **Resolves:** G4.
- **Files:** `docs/store/privacy-policy.md` (no account, no network, data stays on device; update if 6.1 lands), `docs/store/listing_{en,ru,tk}.md` (title ≤ 30, short ≤ 80, full ≤ 4000 chars), a screenshot list (Play, game, Review, Learn map, lesson, Puzzles), data-safety and content-rating answers.
- **Size:** M. **Needs question 5.**

#### 6.6 Data version marker
- **Resolves:** G5.
- **Files:** `app_storage.dart`: user box key `schema` = 1 written in `init()`; a `_migrate(from)` switch with no cases yet.
- **Tests:** fresh install writes 1; an existing box without the key gets 1 and keeps its data.
- **Size:** S.

#### 6.7 iOS icon and a build check
- **Resolves:** G6.
- **Files:** `pubspec.yaml` `flutter_launcher_icons: ios: true` with `remove_alpha_ios: true`; run the generator; confirm `flutter build ios --no-codesign` on a Mac.
- **Size:** S; needs a Mac.

#### 6.8 Native Turkmen review
- **Resolves:** E3. Owner task: go through `l10n/REVIEW_tk.md` (start with Onboarding, Learn, Bot chat, Review sections: they are what a new user reads first) and fix `app_tk.arb`.

### Suggested order
1.1 → 1.7 → 1.8 → 1.4 → 1.6 → 1.5 → 1.2 → 1.3 → 2.1 → 2.2 → 2.3 → (2.4) → 6.3 → 6.2 → 3.2 → 3.3 → 3.5 → 3.6 → 3.1 → 3.4 → 4.1 → 4.2 → 4.3 → 4.6 → 4.4 → 5.1 → 5.2 → the rest.

## 5. Do not do

- **Do not add a liquid-glass or shader blur package.** The bar and sheets are flat on purpose; real backdrop blur costs a full-screen read per surface on Impeller.
- **Do not move Stockfish into a Dart isolate.** It already runs on its own native thread and talks over a stream; the UI isolate only parses short lines.
- **Do not raise engine threads or hash** to make analysis faster; it heats the phone. Persist results instead (1.2).
- **Do not rewrite the board** (`chess_board.dart`) for style; it is the most tuned file in the app and has performance tests.
- **Do not replace `dartchess` rule checks with hand-written ones**, and do not let the engine decide legality.
- **Do not split `chess_controller.dart` before 1.7 exists**; without end-of-game tests the split is blind.
- **Do not add online play, accounts or cloud sync in this plan**; each needs a backend decision first.
- **Do not auto-translate Turkmen in bulk**; use the glossary and mark new strings for review.
- **Do not add `saveLayer`, `Opacity` over large subtrees, or `MaskFilter.blur` in scrolling content.**

## 6. Open questions for the owner

1. **Main button colour:** make green 3D the only main button everywhere and retire gold buttons (task 3.1 default), or keep gold for Play and green for Learn?
2. **Light theme:** delete the light theme code for good, or keep it for a later return?
3. **Crash reporting:** is it acceptable to add the INTERNET permission and send anonymous crash reports (Sentry or Firebase)? The app is fully offline today.
4. **Puzzles:** grow the five carpet levels to 60 puzzles each and add three levels, or keep the carpet at five and put extra puzzles in a separate "Practice" list?
5. **Store:** is there a Google Play developer account, and under which name and contact e-mail should the listing and privacy policy be published?
6. **Brand yellow:** should the splash screen and icon background stay `#FFBB00`, or move to the dark/green look?
7. **Daily reminder:** do you want a local notification for the daily puzzle (needs the notification permission)?
