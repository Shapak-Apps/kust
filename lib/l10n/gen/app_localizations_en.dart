// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get navPlay => 'Play';

  @override
  String get navPuzzles => 'Puzzles';

  @override
  String get navHistory => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get achievements => 'Achievements';

  @override
  String get cont => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get forward => 'Forward';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get delete => 'Delete';

  @override
  String get keep => 'Keep';

  @override
  String get close => 'Close';

  @override
  String get options => 'Options';

  @override
  String get youName => 'You';

  @override
  String get whiteName => 'White';

  @override
  String get blackName => 'Black';

  @override
  String get random => 'Random';

  @override
  String get play => 'Play';

  @override
  String eloValue(int elo) {
    return '$elo Elo';
  }

  @override
  String get passAndPlay => 'Pass & Play';

  @override
  String vsBot(String name) {
    return 'vs $name';
  }

  @override
  String get gameStartTitle => 'Game start';

  @override
  String get whiteMovesFirst => 'White moves first';

  @override
  String get youPlayAsWhite => 'You play as White';

  @override
  String get youPlayAsBlack => 'You play as Black';

  @override
  String get engineUnavailable => 'Engine unavailable';

  @override
  String get engineCouldNotStart =>
      'The chess engine could not start. Try again, or play on this device with a friend.';

  @override
  String get botsNotSupported =>
      'Playing against bots is not supported on this device.';

  @override
  String get playLocallyInstead => 'Play locally instead';

  @override
  String get abortTitle => 'Abort this game?';

  @override
  String get abortSubtitle => 'The game will end without a result.';

  @override
  String get abort => 'Abort';

  @override
  String get keepPlaying => 'Keep playing';

  @override
  String get resignTitle => 'Resign this game?';

  @override
  String get resignSubtitle => 'The game will end and count as a loss.';

  @override
  String get resign => 'Resign';

  @override
  String get leaveGame => 'Leave game';

  @override
  String get exportGame => 'Export game';

  @override
  String get showResult => 'Show result';

  @override
  String get resultCheckmate => 'Checkmate';

  @override
  String get resultDraw => 'Draw';

  @override
  String get resultTimeOut => 'Time out';

  @override
  String get resultGameOver => 'Game over';

  @override
  String wonTheGame(String name) {
    return '$name won the game.';
  }

  @override
  String get gameDrawn => 'The game ended in a draw.';

  @override
  String get gameEndedOnTime => 'The game ended on time.';

  @override
  String get youResigned => 'You resigned.';

  @override
  String endCheckmateWon(String name) {
    return '$name won by checkmate.';
  }

  @override
  String get endStalemate => 'Game drawn by stalemate.';

  @override
  String get endFiftyMove => 'Game drawn by 50-move rule.';

  @override
  String get endInsufficient => 'Game drawn due to insufficient material.';

  @override
  String get endRepetition => 'Game drawn by threefold repetition.';

  @override
  String endTimeWon(String name) {
    return '$name won on time.';
  }

  @override
  String get endTimeNoMate =>
      'Time ran out, but the other side cannot checkmate.';

  @override
  String get lobby => 'Lobby';

  @override
  String get rematch => 'Rematch';

  @override
  String ratingChange(int rating, String change) {
    return 'Rating $rating ($change)';
  }

  @override
  String accuracyValue(String value) {
    return 'Accuracy $value%';
  }

  @override
  String get analyzingYourMoves => 'Analyzing your moves…';

  @override
  String get thinking => 'thinking';

  @override
  String invite1(String name) {
    return 'Inviting $name to the game…';
  }

  @override
  String invite2(String name) {
    return '$name is taking a seat…';
  }

  @override
  String get invite3 => 'Setting up the board…';

  @override
  String invite4(String name) {
    return '$name is getting ready…';
  }

  @override
  String get takeBack => 'Take back';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get hint => 'Hint';

  @override
  String analyzingMove(String san) {
    return 'Analyzing $san…';
  }

  @override
  String get pausedTitle => 'Paused';

  @override
  String get tapToResume => 'Tap to resume';

  @override
  String get pausedSemantics => 'Paused. Tap to resume';

  @override
  String promoteTo(String piece) {
    return 'Promote to $piece';
  }

  @override
  String get cancelPromotion => 'Cancel promotion';

  @override
  String get pieceQueen => 'queen';

  @override
  String get pieceRook => 'rook';

  @override
  String get pieceBishop => 'bishop';

  @override
  String get pieceKnight => 'knight';

  @override
  String get noMovesYet => 'No moves yet';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get gameOptions => 'Game options';

  @override
  String get evalBar => 'Evaluation bar';

  @override
  String get evalBarSub => 'Shows who is better';

  @override
  String get moveFeedback => 'Move feedback';

  @override
  String get moveFeedbackSub => 'Rates each move you play';

  @override
  String get showBest => 'Show best';

  @override
  String get showBestSub => 'An arrow to the better move after yours';

  @override
  String get boardImage => 'Board image';

  @override
  String get boardImageSub => 'Share the position as a PNG';

  @override
  String get copyFen => 'Copy FEN';

  @override
  String get copyFenSub => 'This position, for any chess app';

  @override
  String get copyPgn => 'Copy PGN';

  @override
  String get copyPgnSub => 'Every move of the game';

  @override
  String get sharePgn => 'Share PGN';

  @override
  String get sharePgnSub => 'Send the game to another app';

  @override
  String get fenCopied => 'FEN copied';

  @override
  String get pgnCopied => 'PGN copied';

  @override
  String get qBrilliant => 'Brilliant';

  @override
  String get qGreat => 'Great';

  @override
  String get qBest => 'Best move';

  @override
  String get qExcellent => 'Excellent';

  @override
  String get qGood => 'Good';

  @override
  String get qInaccuracy => 'Inaccuracy';

  @override
  String get qMistake => 'Mistake';

  @override
  String get qMiss => 'Miss';

  @override
  String get qBlunder => 'Blunder';

  @override
  String bannerBrilliant(String played) {
    return '$played · brilliant move';
  }

  @override
  String bannerGreat(String played) {
    return '$played · great move';
  }

  @override
  String bannerBest(String played) {
    return '$played · best move';
  }

  @override
  String bannerExcellent(String played, String best) {
    return '$played was excellent · $best was best';
  }

  @override
  String bannerGood(String played, String best) {
    return '$played was good · $best was best';
  }

  @override
  String bannerInaccuracy(String played, String best) {
    return '$played was an inaccuracy · $best was best';
  }

  @override
  String bannerMistake(String played, String best) {
    return '$played was a mistake · $best was best';
  }

  @override
  String bannerMiss(String played, String best) {
    return '$played was a miss · $best was best';
  }

  @override
  String bannerBlunder(String played, String best) {
    return '$played was a blunder · $best was best';
  }

  @override
  String get welcomeTitle => 'Welcome to Küşt';

  @override
  String get welcomeSub =>
      'Play bots, solve puzzles and get better one move at a time.';

  @override
  String get letsPlay => 'Let’s play';

  @override
  String get challengeBot => 'Challenge a bot';

  @override
  String get newStudents => 'New students from Turkmenistan';

  @override
  String helloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get readyForGame => 'Ready for a game?';

  @override
  String ratingBots(int rating, int beaten, int total) {
    return 'Rating $rating · Bots beaten $beaten of $total';
  }

  @override
  String get playAGame => 'Play a game';

  @override
  String get pickOpponent => 'Pick opponent';

  @override
  String get eloShows => 'Elo shows how strong they play';

  @override
  String get playAs => 'Play as';

  @override
  String get selectOpponent => 'Select an opponent';

  @override
  String playBot(String name) {
    return 'Play $name';
  }

  @override
  String get youMoveFirst => 'You move first';

  @override
  String botMovesFirst(String name) {
    return '$name moves first';
  }

  @override
  String get letFateDecide => 'Let fate decide';

  @override
  String get blitz => 'Blitz';

  @override
  String get rapid => 'Rapid';

  @override
  String minutesShort(int n) {
    return '$n min';
  }

  @override
  String get timeControl => 'Time control';

  @override
  String get timeControlSub => 'How long does each player get?';

  @override
  String get noClock => 'No clock';

  @override
  String get noClockSub => 'Untimed casual game';

  @override
  String get startGame => 'Start game';

  @override
  String get newGame => 'New game';

  @override
  String get playWithBots => 'Play with bots';

  @override
  String get playWithBotsSub => 'Challenge one of our bots';

  @override
  String get playLocally => 'Play locally';

  @override
  String get playLocallySub => 'Pass & play on this device';

  @override
  String get practiceMode => 'Practice mode';

  @override
  String get practiceModeSub => 'Allows undo, hints and move feedback';

  @override
  String get practiceTag => 'Practice';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get boardSection => 'Board';

  @override
  String get piecesSection => 'Pieces';

  @override
  String get movesSection => 'Moves';

  @override
  String get castleOnRook => 'Castle on the rook';

  @override
  String get castleOnRookSub => 'Tap the king, then its rook, to castle';

  @override
  String get premoves => 'Premoves';

  @override
  String get premovesSub => 'Queue your next move while the bot thinks';

  @override
  String get feedbackSection => 'Feedback';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get haptics => 'Haptics';

  @override
  String boardThemeSemantics(String theme) {
    return '$theme board';
  }

  @override
  String pieceSetSemantics(String set) {
    return '$set pieces';
  }

  @override
  String get boardBrown => 'Brown';

  @override
  String get boardGreen => 'Green';

  @override
  String get boardDarkBlue => 'Dark Blue';

  @override
  String get boardWood => 'Wood';

  @override
  String get pieceClassic => 'Classic';

  @override
  String get pieceShaded => 'Shaded';

  @override
  String get pieceGraphite => 'Graphite';

  @override
  String get pieceBrushed => 'Brushed';

  @override
  String get histNoGames => 'No games yet';

  @override
  String get histNoGamesSub =>
      'Finished games show up here so you can replay them.';

  @override
  String get deleteGameTitle => 'Delete this game?';

  @override
  String get deleteGameSub => 'It will be removed from your history.';

  @override
  String get resultWhiteWon => 'White won';

  @override
  String get resultBlackWon => 'Black won';

  @override
  String get resultWin => 'Win';

  @override
  String get resultLoss => 'Loss';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get monthsShort => 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';

  @override
  String dateShort(String month, int day) {
    return '$month $day';
  }

  @override
  String get semGamePassPlay => 'Pass and play';

  @override
  String semGameVsBot(String name) {
    return 'Game against $name';
  }

  @override
  String semAccuracy(String value) {
    return 'accuracy $value percent';
  }

  @override
  String get analysisUnavailable =>
      'Analysis is not available on this device right now';

  @override
  String get retryAnalysis => 'Retry analysis';

  @override
  String get analyzeGame => 'Analyze this game';

  @override
  String get gameTitle => 'Game';

  @override
  String get replaySettings => 'Replay settings';

  @override
  String get evalBarReplaySub => 'Shows who is better at each move';

  @override
  String get moveFeedbackReplaySub => 'Rates each move as you step through';

  @override
  String get showBestReplaySub =>
      'An arrow to the best move when another was played';

  @override
  String get notAvailableHere => 'Not available on this device';

  @override
  String get evalUnavailable => 'Evaluation is unavailable right now';

  @override
  String get gameNotFound => 'This game could not be found.';

  @override
  String get backToHistory => 'Back to history';

  @override
  String puzzleN(int n) {
    return 'Puzzle $n';
  }

  @override
  String get allPuzzles => 'All puzzles';

  @override
  String get puzzleCouldNotLoad => 'Could not load this puzzle';

  @override
  String get puzzlesCouldNotLoad => 'Could not load puzzles';

  @override
  String get noPuzzlesAvailable => 'No puzzles are available yet';

  @override
  String get noPuzzlesYet => 'No puzzles yet. Check back soon.';

  @override
  String get puzzleSolved => 'Puzzle solved!';

  @override
  String get solutionShown => 'Solution shown';

  @override
  String get notThatOne => 'Not that one';

  @override
  String get whiteToMove => 'White to move';

  @override
  String get blackToMove => 'Black to move';

  @override
  String get backToPuzzles => 'Back to puzzles';

  @override
  String get solution => 'Solution';

  @override
  String get nextPuzzle => 'Next puzzle';

  @override
  String get nextLevel => 'Next level';

  @override
  String themeMateIn(int n) {
    return 'Mate in $n';
  }

  @override
  String get themeFork => 'Fork';

  @override
  String get themePin => 'Pin';

  @override
  String get themeEndgame => 'Endgame';

  @override
  String get themeWinMaterial => 'Win material';

  @override
  String get loomMate1 => 'Mate in 1';

  @override
  String get loomMate2 => 'Mate in 2';

  @override
  String get loomForks => 'Forks';

  @override
  String get loomPins => 'Pins';

  @override
  String get loomEndgames => 'Endgames';

  @override
  String get puzzlesAllWoven => 'All puzzles woven!';

  @override
  String puzzlesNext(String theme) {
    return 'Next: $theme';
  }

  @override
  String get puzzlesMoreSoon => 'More are coming soon.';

  @override
  String get reviewPuzzles => 'Review puzzles';

  @override
  String continueTheme(String theme) {
    return 'Continue · $theme';
  }

  @override
  String get statRating => 'RATING';

  @override
  String get statKnots => 'KNOTS';

  @override
  String get statBest => 'BEST';

  @override
  String puzzlesSolvedOf(String theme, int solved, int total) {
    return '$theme · $solved of $total solved';
  }

  @override
  String loomProgress(String theme, int done, int total) {
    return '$theme, $done of $total knots woven';
  }

  @override
  String get levelWoven => 'Woven ✓';

  @override
  String levelKnots(int done, int total) {
    return '$done of $total knots';
  }

  @override
  String get levelNotStarted => 'Not started';

  @override
  String get levelComingSoon => 'Coming soon';

  @override
  String golWovenSem(String tribe) {
    return '$tribe göl, woven';
  }

  @override
  String golWoven(String tribe) {
    return '$tribe göl woven';
  }

  @override
  String golWholeCarpet(int knots) {
    return '$knots of $knots knots. The whole carpet is done.';
  }

  @override
  String golNext(int knots, String next) {
    return '$knots of $knots knots. The $next göl is next.';
  }

  @override
  String get dailyPuzzle => 'Daily puzzle';

  @override
  String get solvedToday => 'Solved today';

  @override
  String get dailySolved => 'solved';

  @override
  String dailyStreakSem(String days) {
    return 'streak $days';
  }

  @override
  String get coachMateIn1 =>
      'One move ends the game. Can you see it?\nFind the move that mates right now.\nThe king has no way out. Close the door!';

  @override
  String get coachMateIn2 =>
      'Can you force mate in two moves?\nStart with a check or a strong threat.\nTwo moves to mate. Which one comes first?';

  @override
  String get coachMateIn3 =>
      'Mate in three. Think forcing moves.\nChecks first, then see where the king goes.';

  @override
  String get coachFork =>
      'Find a move that attacks two pieces at once.\nCan you spot a fork?\nOne piece, two targets. Where does it land?';

  @override
  String get coachPin =>
      'A piece cannot move. Can you use that?\nLook for a pinned piece and pile on.\nWhat is stuck in front of its king?';

  @override
  String get coachEndgame =>
      'Few pieces, big ideas. Take your time.\nIn the endgame your king is a fighter.\nCareful moves win this one.';

  @override
  String get coachGeneric =>
      'Look for checks, captures and threats first.\nWhat is hanging? Take your time.\nThe best move is usually forcing.';

  @override
  String get coachWrong =>
      'Close, but not quite. Try another move.\nNot this one. Think about checks and captures.\nHmm, look again. You can do this!\nThat lets them off. What else is there?';

  @override
  String get coachCorrect =>
      'Nice work! On to the next one.\nYou saw it. Well played!\nSharp eyes. That was clean.\nAnother knot woven. Keep going!';

  @override
  String get coachRetry =>
      'Study it, then try it yourself.\nNow you know. Hit Retry!\nWatch how the pieces work together.';

  @override
  String get coachDaily =>
      'Never skip puzzle day!\nLook for checks, captures and threats first.\nOne puzzle a day keeps the blunders away.\nTake your time: the best move is usually forcing.';

  @override
  String achEarnedOf(int earned, int total) {
    return '$earned of $total earned';
  }

  @override
  String get achUnlocked => 'Achievement unlocked';

  @override
  String get achEarned => 'earned';

  @override
  String get achNotEarned => 'not earned yet';

  @override
  String get ach_first_game_t => 'First move';

  @override
  String get ach_first_game_d => 'Finish a game against a bot';

  @override
  String get ach_first_win_t => 'First victory';

  @override
  String get ach_first_win_d => 'Win a game against a bot';

  @override
  String get ach_checkmate_t => 'Checkmate!';

  @override
  String get ach_checkmate_d => 'Win a game by checkmate';

  @override
  String get ach_quick_mate_t => 'Lightning';

  @override
  String get ach_quick_mate_d => 'Checkmate a bot in 20 moves or less';

  @override
  String get ach_giant_slayer_t => 'Giant slayer';

  @override
  String get ach_giant_slayer_d => 'Beat a bot rated 300 or more above you';

  @override
  String get ach_three_bots_t => 'Rising star';

  @override
  String get ach_three_bots_d => 'Beat 3 different bots';

  @override
  String get ach_all_bots_t => 'Champion';

  @override
  String get ach_all_bots_d => 'Beat every bot';

  @override
  String get ach_marathon_t => 'Marathon';

  @override
  String get ach_marathon_d => 'Play a game of 60 moves or more';

  @override
  String get ach_accurate_t => 'Sharpshooter';

  @override
  String get ach_accurate_d => 'Play a game with 90% accuracy';

  @override
  String get ach_brilliant_t => 'Brilliant!';

  @override
  String get ach_brilliant_d => 'Play a brilliant move';

  @override
  String get ach_first_puzzle_t => 'Puzzler';

  @override
  String get ach_first_puzzle_d => 'Solve your first puzzle';

  @override
  String get ach_puzzles_25_t => 'Knot by knot';

  @override
  String get ach_puzzles_25_d => 'Solve 25 puzzles';

  @override
  String get ach_first_gol_t => 'First göl';

  @override
  String get ach_first_gol_d => 'Weave a whole göl';

  @override
  String get ach_whole_carpet_t => 'Master weaver';

  @override
  String get ach_whole_carpet_d => 'Weave all five göls';

  @override
  String get ach_streak_3_t => 'On a roll';

  @override
  String get ach_streak_3_d => 'Solve the daily puzzle 3 days in a row';

  @override
  String get ach_streak_7_t => 'Week of fire';

  @override
  String get ach_streak_7_d => 'Solve the daily puzzle 7 days in a row';

  @override
  String get onbGetStarted => 'Get started';

  @override
  String get onbStartPlaying => 'Start playing';

  @override
  String get onbSkip => 'Skip for now';

  @override
  String get onbTitle => 'Chess that helps you improve';

  @override
  String get onbIntro =>
      'Play bots at your level, train with puzzles and replay your games to learn from them.';

  @override
  String get onbPlayBots => 'Play bots';

  @override
  String get onbPlayBotsSub =>
      'From 400 to 2000 Elo, or pass the phone to a friend';

  @override
  String get onbSolve => 'Solve puzzles';

  @override
  String get onbSolveSub => 'Short tactics with hints and a rating';

  @override
  String get onbReview => 'Review your games';

  @override
  String get onbReviewSub => 'Every finished game is saved for replay';

  @override
  String get onbNoAccount =>
      'No account needed. Your games and progress stay on this device.';

  @override
  String get onbHowStrong => 'How strong are you?';

  @override
  String get onbHowStrongSub =>
      'This sets your starting rating. It adjusts as you play, so don’t overthink it.';

  @override
  String get lvlBeginner => 'Beginner';

  @override
  String get lvlBeginnerD => 'I’m just getting started with chess.';

  @override
  String get lvlIntermediate => 'Intermediate';

  @override
  String get lvlIntermediateD => 'I know the basics and play regularly.';

  @override
  String get lvlAdvanced => 'Advanced';

  @override
  String get lvlAdvancedD => 'I understand strategy and complex positions.';

  @override
  String get lvlCompetitive => 'Competitive';

  @override
  String get lvlCompetitiveD =>
      'I play seriously and may compete in tournaments.';

  @override
  String get onbAllSet => 'You’re all set';

  @override
  String onbStartingRating(int rating) {
    return 'Your starting rating is $rating.\nYour first game is one tap away.';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get yourAvatar => 'Your avatar';

  @override
  String avatarOf(String name) {
    return '$name, your avatar';
  }

  @override
  String get language => 'Language';

  @override
  String get languageAuto => 'System';

  @override
  String get youWonGame => 'You won the game.';

  @override
  String get youWonOnTime => 'You won on time.';
}
