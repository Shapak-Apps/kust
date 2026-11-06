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

  /// No description provided for @endCheckmateWon.
  ///
  /// In en, this message translates to:
  /// **'{name} won by checkmate.'**
  String endCheckmateWon(String name);

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

  /// No description provided for @onbIntro.
  ///
  /// In en, this message translates to:
  /// **'Play bots at your level, train with puzzles and replay your games to learn from them.'**
  String get onbIntro;

  /// No description provided for @onbPlayBots.
  ///
  /// In en, this message translates to:
  /// **'Play bots'**
  String get onbPlayBots;

  /// No description provided for @onbPlayBotsSub.
  ///
  /// In en, this message translates to:
  /// **'From 400 to 2000 Elo, or pass the phone to a friend'**
  String get onbPlayBotsSub;

  /// No description provided for @onbSolve.
  ///
  /// In en, this message translates to:
  /// **'Solve puzzles'**
  String get onbSolve;

  /// No description provided for @onbSolveSub.
  ///
  /// In en, this message translates to:
  /// **'Short tactics with hints and a rating'**
  String get onbSolveSub;

  /// No description provided for @onbReview.
  ///
  /// In en, this message translates to:
  /// **'Review your games'**
  String get onbReview;

  /// No description provided for @onbReviewSub.
  ///
  /// In en, this message translates to:
  /// **'Every finished game is saved for replay'**
  String get onbReviewSub;

  /// No description provided for @onbNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account needed. Your games and progress stay on this device.'**
  String get onbNoAccount;

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

  /// No description provided for @onbAllSet.
  ///
  /// In en, this message translates to:
  /// **'You’re all set'**
  String get onbAllSet;

  /// No description provided for @onbStartingRating.
  ///
  /// In en, this message translates to:
  /// **'Your starting rating is {rating}.\nYour first game is one tap away.'**
  String onbStartingRating(int rating);

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
