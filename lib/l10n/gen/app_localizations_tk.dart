// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkmen (`tk`).
class AppL10nTk extends AppL10n {
  AppL10nTk([String locale = 'tk']) : super(locale);

  @override
  String get navPlay => 'Oýna';

  @override
  String get navPuzzles => 'Meseleler';

  @override
  String get navHistory => 'Oýunlarym';

  @override
  String get settings => 'Sazlamalar';

  @override
  String get achievements => 'Baýraklar';

  @override
  String get cont => 'Dowam et';

  @override
  String get back => 'Yza';

  @override
  String get forward => 'Öňe';

  @override
  String get start => 'Başy';

  @override
  String get end => 'Soňy';

  @override
  String get retry => 'Gaýtala';

  @override
  String get tryAgain => 'Täzeden synanyşyň';

  @override
  String get delete => 'Poz';

  @override
  String get keep => 'Sakla';

  @override
  String get close => 'Ýap';

  @override
  String get options => 'Saýlawlar';

  @override
  String get youName => 'Siz';

  @override
  String get whiteName => 'Ak';

  @override
  String get blackName => 'Gara';

  @override
  String get random => 'Tapawudy ýok';

  @override
  String get play => 'Oýna';

  @override
  String eloValue(int elo) {
    return '$elo Elo';
  }

  @override
  String get passAndPlay => 'Iki oýunçy';

  @override
  String vsBot(String name) {
    return '$name garşy';
  }

  @override
  String get gameStartTitle => 'Oýun başlaýar';

  @override
  String get whiteMovesFirst => 'Ak başlaýar';

  @override
  String get youPlayAsWhite => 'Siz Ak bilen oýnaýarsyňyz';

  @override
  String get youPlayAsBlack => 'Siz Gara bilen oýnaýarsyňyz';

  @override
  String get engineUnavailable => 'Motor elýeterli däl';

  @override
  String get engineCouldNotStart =>
      'Şahmat motory başlamady. Täzeden synanyşyň ýa-da dostuňyz bilen şu enjamda oýnaň.';

  @override
  String get botsNotSupported =>
      'Botlar bilen oýnamak bu enjamda goldanylmaýar.';

  @override
  String get playLocallyInstead => 'Şu enjamda oýnaň';

  @override
  String get abortTitle => 'Bu oýundan çykaýynmy?';

  @override
  String get abortSubtitle => 'Oýun netijesiz gutarar.';

  @override
  String get abort => 'Çyk';

  @override
  String get keepPlaying => 'Oýny dowam et';

  @override
  String get resignTitle => 'Bu oýny boýnuňyza alýarsyňyzmy?';

  @override
  String get resignSubtitle => 'Oýun gutarar we ýeňiliş hasaplanar.';

  @override
  String resignLocalTitle(String name) {
    return '$name boýnuna alýarmy?';
  }

  @override
  String resignLocalSubtitle(String winner) {
    return 'Oýun gutarar. $winner ýeňiji bolar.';
  }

  @override
  String get resign => 'Boýnuňa al';

  @override
  String get leaveGame => 'Oýundan çyk';

  @override
  String get exportGame => 'Oýny eksport et';

  @override
  String get showResult => 'Netijäni görkez';

  @override
  String get resultCheckmate => 'Şahmat';

  @override
  String get resultDraw => 'Deňe deň';

  @override
  String get resultTimeOut => 'Wagt gutardy';

  @override
  String get resultGameOver => 'Oýun gutardy';

  @override
  String wonTheGame(String name) {
    return '$name ýeňdi.';
  }

  @override
  String get gameDrawn => 'Oýun deňe deň gutardy.';

  @override
  String get gameEndedOnTime => 'Oýun wagt boýunça gutardy.';

  @override
  String get youResigned => 'Siz boýnuňyza aldyňyz.';

  @override
  String endCheckmateWon(String name) {
    return '$name şahmat bilen ýeňdi.';
  }

  @override
  String get endStalemate => 'Pat sebäpli deňe deň.';

  @override
  String get endFiftyMove => '50 göçüm düzgüni boýunça deňe deň.';

  @override
  String get endInsufficient => 'Material ýeterlik däl, deňe deň.';

  @override
  String get endRepetition => 'Üç gezek gaýtalanma sebäpli deňe deň.';

  @override
  String endTimeWon(String name) {
    return '$name wagt boýunça ýeňdi.';
  }

  @override
  String get endTimeNoMate =>
      'Wagt gutardy, emma garşydaş şahmat edip bilmeýär.';

  @override
  String get lobby => 'Baş sahypa';

  @override
  String get rematch => 'Ýene oýna';

  @override
  String ratingChange(int rating, String change) {
    return 'Reýting $rating ($change)';
  }

  @override
  String accuracyValue(String value) {
    return 'Takyklyk $value%';
  }

  @override
  String get analyzingYourMoves => 'Göçümleriňiz seljerilýär…';

  @override
  String get thinking => 'pikirlenýär';

