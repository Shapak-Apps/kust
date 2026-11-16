import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('tk'),
  ];

  /// No description provided for @navPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get navPlay;

  /// No description provided for @navPuzzles.
  ///
  /// In en, this message translates to:
  /// **'Puzzles'**
  String get navPuzzles;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @cont.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cont;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @youName.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youName;

  /// No description provided for @whiteName.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get whiteName;

  /// No description provided for @blackName.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get blackName;

  /// No description provided for @random.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @eloValue.
  ///
  /// In en, this message translates to:
  /// **'{elo} Elo'**
  String eloValue(int elo);

  /// No description provided for @passAndPlay.
  ///
  /// In en, this message translates to:
  /// **'Pass & Play'**
  String get passAndPlay;

  /// No description provided for @vsBot.
  ///
  /// In en, this message translates to:
  /// **'vs {name}'**
  String vsBot(String name);

  /// No description provided for @gameStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Game start'**
  String get gameStartTitle;

  /// No description provided for @whiteMovesFirst.
  ///
  /// In en, this message translates to:
  /// **'White moves first'**
  String get whiteMovesFirst;

  /// No description provided for @youPlayAsWhite.
  ///
  /// In en, this message translates to:
  /// **'You play as White'**
  String get youPlayAsWhite;

  /// No description provided for @youPlayAsBlack.
  ///
  /// In en, this message translates to:
  /// **'You play as Black'**
  String get youPlayAsBlack;

  /// No description provided for @engineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Engine unavailable'**
  String get engineUnavailable;

  /// No description provided for @engineCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'The chess engine could not start. Try again, or play on this device with a friend.'**
  String get engineCouldNotStart;

  /// No description provided for @botsNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Playing against bots is not supported on this device.'**
  String get botsNotSupported;

  /// No description provided for @playLocallyInstead.
  ///
  /// In en, this message translates to:
  /// **'Play locally instead'**
  String get playLocallyInstead;

  /// No description provided for @abortTitle.
  ///
  /// In en, this message translates to:
  /// **'Abort this game?'**
  String get abortTitle;

  /// No description provided for @abortSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The game will end without a result.'**
  String get abortSubtitle;

  /// No description provided for @abort.
  ///
  /// In en, this message translates to:
  /// **'Abort'**
  String get abort;

  /// No description provided for @keepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get keepPlaying;

  /// No description provided for @resignTitle.
  ///
  /// In en, this message translates to:
  /// **'Resign this game?'**
  String get resignTitle;

  /// No description provided for @resignSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The game will end and count as a loss.'**
  String get resignSubtitle;

  /// No description provided for @resignLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}: resign?'**
  String resignLocalTitle(String name);

  /// No description provided for @resignLocalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The game will end and {winner} wins.'**
  String resignLocalSubtitle(String winner);

  /// No description provided for @resign.
  ///
  /// In en, this message translates to:
  /// **'Resign'**
  String get resign;

  /// No description provided for @leaveGame.
  ///
  /// In en, this message translates to:
  /// **'Leave game'**
  String get leaveGame;

  /// No description provided for @exportGame.
  ///
  /// In en, this message translates to:
  /// **'Export game'**
  String get exportGame;

  /// No description provided for @showResult.
  ///
  /// In en, this message translates to:
  /// **'Show result'**
  String get showResult;

  /// No description provided for @resultCheckmate.
  ///
  /// In en, this message translates to:
  /// **'Checkmate'**
  String get resultCheckmate;

  /// No description provided for @resultDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get resultDraw;

  /// No description provided for @resultTimeOut.
  ///
  /// In en, this message translates to:
  /// **'Time out'**
  String get resultTimeOut;

  /// No description provided for @resultGameOver.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get resultGameOver;

  /// No description provided for @wonTheGame.
  ///
  /// In en, this message translates to:
  /// **'{name} won the game.'**
  String wonTheGame(String name);

  /// No description provided for @gameDrawn.
  ///
  /// In en, this message translates to:
  /// **'The game ended in a draw.'**
  String get gameDrawn;

  /// No description provided for @gameEndedOnTime.
  ///
  /// In en, this message translates to:
  /// **'The game ended on time.'**
  String get gameEndedOnTime;

  /// No description provided for @youResigned.
  ///
  /// In en, this message translates to:
  /// **'You resigned.'**
  String get youResigned;

  /// No description provided for @endStalemate.
  ///
  /// In en, this message translates to:
  /// **'Game drawn by stalemate.'**
  String get endStalemate;

  /// No description provided for @endFiftyMove.
  ///
  /// In en, this message translates to:
  /// **'Game drawn by 50-move rule.'**
  String get endFiftyMove;

  /// No description provided for @endInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Game drawn due to insufficient material.'**
  String get endInsufficient;

  /// No description provided for @endRepetition.
  ///
  /// In en, this message translates to:
  /// **'Game drawn by threefold repetition.'**
  String get endRepetition;

  /// No description provided for @endTimeWon.
  ///
  /// In en, this message translates to:
  /// **'{name} won on time.'**
  String endTimeWon(String name);

  /// No description provided for @endTimeNoMate.
  ///
  /// In en, this message translates to:
  /// **'Time ran out, but the other side cannot checkmate.'**
  String get endTimeNoMate;

  /// No description provided for @lobby.
  ///
  /// In en, this message translates to:
  /// **'Lobby'**
  String get lobby;

  /// No description provided for @rematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get rematch;

  /// No description provided for @ratingChange.
  ///
  /// In en, this message translates to:
  /// **'Rating {rating} ({change})'**
  String ratingChange(int rating, String change);

  /// No description provided for @accuracyValue.
  ///
  /// In en, this message translates to:
  /// **'Accuracy {value}%'**
  String accuracyValue(String value);

  /// No description provided for @analyzingYourMoves.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your moves…'**
  String get analyzingYourMoves;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'thinking'**
  String get thinking;

  /// No description provided for @invite1.
  ///
  /// In en, this message translates to:
  /// **'Inviting {name} to the game…'**
  String invite1(String name);

  /// No description provided for @invite2.
  ///
  /// In en, this message translates to:
  /// **'{name} is taking a seat…'**
  String invite2(String name);

  /// No description provided for @invite3.
  ///
  /// In en, this message translates to:
  /// **'Setting up the board…'**
  String get invite3;

  /// No description provided for @invite4.
  ///
  /// In en, this message translates to:
  /// **'{name} is getting ready…'**
  String invite4(String name);

  /// No description provided for @takeBack.
  ///
  /// In en, this message translates to:
  /// **'Take back'**
  String get takeBack;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @analyzingMove.
  ///
  /// In en, this message translates to:
  /// **'Analyzing {san}…'**
  String analyzingMove(String san);

  /// No description provided for @pausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausedTitle;

  /// No description provided for @tapToResume.
  ///
  /// In en, this message translates to:
  /// **'Tap to resume'**
  String get tapToResume;

  /// No description provided for @pausedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Paused. Tap to resume'**
  String get pausedSemantics;

  /// No description provided for @promoteTo.
  ///
  /// In en, this message translates to:
  /// **'Promote to {piece}'**
  String promoteTo(String piece);

  /// No description provided for @cancelPromotion.
  ///
  /// In en, this message translates to:
  /// **'Cancel promotion'**
  String get cancelPromotion;

  /// No description provided for @pieceQueen.
  ///
  /// In en, this message translates to:
  /// **'queen'**
  String get pieceQueen;

  /// No description provided for @pieceRook.
  ///
  /// In en, this message translates to:
  /// **'rook'**
  String get pieceRook;

  /// No description provided for @pieceBishop.
  ///
  /// In en, this message translates to:
  /// **'bishop'**
  String get pieceBishop;

  /// No description provided for @pieceKnight.
  ///
  /// In en, this message translates to:
  /// **'knight'**
  String get pieceKnight;

  /// No description provided for @noMovesYet.
  ///
  /// In en, this message translates to:
  /// **'No moves yet'**
  String get noMovesYet;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @gameOptions.
  ///
  /// In en, this message translates to:
  /// **'Game options'**
  String get gameOptions;

  /// No description provided for @evalBar.
  ///
  /// In en, this message translates to:
  /// **'Evaluation bar'**
  String get evalBar;

  /// No description provided for @evalBarSub.
  ///
  /// In en, this message translates to:
  /// **'Shows who is better'**
  String get evalBarSub;

  /// No description provided for @moveFeedback.
  ///
  /// In en, this message translates to:
  /// **'Move feedback'**
  String get moveFeedback;

  /// No description provided for @moveFeedbackSub.
  ///
  /// In en, this message translates to:
  /// **'Rates each move you play'**
  String get moveFeedbackSub;

  /// No description provided for @showBest.
  ///
  /// In en, this message translates to:
  /// **'Show best'**
  String get showBest;

  /// No description provided for @showBestSub.
  ///
  /// In en, this message translates to:
  /// **'Shows an arrow to the best move for you to play now'**
  String get showBestSub;

  /// No description provided for @boardImage.
  ///
  /// In en, this message translates to:
  /// **'Board image'**
  String get boardImage;

  /// No description provided for @boardImageSub.
  ///
  /// In en, this message translates to:
  /// **'Share the position as a PNG'**
  String get boardImageSub;

  /// No description provided for @copyFen.
  ///
  /// In en, this message translates to:
  /// **'Copy FEN'**
  String get copyFen;

  /// No description provided for @copyFenSub.
  ///
  /// In en, this message translates to:
  /// **'This position, for any chess app'**
  String get copyFenSub;

  /// No description provided for @copyPgn.
  ///
  /// In en, this message translates to:
  /// **'Copy PGN'**
  String get copyPgn;

  /// No description provided for @copyPgnSub.
  ///
  /// In en, this message translates to:
  /// **'Every move of the game'**
  String get copyPgnSub;

  /// No description provided for @sharePgn.
  ///
  /// In en, this message translates to:
  /// **'Share PGN'**
  String get sharePgn;

  /// No description provided for @sharePgnSub.
  ///
  /// In en, this message translates to:
  /// **'Send the game to another app'**
  String get sharePgnSub;

  /// No description provided for @fenCopied.
  ///
  /// In en, this message translates to:
  /// **'FEN copied'**
  String get fenCopied;

  /// No description provided for @pgnCopied.
  ///
  /// In en, this message translates to:
  /// **'PGN copied'**
  String get pgnCopied;

  /// No description provided for @qBrilliant.
  ///
  /// In en, this message translates to:
  /// **'Brilliant'**
  String get qBrilliant;

  /// No description provided for @qGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get qGreat;

  /// No description provided for @qBest.
  ///
  /// In en, this message translates to:
  /// **'Best move'**
  String get qBest;

  /// No description provided for @qExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get qExcellent;

  /// No description provided for @qGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get qGood;

  /// No description provided for @qBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get qBook;

  /// No description provided for @qInaccuracy.
  ///
  /// In en, this message translates to:
  /// **'Inaccuracy'**
  String get qInaccuracy;

  /// No description provided for @qMistake.
  ///
  /// In en, this message translates to:
  /// **'Mistake'**
  String get qMistake;

  /// No description provided for @qMiss.
  ///
  /// In en, this message translates to:
  /// **'Miss'**
  String get qMiss;

  /// No description provided for @qBlunder.
  ///
  /// In en, this message translates to:
  /// **'Blunder'**
  String get qBlunder;

  /// No description provided for @bannerBrilliant.
  ///
  /// In en, this message translates to:
  /// **'{played} · brilliant move'**
  String bannerBrilliant(String played);

  /// No description provided for @bannerGreat.
  ///
  /// In en, this message translates to:
  /// **'{played} · great move'**
  String bannerGreat(String played);

  /// No description provided for @bannerBest.
  ///
  /// In en, this message translates to:
  /// **'{played} · best move'**
  String bannerBest(String played);

  /// No description provided for @bannerBook.
  ///
  /// In en, this message translates to:
  /// **'{played} · book move'**
  String bannerBook(String played);

  /// No description provided for @bannerExcellent.
  ///
  /// In en, this message translates to:
  /// **'{played} was excellent · {best} was best'**
  String bannerExcellent(String played, String best);

  /// No description provided for @bannerGood.
  ///
  /// In en, this message translates to:
  /// **'{played} was good · {best} was best'**
  String bannerGood(String played, String best);

  /// No description provided for @bannerInaccuracy.
  ///
  /// In en, this message translates to:
  /// **'{played} was an inaccuracy · {best} was best'**
  String bannerInaccuracy(String played, String best);

  /// No description provided for @bannerMistake.
  ///
  /// In en, this message translates to:
  /// **'{played} was a mistake · {best} was best'**
  String bannerMistake(String played, String best);

  /// No description provided for @bannerMiss.
  ///
  /// In en, this message translates to:
  /// **'{played} was a miss · {best} was best'**
  String bannerMiss(String played, String best);

  /// No description provided for @bannerBlunder.
  ///
  /// In en, this message translates to:
  /// **'{played} was a blunder · {best} was best'**
  String bannerBlunder(String played, String best);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Küşt'**
  String get welcomeTitle;

  /// No description provided for @welcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Play bots, solve puzzles and get better one move at a time.'**
  String get welcomeSub;

  /// No description provided for @letsPlay.
  ///
  /// In en, this message translates to:
  /// **'Let’s play'**
  String get letsPlay;

  /// No description provided for @challengeBot.
  ///
  /// In en, this message translates to:
  /// **'Challenge a bot'**
  String get challengeBot;

  /// No description provided for @newStudents.
  ///
  /// In en, this message translates to:
  /// **'New students from Turkmenistan'**
  String get newStudents;

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloName(String name);

  /// No description provided for @readyForGame.
  ///
  /// In en, this message translates to:
  /// **'Ready for a game?'**
  String get readyForGame;

  /// No description provided for @ratingBots.
  ///
  /// In en, this message translates to:
  /// **'Rating {rating} · Bots beaten {beaten} of {total}'**
  String ratingBots(int rating, int beaten, int total);

  /// No description provided for @playAGame.
  ///
  /// In en, this message translates to:
  /// **'Play a game'**
  String get playAGame;

  /// No description provided for @pickOpponent.
  ///
  /// In en, this message translates to:
  /// **'Pick opponent'**
  String get pickOpponent;

  /// No description provided for @eloShows.
  ///
  /// In en, this message translates to:
  /// **'Elo shows how strong they play'**
  String get eloShows;

  /// No description provided for @playAs.
  ///
  /// In en, this message translates to:
  /// **'Play as'**
  String get playAs;

  /// No description provided for @selectOpponent.
  ///
  /// In en, this message translates to:
  /// **'Select an opponent'**
  String get selectOpponent;

  /// No description provided for @playBot.
  ///
  /// In en, this message translates to:
  /// **'Play {name}'**
  String playBot(String name);

  /// No description provided for @youMoveFirst.
  ///
  /// In en, this message translates to:
  /// **'You move first'**
  String get youMoveFirst;

  /// No description provided for @botMovesFirst.
  ///
  /// In en, this message translates to:
  /// **'{name} moves first'**
  String botMovesFirst(String name);

  /// No description provided for @letFateDecide.
  ///
  /// In en, this message translates to:
  /// **'Let fate decide'**
  String get letFateDecide;

  /// No description provided for @blitz.
  ///
  /// In en, this message translates to:
  /// **'Blitz'**
  String get blitz;

  /// No description provided for @rapid.
  ///
  /// In en, this message translates to:
  /// **'Rapid'**
  String get rapid;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutesShort(int n);

  /// No description provided for @timeControl.
  ///
  /// In en, this message translates to:
  /// **'Time control'**
  String get timeControl;

  /// No description provided for @timeControlSub.
  ///
  /// In en, this message translates to:
  /// **'How long does each player get?'**
  String get timeControlSub;

  /// No description provided for @noClock.
  ///
  /// In en, this message translates to:
  /// **'No clock'**
  String get noClock;

  /// No description provided for @noClockSub.
  ///
  /// In en, this message translates to:
  /// **'Untimed casual game'**
  String get noClockSub;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start game'**
  String get startGame;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGame;

  /// No description provided for @playWithBots.
  ///
  /// In en, this message translates to:
  /// **'Play with bots'**
  String get playWithBots;

  /// No description provided for @playWithBotsSub.
  ///
  /// In en, this message translates to:
  /// **'Challenge one of our bots'**
  String get playWithBotsSub;

  /// No description provided for @playLocally.
  ///
  /// In en, this message translates to:
  /// **'Play locally'**
  String get playLocally;

  /// No description provided for @playLocallySub.
  ///
  /// In en, this message translates to:
  /// **'Pass & play on this device'**
  String get playLocallySub;

  /// No description provided for @practiceMode.
  ///
  /// In en, this message translates to:
  /// **'Practice mode'**
  String get practiceMode;

  /// No description provided for @practiceModeSub.
  ///
  /// In en, this message translates to:
  /// **'Allows undo, hints and move feedback'**
  String get practiceModeSub;

  /// No description provided for @practiceTag.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceTag;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @boardSection.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get boardSection;

  /// No description provided for @piecesSection.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get piecesSection;

  /// No description provided for @movesSection.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get movesSection;

  /// No description provided for @castleOnRook.
  ///
  /// In en, this message translates to:
  /// **'Castle on the rook'**
  String get castleOnRook;

  /// No description provided for @castleOnRookSub.
  ///
  /// In en, this message translates to:
  /// **'Tap the king, then its rook, to castle'**
  String get castleOnRookSub;

  /// No description provided for @premoves.
  ///
  /// In en, this message translates to:
  /// **'Premoves'**
  String get premoves;

  /// No description provided for @premovesSub.
  ///
  /// In en, this message translates to:
  /// **'Queue your next move while the bot thinks'**
  String get premovesSub;

  /// No description provided for @feedbackSection.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackSection;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffects;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @boardThemeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{theme} board'**
  String boardThemeSemantics(String theme);

  /// No description provided for @pieceSetSemantics.
  ///
  /// In en, this message translates to:
  /// **'{set} pieces'**
  String pieceSetSemantics(String set);

  /// No description provided for @boardBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get boardBrown;

  /// No description provided for @boardGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get boardGreen;

  /// No description provided for @boardDarkBlue.
  ///
  /// In en, this message translates to:
  /// **'Dark Blue'**
  String get boardDarkBlue;

  /// No description provided for @boardWood.
  ///
  /// In en, this message translates to:
  /// **'Wood'**
  String get boardWood;

  /// No description provided for @pieceClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get pieceClassic;

  /// No description provided for @pieceShaded.
  ///
  /// In en, this message translates to:
  /// **'Shaded'**
  String get pieceShaded;

  /// No description provided for @pieceGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get pieceGraphite;

  /// No description provided for @pieceBrushed.
  ///
  /// In en, this message translates to:
  /// **'Brushed'**
  String get pieceBrushed;

  /// No description provided for @histNoGames.
  ///
  /// In en, this message translates to:
  /// **'No games yet'**
  String get histNoGames;

  /// No description provided for @histNoGamesSub.
  ///
  /// In en, this message translates to:
  /// **'Finished games show up here so you can replay them.'**
  String get histNoGamesSub;

  /// No description provided for @deleteGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this game?'**
  String get deleteGameTitle;

  /// No description provided for @deleteGameSub.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your history.'**
  String get deleteGameSub;

  /// No description provided for @resultWhiteWon.
  ///
  /// In en, this message translates to:
  /// **'White won'**
  String get resultWhiteWon;

  /// No description provided for @resultBlackWon.
  ///
  /// In en, this message translates to:
  /// **'Black won'**
  String get resultBlackWon;

  /// No description provided for @resultWin.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get resultWin;

  /// No description provided for @resultLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get resultLoss;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @monthsShort.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get monthsShort;

  /// No description provided for @dateShort.
  ///
  /// In en, this message translates to:
  /// **'{month} {day}'**
  String dateShort(String month, int day);

  /// No description provided for @semGamePassPlay.
  ///
  /// In en, this message translates to:
  /// **'Pass and play'**
  String get semGamePassPlay;

  /// No description provided for @semGameVsBot.
  ///
  /// In en, this message translates to:
  /// **'Game against {name}'**
  String semGameVsBot(String name);

  /// No description provided for @semAccuracy.
  ///
  /// In en, this message translates to:
  /// **'accuracy {value} percent'**
  String semAccuracy(String value);

  /// No description provided for @analysisUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Analysis is not available on this device right now'**
  String get analysisUnavailable;

  /// No description provided for @retryAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Retry analysis'**
  String get retryAnalysis;

  /// No description provided for @analyzeGame.
  ///
  /// In en, this message translates to:
  /// **'Analyze this game'**
  String get analyzeGame;

  /// No description provided for @gameTitle.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get gameTitle;

  /// No description provided for @replaySettings.
  ///
  /// In en, this message translates to:
  /// **'Replay settings'**
  String get replaySettings;

  /// No description provided for @evalBarReplaySub.
  ///
  /// In en, this message translates to:
  /// **'Shows who is better at each move'**
  String get evalBarReplaySub;

  /// No description provided for @moveFeedbackReplaySub.
  ///
  /// In en, this message translates to:
  /// **'Rates each move as you step through'**
  String get moveFeedbackReplaySub;

  /// No description provided for @showBestReplaySub.
  ///
  /// In en, this message translates to:
  /// **'An arrow to the best move when another was played'**
  String get showBestReplaySub;

  /// No description provided for @notAvailableHere.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get notAvailableHere;

  /// No description provided for @evalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Evaluation is unavailable right now'**
  String get evalUnavailable;

  /// No description provided for @gameNotFound.
  ///
  /// In en, this message translates to:
  /// **'This game could not be found.'**
  String get gameNotFound;

  /// No description provided for @backToHistory.
  ///
  /// In en, this message translates to:
  /// **'Back to history'**
  String get backToHistory;

  /// No description provided for @puzzleN.
  ///
  /// In en, this message translates to:
  /// **'Puzzle {n}'**
  String puzzleN(int n);

  /// No description provided for @allPuzzles.
  ///
  /// In en, this message translates to:
  /// **'All puzzles'**
  String get allPuzzles;

  /// No description provided for @puzzleCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load this puzzle'**
  String get puzzleCouldNotLoad;

  /// No description provided for @puzzlesCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load puzzles'**
  String get puzzlesCouldNotLoad;

  /// No description provided for @noPuzzlesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No puzzles are available yet'**
  String get noPuzzlesAvailable;

  /// No description provided for @noPuzzlesYet.
  ///
  /// In en, this message translates to:
  /// **'No puzzles yet. Check back soon.'**
  String get noPuzzlesYet;

  /// No description provided for @puzzleSolved.
  ///
  /// In en, this message translates to:
  /// **'Puzzle solved!'**
  String get puzzleSolved;

  /// No description provided for @solutionShown.
  ///
  /// In en, this message translates to:
  /// **'Solution shown'**
  String get solutionShown;

  /// No description provided for @notThatOne.
  ///
  /// In en, this message translates to:
  /// **'Not that one'**
  String get notThatOne;

  /// No description provided for @whiteToMove.
  ///
  /// In en, this message translates to:
  /// **'White to move'**
  String get whiteToMove;

  /// No description provided for @blackToMove.
  ///
  /// In en, this message translates to:
  /// **'Black to move'**
  String get blackToMove;

  /// No description provided for @backToPuzzles.
  ///
  /// In en, this message translates to:
  /// **'Back to puzzles'**
  String get backToPuzzles;

  /// No description provided for @solution.
  ///
  /// In en, this message translates to:
  /// **'Solution'**
  String get solution;

  /// No description provided for @nextPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Next puzzle'**
  String get nextPuzzle;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get nextLevel;

  /// No description provided for @themeMateIn.
  ///
  /// In en, this message translates to:
  /// **'Mate in {n}'**
  String themeMateIn(int n);

  /// No description provided for @themeFork.
  ///
  /// In en, this message translates to:
  /// **'Fork'**
  String get themeFork;

  /// No description provided for @themePin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get themePin;

  /// No description provided for @themeEndgame.
  ///
  /// In en, this message translates to:
  /// **'Endgame'**
  String get themeEndgame;

  /// No description provided for @themeWinMaterial.
  ///
  /// In en, this message translates to:
  /// **'Win material'**
  String get themeWinMaterial;

  /// No description provided for @loomMate1.
  ///
  /// In en, this message translates to:
  /// **'Mate in 1'**
  String get loomMate1;

  /// No description provided for @loomMate2.
  ///
  /// In en, this message translates to:
  /// **'Mate in 2'**
  String get loomMate2;

  /// No description provided for @loomForks.
  ///
  /// In en, this message translates to:
  /// **'Forks'**
  String get loomForks;

  /// No description provided for @loomPins.
  ///
  /// In en, this message translates to:
  /// **'Pins'**
  String get loomPins;

  /// No description provided for @loomEndgames.
  ///
  /// In en, this message translates to:
  /// **'Endgames'**
  String get loomEndgames;

  /// No description provided for @puzzlesAllWoven.
  ///
  /// In en, this message translates to:
  /// **'All puzzles woven!'**
  String get puzzlesAllWoven;

  /// No description provided for @puzzlesNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {theme}'**
  String puzzlesNext(String theme);

  /// No description provided for @puzzlesMoreSoon.
  ///
  /// In en, this message translates to:
  /// **'More are coming soon.'**
  String get puzzlesMoreSoon;

  /// No description provided for @reviewPuzzles.
  ///
  /// In en, this message translates to:
  /// **'Review puzzles'**
  String get reviewPuzzles;

  /// No description provided for @statRating.
  ///
  /// In en, this message translates to:
  /// **'RATING'**
  String get statRating;

  /// No description provided for @statKnots.
  ///
  /// In en, this message translates to:
  /// **'KNOTS'**
  String get statKnots;

  /// No description provided for @statBest.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get statBest;

  /// No description provided for @puzzlesSolvedOf.
  ///
  /// In en, this message translates to:
  /// **'{theme} · {solved} of {total} solved'**
  String puzzlesSolvedOf(String theme, int solved, int total);

  /// No description provided for @loomProgress.
  ///
  /// In en, this message translates to:
  /// **'{theme}, {done} of {total} knots woven'**
  String loomProgress(String theme, int done, int total);

  /// No description provided for @levelWoven.
  ///
  /// In en, this message translates to:
  /// **'Woven ✓'**
  String get levelWoven;

  /// No description provided for @levelKnots.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} knots'**
  String levelKnots(int done, int total);

  /// No description provided for @levelNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get levelNotStarted;

  /// No description provided for @levelComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get levelComingSoon;

  /// No description provided for @golWovenSem.
  ///
  /// In en, this message translates to:
  /// **'{tribe} göl, woven'**
  String golWovenSem(String tribe);

  /// No description provided for @golWoven.
  ///
  /// In en, this message translates to:
  /// **'{tribe} göl woven'**
  String golWoven(String tribe);

  /// No description provided for @golWholeCarpet.
  ///
  /// In en, this message translates to:
  /// **'{knots} of {knots} knots. The whole carpet is done.'**
  String golWholeCarpet(int knots);

  /// No description provided for @golNext.
  ///
  /// In en, this message translates to:
  /// **'{knots} of {knots} knots. The {next} göl is next.'**
  String golNext(int knots, String next);

  /// No description provided for @dailyPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Daily puzzle'**
  String get dailyPuzzle;

  /// No description provided for @solvedToday.
  ///
  /// In en, this message translates to:
  /// **'Solved today'**
  String get solvedToday;

  /// No description provided for @dailySolved.
  ///
  /// In en, this message translates to:
  /// **'solved'**
  String get dailySolved;

  /// No description provided for @dailyStreakSem.
  ///
  /// In en, this message translates to:
  /// **'streak {days}'**
  String dailyStreakSem(String days);

  /// No description provided for @coachMateIn1.
  ///
  /// In en, this message translates to:
  /// **'One move ends the game. Can you see it?\nFind the move that mates right now.\nThe king has no way out. Close the door!'**
  String get coachMateIn1;

  /// No description provided for @coachMateIn2.
  ///
  /// In en, this message translates to:
  /// **'Can you force mate in two moves?\nStart with a check or a strong threat.\nTwo moves to mate. Which one comes first?'**
  String get coachMateIn2;

  /// No description provided for @coachMateIn3.
  ///
  /// In en, this message translates to:
  /// **'Mate in three. Think forcing moves.\nChecks first, then see where the king goes.'**
  String get coachMateIn3;

  /// No description provided for @coachFork.
  ///
  /// In en, this message translates to:
  /// **'Find a move that attacks two pieces at once.\nCan you spot a fork?\nOne piece, two targets. Where does it land?'**
  String get coachFork;

  /// No description provided for @coachPin.
  ///
  /// In en, this message translates to:
  /// **'A piece cannot move. Can you use that?\nLook for a pinned piece and pile on.\nWhat is stuck in front of its king?'**
  String get coachPin;

  /// No description provided for @coachEndgame.
  ///
  /// In en, this message translates to:
  /// **'Few pieces, big ideas. Take your time.\nIn the endgame your king is a fighter.\nCareful moves win this one.'**
  String get coachEndgame;

  /// No description provided for @coachGeneric.
  ///
  /// In en, this message translates to:
  /// **'Look for checks, captures and threats first.\nWhat is hanging? Take your time.\nThe best move is usually forcing.'**
  String get coachGeneric;

  /// No description provided for @coachWrong.
  ///
  /// In en, this message translates to:
  /// **'Close, but not quite. Try another move.\nNot this one. Think about checks and captures.\nHmm, look again. You can do this!\nThat lets them off. What else is there?'**
  String get coachWrong;

  /// No description provided for @coachCorrect.
  ///
  /// In en, this message translates to:
  /// **'Nice work! On to the next one.\nYou saw it. Well played!\nSharp eyes. That was clean.\nAnother knot woven. Keep going!'**
  String get coachCorrect;

  /// No description provided for @coachRetry.
  ///
  /// In en, this message translates to:
  /// **'Study it, then try it yourself.\nNow you know. Hit Retry!\nWatch how the pieces work together.'**
  String get coachRetry;

  /// No description provided for @coachDaily.
  ///
  /// In en, this message translates to:
  /// **'Never skip puzzle day!\nLook for checks, captures and threats first.\nOne puzzle a day keeps the blunders away.\nTake your time: the best move is usually forcing.'**
  String get coachDaily;

  /// No description provided for @achEarnedOf.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} earned'**
  String achEarnedOf(int earned, int total);

  /// No description provided for @achUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked'**
  String get achUnlocked;

  /// No description provided for @achEarned.
  ///
  /// In en, this message translates to:
  /// **'earned'**
  String get achEarned;

  /// No description provided for @achNotEarned.
  ///
  /// In en, this message translates to:
  /// **'not earned yet'**
  String get achNotEarned;

  /// No description provided for @ach_first_game_t.
  ///
  /// In en, this message translates to:
  /// **'First move'**
  String get ach_first_game_t;

  /// No description provided for @ach_first_game_d.
  ///
  /// In en, this message translates to:
  /// **'Finish a game against a bot'**
  String get ach_first_game_d;

  /// No description provided for @ach_first_win_t.
  ///
  /// In en, this message translates to:
  /// **'First victory'**
  String get ach_first_win_t;

  /// No description provided for @ach_first_win_d.
  ///
  /// In en, this message translates to:
  /// **'Win a game against a bot'**
  String get ach_first_win_d;

  /// No description provided for @ach_checkmate_t.
  ///
  /// In en, this message translates to:
  /// **'Checkmate!'**
  String get ach_checkmate_t;

  /// No description provided for @ach_checkmate_d.
  ///
  /// In en, this message translates to:
  /// **'Win a game by checkmate'**
  String get ach_checkmate_d;

  /// No description provided for @ach_quick_mate_t.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get ach_quick_mate_t;

  /// No description provided for @ach_quick_mate_d.
  ///
  /// In en, this message translates to:
  /// **'Checkmate a bot in 20 moves or less'**
  String get ach_quick_mate_d;

  /// No description provided for @ach_giant_slayer_t.
  ///
  /// In en, this message translates to:
  /// **'Giant slayer'**
  String get ach_giant_slayer_t;

  /// No description provided for @ach_giant_slayer_d.
  ///
  /// In en, this message translates to:
  /// **'Beat a bot rated 300 or more above you'**
  String get ach_giant_slayer_d;

  /// No description provided for @ach_three_bots_t.
  ///
  /// In en, this message translates to:
  /// **'Rising star'**
  String get ach_three_bots_t;

  /// No description provided for @ach_three_bots_d.
  ///
  /// In en, this message translates to:
  /// **'Beat 3 different bots'**
  String get ach_three_bots_d;

  /// No description provided for @ach_all_bots_t.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get ach_all_bots_t;

  /// No description provided for @ach_all_bots_d.
  ///
  /// In en, this message translates to:
  /// **'Beat every bot'**
  String get ach_all_bots_d;

  /// No description provided for @ach_marathon_t.
  ///
  /// In en, this message translates to:
  /// **'Marathon'**
  String get ach_marathon_t;

  /// No description provided for @ach_marathon_d.
  ///
  /// In en, this message translates to:
  /// **'Play a game of 60 moves or more'**
  String get ach_marathon_d;

  /// No description provided for @ach_accurate_t.
  ///
  /// In en, this message translates to:
  /// **'Sharpshooter'**
  String get ach_accurate_t;

  /// No description provided for @ach_accurate_d.
  ///
  /// In en, this message translates to:
  /// **'Play a game with 90% accuracy'**
  String get ach_accurate_d;

  /// No description provided for @ach_brilliant_t.
  ///
  /// In en, this message translates to:
  /// **'Brilliant!'**
  String get ach_brilliant_t;

  /// No description provided for @ach_brilliant_d.
  ///
  /// In en, this message translates to:
  /// **'Play a brilliant move'**
  String get ach_brilliant_d;

  /// No description provided for @ach_first_puzzle_t.
  ///
  /// In en, this message translates to:
  /// **'Puzzler'**
  String get ach_first_puzzle_t;

  /// No description provided for @ach_first_puzzle_d.
  ///
  /// In en, this message translates to:
  /// **'Solve your first puzzle'**
  String get ach_first_puzzle_d;

  /// No description provided for @ach_puzzles_25_t.
  ///
  /// In en, this message translates to:
  /// **'Knot by knot'**
  String get ach_puzzles_25_t;

  /// No description provided for @ach_puzzles_25_d.
  ///
  /// In en, this message translates to:
  /// **'Solve 25 puzzles'**
  String get ach_puzzles_25_d;

  /// No description provided for @ach_first_gol_t.
  ///
  /// In en, this message translates to:
  /// **'First göl'**
  String get ach_first_gol_t;

  /// No description provided for @ach_first_gol_d.
  ///
  /// In en, this message translates to:
  /// **'Weave a whole göl'**
  String get ach_first_gol_d;

  /// No description provided for @ach_whole_carpet_t.
  ///
  /// In en, this message translates to:
  /// **'Master weaver'**
  String get ach_whole_carpet_t;

  /// No description provided for @ach_whole_carpet_d.
  ///
  /// In en, this message translates to:
  /// **'Weave all five göls'**
  String get ach_whole_carpet_d;

  /// No description provided for @ach_streak_3_t.
  ///
  /// In en, this message translates to:
  /// **'On a roll'**
  String get ach_streak_3_t;

  /// No description provided for @ach_streak_3_d.
  ///
  /// In en, this message translates to:
  /// **'Solve the daily puzzle 3 days in a row'**
  String get ach_streak_3_d;

  /// No description provided for @ach_streak_7_t.
  ///
  /// In en, this message translates to:
  /// **'Week of fire'**
  String get ach_streak_7_t;

  /// No description provided for @ach_streak_7_d.
  ///
  /// In en, this message translates to:
  /// **'Solve the daily puzzle 7 days in a row'**
  String get ach_streak_7_d;

  /// No description provided for @onbGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onbGetStarted;

  /// No description provided for @onbStartPlaying.
  ///
  /// In en, this message translates to:
  /// **'Start playing'**
  String get onbStartPlaying;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onbSkip;

  /// No description provided for @onbTitle.
  ///
  /// In en, this message translates to:
  /// **'Chess that helps you improve'**
  String get onbTitle;

  /// No description provided for @onbHowStrong.
  ///
  /// In en, this message translates to:
  /// **'How strong are you?'**
  String get onbHowStrong;

  /// No description provided for @onbHowStrongSub.
  ///
  /// In en, this message translates to:
  /// **'This sets your starting rating. It adjusts as you play, so don’t overthink it.'**
  String get onbHowStrongSub;

  /// No description provided for @lvlBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get lvlBeginner;

  /// No description provided for @lvlBeginnerD.
  ///
  /// In en, this message translates to:
  /// **'I’m just getting started with chess.'**
  String get lvlBeginnerD;

  /// No description provided for @lvlIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get lvlIntermediate;

  /// No description provided for @lvlIntermediateD.
  ///
  /// In en, this message translates to:
  /// **'I know the basics and play regularly.'**
  String get lvlIntermediateD;

  /// No description provided for @lvlAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get lvlAdvanced;

  /// No description provided for @lvlAdvancedD.
  ///
  /// In en, this message translates to:
  /// **'I understand strategy and complex positions.'**
  String get lvlAdvancedD;

  /// No description provided for @lvlCompetitive.
  ///
  /// In en, this message translates to:
  /// **'Competitive'**
  String get lvlCompetitive;

  /// No description provided for @lvlCompetitiveD.
  ///
  /// In en, this message translates to:
  /// **'I play seriously and may compete in tournaments.'**
  String get lvlCompetitiveD;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String streakDays(int count);

  /// No description provided for @yourAvatar.
  ///
  /// In en, this message translates to:
  /// **'Your avatar'**
  String get yourAvatar;

  /// No description provided for @avatarOf.
  ///
  /// In en, this message translates to:
  /// **'{name}, your avatar'**
  String avatarOf(String name);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageAuto.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageAuto;

  /// No description provided for @youWonGame.
  ///
  /// In en, this message translates to:
  /// **'You won the game.'**
  String get youWonGame;

  /// No description provided for @youWonOnTime.
  ///
  /// In en, this message translates to:
  /// **'You won on time.'**
  String get youWonOnTime;

  /// No description provided for @botGreetBahar.
  ///
  /// In en, this message translates to:
  /// **'Salam! I am Bahar. I am learning chess too, let\'s play!'**
  String get botGreetBahar;

  /// No description provided for @botGreetElizabeth.
  ///
  /// In en, this message translates to:
  /// **'Good day. Shall we have a pleasant game?'**
  String get botGreetElizabeth;

  /// No description provided for @botGreetMark.
  ///
  /// In en, this message translates to:
  /// **'Hey! Ready for a game? I am!'**
  String get botGreetMark;

  /// No description provided for @botGreetApex.
  ///
  /// In en, this message translates to:
  /// **'Think you can beat me? Let\'s see.'**
  String get botGreetApex;

  /// No description provided for @botGreetKarl.
  ///
  /// In en, this message translates to:
  /// **'Take your time. Chess rewards patience.'**
  String get botGreetKarl;

  /// No description provided for @botGreetEnejan.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Sit down, let\'s play a game.'**
  String get botGreetEnejan;

  /// No description provided for @botGreetMaya.
  ///
  /// In en, this message translates to:
  /// **'Hi! I like clever moves. Show me yours.'**
  String get botGreetMaya;

  /// No description provided for @botGreetYura.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play. I do not go easy.'**
  String get botGreetYura;

  /// No description provided for @botGreetBerdi.
  ///
  /// In en, this message translates to:
  /// **'Welcome. Chess is a long road. Let us walk it.'**
  String get botGreetBerdi;

  /// No description provided for @botCheerfulBlunder.
  ///
  /// In en, this message translates to:
  /// **'Oh! Thank you for that!|Whoa, did you mean to do that?'**
  String get botCheerfulBlunder;

  /// No description provided for @botCheerfulBrilliant.
  ///
  /// In en, this message translates to:
  /// **'Wow, what a move!|You are really good at this!'**
  String get botCheerfulBrilliant;

  /// No description provided for @botCheerfulWin.
  ///
  /// In en, this message translates to:
  /// **'Yay, a win! Great game!|That was fun, play again?'**
  String get botCheerfulWin;

  /// No description provided for @botCheerfulLoss.
  ///
  /// In en, this message translates to:
  /// **'You got me! Well played!|Wow, you win! Let\'s go again!'**
  String get botCheerfulLoss;

  /// No description provided for @botCheerfulDraw.
  ///
  /// In en, this message translates to:
  /// **'A draw! Fair and square.|Nobody lost, so we both won!'**
  String get botCheerfulDraw;

  /// No description provided for @botCalmBlunder.
  ///
  /// In en, this message translates to:
  /// **'An interesting choice.|I will gladly take that.'**
  String get botCalmBlunder;

  /// No description provided for @botCalmBrilliant.
  ///
  /// In en, this message translates to:
  /// **'A fine move. Well seen.|Impressive. That was unexpected.'**
  String get botCalmBrilliant;

  /// No description provided for @botCalmWin.
  ///
  /// In en, this message translates to:
  /// **'A good game. Thank you.|Better luck next time.'**
  String get botCalmWin;

  /// No description provided for @botCalmLoss.
  ///
  /// In en, this message translates to:
  /// **'Well played. You earned it.|Congratulations, a deserved win.'**
  String get botCalmLoss;

  /// No description provided for @botCalmDraw.
  ///
  /// In en, this message translates to:
  /// **'A fair result.|We were evenly matched.'**
  String get botCalmDraw;

  /// No description provided for @botCockyBlunder.
  ///
  /// In en, this message translates to:
  /// **'Ha! Too easy.|Was that your plan?'**
  String get botCockyBlunder;

  /// No description provided for @botCockyBrilliant.
  ///
  /// In en, this message translates to:
  /// **'Lucky shot. Don\'t get used to it.|Okay, that was not bad.'**
  String get botCockyBrilliant;

  /// No description provided for @botCockyWin.
  ///
  /// In en, this message translates to:
  /// **'Never in doubt.|Better luck next time, champ.'**
  String get botCockyWin;

  /// No description provided for @botCockyLoss.
  ///
  /// In en, this message translates to:
  /// **'Fine, this one is yours. Rematch?|Beginner\'s luck. Again!'**
  String get botCockyLoss;

  /// No description provided for @botCockyDraw.
  ///
  /// In en, this message translates to:
  /// **'A draw? I was only warming up.|Hmm. Next time I win.'**
  String get botCockyDraw;

  /// No description provided for @botWiseBlunder.
  ///
  /// In en, this message translates to:
  /// **'Think before you move.|Every move has a price.'**
  String get botWiseBlunder;

  /// No description provided for @botWiseBrilliant.
  ///
  /// In en, this message translates to:
  /// **'A move worth remembering.|Now that is real chess.'**
  String get botWiseBrilliant;

  /// No description provided for @botWiseWin.
  ///
  /// In en, this message translates to:
  /// **'Every game teaches something.|Learn from this one.'**
  String get botWiseWin;

  /// No description provided for @botWiseLoss.
  ///
  /// In en, this message translates to:
  /// **'You taught me something today.|Well played, a worthy victory.'**
  String get botWiseLoss;

  /// No description provided for @botWiseDraw.
  ///
  /// In en, this message translates to:
  /// **'Balance is also a result.|A calm game, a calm ending.'**
  String get botWiseDraw;

  /// No description provided for @botChat.
  ///
  /// In en, this message translates to:
  /// **'Bot chat'**
  String get botChat;

  /// No description provided for @botChatSub.
  ///
  /// In en, this message translates to:
  /// **'Bots comment on the game'**
  String get botChatSub;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Game review'**
  String get reviewTitle;

  /// No description provided for @reviewButton.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewButton;

  /// No description provided for @reviewAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get reviewAccuracy;

  /// No description provided for @reviewMoves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get reviewMoves;

  /// No description provided for @reviewGraph.
  ///
  /// In en, this message translates to:
  /// **'Who was winning'**
  String get reviewGraph;

  /// No description provided for @reviewKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Moves to learn from'**
  String get reviewKeyTitle;

  /// No description provided for @reviewNoBig.
  ///
  /// In en, this message translates to:
  /// **'No big mistakes. Well played!'**
  String get reviewNoBig;

  /// No description provided for @reviewBestWas.
  ///
  /// In en, this message translates to:
  /// **'Best was {san}'**
  String reviewBestWas(String san);

  /// No description provided for @reviewMoveNo.
  ///
  /// In en, this message translates to:
  /// **'Move {n}'**
  String reviewMoveNo(int n);

  /// No description provided for @reviewOpenReplay.
  ///
  /// In en, this message translates to:
  /// **'Open replay'**
  String get reviewOpenReplay;

  /// No description provided for @reviewNoEngine.
  ///
  /// In en, this message translates to:
  /// **'The engine is not available on this device, so the game cannot be analyzed.'**
  String get reviewNoEngine;

  /// No description provided for @reviewFailed.
  ///
  /// In en, this message translates to:
  /// **'The analysis did not finish.'**
  String get reviewFailed;

  /// No description provided for @reviewTooShort.
  ///
  /// In en, this message translates to:
  /// **'This game is too short to review.'**
  String get reviewTooShort;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// No description provided for @learnTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learnTitle;

  /// No description provided for @learnSub.
  ///
  /// In en, this message translates to:
  /// **'From your first move to checkmate'**
  String get learnSub;

  /// No description provided for @lessonStart.
  ///
  /// In en, this message translates to:
  /// **'Start lesson'**
  String get lessonStart;

  /// No description provided for @learnWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite. Try again.'**
  String get learnWrong;

  /// No description provided for @learnStalemate.
  ///
  /// In en, this message translates to:
  /// **'That is stalemate, a draw. Find the checkmate.'**
  String get learnStalemate;

  /// No description provided for @learnWellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done!'**
  String get learnWellDone;

  /// No description provided for @lessonDone.
  ///
  /// In en, this message translates to:
  /// **'Lesson complete!'**
  String get lessonDone;

  /// No description provided for @lessonNext.
  ///
  /// In en, this message translates to:
  /// **'Next lesson'**
  String get lessonNext;

  /// No description provided for @lessonPlayGame.
  ///
  /// In en, this message translates to:
  /// **'Play a game'**
  String get lessonPlayGame;

  /// No description provided for @learnHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get learnHint;

  /// No description provided for @learnAllDone.
  ///
  /// In en, this message translates to:
  /// **'You finished every lesson. Time to play!'**
  String get learnAllDone;

  /// No description provided for @pieceKing.
  ///
  /// In en, this message translates to:
  /// **'king'**
  String get pieceKing;

  /// No description provided for @piecePawn.
  ///
  /// In en, this message translates to:
  /// **'pawn'**
  String get piecePawn;

  /// No description provided for @taskCollectOne.
  ///
  /// In en, this message translates to:
  /// **'Move the {piece} to the star'**
  String taskCollectOne(String piece);

  /// No description provided for @taskCollectMany.
  ///
  /// In en, this message translates to:
  /// **'Collect every star with the {piece}'**
  String taskCollectMany(String piece);

  /// No description provided for @taskCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture all the marked pieces'**
  String get taskCapture;

  /// No description provided for @taskBestCapture.
  ///
  /// In en, this message translates to:
  /// **'Capture the most valuable piece'**
  String get taskBestCapture;

  /// No description provided for @taskCheck.
  ///
  /// In en, this message translates to:
  /// **'Give check'**
  String get taskCheck;

  /// No description provided for @taskMate.
  ///
  /// In en, this message translates to:
  /// **'Checkmate in one move'**
  String get taskMate;

  /// No description provided for @taskEscape.
  ///
  /// In en, this message translates to:
  /// **'Your king is in check. Get out of check.'**
  String get taskEscape;

  /// No description provided for @taskEscapeCapture.
  ///
  /// In en, this message translates to:
  /// **'Get out of check by capturing the attacker'**
  String get taskEscapeCapture;

  /// No description provided for @taskCastleKing.
  ///
  /// In en, this message translates to:
  /// **'Castle kingside: move the king two squares towards the rook'**
  String get taskCastleKing;

  /// No description provided for @taskCastleQueen.
  ///
  /// In en, this message translates to:
  /// **'Castle queenside: move the king two squares towards the rook'**
  String get taskCastleQueen;

  /// No description provided for @taskEnPassant.
  ///
  /// In en, this message translates to:
  /// **'Capture the pawn en passant'**
  String get taskEnPassant;

  /// No description provided for @taskPromote.
  ///
  /// In en, this message translates to:
  /// **'Move the pawn to the last row to promote it'**
  String get taskPromote;

  /// No description provided for @lessonPawnTitle.
  ///
  /// In en, this message translates to:
  /// **'The pawn'**
  String get lessonPawnTitle;

  /// No description provided for @lessonPawnIntro.
  ///
  /// In en, this message translates to:
  /// **'Pawns are the foot soldiers. A pawn moves one square forward, or two from its starting square. It captures one square diagonally forward, never straight ahead.'**
  String get lessonPawnIntro;

  /// No description provided for @lessonRookTitle.
  ///
  /// In en, this message translates to:
  /// **'The rook'**
  String get lessonRookTitle;

  /// No description provided for @lessonRookIntro.
  ///
  /// In en, this message translates to:
  /// **'The rook moves any number of squares in a straight line, along a row or a column. It cannot jump over other pieces.'**
  String get lessonRookIntro;

  /// No description provided for @lessonBishopTitle.
  ///
  /// In en, this message translates to:
  /// **'The bishop'**
  String get lessonBishopTitle;

  /// No description provided for @lessonBishopIntro.
  ///
  /// In en, this message translates to:
  /// **'The bishop moves any number of squares diagonally. It always stays on the same colour of square.'**
  String get lessonBishopIntro;

  /// No description provided for @lessonQueenTitle.
  ///
  /// In en, this message translates to:
  /// **'The queen'**
  String get lessonQueenTitle;

  /// No description provided for @lessonQueenIntro.
  ///
  /// In en, this message translates to:
  /// **'The queen is the strongest piece. She moves like a rook and a bishop together: any number of squares in a straight line or diagonally.'**
  String get lessonQueenIntro;

  /// No description provided for @lessonKnightTitle.
  ///
  /// In en, this message translates to:
  /// **'The knight'**
  String get lessonKnightTitle;

  /// No description provided for @lessonKnightIntro.
  ///
  /// In en, this message translates to:
  /// **'The knight moves in an L: two squares one way and one square to the side. It is the only piece that jumps over others.'**
  String get lessonKnightIntro;

  /// No description provided for @lessonKingTitle.
  ///
  /// In en, this message translates to:
  /// **'The king'**
  String get lessonKingTitle;

  /// No description provided for @lessonKingIntro.
  ///
  /// In en, this message translates to:
  /// **'The king moves one square in any direction. Protect him: if he is lost, the game is lost. He can never step next to the enemy king or into an attack.'**
  String get lessonKingIntro;

  /// No description provided for @lessonValuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Taking pieces'**
  String get lessonValuesTitle;

  /// No description provided for @lessonValuesIntro.
  ///
  /// In en, this message translates to:
  /// **'Pieces are worth points: pawn 1, knight 3, bishop 3, rook 5, queen 9. Capturing a bigger piece wins material. Always look for the most valuable capture.'**
  String get lessonValuesIntro;

  /// No description provided for @lessonCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get lessonCheckTitle;

  /// No description provided for @lessonCheckIntro.
  ///
  /// In en, this message translates to:
  /// **'When a king is attacked, it is in check. You must get out of check at once: move the king, block the attack, or capture the attacker.'**
  String get lessonCheckIntro;

  /// No description provided for @lessonSpecialTitle.
  ///
  /// In en, this message translates to:
  /// **'Special moves'**
  String get lessonSpecialTitle;

  /// No description provided for @lessonSpecialIntro.
  ///
  /// In en, this message translates to:
  /// **'Castling moves your king two squares towards a rook, and the rook jumps over it. En passant lets a pawn capture one that has just moved two squares past it. A pawn that reaches the last row promotes, usually to a queen.'**
  String get lessonSpecialIntro;

  /// No description provided for @lessonMateTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkmate'**
  String get lessonMateTitle;

  /// No description provided for @lessonMateIntro.
  ///
  /// In en, this message translates to:
  /// **'Checkmate is a check that cannot be escaped: the game ends and you win. If the other side has no legal move but is not in check, it is stalemate, a draw. Be careful not to stalemate when you are winning.'**
  String get lessonMateIntro;

  /// No description provided for @lessonFirstMatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first checkmates'**
  String get lessonFirstMatesTitle;

  /// No description provided for @lessonFirstMatesIntro.
  ///
  /// In en, this message translates to:
  /// **'Three patterns that win games: the back rank mate, the two-rook ladder and the queen with the king. Find the mate in one move.'**
  String get lessonFirstMatesIntro;

  /// No description provided for @campPiecesTitle.
  ///
  /// In en, this message translates to:
  /// **'The pieces'**
  String get campPiecesTitle;

  /// No description provided for @campPiecesSub.
  ///
  /// In en, this message translates to:
  /// **'Learn how every piece moves'**
  String get campPiecesSub;

  /// No description provided for @campRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'The rules'**
  String get campRulesTitle;

  /// No description provided for @campRulesSub.
  ///
  /// In en, this message translates to:
  /// **'Captures, check and special moves'**
  String get campRulesSub;

  /// No description provided for @campMateTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkmate'**
  String get campMateTitle;

  /// No description provided for @campMateSub.
  ///
  /// In en, this message translates to:
  /// **'Win your first games'**
  String get campMateSub;

  /// No description provided for @campLabel.
  ///
  /// In en, this message translates to:
  /// **'CAMP {n}'**
  String campLabel(int n);

  /// No description provided for @summitLabel.
  ///
  /// In en, this message translates to:
  /// **'SUMMIT'**
  String get summitLabel;

  /// No description provided for @learnUpNext.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT · LESSON {n}'**
  String learnUpNext(int n);

  /// No description provided for @lessonLabel.
  ///
  /// In en, this message translates to:
  /// **'LESSON {n}'**
  String lessonLabel(int n);

  /// No description provided for @lessonMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} tasks · {m} min'**
  String lessonMinutes(int n, int m);

  /// No description provided for @learnSummitDone.
  ///
  /// In en, this message translates to:
  /// **'You reached the summit'**
  String get learnSummitDone;

  /// No description provided for @lessonMistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get lessonMistakes;

  /// No description provided for @lessonHintsUsed.
  ///
  /// In en, this message translates to:
  /// **'Hints'**
  String get lessonHintsUsed;

  /// No description provided for @lessonTasksDone.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get lessonTasksDone;

  /// No description provided for @lessonBackToMap.
  ///
  /// In en, this message translates to:
  /// **'Back to the map'**
  String get lessonBackToMap;

  /// No description provided for @learnCoachDone.
  ///
  /// In en, this message translates to:
  /// **'That is it! Tap Continue.'**
  String get learnCoachDone;

  /// No description provided for @lessonPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect lesson!'**
  String get lessonPerfect;

  /// No description provided for @onbStartLesson.
  ///
  /// In en, this message translates to:
  /// **'Start the first lesson'**
  String get onbStartLesson;

  /// No description provided for @lessonLocked.
  ///
  /// In en, this message translates to:
  /// **'Finish lesson {n} first.'**
  String lessonLocked(int n);

  /// No description provided for @lessonLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Each lesson builds on the one before it.'**
  String get lessonLockedHint;

  /// No description provided for @lessonLockedOpen.
  ///
  /// In en, this message translates to:
  /// **'Open lesson {n}'**
  String lessonLockedOpen(int n);

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @defaultPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get defaultPlayerName;

  /// No description provided for @saveName.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveName;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue your game'**
  String get continueGame;

  /// No description provided for @continueGameSub.
  ///
  /// In en, this message translates to:
  /// **'{who} · move {n}'**
  String continueGameSub(String who, int n);

  /// No description provided for @retryTitle.
  ///
  /// In en, this message translates to:
  /// **'What should you have played?'**
  String get retryTitle;

  /// No description provided for @retryRight.
  ///
  /// In en, this message translates to:
  /// **'That\'s the move!'**
  String get retryRight;

  /// No description provided for @retryWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite. Try again.'**
  String get retryWrong;

  /// No description provided for @retryShow.
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get retryShow;

  /// No description provided for @retryTry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryTry;

  /// No description provided for @retryNoPosition.
  ///
  /// In en, this message translates to:
  /// **'This move cannot be shown.'**
  String get retryNoPosition;

  /// No description provided for @reviewAnalyzingTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your game'**
  String get reviewAnalyzingTitle;

  /// No description provided for @reviewCheckingMove.
  ///
  /// In en, this message translates to:
  /// **'Checking move {n} of {total}'**
  String reviewCheckingMove(int n, int total);

  /// No description provided for @reviewTip1.
  ///
  /// In en, this message translates to:
  /// **'Accuracy compares each of your moves with the engine\'s best move.'**
  String get reviewTip1;

  /// No description provided for @reviewTip2.
  ///
  /// In en, this message translates to:
  /// **'A blunder gives away a lot in one move. Look for those first.'**
  String get reviewTip2;

  /// No description provided for @reviewTip3.
  ///
  /// In en, this message translates to:
  /// **'Tap the replay button on a key moment to try that position again.'**
  String get reviewTip3;

  /// No description provided for @reviewTip4.
  ///
  /// In en, this message translates to:
  /// **'Brilliant moves are rare: a sacrifice the engine agrees with.'**
  String get reviewTip4;

  /// No description provided for @reviewTip5.
  ///
  /// In en, this message translates to:
  /// **'Once analyzed, a game opens instantly next time.'**
  String get reviewTip5;

  /// No description provided for @sendErrorReport.
  ///
  /// In en, this message translates to:
  /// **'Send error report'**
  String get sendErrorReport;

  /// No description provided for @taskFork.
  ///
  /// In en, this message translates to:
  /// **'Fork: attack two pieces with one move'**
  String get taskFork;

  /// No description provided for @taskPin.
  ///
  /// In en, this message translates to:
  /// **'Pin a piece to its king'**
  String get taskPin;

  /// No description provided for @taskSkewer.
  ///
  /// In en, this message translates to:
  /// **'Check the king and win the piece behind it'**
  String get taskSkewer;

  /// No description provided for @lessonForkTitle.
  ///
  /// In en, this message translates to:
  /// **'The fork'**
  String get lessonForkTitle;

  /// No description provided for @lessonForkIntro.
  ///
  /// In en, this message translates to:
  /// **'A fork attacks two pieces at once. The other side can save only one, so you win the other. Knights are the masters of the fork.'**
  String get lessonForkIntro;

  /// No description provided for @lessonPinTitle.
  ///
  /// In en, this message translates to:
  /// **'The pin'**
  String get lessonPinTitle;

  /// No description provided for @lessonPinIntro.
  ///
  /// In en, this message translates to:
  /// **'A pinned piece cannot move, because the king behind it would be in check. Pin a piece, then attack it again to win it.'**
  String get lessonPinIntro;

  /// No description provided for @lessonSkewerTitle.
  ///
  /// In en, this message translates to:
  /// **'The skewer'**
  String get lessonSkewerTitle;

  /// No description provided for @lessonSkewerIntro.
  ///
  /// In en, this message translates to:
  /// **'A skewer is a pin turned around: you check the king, it must step aside, and you take the piece behind it.'**
  String get lessonSkewerIntro;

  /// No description provided for @lessonPatternsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mate patterns'**
  String get lessonPatternsTitle;

  /// No description provided for @lessonPatternsIntro.
  ///
  /// In en, this message translates to:
  /// **'Strong players know mates by their shape: the smothered mate with a knight, the queen right next to the king, and the rook and knight working together. Find the mate in one move.'**
  String get lessonPatternsIntro;

  /// No description provided for @campTacticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tactics'**
  String get campTacticsTitle;

  /// No description provided for @campTacticsSub.
  ///
  /// In en, this message translates to:
  /// **'Win pieces with clever moves'**
  String get campTacticsSub;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameRule.
  ///
  /// In en, this message translates to:
  /// **'3–20 letters, digits or _'**
  String get usernameRule;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get bio;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get choosePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @onbNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get onbNameTitle;

  /// No description provided for @onbNameSub.
  ///
  /// In en, this message translates to:
  /// **'You can change these later in your profile.'**
  String get onbNameSub;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @navTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get navTrain;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @gameHistory.
  ///
  /// In en, this message translates to:
  /// **'Game history'**
  String get gameHistory;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get qrCode;

  /// No description provided for @trainSoonSub.
  ///
  /// In en, this message translates to:
  /// **'A new way to practise is on its way. Until then, keep sharp with puzzles.'**
  String get trainSoonSub;

  /// No description provided for @solvePuzzles.
  ///
  /// In en, this message translates to:
  /// **'Solve puzzles'**
  String get solvePuzzles;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutTitle;

  /// No description provided for @logOutSub.
  ///
  /// In en, this message translates to:
  /// **'Your name, username, bio and photo are removed from this device and you play as a guest. Your games and progress stay.'**
  String get logOutSub;

  /// No description provided for @youWonTitle.
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get youWonTitle;

  /// No description provided for @youLostTitle.
  ///
  /// In en, this message translates to:
  /// **'You lost'**
  String get youLostTitle;

  /// No description provided for @byCheckmate.
  ///
  /// In en, this message translates to:
  /// **'by checkmate'**
  String get byCheckmate;

  /// No description provided for @byResignation.
  ///
  /// In en, this message translates to:
  /// **'by resignation'**
  String get byResignation;

  /// No description provided for @byTimeout.
  ///
  /// In en, this message translates to:
  /// **'on time'**
  String get byTimeout;

  /// No description provided for @byStalemate.
  ///
  /// In en, this message translates to:
  /// **'by stalemate'**
  String get byStalemate;

  /// No description provided for @byRepetition.
  ///
  /// In en, this message translates to:
  /// **'by repetition'**
  String get byRepetition;

  /// No description provided for @byFiftyMove.
  ///
  /// In en, this message translates to:
  /// **'by the 50-move rule'**
  String get byFiftyMove;

  /// No description provided for @byInsufficient.
  ///
  /// In en, this message translates to:
  /// **'by insufficient material'**
  String get byInsufficient;

  /// No description provided for @byAgreement.
  ///
  /// In en, this message translates to:
  /// **'by agreement'**
  String get byAgreement;

  /// No description provided for @byTimeNoMate.
  ///
  /// In en, this message translates to:
  /// **'on time, with no mate possible'**
  String get byTimeNoMate;

  /// No description provided for @tierCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get tierCommon;

  /// No description provided for @tierRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get tierRare;

  /// No description provided for @tierMythic.
  ///
  /// In en, this message translates to:
  /// **'Mythic'**
  String get tierMythic;

  /// No description provided for @opItalianD.
  ///
  /// In en, this message translates to:
  /// **'Quick development and an early fight for the centre: bishop to c4 aims at f7, then c3 and d3 or d4. Calm on the surface, full of traps underneath.'**
  String get opItalianD;

  /// No description provided for @opRuyLopezD.
  ///
  /// In en, this message translates to:
  /// **'The bishop pins pressure on the knight that guards e5. A slow, rich plan that has been the main road at the top for over a century.'**
  String get opRuyLopezD;

  /// No description provided for @opLondonD.
  ///
  /// In en, this message translates to:
  /// **'The same easy setup almost every game: d4, Bf4, e3, Nf3 and c3. Solid, quick to learn, and full of chances to attack the king.'**
  String get opLondonD;

  /// No description provided for @opQueensGambitD.
  ///
  /// In en, this message translates to:
  /// **'White offers the c-pawn to pull Black\'s d-pawn from the centre. If Black takes, White builds a big centre and wins the pawn back.'**
  String get opQueensGambitD;

  /// No description provided for @opKingsGambitD.
  ///
  /// In en, this message translates to:
  /// **'White gives the f-pawn on move two to open the f-file and race for the attack. Wild, risky and a favourite of the Romantic era.'**
  String get opKingsGambitD;

  /// No description provided for @opFriedLiverD.
  ///
  /// In en, this message translates to:
  /// **'Against the Two Knights, the knight jumps to g5 and then sacrifices itself on f7 to drag the black king into the open.'**
  String get opFriedLiverD;

  /// No description provided for @opSicilianD.
  ///
  /// In en, this message translates to:
  /// **'Black answers 1.e4 with c5 and fights unequally: sharp, double-edged games where Black plays to win, not to draw.'**
  String get opSicilianD;

  /// No description provided for @opFrenchD.
  ///
  /// In en, this message translates to:
  /// **'Black builds a solid chain with e6 and d5, lets White take space, then strikes back at the centre with c5.'**
  String get opFrenchD;

  /// No description provided for @opCaroKannD.
  ///
  /// In en, this message translates to:
  /// **'Like the French, but the light-squared bishop gets out first. A sound, hard-to-crack defence with a clean pawn structure.'**
  String get opCaroKannD;

  /// No description provided for @opKingsIndianD.
  ///
  /// In en, this message translates to:
  /// **'Black lets White take the whole centre, finishes castling, then hits back with e5 or c5 and often storms the kingside.'**
  String get opKingsIndianD;

  /// No description provided for @opScandinavianD.
  ///
  /// In en, this message translates to:
  /// **'Black attacks e4 at once with d5. One simple idea, a quick game, and little theory to remember.'**
  String get opScandinavianD;

  /// No description provided for @opBudapestD.
  ///
  /// In en, this message translates to:
  /// **'Against 1.d4 Nf6 2.c4, Black throws in e5 to free the pieces fast. The pawn usually comes back, with the initiative.'**
  String get opBudapestD;

  /// No description provided for @kindOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get kindOpening;

  /// No description provided for @kindDefense.
  ///
  /// In en, this message translates to:
  /// **'Defence'**
  String get kindDefense;

  /// No description provided for @kindGambit.
  ///
  /// In en, this message translates to:
  /// **'Gambit'**
  String get kindGambit;

  /// No description provided for @kindAttack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get kindAttack;

  /// No description provided for @trainAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get trainAll;

  /// No description provided for @trainSearch.
  ///
  /// In en, this message translates to:
  /// **'Search openings'**
  String get trainSearch;

  /// No description provided for @trainTryFirst.
  ///
  /// In en, this message translates to:
  /// **'Try the first line'**
  String get trainTryFirst;

  /// No description provided for @trainLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 line} other{{count} lines}}'**
  String trainLines(int count);

  /// No description provided for @trainAsWhite.
  ///
  /// In en, this message translates to:
  /// **'As White'**
  String get trainAsWhite;

  /// No description provided for @trainAsBlack.
  ///
  /// In en, this message translates to:
  /// **'As Black'**
  String get trainAsBlack;

  /// No description provided for @trainPractise.
  ///
  /// In en, this message translates to:
  /// **'Practise vs {name}'**
  String trainPractise(String name);

  /// No description provided for @trainNoResults.
  ///
  /// In en, this message translates to:
  /// **'No openings match your search.'**
  String get trainNoResults;

  /// No description provided for @trainMainLine.
  ///
  /// In en, this message translates to:
  /// **'Main line'**
  String get trainMainLine;

  /// No description provided for @trainSecondLine.
  ///
  /// In en, this message translates to:
  /// **'Second line'**
  String get trainSecondLine;

  /// No description provided for @trainThirdLine.
  ///
  /// In en, this message translates to:
  /// **'Third line'**
  String get trainThirdLine;

  /// No description provided for @trainOrigin.
  ///
  /// In en, this message translates to:
  /// **'Named after {origin}'**
  String trainOrigin(String origin);

  /// No description provided for @toStart.
  ///
  /// In en, this message translates to:
  /// **'To the start'**
  String get toStart;

  /// No description provided for @toEnd.
  ///
  /// In en, this message translates to:
  /// **'To the end'**
  String get toEnd;

  /// No description provided for @trainLineProgress.
  ///
  /// In en, this message translates to:
  /// **'{name} · move {done} of {total}'**
  String trainLineProgress(String name, int done, int total);

  /// No description provided for @trainLineWrong.
  ///
  /// In en, this message translates to:
  /// **'Not the line. Play {san}'**
  String trainLineWrong(String san);

  /// No description provided for @trainLineDone.
  ///
  /// In en, this message translates to:
  /// **'Line done! Play on from here.'**
  String get trainLineDone;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'tk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'ru':
      return AppL10nRu();
    case 'tk':
      return AppL10nTk();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
