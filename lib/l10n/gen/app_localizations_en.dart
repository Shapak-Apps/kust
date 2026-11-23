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
  String resignLocalTitle(String name) {
    return '$name: resign?';
  }

  @override
  String resignLocalSubtitle(String winner) {
    return 'The game will end and $winner wins.';
  }

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
  String get showBestSub =>
      'Shows an arrow to the best move for you to play now';

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
  String get qBook => 'Book';

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
  String bannerBook(String played) {
    return '$played · book move';
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

  @override
  String get botGreetBahar =>
      'Salam! I am Bahar. I am learning chess too, let\'s play!';

  @override
  String get botGreetElizabeth => 'Good day. Shall we have a pleasant game?';

  @override
  String get botGreetMark => 'Hey! Ready for a game? I am!';

  @override
  String get botGreetApex => 'Think you can beat me? Let\'s see.';

  @override
  String get botGreetKarl => 'Take your time. Chess rewards patience.';

  @override
  String get botGreetEnejan => 'Welcome! Sit down, let\'s play a game.';

  @override
  String get botGreetMaya => 'Hi! I like clever moves. Show me yours.';

  @override
  String get botGreetYura => 'Let\'s play. I do not go easy.';

  @override
  String get botGreetBerdi => 'Welcome. Chess is a long road. Let us walk it.';

  @override
  String get botCheerfulBlunder =>
      'Oh! Thank you for that!|Whoa, did you mean to do that?';

  @override
  String get botCheerfulBrilliant =>
      'Wow, what a move!|You are really good at this!';

  @override
  String get botCheerfulWin =>
      'Yay, a win! Great game!|That was fun, play again?';

  @override
  String get botCheerfulLoss =>
      'You got me! Well played!|Wow, you win! Let\'s go again!';

  @override
  String get botCheerfulDraw =>
      'A draw! Fair and square.|Nobody lost, so we both won!';

  @override
  String get botCalmBlunder =>
      'An interesting choice.|I will gladly take that.';

  @override
  String get botCalmBrilliant =>
      'A fine move. Well seen.|Impressive. That was unexpected.';

  @override
  String get botCalmWin => 'A good game. Thank you.|Better luck next time.';

  @override
  String get botCalmLoss =>
      'Well played. You earned it.|Congratulations, a deserved win.';

  @override
  String get botCalmDraw => 'A fair result.|We were evenly matched.';

  @override
  String get botCockyBlunder => 'Ha! Too easy.|Was that your plan?';

  @override
  String get botCockyBrilliant =>
      'Lucky shot. Don\'t get used to it.|Okay, that was not bad.';

  @override
  String get botCockyWin => 'Never in doubt.|Better luck next time, champ.';

  @override
  String get botCockyLoss =>
      'Fine, this one is yours. Rematch?|Beginner\'s luck. Again!';

  @override
  String get botCockyDraw =>
      'A draw? I was only warming up.|Hmm. Next time I win.';

  @override
  String get botWiseBlunder => 'Think before you move.|Every move has a price.';

  @override
  String get botWiseBrilliant =>
      'A move worth remembering.|Now that is real chess.';

  @override
  String get botWiseWin => 'Every game teaches something.|Learn from this one.';

  @override
  String get botWiseLoss =>
      'You taught me something today.|Well played, a worthy victory.';

  @override
  String get botWiseDraw =>
      'Balance is also a result.|A calm game, a calm ending.';

  @override
  String get botChat => 'Bot chat';

  @override
  String get botChatSub => 'Bots comment on the game';

  @override
  String get reviewTitle => 'Game review';

  @override
  String get reviewButton => 'Review';

  @override
  String get reviewAccuracy => 'Accuracy';

  @override
  String get reviewMoves => 'Moves';

  @override
  String get reviewGraph => 'Who was winning';

  @override
  String get reviewKeyTitle => 'Moves to learn from';

  @override
  String get reviewNoBig => 'No big mistakes. Well played!';

  @override
  String reviewBestWas(String san) {
    return 'Best was $san';
  }

  @override
  String reviewMoveNo(int n) {
    return 'Move $n';
  }

  @override
  String get reviewOpenReplay => 'Open replay';

  @override
  String get reviewNoEngine =>
      'The engine is not available on this device, so the game cannot be analyzed.';

  @override
  String get reviewFailed => 'The analysis did not finish.';

  @override
  String get reviewTooShort => 'This game is too short to review.';

  @override
  String get navLearn => 'Learn';

  @override
  String get learnTitle => 'Learn';

  @override
  String get learnSub => 'From your first move to checkmate';

  @override
  String get lessonStart => 'Start lesson';

  @override
  String get learnWrong => 'Not quite. Try again.';

  @override
  String get learnStalemate => 'That is stalemate, a draw. Find the checkmate.';

  @override
  String get learnWellDone => 'Well done!';

  @override
  String get lessonDone => 'Lesson complete!';

  @override
  String get lessonNext => 'Next lesson';

  @override
  String get lessonPlayGame => 'Play a game';

  @override
  String get learnHint => 'Hint';

  @override
  String get learnAllDone => 'You finished every lesson. Time to play!';

  @override
  String get pieceKing => 'king';

  @override
  String get piecePawn => 'pawn';

  @override
  String taskCollectOne(String piece) {
    return 'Move the $piece to the star';
  }

  @override
  String taskCollectMany(String piece) {
    return 'Collect every star with the $piece';
  }

  @override
  String get taskCapture => 'Capture all the marked pieces';

  @override
  String get taskBestCapture => 'Capture the most valuable piece';

  @override
  String get taskCheck => 'Give check';

  @override
  String get taskMate => 'Checkmate in one move';

  @override
  String get taskEscape => 'Your king is in check. Get out of check.';

  @override
  String get taskEscapeCapture => 'Get out of check by capturing the attacker';

  @override
  String get taskCastleKing =>
      'Castle kingside: move the king two squares towards the rook';

  @override
  String get taskCastleQueen =>
      'Castle queenside: move the king two squares towards the rook';

  @override
  String get taskEnPassant => 'Capture the pawn en passant';

  @override
  String get taskPromote => 'Move the pawn to the last row to promote it';

  @override
  String get lessonPawnTitle => 'The pawn';

  @override
  String get lessonPawnIntro =>
      'Pawns are the foot soldiers. A pawn moves one square forward, or two from its starting square. It captures one square diagonally forward, never straight ahead.';

  @override
  String get lessonRookTitle => 'The rook';

  @override
  String get lessonRookIntro =>
      'The rook moves any number of squares in a straight line, along a row or a column. It cannot jump over other pieces.';

  @override
  String get lessonBishopTitle => 'The bishop';

  @override
  String get lessonBishopIntro =>
      'The bishop moves any number of squares diagonally. It always stays on the same colour of square.';

  @override
  String get lessonQueenTitle => 'The queen';

  @override
  String get lessonQueenIntro =>
      'The queen is the strongest piece. She moves like a rook and a bishop together: any number of squares in a straight line or diagonally.';

  @override
  String get lessonKnightTitle => 'The knight';

  @override
  String get lessonKnightIntro =>
      'The knight moves in an L: two squares one way and one square to the side. It is the only piece that jumps over others.';

  @override
  String get lessonKingTitle => 'The king';

  @override
  String get lessonKingIntro =>
      'The king moves one square in any direction. Protect him: if he is lost, the game is lost. He can never step next to the enemy king or into an attack.';

  @override
  String get lessonValuesTitle => 'Taking pieces';

  @override
  String get lessonValuesIntro =>
      'Pieces are worth points: pawn 1, knight 3, bishop 3, rook 5, queen 9. Capturing a bigger piece wins material. Always look for the most valuable capture.';

  @override
  String get lessonCheckTitle => 'Check';

  @override
  String get lessonCheckIntro =>
      'When a king is attacked, it is in check. You must get out of check at once: move the king, block the attack, or capture the attacker.';

  @override
  String get lessonSpecialTitle => 'Special moves';

  @override
  String get lessonSpecialIntro =>
      'Castling moves your king two squares towards a rook, and the rook jumps over it. En passant lets a pawn capture one that has just moved two squares past it. A pawn that reaches the last row promotes, usually to a queen.';

  @override
  String get lessonMateTitle => 'Checkmate';

  @override
  String get lessonMateIntro =>
      'Checkmate is a check that cannot be escaped: the game ends and you win. If the other side has no legal move but is not in check, it is stalemate, a draw. Be careful not to stalemate when you are winning.';

  @override
  String get lessonFirstMatesTitle => 'Your first checkmates';

  @override
  String get lessonFirstMatesIntro =>
      'Three patterns that win games: the back rank mate, the two-rook ladder and the queen with the king. Find the mate in one move.';

  @override
  String get campPiecesTitle => 'The pieces';

  @override
  String get campPiecesSub => 'Learn how every piece moves';

  @override
  String get campRulesTitle => 'The rules';

  @override
  String get campRulesSub => 'Captures, check and special moves';

  @override
  String get campMateTitle => 'Checkmate';

  @override
  String get campMateSub => 'Win your first games';

  @override
  String campLabel(int n) {
    return 'CAMP $n';
  }

  @override
  String get summitLabel => 'SUMMIT';

  @override
  String learnUpNext(int n) {
    return 'UP NEXT · LESSON $n';
  }

  @override
  String lessonLabel(int n) {
    return 'LESSON $n';
  }

  @override
  String lessonMinutes(int n, int m) {
    return '$n tasks · $m min';
  }

  @override
  String get learnSummitDone => 'You reached the summit';

  @override
  String get lessonMistakes => 'Mistakes';

  @override
  String get lessonHintsUsed => 'Hints';

  @override
  String get lessonTasksDone => 'Tasks';

  @override
  String get lessonBackToMap => 'Back to the map';

  @override
  String get learnCoachDone => 'That is it! Tap Continue.';

  @override
  String get lessonPerfect => 'Perfect lesson!';

  @override
  String get onbStartLesson => 'Start the first lesson';

  @override
  String lessonLocked(int n) {
    return 'Finish lesson $n first.';
  }

  @override
  String get lessonLockedHint => 'Each lesson builds on the one before it.';

  @override
  String lessonLockedOpen(int n) {
    return 'Open lesson $n';
  }

  @override
  String get yourName => 'Your name';

  @override
  String get defaultPlayerName => 'Player';

  @override
  String get saveName => 'Save';

  @override
  String get continueGame => 'Continue your game';

  @override
  String continueGameSub(String who, int n) {
    return '$who · move $n';
  }

  @override
  String get retryTitle => 'What should you have played?';

  @override
  String get retryRight => 'That\'s the move!';

  @override
  String get retryWrong => 'Not quite. Try again.';

  @override
  String get retryShow => 'Show answer';

  @override
  String get retryTry => 'Try again';

  @override
  String get retryNoPosition => 'This move cannot be shown.';

  @override
  String get reviewAnalyzingTitle => 'Analyzing your game';

  @override
  String reviewCheckingMove(int n, int total) {
    return 'Checking move $n of $total';
  }

  @override
  String get reviewTip1 =>
      'Accuracy compares each of your moves with the engine\'s best move.';

  @override
  String get reviewTip2 =>
      'A blunder gives away a lot in one move. Look for those first.';

  @override
  String get reviewTip3 =>
      'Tap the replay button on a key moment to try that position again.';

  @override
  String get reviewTip4 =>
      'Brilliant moves are rare: a sacrifice the engine agrees with.';

  @override
  String get reviewTip5 => 'Once analyzed, a game opens instantly next time.';

  @override
  String get sendErrorReport => 'Send error report';

  @override
  String get taskFork => 'Fork: attack two pieces with one move';

  @override
  String get taskPin => 'Pin a piece to its king';

  @override
  String get taskSkewer => 'Check the king and win the piece behind it';

  @override
  String get lessonForkTitle => 'The fork';

  @override
  String get lessonForkIntro =>
      'A fork attacks two pieces at once. The other side can save only one, so you win the other. Knights are the masters of the fork.';

  @override
  String get lessonPinTitle => 'The pin';

  @override
  String get lessonPinIntro =>
      'A pinned piece cannot move, because the king behind it would be in check. Pin a piece, then attack it again to win it.';

  @override
  String get lessonSkewerTitle => 'The skewer';

  @override
  String get lessonSkewerIntro =>
      'A skewer is a pin turned around: you check the king, it must step aside, and you take the piece behind it.';

  @override
  String get lessonPatternsTitle => 'Mate patterns';

  @override
  String get lessonPatternsIntro =>
      'Strong players know mates by their shape: the smothered mate with a knight, the queen right next to the king, and the rook and knight working together. Find the mate in one move.';

  @override
  String get campTacticsTitle => 'Tactics';

  @override
  String get campTacticsSub => 'Win pieces with clever moves';

  @override
  String get profile => 'Profile';

  @override
  String get username => 'Username';

  @override
  String get usernameRule => '3–20 letters, digits or _';

  @override
  String get bio => 'About you';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get onbNameTitle => 'What should we call you?';

  @override
  String get onbNameSub => 'You can change these later in your profile.';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get navTrain => 'Train';

  @override
  String get joined => 'Joined';

  @override
  String get rating => 'Rating';

  @override
  String get games => 'Games';

  @override
  String get gameHistory => 'Game history';

  @override
  String get viewAll => 'View all';

  @override
  String get qrCode => 'QR code';

  @override
  String get trainSoonSub =>
      'A new way to practise is on its way. Until then, keep sharp with puzzles.';

  @override
  String get solvePuzzles => 'Solve puzzles';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutTitle => 'Log out?';

  @override
  String get logOutSub =>
      'Your name, username, bio and photo are removed from this device and you play as a guest. Your games and progress stay.';

  @override
  String get youWonTitle => 'You won!';

  @override
  String get youLostTitle => 'You lost';

  @override
  String get byCheckmate => 'by checkmate';

  @override
  String get byResignation => 'by resignation';

  @override
  String get byTimeout => 'on time';

  @override
  String get byStalemate => 'by stalemate';

  @override
  String get byRepetition => 'by repetition';

  @override
  String get byFiftyMove => 'by the 50-move rule';

  @override
  String get byInsufficient => 'by insufficient material';

  @override
  String get byAgreement => 'by agreement';

  @override
  String get byTimeNoMate => 'on time, with no mate possible';

  @override
  String get tierCommon => 'Common';

  @override
  String get tierRare => 'Rare';

  @override
  String get tierMythic => 'Mythic';

  @override
  String get opItalianD =>
      'Quick development and an early fight for the centre: bishop to c4 aims at f7, then c3 and d3 or d4. Calm on the surface, full of traps underneath.';

  @override
  String get opRuyLopezD =>
      'The bishop pins pressure on the knight that guards e5. A slow, rich plan that has been the main road at the top for over a century.';

  @override
  String get opLondonD =>
      'The same easy setup almost every game: d4, Bf4, e3, Nf3 and c3. Solid, quick to learn, and full of chances to attack the king.';

  @override
  String get opQueensGambitD =>
      'White offers the c-pawn to pull Black\'s d-pawn from the centre. If Black takes, White builds a big centre and wins the pawn back.';

  @override
  String get opKingsGambitD =>
      'White gives the f-pawn on move two to open the f-file and race for the attack. Wild, risky and a favourite of the Romantic era.';

  @override
  String get opFriedLiverD =>
      'Against the Two Knights, the knight jumps to g5 and then sacrifices itself on f7 to drag the black king into the open.';

  @override
  String get opSicilianD =>
      'Black answers 1.e4 with c5 and fights unequally: sharp, double-edged games where Black plays to win, not to draw.';

  @override
  String get opFrenchD =>
      'Black builds a solid chain with e6 and d5, lets White take space, then strikes back at the centre with c5.';

  @override
  String get opCaroKannD =>
      'Like the French, but the light-squared bishop gets out first. A sound, hard-to-crack defence with a clean pawn structure.';

  @override
  String get opKingsIndianD =>
      'Black lets White take the whole centre, finishes castling, then hits back with e5 or c5 and often storms the kingside.';

  @override
  String get opScandinavianD =>
      'Black attacks e4 at once with d5. One simple idea, a quick game, and little theory to remember.';

  @override
  String get opBudapestD =>
      'Against 1.d4 Nf6 2.c4, Black throws in e5 to free the pieces fast. The pawn usually comes back, with the initiative.';

  @override
  String get kindOpening => 'Opening';

  @override
  String get kindDefense => 'Defence';

  @override
  String get kindGambit => 'Gambit';

  @override
  String get kindAttack => 'Attack';

  @override
  String get trainAll => 'All';

  @override
  String get trainSearch => 'Search openings';

  @override
  String get trainTryFirst => 'Try the first line';

  @override
  String trainLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String get trainAsWhite => 'As White';

  @override
  String get trainAsBlack => 'As Black';

  @override
  String trainPractise(String name) {
    return 'Practise vs $name';
  }

  @override
  String get trainNoResults => 'No openings match your search.';

  @override
  String get trainMainLine => 'Main line';

  @override
  String get trainSecondLine => 'Second line';

  @override
  String get trainThirdLine => 'Third line';

  @override
  String trainOrigin(String origin) {
    return 'Named after $origin';
  }

  @override
  String get toStart => 'To the start';

  @override
  String get toEnd => 'To the end';

  @override
  String trainLineProgress(String name, int done, int total) {
    return '$name · move $done of $total';
  }

  @override
  String trainLineWrong(String san) {
    return 'Not the line. Play $san';
  }

  @override
  String get trainLineDone => 'Line done! Play on from here.';

  @override
  String get showBestAfterLine => 'Unlocks when you finish the opening line';

  @override
  String get yourMove => 'Your move';

  @override
  String sideToMove(String name) {
    return '$name to move';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get discardGame => 'Remove this game';

  @override
  String get gameRemoved => 'Game removed';

  @override
  String get undo => 'Undo';

  @override
  String get doneButton => 'Done';
}