  @override
  String invite1(String name) {
    return '$name oýna çagyrylýar…';
  }

  @override
  String invite2(String name) {
    return '$name oturýar…';
  }

  @override
  String get invite3 => 'Tagta taýýarlanýar…';

  @override
  String invite4(String name) {
    return '$name taýýarlanýar…';
  }

  @override
  String get takeBack => 'Yza al';

  @override
  String get pause => 'Bes et';

  @override
  String get resume => 'Dowam et';

  @override
  String get hint => 'Kömek';

  @override
  String analyzingMove(String san) {
    return '$san seljerilýär…';
  }

  @override
  String get pausedTitle => 'Bes edildi';

  @override
  String get tapToResume => 'Dowam etmek üçin basyň';

  @override
  String get pausedSemantics => 'Bes edildi. Dowam etmek üçin basyň';

  @override
  String promoteTo(String piece) {
    return '$piece bolup öwrül';
  }

  @override
  String get cancelPromotion => 'Öwrülişigi ýatyr';

  @override
  String get pieceQueen => 'Wezir';

  @override
  String get pieceRook => 'Gala';

  @override
  String get pieceBishop => 'Pil';

  @override
  String get pieceKnight => 'At';

  @override
  String get noMovesYet => 'Heniz göçüm ýok';

  @override
  String get dismiss => 'Ýap';

  @override
  String get gameOptions => 'Oýun saýlawlary';

  @override
  String get evalBar => 'Baha ölçegi';

  @override
  String get evalBarSub => 'Kimiň ýagdaýynyň gowudygyny görkezýär';

  @override
  String get moveFeedback => 'Göçüm bahasy';

  @override
  String get moveFeedbackSub => 'Her göçümiňizi bahalandyrýar';

  @override
  String get showBest => 'Iň gowusyny görkez';

  @override
  String get showBestSub => 'Häzirki ýagdaýda iň gowy göçüme ok';

  @override
  String get boardImage => 'Tagta suraty';

  @override
  String get boardImageSub => 'Ýagdaýy PNG hökmünde paýlaşyň';

  @override
  String get copyFen => 'FEN göçür';

  @override
  String get copyFenSub => 'Islendik küşt programmasy üçin';

  @override
  String get copyPgn => 'PGN göçür';

  @override
  String get copyPgnSub => 'Oýnuň ähli göçümleri';

  @override
  String get sharePgn => 'PGN paýlaş';

  @override
  String get sharePgnSub => 'Oýny başga programma iber';

  @override
  String get fenCopied => 'FEN göçürildi';

  @override
  String get pgnCopied => 'PGN göçürildi';

  @override
  String get qBrilliant => 'Haýran galdyryjy';

  @override
  String get qGreat => 'Ajaýyp';

  @override
  String get qBest => 'Takyk';

  @override
  String get qExcellent => 'Dogry göçüm';

  @override
  String get qGood => 'Gowy';

  @override
  String get qInaccuracy => 'Gowşak';

  @override
  String get qMistake => 'Ýalňyşlyk';

  @override
  String get qMiss => 'Elden gidirme';

  @override
  String get qBlunder => 'Erbet';

  @override
  String bannerBrilliant(String played) {
    return '$played · haýran galdyryjy göçüm';
  }

  @override
  String bannerGreat(String played) {
    return '$played · ajaýyp göçüm';
  }

  @override
  String bannerBest(String played) {
    return '$played · takyk göçüm';
  }

  @override
  String bannerExcellent(String played, String best) {
    return '$played dogry göçümdi · iň gowusy $best';
  }

  @override
  String bannerGood(String played, String best) {
    return '$played gowudy · iň gowusy $best';
  }

  @override
  String bannerInaccuracy(String played, String best) {
    return '$played gowşakdy · iň gowusy $best';
  }

  @override
  String bannerMistake(String played, String best) {
    return '$played ýalňyşlykdy · iň gowusy $best';
  }

  @override
  String bannerMiss(String played, String best) {
    return '$played elden gidirmedi · iň gowusy $best';
  }

  @override
  String bannerBlunder(String played, String best) {
    return '$played erbetdi · iň gowusy $best';
  }

  @override
  String get welcomeTitle => 'Küşt-e hoş geldiňiz';

  @override
  String get welcomeSub =>
      'Botlar bilen oýnaň, meseleleri çözüň we her göçümde gowulaşyň.';

  @override
  String get letsPlay => 'Oýnalyň';

  @override
  String get challengeBot => 'Bot bilen güýç synanyşyň';

  @override
  String get newStudents => 'Türkmenistandan täze okuwçylar';

  @override
  String helloName(String name) {
    return 'Salam, $name';
  }

  @override
  String get readyForGame => 'Oýna taýynmysyňyz?';

  @override
  String ratingBots(int rating, int beaten, int total) {
    return 'Reýting $rating · Ýeňilen botlar: $beaten/$total';
  }

  @override
  String get playAGame => 'Oýun oýnaň';

  @override
  String get pickOpponent => 'Garşydaşyňyzy saýlaň';

