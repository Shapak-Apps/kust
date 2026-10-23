# Küşt

![Küşt - Improve, Learn moreover Practice your chess](https://raw.githubusercontent.com/Shapak-Apps/kust/main/assets/images/banner.png)

Küşt is an open-source chess application built with Flutter and Dart. It uses `dartchess` for chess rules and position handling, and Stockfish as the engine for bot gameplay and position evaluation.

The core idea: chess analysis should help you improve, not just tell you a move was bad. Post-game analysis with move classification and explanations is on the roadmap — right now Küşt is focused on being a genuinely good place to play.

## Features

### Play Against Bots

Play complete games against Stockfish-powered bots at adjustable difficulty levels. Bot strength is mapped from an Elo rating to a Stockfish skill level (and UCI Elo where supported), so you can pick an opponent that suits where you are as a player.

`dartchess` maintains the chess position and validates moves. Stockfish handles engine calculation for the bot's responses.

### Local Pass-and-Play

No engine, no wifi excuse. Play a full game locally on one device with a friend, no Stockfish dependency required.

### Time Controls

Pick from preset time controls (blitz, rapid, with or without increment) before starting a game, with a live clock for both sides during play.

### Move Undo and Hints

During a game you can undo your last move or request a hint. Hints run Stockfish at full strength on a short time budget and highlight the suggested origin and destination squares. Undo steps back both the player move and the preceding bot move so the position stays consistent.

### Practice Mode

Toggle practice mode to play more freely while still getting the full board and engine experience — good for exploring lines without it counting against your rating.

### Rating System

Küşt tracks your own Elo-style rating locally (it starts at 1200, or at the value for the experience level you pick during onboarding) and updates it after rated games against bots. Practice-mode and pass-and-play games do not affect it. The change is shown in the post-game result.

### Game History and Replay

Every finished game is saved locally, newest first, with the opponent, result and moves. Open one from the History tab to step through it move by move. Long-press a game to delete it.

### Evaluation Bar

An optional live evaluation bar shows how the position is trending as the game progresses.

## Architecture

The application is built around three components.

### dartchess

Handles chess logic: board position, legal move generation, rule enforcement, FEN and PGN parsing, and position representation. Chess rules are kept entirely separate from the UI and engine layers.

### Stockfish

Used for two purposes:

- calculating moves for the bot opponent during gameplay
- powering hints and the live evaluation bar

Stockfish does not enforce chess rules. `dartchess` owns the game state and legal move validation. Stockfish only sees FEN strings.

Stockfish currently runs on Android and iOS. On any other platform, or if the engine fails to start or stops responding, Küşt tells you and offers pass-and-play instead of freezing.

The engine's two NNUE network files (about 110MB) ship inside the app, so bots work offline from the first launch. They are **not committed to git**. Run `python3 tools/pack_nnue.py` once after cloning (and before release builds): it downloads the networks from `data.stockfishchess.org`, verifies their names against their hash, and packs them into gzip pieces in `assets/engine/`, which is git-ignored. On first launch the app unpacks the pieces into its support directory (a few seconds, with a progress bar), checks them again, and reuses them afterwards. Without the packed files the app still builds, and bot games offer pass-and-play instead.

## Tech Stack

| Technology         | Purpose                                           |
| ------------------ | ------------------------------------------------- |
| Dart               | Application language and core logic               |
| Flutter            | UI and cross-platform application shell           |
| dartchess          | Chess rules, legal moves, FEN/PGN, position state |
| Stockfish          | Bot gameplay, hints, and live evaluation          |
| Riverpod           | State management                                  |
| go_router          | Declarative navigation                            |
| audioplayers       | Move and game event sounds                        |
| shared_preferences | Onboarding state and settings persistence         |
| Hive               | Local ratings, puzzle progress and game history   |
| flutter_svg        | SVG asset rendering                               |

## Getting Started

### Requirements

- Flutter SDK
- Dart SDK compatible with the Flutter version
- Git
- An Android or iOS device or emulator to play against bots (other platforms run pass-and-play only)

### Clone and Run

```bash
git clone https://github.com/Shapak-Apps/kust.git
cd kust
python3 tools/pack_nnue.py   # one-time: fetches and packs the engine
flutter pub get
flutter run
```

### Release builds

Release builds are signed with `android/key.properties`, which is not committed:

```properties
storeFile=../upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Without that file a release build falls back to the debug key so `flutter run --release` still works locally. Never publish such a build. The Android and iOS application ID is `com.shapakapps.kust`.

## Roadmap (will be updated soon)

- [x] Play against Stockfish bots
- [x] Adjustable bot difficulty
- [x] Move undo
- [x] Hints during play
- [x] Local pass-and-play mode
- [x] Time controls
- [x] Local Elo-style rating tracking
- [x] Live evaluation bar
- [x] Puzzles (level 1)
- [x] Game history with replay
- [x] Local game storage
- [ ] More puzzle levels and themes
- [ ] FEN and PGN support
- [ ] Post-game analysis
- [ ] Inaccuracy, mistake, and blunder detection
- [ ] Missed opportunity detection
- [ ] Explanations for critical moves
- [ ] Personal mistake pattern detection
- [ ] Opening performance analysis
- [ ] Tactical training based on previous mistakes
- [ ] Endgame analysis
- [ ] Progress tracking
- [ ] Import games for analysis
- [ ] Export games as PGN

## Contributing

Küşt is open source and contributions are welcome.

Fork the repository, create a branch, make your changes, and open a pull request.

Before submitting, format and test:

```bash
dart format .
flutter test
```

Chess software has many edge cases. Changes involving chess logic should include tests where possible. Critical cases include check, checkmate, castling, en passant, promotion, FEN and PGN parsing, engine evaluation, and move classification.

## License

Küşt is licensed under the [GNU General Public License v3.0](LICENSE). It uses [Stockfish](https://stockfishchess.org/) and [dartchess](https://pub.dev/packages/dartchess), both GPL-3.0.

## Acknowledgements

Küşt builds on:

- [dartchess](https://pub.dev/packages/dartchess)
- [Stockfish](https://stockfishchess.org/)
- [Flutter](https://flutter.dev/)

Follow the licensing and attribution requirements for each dependency.
