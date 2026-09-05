# Küşt

Küşt is an open-source chess application built with Dart and Flutter. It combines `dartchess` for chess rules and position handling with Stockfish for playing against bots and analyzing finished games.

The main idea behind Küşt is simple: chess analysis should help you improve, not just tell you that a move was bad. After a game, Küşt examines your decisions, identifies inaccuracies, mistakes, and blunders, and explains what could have been played instead and what you should learn from the position.

## Features

### Play Against Bots

Play complete chess games against Stockfish-powered opponents. The application is designed to support different playing strengths so you can choose an opponent that fits your level.

`dartchess` is responsible for maintaining the chess position and validating moves, while Stockfish provides the engine calculation used by the bot.

### Analyze Your Games

After a game, Küşt can go through the played moves position by position and compare your moves with Stockfish's analysis.

The analysis can classify moves into categories such as:

- **Best move**: a move that matches or is very close to the engine's preferred choice.
- **Good move**: a strong and reasonable move that keeps the position in good shape.
- **Inaccuracy**: a small error that worsens the position but usually does not change the result immediately.
- **Mistake**: a more serious error that gives the opponent a meaningful advantage.
- **Blunder**: a major error that can lose material, position, or the game.
- **Missed opportunity**: a position where a stronger tactical or positional continuation was available but was not played.

The exact thresholds are determined by the analysis implementation and engine settings.

### Learn From Mistakes

Küşt is intended to go further than showing engine evaluations. For every important mistake, the goal is to explain the position in a way a player can actually use.

For example, instead of only displaying that a move changed the evaluation from `+1.2` to `-2.4`, the analysis can explain that the move allowed a tactical attack, left a piece undefended, ignored an opponent's threat, or missed a simple way to win material.

A useful analysis should answer four questions:

1. What did I play?
2. What was the better move?
3. Why was the better move stronger?
4. What should I remember for the next game?

The long-term goal is to turn engine output into practical lessons rather than a collection of numbers.

### Personal Chess Insights

By analyzing multiple games, Küşt can eventually identify recurring weaknesses in a player's chess. For example, a player may repeatedly miss tactical threats, lose material in the opening, make inaccurate decisions in endgames, or struggle when under pressure.

These patterns can be used to provide more useful feedback and suggest what the player should study or practice next.

## How It Works

The application is built around three main components.

### `dartchess`

`dartchess` provides the chess logic used by the application. It handles the board position, legal moves, chess rules, notation, and position representation.

This keeps chess rules separate from the user interface and engine code.

### Stockfish

Stockfish is used for two main purposes:

- playing against the user as a chess engine opponent;
- evaluating positions and finding stronger moves during game analysis.

The engine is not responsible for enforcing the rules of the game. `dartchess` handles the chess state and legal move validation, while Stockfish calculates positions.

### Analysis Layer

The analysis layer connects the game history with Stockfish. It replays the game, evaluates the relevant positions, compares the player's move with stronger alternatives, and assigns an appropriate classification.

The result can then be presented to the player as a structured explanation of what happened during the game.

A typical analysis flow is:

```text
Finished game
    -> Replay the moves
    -> Evaluate positions with Stockfish
    -> Compare played moves with stronger alternatives
    -> Measure the change in evaluation
    -> Classify important moves
    -> Explain the reason for the error
    -> Produce learning feedback
```

## Example Analysis

A simplified example of the intended experience could look like this:

```text
Move: 18...Qxd4?

Classification: Mistake

You captured the pawn on d4, but the move allowed White to develop
with tempo and attack the queen. The stronger continuation was
18...Nc6, keeping the queen safe and maintaining development.

Lesson:
Before making a capture, check whether the opponent can respond
with a forcing move such as a check, capture, or attack on your queen.
```

The exact explanation depends on the position and the analysis implementation. The goal is to make the feedback understandable to a human player rather than simply exposing raw Stockfish output.

## Tech Stack

| Technology | Purpose                                                 |
| ---------- | ------------------------------------------------------- |
| Dart       | Application and core logic                              |
| Flutter    | User interface and cross-platform application           |
| dartchess  | Chess rules, legal moves, FEN/PGN and position handling |
| Stockfish  | Bot gameplay and chess analysis                         |

## Getting Started

### Requirements

Before running Küşt, make sure you have:

- Flutter SDK installed
- Dart SDK compatible with the Flutter version
- Git
- A working Stockfish integration for your target platform

### Clone the Repository

```bash
git clone https://github.com/Shapak-Apps/kust.git
cd kust
```

### Install Dependencies

```bash
flutter pub get
```

### Run the Application

```bash
flutter run
```

Stockfish setup can differ between Android, iOS, desktop, and other targets. Follow the platform-specific configuration used by the project when enabling the engine.

## Roadmap

The project is still evolving. Planned functionality includes:

- Playing against Stockfish bots
- Adjustable bot difficulty
- Complete game history
- FEN and PGN support
- Local game storage
- Post-game analysis
- Inaccuracy, mistake, and blunder detection
- Missed opportunity detection
- Explanations for critical moves
- Personal mistake pattern detection
- Opening performance analysis
- Tactical training based on previous mistakes
- Endgame analysis
- Progress tracking
- Importing games for analysis
- Exporting games as PGN

## Contributing

Küşt is open source and contributions are welcome.

You can contribute to the project by improving the chess analysis, Stockfish integration, performance, UI, testing, documentation, or learning features.

### Development Workflow

Fork the repository, create a branch for your changes, make the changes, and open a pull request.

Before submitting a pull request, format the Dart code and run the tests:

```bash
dart format .
flutter test
```

Chess software has many edge cases, so changes involving chess logic should include appropriate tests whenever possible. Important cases include check, checkmate, castling, en passant, promotion, FEN/PGN parsing, engine evaluation, and move classification.

## Open Source

Küşt is intended to remain an open-source project. The repository should provide a place where developers can contribute improvements and where chess players can help shape the learning experience.

Please make sure that the final project license and all third-party dependencies comply with their respective licenses and attribution requirements.

## License

The project license will be added to the repository. If MIT is chosen, the repository should include the standard MIT `LICENSE` file.

## Acknowledgements

Küşt uses and builds upon:

- [dartchess](https://pub.dev/packages/dartchess)
- [Stockfish](https://stockfishchess.org/)
- [Flutter](https://flutter.dev/)

Please follow the licensing and attribution requirements of each dependency used by the project.