  @override
  String get eloShows => 'Elo olaryň oýun güýjüni görkezýär';

  @override
  String get playAs => 'Oýnaýan tarapyňyz';

  @override
  String get selectOpponent => 'Garşydaş saýlaň';

  @override
  String playBot(String name) {
    return '$name bilen oýnaň';
  }

  @override
  String get youMoveFirst => 'Ilki siz göçýärsiňiz';

  @override
  String botMovesFirst(String name) {
    return '$name ilki göçýär';
  }

  @override
  String get letFateDecide => 'Kysmat saýlasyn';

  @override
  String get blitz => 'Blis';

  @override
  String get rapid => 'Rapid';

  @override
  String minutesShort(int n) {
    return '$n min';
  }

  @override
  String get timeControl => 'Wagt dolandyryşy';

  @override
  String get timeControlSub => 'Her oýunçynyň wagty näçe?';

  @override
  String get noClock => 'Sagatsyz';

  @override
  String get noClockSub => 'Wagt çäklendirmesiz oýun';

  @override
  String get startGame => 'Oýuna başlaň';

  @override
  String get newGame => 'Täze oýun';

  @override
  String get playWithBots => 'Botlar bilen oýnaň';

  @override
  String get playWithBotsSub => 'Botlarymyz bilen güýç synanyşyň';

  @override
  String get playLocally => 'Şu enjamda oýnaň';

  @override
  String get playLocallySub => 'Bir enjamda iki oýunçy';

  @override
  String get practiceMode => 'Türgenleşik';

  @override
  String get practiceModeSub =>
      'Göçümi yza almaga, kömege we göçüm bahasyny görkezmäge rugsat berýär';

  @override
  String get practiceTag => 'Türgenleşik';

  @override
  String get appearance => 'Daşky görnüş';

  @override
  String get themeAuto => 'Awto';

  @override
  String get themeLight => 'Açyk';

  @override
  String get themeDark => 'Garaňky';

  @override
  String get boardSection => 'Tagta';

  @override
  String get piecesSection => 'Daşlar';

  @override
  String get movesSection => 'Göçümler';

  @override
  String get castleOnRook => 'Rokirowkany gala basyp ediň';

  @override
  String get castleOnRookSub =>
      'Rokirowka etmek üçin şa, soňra onuň galasyna basyň';

  @override
  String get premoves => 'Öň göçümler';

  @override
  String get premovesSub => 'Bot pikirlenýärkä indiki göçümiňizi nobata goýuň';

  @override
  String get feedbackSection => 'Seslenme';

  @override
  String get soundEffects => 'Ses effektleri';

  @override
  String get haptics => 'Titreme';

  @override
  String boardThemeSemantics(String theme) {
    return '$theme tagta';
  }

  @override
  String pieceSetSemantics(String set) {
    return '$set çöpler';
  }

  @override
  String get boardBrown => 'Goňur';

  @override
  String get boardGreen => 'Ýaşyl';

  @override
  String get boardDarkBlue => 'Goýy gök';

  @override
  String get boardWood => 'Agaç';

  @override
  String get pieceClassic => 'Klassiki';

  @override
  String get pieceShaded => 'Kölegeli';

  @override
  String get pieceGraphite => 'Grafit';

  @override
  String get pieceBrushed => 'Çotgalanan';

  @override
  String get histNoGames => 'Heniz oýun ýok';

  @override
  String get histNoGamesSub =>
      'Gutarylan oýunlar şu ýerde görünýär, şonuň üçin olary gaýtadan görüp bilersiňiz.';

  @override
  String get deleteGameTitle => 'Bu oýny pozmalymy?';

  @override
  String get deleteGameSub => 'Ol Oýunlarym sahypasyndan aýrylar.';

  @override
  String get resultWhiteWon => 'Ak ýeňdi';

  @override
  String get resultBlackWon => 'Gara ýeňdi';

  @override
  String get resultWin => 'Ýeňiş';

  @override
  String get resultLoss => 'Ýeňiliş';

  @override
  String get today => 'Şu gün';

  @override
  String get yesterday => 'Düýn';

  @override
  String get monthsShort =>
      'Ýan,Few,Mart,Apr,Maý,Iýun,Iýul,Awg,Sen,Okt,Noý,Dek';

  @override
  String dateShort(String month, int day) {
    return '$day $month';
  }

  @override
  String get semGamePassPlay => 'Iki oýunçy';

  @override
  String semGameVsBot(String name) {
    return '$name garşy oýun';
  }

  @override
  String semAccuracy(String value) {
    return 'takyklyk $value göterim';
  }

  @override
  String get analysisUnavailable => 'Seljerme häzir bu enjamda elýeterli däl';

  @override
  String get retryAnalysis => 'Seljermäni gaýtalaň';

  @override
  String get analyzeGame => 'Bu oýny seljeriň';

  @override
  String get gameTitle => 'Oýun';

  @override
  String get replaySettings => 'Gaýtadan görmegiň sazlamalary';

