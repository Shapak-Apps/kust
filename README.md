# Küşt

![Küşt](https://raw.githubusercontent.com/Shapak-Apps/kust/main/assets/images/banner.png)

Küşt is an open-source chess application built with Flutter and Dart. It uses `dartchess` for chess rules and position handling, and Stockfish as the engine for bot gameplay and position evaluation.

The core idea: chess analysis should help you improve, not just tell you a move was bad. After a game, Küşt examines your decisions, identifies inaccuracies, mistakes, and blunders, and explains what could have been played instead and what you should take away from the position.

## Features

### Play Against Bots

Play complete games against Stockfish-powered bots at adjustable difficulty levels. Bot strength is mapped from an Elo rating to a Stockfish skill level, so you can pick an opponent that suits where you are as a player.

`dartchess` maintains the chess position and validates moves. Stockfish handles engine calculation for the bot's responses.

### Move Undo and Hints

During a game you can undo your last move or request a hint. Hints run Stockfish at full strength on a short time budget and highlight the suggested origin and destination squares. Undo steps back both the player move and the preceding bot move so the position stays consistent.

### Move Classification

After a game, Küşt evaluates the played positions with Stockfish and classifies each move:

- **Best move** — matches or comes very close to the engine's preferred choice
- **Good move** — strong and reasonable, keeps the position in good shape
- **Inaccuracy** — a small error that worsens the position without immediately changing the result
- **Mistake** — a more serious error that gives the opponent a meaningful advantage
- **Blunder** — a major error that loses material, position, or the game
- **Missed opportunity** — a position where a stronger continuation existed but was not played

### Post-Game Analysis

Küşt is designed to go further than raw engine evaluations. For every significant error, the goal is to explain what happened in terms a player can actually use.

A useful analysis answers four questions:

1. What did I play?
2. What was the better move?
3. Why was the better move stronger?
4. What should I remember for the next game?

An example of the intended output:

```
Move: 18...Qxd4?

Classification: Mistake

You captured the pawn on d4, but the move allowed White to develop
with tempo and attack the queen. The stronger continuation was
18...Nc6, keeping the queen safe and maintaining development.

Lesson:
Before making a capture, check whether the opponent can respond
with a forcing move such as a check, capture, or attack on your queen.
```

### Personal Pattern Detection

By analyzing multiple games, Küşt can identify recurring weaknesses — repeatedly missing tactical threats, losing material in the opening, struggling in endgames, or making poor decisions under pressure. These patterns feed into more targeted feedback and study suggestions.

## Architecture

The application is built around three components.

### dartchess

Handles chess logic: board position, legal move generation, rule enforcement, FEN and PGN parsing, and position representation. Chess rules are kept entirely separate from the UI and engine layers.

### Stockfish

Used for two purposes:

- calculating moves for the bot opponent during gameplay
- evaluating positions and finding stronger alternatives during post-game analysis

Stockfish does not enforce chess rules. `dartchess` owns the game state and legal move validation. Stockfish only sees FEN strings.

### Analysis Layer

Connects the game history to Stockfish. It replays the game, evaluates positions, compares the player's moves against stronger alternatives, measures the evaluation change, and classifies the result.

```
Finished game
  -> Replay moves
  -> Evaluate positions with Stockfish
  -> Compare played moves with stronger alternatives
  -> Measure evaluation delta
  -> Classify moves
  -> Explain critical errors
  -> Produce learning feedback
```

## Tech Stack

| Technology         | Purpose                                           |
| ------------------ | ------------------------------------------------- |
| Dart               | Application language and core logic               |
| Flutter            | UI and cross-platform application shell           |
| dartchess          | Chess rules, legal moves, FEN/PGN, position state |
| Stockfish          | Bot gameplay and position analysis                |
| Riverpod           | State management                                  |
| go_router          | Declarative navigation                            |
| audioplayers       | Move and game event sounds                        |
| shared_preferences | Onboarding state persistence                      |
| flutter_svg        | SVG asset rendering                               |

## Getting Started

### Requirements

- Flutter SDK
- Dart SDK compatible with the Flutter version
- Git
- A working Stockfish integration for your target platform

Stockfish setup differs between Android, iOS, and desktop. Follow the platform-specific configuration in the project when setting up the engine.

### Clone and Run

```bash
git clone https://github.com/Shapak-Apps/kust.git
cd kust
flutter pub get
flutter run
```

## Roadmap

- [x] Play against Stockfish bots
- [x] Adjustable bot difficulty
- [x] Move undo
- [x] Hints during play
- [ ] Complete game history
- [ ] FEN and PGN support
- [ ] Local game storage
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

The project license will be added to the repository.

## Acknowledgements

Küşt builds on:

- [dartchess](https://pub.dev/packages/dartchess)
- [Stockfish](https://stockfishchess.org/)
- [Flutter](https://flutter.dev/)

Follow the licensing and attribution requirements for each dependency.