  @override
  String get evalBarReplaySub =>
      'Her göçümde kimiň ýagdaýynyň gowudygyny görkezýär';

  @override
  String get moveFeedbackReplaySub =>
      'Gezip çykanyňyzda her göçümi bahalandyrýar';

  @override
  String get showBestReplaySub => 'Başga göçüm edilen bolsa, iň gowy göçüme ok';

  @override
  String get notAvailableHere => 'Bu enjamda elýeterli däl';

  @override
  String get evalUnavailable => 'Baha häzir elýeterli däl';

  @override
  String get gameNotFound => 'Bu oýun tapylmady.';

  @override
  String get backToHistory => 'Oýunlarym sahypasyna gaýdyň';

  @override
  String puzzleN(int n) {
    return 'Mesele $n';
  }

  @override
  String get allPuzzles => 'Ähli meseleler';

  @override
  String get puzzleCouldNotLoad => 'Meseläni ýükläp bolmady';

  @override
  String get puzzlesCouldNotLoad => 'Meseleleri ýükläp bolmady';

  @override
  String get noPuzzlesAvailable => 'Heniz mesele ýok';

  @override
  String get noPuzzlesYet => 'Heniz mesele ýok. Ýakynda gaýdyp geliň.';

  @override
  String get puzzleSolved => 'Mesele çözüldi!';

  @override
  String get solutionShown => 'Çözgüt görkezildi';

  @override
  String get notThatOne => 'Bu däl';

  @override
  String get whiteToMove => 'Akyň göçümi';

  @override
  String get blackToMove => 'Garanyň göçümi';

  @override
  String get backToPuzzles => 'Meselelere gaýdyň';

  @override
  String get solution => 'Çözgüt';

  @override
  String get nextPuzzle => 'Indiki mesele';

  @override
  String get nextLevel => 'Indiki derejä';

  @override
  String themeMateIn(int n) {
    return '$n göçümde şahmat';
  }

  @override
  String get themeFork => 'Çatal';

  @override
  String get themePin => 'Baglanma';

  @override
  String get themeEndgame => 'Ahyrky oýun';

  @override
  String get themeWinMaterial => 'Material ýeňmek';

  @override
  String get loomMate1 => 'Şahmat 1';

  @override
  String get loomMate2 => 'Şahmat 2';

  @override
  String get loomForks => 'Çatallar';

  @override
  String get loomPins => 'Baglanmalar';

  @override
  String get loomEndgames => 'Ahyrky oýunlar';

  @override
  String get puzzlesAllWoven => 'Ähli meseleler dokaldy!';

  @override
  String puzzlesNext(String theme) {
    return 'Indiki: $theme';
  }

  @override
  String get puzzlesMoreSoon => 'Täzeleri ýakynda goşular.';

  @override
  String get reviewPuzzles => 'Meseleleri gaýtalaň';

  @override
  String get statRating => 'REÝTING';

  @override
  String get statKnots => 'DÜWÜNLER';

  @override
  String get statBest => 'IŇ GOWY';

  @override
  String puzzlesSolvedOf(String theme, int solved, int total) {
    return '$theme · $solved/$total çözüldi';
  }

  @override
  String loomProgress(String theme, int done, int total) {
    return '$theme, $done/$total düwün dokaldy';
  }

  @override
  String get levelWoven => 'Dokaldy ✓';

  @override
  String levelKnots(int done, int total) {
    return '$done/$total düwün';
  }

  @override
  String get levelNotStarted => 'Başlanmady';

  @override
  String get levelComingSoon => 'Ýakynda';

  @override
  String golWovenSem(String tribe) {
    return '$tribe göl dokaldy';
  }

  @override
  String golWoven(String tribe) {
    return '$tribe göl dokaldy';
  }

  @override
  String golWholeCarpet(int knots) {
    return '$knots/$knots düwün. Tutuş haly taýýar.';
  }

  @override
  String golNext(int knots, String next) {
    return '$knots/$knots düwün. Indiki göl: $next.';
  }

  @override
  String get dailyPuzzle => 'Günüň meselesi';

  @override
  String get solvedToday => 'Şu gün çözüldi';

  @override
  String get dailySolved => 'çözüldi';

  @override
  String dailyStreakSem(String days) {
    return 'yzygiderlilik: $days';
  }

  @override
  String get coachMateIn1 =>
      'Bir göçüm oýny gutarýar. Ony görýärsiňizmi?\nHut şu wagt şahmat edýän göçümi tapyň.\nŞanyň çykar ýoly ýok. Gapyny ýapyň!';

  @override
  String get coachMateIn2 =>
      'Iki göçümde şahmat edip bilersiňizmi?\nŞah ýa-da güýçli haýbat bilen başlaň.\nŞahmata iki göçüm. Haýsysy birinji?';

  @override
  String get coachMateIn3 =>
      'Üç göçümde şahmat. Mejbur edýän göçümler hakda pikir ediň.\nÖň şahlar, soň şanyň nirä gidýändigine seret.';

  @override
  String get coachFork =>
      'Bir wagtyň özünde iki çöpe hüjüm edýän göçümi tapyň.\nÇatal görýärsiňizmi?\nBir çöp, iki nyşan. Ol nirä düşýär?';

  @override
  String get coachPin =>
      'Bir çöp gozgalyp bilmeýär. Muny ulanyp bilersiňizmi?\nBaglanan çöpi tapyň we basyşy artdyryň.\nŞasynyň öňünde näme gysylyp galdy?';

  @override
  String get coachEndgame =>
      'Az çöp, uly pikirler. Howlukmaň.\nAhyrky oýunda şa — söweşiji.\nÄhtiýatly göçümler muny ýeňýär.';

  @override
  String get coachGeneric =>
      'Ilki şahlary, alyşlary we haýbatlary gözläň.\nNäme goragsyz? Howlukmaň.\nIň gowy göçüm adatça mejbur edýär.';

  @override
  String get coachWrong =>
      'Ýakyn, ýöne däl. Başga göçüm synanyşyň.\nBu däl. Şahlar we alyşlar hakda pikir ediň.\nHm, ýene seredip görüň. Siz edip bilersiňiz!\nMuňa garşydaş sypýar. Başga näme bar?';

  @override
  String get coachCorrect =>
      'Ajaýyp iş! Indikä geçeliň.\nSiz ony gördüňiz. Gowy oýnadyňyz!\nÖtgür göz. Arassa oýnadyňyz.\nÝene bir düwün dokaldy. Dowam ediň!';

  @override
  String get coachRetry =>
      'Öwreniň, soň özüňiz synanyşyň.\nIndi bilýärsiňiz. «Gaýtala» basyň!\nÇöpleriň bilelikde nähili işleýändigine syn ediň.';

  @override
  String get coachDaily =>
      'Mesele gününi hiç haçan geçirmäň!\nIlki şahlary, alyşlary we haýbatlary gözläň.\nGünde bir mesele erbet göçümleri daşlaşdyrýar.\nHowlukmaň: iň gowy göçüm adatça mejbur edýär.';

  @override
  String achEarnedOf(int earned, int total) {
    return '$earned/$total gazanyldy';
  }

  @override
  String get achUnlocked => 'Baýrak gazanyldy';

  @override
  String get achEarned => 'gazanyldy';

  @override
  String get achNotEarned => 'entek gazanylmady';

  @override
  String get ach_first_game_t => 'Ilkinji göçüm';

  @override
  String get ach_first_game_d => 'Bot bilen bir oýun gutaryň';

  @override
  String get ach_first_win_t => 'Ilkinji ýeňiş';

  @override
  String get ach_first_win_d => 'Bota garşy oýun ýeňiň';

  @override
  String get ach_checkmate_t => 'Şahmat!';

  @override
  String get ach_checkmate_d => 'Oýuny şahmat bilen ýeňiň';

  @override
  String get ach_quick_mate_t => 'Ýyldyrym';

  @override
  String get ach_quick_mate_d => 'Boty 20 ýa-da has az göçümde şahmat ediň';

  @override
  String get ach_giant_slayer_t => 'Äpet ýeňiji';

  @override
  String get ach_giant_slayer_d =>
      'Reýtingi siziňkiden 300 ýa-da has ýokary bota ýeňiň';

  @override
  String get ach_three_bots_t => 'Ýokary galýan ýyldyz';

  @override
  String get ach_three_bots_d => '3 dürli bota ýeňiň';

  @override
  String get ach_all_bots_t => 'Çempion';

  @override
  String get ach_all_bots_d => 'Ähli botlara ýeňiň';

  @override
  String get ach_marathon_t => 'Marafon';

  @override
  String get ach_marathon_d => '60 ýa-da has köp göçümli oýun oýnaň';

  @override
  String get ach_accurate_t => 'Ökde atyjy';

  @override
  String get ach_accurate_d => '90% takyklykly oýun oýnaň';

  @override
  String get ach_brilliant_t => 'Haýran galdyryjy!';

  @override
  String get ach_brilliant_d => 'Haýran galdyryjy göçüm ediň';

  @override
  String get ach_first_puzzle_t => 'Mesele çözüji';

  @override
  String get ach_first_puzzle_d => 'Ilkinji meseläňizi çözüň';

  @override
  String get ach_puzzles_25_t => 'Düwün-düwün';

  @override
  String get ach_puzzles_25_d => '25 mesele çözüň';

  @override
  String get ach_first_gol_t => 'Ilkinji göl';

  @override
  String get ach_first_gol_d => 'Bir göli doly dokaň';

  @override
  String get ach_whole_carpet_t => 'Ussat dokmaçy';

  @override
  String get ach_whole_carpet_d => 'Bäş göliň hemmesini dokaň';

  @override
  String get ach_streak_3_t => 'Üstünlik yzly-yzyna';

  @override
  String get ach_streak_3_d => 'Günüň meselesini yzly-yzyna 3 gün çözüň';

  @override
  String get ach_streak_7_t => 'Ody hepde';

  @override
  String get ach_streak_7_d => 'Günüň meselesini yzly-yzyna 7 gün çözüň';

  @override
  String get onbGetStarted => 'Başlaň';

  @override
  String get onbStartPlaying => 'Oýnamaga başlaň';

  @override
  String get onbSkip => 'Häzirlikçe geçiň';

  @override
  String get onbTitle => 'Gowulaşmaga kömek edýän şahmat';

  @override
  String get onbIntro =>
      'Derejeňize laýyk botlar bilen oýnaň, meseleler bilen türgenleşiň we oýunlaryňyzy gaýtadan görüp, olardan öwreniň.';

  @override
  String get onbPlayBots => 'Botlar bilen oýnaň';

  @override
  String get onbPlayBotsSub =>
      '400-den 2000 Elo çenli ýa-da telefony dostuňyza beriň';

  @override
  String get onbSolve => 'Meseleleri çözüň';

  @override
  String get onbSolveSub => 'Kömekli we reýtingli gysga taktikalar';

  @override
  String get onbReview => 'Oýunlaryňyzy gaýtadan görüň';

  @override
  String get onbReviewSub =>
      'Her gutarylan oýun gaýtadan görmek üçin saklanýar';

  @override
  String get onbNoAccount =>
      'Akkaunt gerek däl. Oýunlaryňyz we ösüşiňiz şu enjamda saklanýar.';

  @override
  String get onbHowStrong => 'Güýjüňiz nähili?';

  @override
  String get onbHowStrongSub =>
      'Bu başlangyç reýtingiňizi kesgitleýär. Ol oýnadygyňyzça üýtgeýär, şonuň üçin köp pikir etmäň.';

  @override
  String get lvlBeginner => 'Başlangyç';

  @override
  String get lvlBeginnerD => 'Men entek şahmat öwrenip başladym.';

  @override
  String get lvlIntermediate => 'Orta';

  @override
  String get lvlIntermediateD =>
      'Men esaslary bilýärin we yzygiderli oýnaýaryn.';

  @override
  String get lvlAdvanced => 'Ösen';

  @override
  String get lvlAdvancedD =>
      'Men strategiýany we çylşyrymly ýagdaýlary düşünýärin.';

  @override
  String get lvlCompetitive => 'Ýaryşçy';

  @override
  String get lvlCompetitiveD =>
      'Men çynlakaý oýnaýaryn we ýaryşlara gatnaşyp bilerin.';

  @override
  String get onbAllSet => 'Hemme zat taýýar';

  @override
  String onbStartingRating(int rating) {
    return 'Başlangyç reýtingiňiz $rating.\nIlkinji oýnuňyz bir basyş uzaklykda.';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
      one: '1 gün',
    );
    return '$_temp0';
  }

  @override
  String get yourAvatar => 'Siziň suratyňyz';

  @override
  String avatarOf(String name) {
    return '$name, siziň suratyňyz';
  }

  @override
  String get language => 'Dil';

  @override
  String get languageAuto => 'Ulgam';

  @override
  String get youWonGame => 'Siz ýeňdiňiz.';

  @override
  String get youWonOnTime => 'Siz wagt boýunça ýeňdiňiz.';

  @override
  String get botGreetBahar =>
      'Salam! Men Bahar. Men hem küşt öwrenýärin, oýnalyň!';

  @override
  String get botGreetElizabeth => 'Salam. Ýakymly bir oýun oýnalymy?';

  @override
  String get botGreetMark => 'Hey! Oýna taýynsyňyzmy? Men taýyn!';

  @override
  String get botGreetApex => 'Meni ýeňip bilersiňiz öýdýärsiňizmi? Görkeziň.';

  @override
  String get botGreetKarl => 'Howlukmaň. Küşt sabyrlylyga sylag berýär.';

  @override
  String get botGreetEnejan => 'Hoş geldiňiz! Oturyň, bir oýun oýnalyň.';

  @override
  String get botGreetMaya =>
      'Salam! Men akylly göçümleri halaýaryn. Siziňkini görkeziň.';

  @override
  String get botGreetYura => 'Oýnalyň. Men aňsat bermeýärin.';

  @override
  String get botGreetBerdi => 'Hoş geldiňiz. Küşt uzak ýol. Geliň, ýöreliň.';

  @override
  String get botCheerfulBlunder =>
      'Aha! Sag boluň!|Waý, muny bilgeşleýin etdiňizmi?';

  @override
  String get botCheerfulBrilliant =>
      'Waý, haýran galdyryjy göçüm!|Siz örän gowy oýnaýarsyňyz!';

  @override
  String get botCheerfulWin =>
      'Ýeňdim! Gowy oýun boldy!|Örän gyzykly boldy, ýene oýnalymy?';

  @override
  String get botCheerfulLoss =>
      'Siz ýeňdiňiz! Gutlaýaryn!|Waý, ýeňdiňiz! Ýene bir oýnalyň!';

  @override
  String get botCheerfulDraw =>
      'Deňe deň! Adalatly netije.|Hiç kim utulmady, ikimiz hem gazandyk!';

  @override
  String get botCalmBlunder => 'Gyzykly saýlaw.|Muny şatlyk bilen alaryn.';

  @override
  String get botCalmBrilliant =>
      'Gowy göçüm. Gözüňiz ýitidir.|Täsirli. Muny garaşmadym.';

  @override
  String get botCalmWin =>
      'Gowy oýun. Sag boluň.|Indiki gezek bagtyňyz getsin.';

  @override
  String get botCalmLoss =>
      'Gowy oýnadyňyz. Mynasyp ýeňiş.|Gutlaýaryn, hakyky ýeňiş.';

  @override
  String get botCalmDraw => 'Adalatly netije.|Güýçlerimiz deň eken.';

  @override
  String get botCockyBlunder => 'Ha! Aňsat boldy.|Bu siziň meýilnamaňyzmydy?';

  @override
  String get botCockyBrilliant =>
      'Bagt getirdi. Öwrenişmäň.|Ýagşy, bu erbet däl.';

  @override
  String get botCockyWin => 'Hiç şübhem ýokdy.|Indiki gezek, çempion.';

  @override
  String get botCockyLoss =>
      'Bolýar, bu gezek siz. Täzeden?|Täze başlaýanyň bagty. Ýene!';

  @override
  String get botCockyDraw =>
      'Deňe deň? Men entek gyzyp ýördüm.|Hm. Indiki gezek men ýeňerin.';

  @override
  String get botWiseBlunder => 'Göçmezden öň oýlanyň.|Her göçümiň bahasy bar.';

  @override
  String get botWiseBrilliant => 'Ýatda galjak göçüm.|Ine, hakyky küşt.';

  @override
  String get botWiseWin => 'Her oýun bir zat öwredýär.|Muňa seredip öwreniň.';

  @override
  String get botWiseLoss =>
      'Siz maňa bir zat öwretdiňiz.|Gowy oýnadyňyz, mynasyp ýeňiş.';

  @override
  String get botWiseDraw =>
      'Deňagramlylyk hem netijedir.|Rahat oýun, rahat tamamlanyş.';

  @override
  String get botChat => 'Botlaryň gepleşigi';

  @override
  String get botChatSub => 'Botlar oýun barada pikir aýdýar';

  @override
  String get reviewTitle => 'Oýunyň seljermesi';

  @override
  String get reviewButton => 'Seljerme';

  @override
  String reviewAnalyzing(int percent) {
    return 'Oýun seljerilýär… $percent%';
  }

  @override
  String get reviewAccuracy => 'Takyklyk';

  @override
  String get reviewMoves => 'Göçümler';

  @override
  String get reviewGraph => 'Kim öňdedi';

  @override
  String get reviewKeyTitle => 'Öwrenmeli göçümler';

  @override
  String get reviewNoBig => 'Uly ýalňyşlyk ýok. Gowy oýnadyňyz!';

  @override
  String reviewBestWas(String san) {
    return 'Takyk göçüm: $san';
  }

  @override
  String reviewMoveNo(int n) {
    return '$n-nji göçüm';
  }

  @override
  String get reviewOpenReplay => 'Gaýtalamany aç';

  @override
  String get reviewNoEngine =>
      'Bu enjamda hereketlendiriji ýok, oýny seljerip bolmaýar.';

  @override
  String get reviewFailed => 'Seljerme tamamlanmady.';

  @override
  String get reviewTooShort => 'Bu oýun seljermek üçin gaty gysga.';

  @override
  String get navLearn => 'Sapaklar';

  @override
  String get learnTitle => 'Sapaklar';

  @override
  String get learnSub => 'Ilkinji göçümden şahmada çenli';

  @override
  String lessonCount(int done, int total) {
    return '$done/$total sapak';
  }

  @override
  String lessonTasks(int n) {
    return '$n tabşyryk';
  }

  @override
  String get lessonStart => 'Sapagy başla';

  @override
  String get learnNext => 'Indiki';

  @override
  String taskProgress(int n, int total) {
    return 'Tabşyryk $n/$total';
  }

  @override
  String get learnWrong => 'Bolmady. Ýene synanyşyň.';

  @override
  String get learnNotBest => 'Bu iň gymmat çöpi almak däl.';

  @override
  String get learnStalemate => 'Bu pat, deňe deň. Şahmady tapyň.';

  @override
  String get learnWellDone => 'Ajaýyp!';

  @override
  String get lessonDone => 'Sapak tamamlandy!';

  @override
  String get lessonNext => 'Indiki sapak';

  @override
  String get lessonAll => 'Ähli sapaklar';

  @override
  String get lessonPlayGame => 'Oýun oýnaň';

  @override
  String get learnHint => 'Kömek';

  @override
  String get learnAllDone => 'Ähli sapaklary gutardyňyz. Oýnamaga wagt!';

  @override
  String get pieceKing => 'Şa';

  @override
  String get piecePawn => 'Peşka';

  @override
  String taskCollectOne(String piece) {
    return '$piece bilen ýyldyza baryň';
  }

  @override
  String taskCollectMany(String piece) {
    return '$piece bilen ähli ýyldyzlary ýygnaň';
  }

  @override
  String get taskCapture => 'Bellenen ähli çöpleri alyň';

  @override
  String get taskBestCapture => 'Iň gymmat çöpi alyň';

  @override
  String get taskCheck => 'Şah beriň';

  @override
  String get taskMate => 'Bir göçümde şahmat ediň';

  @override
  String get taskEscape => 'Şahyňyza şah berildi. Ondan çykyň.';

  @override
  String get taskEscapeCapture => 'Hüjüm edýän çöpi alyp, şahdan çykyň';

  @override
  String get taskCastleKing =>
      'Kiçi rokirowka ediň: şany gala tarap iki öýjük süýşüriň';

  @override
  String get taskCastleQueen =>
      'Uly rokirowka ediň: şany gala tarap iki öýjük süýşüriň';

  @override
  String get taskEnPassant => 'Peşkany geçip barýarka alyň (en passant)';

  @override
  String get taskPromote => 'Peşkany soňky hatara ýetirip, ýokarlandyryň';

  @override
  String get lessonPawnTitle => 'Peşka';

  @override
  String get lessonPawnIntro =>
      'Peşkalar piýada esgerlerdir. Peşka bir öýjük öňe, başlangyç ýerinden bolsa iki öýjük öňe göçýär. Ol diňe çapraz bir öýjügi alýar, göni öňdäkini däl.';

  @override
  String get lessonRookTitle => 'Gala';

  @override
  String get lessonRookIntro =>
      'Gala göni çyzykda, hatar ýa-da sütün boýunça islendik öýjük sanyna göçýär. Ol başga çöpleriň üstünden böküp bilmeýär.';

  @override
  String get lessonBishopTitle => 'Pil';

  @override
  String get lessonBishopIntro =>
      'Pil çapraz islendik öýjük sanyna göçýär. Ol hemişe şol bir reňkdäki öýjüklerde galýar.';

  @override
  String get lessonQueenTitle => 'Wezir';

  @override
  String get lessonQueenIntro =>
      'Wezir iň güýçli çöp. Ol gala bilen pilin göçümlerini birleşdirýär: göni ýa-da çapraz islendik öýjük sanyna.';

  @override
  String get lessonKnightTitle => 'At';

  @override
  String get lessonKnightIntro =>
      'At «G» şekilinde göçýär: bir tarapa iki öýjük, ýanyna bir öýjük. Ol başga çöpleriň üstünden böküp bilýän ýeke-täk çöpdür.';

  @override
  String get lessonKingTitle => 'Şa';

  @override
  String get lessonKingIntro =>
      'Şa islendik tarapa bir öýjük göçýär. Ony goraň: şa ýitse, oýun ýitýär. Ol garşydaşyň şasynyň ýanyna ýa-da hüjüm astyndaky öýjüge baryp bilmeýär.';

  @override
  String get lessonValuesTitle => 'Daşlary almak';

  @override
  String get lessonValuesIntro =>
      'Çöpleriň bahasy bar: peşka 1, at 3, pil 3, gala 5, wezir 9. Has gymmat çöpi almak artykmaçlyk berýär. Hemişe iň gymmat çöpi almagy gözläň.';

  @override
  String get lessonCheckTitle => 'Şah';

  @override
  String get lessonCheckIntro =>
      'Şa hüjüm astynda bolsa, oňa şah diýilýär. Derrew şahdan çykmaly: şany süýşüriň, hüjümi ýapyň ýa-da hüjüm edýän çöpi alyň.';

  @override
  String get lessonSpecialTitle => 'Aýratyn göçümler';

  @override
  String get lessonSpecialIntro =>
      'Rokirowka şany gala tarap iki öýjük süýşürýär, gala bolsa onuň üstünden geçýär. En passant peşka iki öýjük bilen geçen garşydaş peşkany almaga mümkinçilik berýär. Soňky hatara ýeten peşka ýokarlanýar, adatça wezir bolýar.';

  @override
  String get lessonMateTitle => 'Şahmat';

  @override
  String get lessonMateIntro =>
      'Şahmat – çykyp bolmaýan şah: oýun gutarýar we siz ýeňýärsiňiz. Garşydaşyň göçümi ýok, ýöne şah ýok bolsa, bu pat – deňe deň. Ýeňip barýarkaňyz, pat etmekden gaça duruň.';

  @override
  String get lessonFirstMatesTitle => 'Ilkinji şahmatlaryňyz';

  @override
  String get lessonFirstMatesIntro =>
      'Oýunlary ýeňdirýän üç nagyş: soňky hatardaky şahmat, iki galanyň basgançagy we wezir bilen şa. Bir göçümde şahmady tapyň.';
}
