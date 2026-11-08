// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppL10nRu extends AppL10n {
  AppL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get navPlay => 'Играть';

  @override
  String get navPuzzles => 'Задачи';

  @override
  String get navHistory => 'История';

  @override
  String get settings => 'Настройки';

  @override
  String get achievements => 'Достижения';

  @override
  String get cont => 'Продолжить';

  @override
  String get back => 'Назад';

  @override
  String get forward => 'Вперёд';

  @override
  String get start => 'В начало';

  @override
  String get end => 'В конец';

  @override
  String get retry => 'Повторить';

  @override
  String get tryAgain => 'Повторить попытку';

  @override
  String get delete => 'Удалить';

  @override
  String get keep => 'Оставить';

  @override
  String get close => 'Закрыть';

  @override
  String get options => 'Параметры';

  @override
  String get youName => 'Вы';

  @override
  String get whiteName => 'Белые';

  @override
  String get blackName => 'Чёрные';

  @override
  String get random => 'Случайно';

  @override
  String get play => 'Играть';

  @override
  String eloValue(int elo) {
    return '$elo Elo';
  }

  @override
  String get passAndPlay => 'Игра вдвоём';

  @override
  String vsBot(String name) {
    return 'против $name';
  }

  @override
  String get gameStartTitle => 'Начало партии';

  @override
  String get whiteMovesFirst => 'Белые ходят первыми';

  @override
  String get youPlayAsWhite => 'Вы играете белыми';

  @override
  String get youPlayAsBlack => 'Вы играете чёрными';

  @override
  String get engineUnavailable => 'Движок недоступен';

  @override
  String get engineCouldNotStart =>
      'Шахматный движок не запустился. Повторите попытку или сыграйте с другом на этом устройстве.';

  @override
  String get botsNotSupported =>
      'Игра с ботами не поддерживается на этом устройстве.';

  @override
  String get playLocallyInstead => 'Играть вдвоём на этом устройстве';

  @override
  String get abortTitle => 'Прервать эту партию?';

  @override
  String get abortSubtitle => 'Партия закончится без результата.';

  @override
  String get abort => 'Прервать';

  @override
  String get keepPlaying => 'Продолжить игру';

  @override
  String get resignTitle => 'Сдать эту партию?';

  @override
  String get resignSubtitle => 'Партия закончится поражением.';

  @override
  String resignLocalTitle(String name) {
    return '$name: сдаться?';
  }

  @override
  String resignLocalSubtitle(String winner) {
    return 'Партия закончится. Победа: $winner.';
  }

  @override
  String get resign => 'Сдаться';

  @override
  String get leaveGame => 'Выйти из партии';

  @override
  String get exportGame => 'Экспорт партии';

  @override
  String get showResult => 'Показать результат';

  @override
  String get resultCheckmate => 'Мат';

  @override
  String get resultDraw => 'Ничья';

  @override
  String get resultTimeOut => 'Время вышло';

  @override
  String get resultGameOver => 'Партия окончена';

  @override
  String wonTheGame(String name) {
    return 'Победа: $name.';
  }

  @override
  String get gameDrawn => 'Партия закончилась вничью.';

  @override
  String get gameEndedOnTime => 'Партия закончилась по времени.';

  @override
  String get youResigned => 'Вы сдались.';

  @override
  String endCheckmateWon(String name) {
    return 'Победа матом: $name.';
  }

  @override
  String get endStalemate => 'Ничья: пат.';

  @override
  String get endFiftyMove => 'Ничья по правилу 50 ходов.';

  @override
  String get endInsufficient => 'Ничья: недостаточно материала.';

  @override
  String get endRepetition => 'Ничья по троекратному повторению.';

  @override
  String endTimeWon(String name) {
    return 'Победа по времени: $name.';
  }

  @override
  String get endTimeNoMate =>
      'Время вышло, но у соперника недостаточно сил для мата.';

  @override
  String get lobby => 'В меню';

  @override
  String get rematch => 'Реванш';

  @override
  String ratingChange(int rating, String change) {
    return 'Рейтинг $rating ($change)';
  }

  @override
  String accuracyValue(String value) {
    return 'Точность $value%';
  }

  @override
  String get analyzingYourMoves => 'Анализ ваших ходов…';

  @override
  String get thinking => 'думает';

  @override
  String invite1(String name) {
    return 'Приглашаем $name в партию…';
  }

  @override
  String invite2(String name) {
    return '$name садится за доску…';
  }

  @override
  String get invite3 => 'Расставляем фигуры…';

  @override
  String invite4(String name) {
    return '$name готовится…';
  }

  @override
  String get takeBack => 'Вернуть';

  @override
  String get pause => 'Пауза';

  @override
  String get resume => 'Продолжить';

  @override
  String get hint => 'Подсказка';

  @override
  String analyzingMove(String san) {
    return 'Анализ $san…';
  }

  @override
  String get pausedTitle => 'Пауза';

  @override
  String get tapToResume => 'Нажмите, чтобы продолжить';

  @override
  String get pausedSemantics => 'Пауза. Нажмите, чтобы продолжить';

  @override
  String promoteTo(String piece) {
    return 'Превратить в $piece';
  }

  @override
  String get cancelPromotion => 'Отменить превращение';

  @override
  String get pieceQueen => 'ферзя';

  @override
  String get pieceRook => 'ладью';

  @override
  String get pieceBishop => 'слона';

  @override
  String get pieceKnight => 'коня';

  @override
  String get noMovesYet => 'Ходов пока нет';

  @override
  String get dismiss => 'Закрыть';

  @override
  String get gameOptions => 'Параметры партии';

  @override
  String get evalBar => 'Шкала оценки';

  @override
  String get evalBarSub => 'Показывает, у кого лучше позиция';

  @override
  String get moveFeedback => 'Оценка ходов';

  @override
  String get moveFeedbackSub => 'Оценивает каждый ваш ход';

  @override
  String get showBest => 'Лучший ход';

  @override
  String get showBestSub => 'Стрелка к лучшему ходу в текущей позиции';

  @override
  String get boardImage => 'Изображение доски';

  @override
  String get boardImageSub => 'Поделиться позицией в формате PNG';

  @override
  String get copyFen => 'Копировать FEN';

  @override
  String get copyFenSub => 'Эта позиция для любого шахматного приложения';

  @override
  String get copyPgn => 'Копировать PGN';

  @override
  String get copyPgnSub => 'Все ходы партии';

  @override
  String get sharePgn => 'Поделиться PGN';

  @override
  String get sharePgnSub => 'Отправить партию в другое приложение';

  @override
  String get fenCopied => 'FEN скопирован';

  @override
  String get pgnCopied => 'PGN скопирован';

  @override
  String get qBrilliant => 'Блестящий';

  @override
  String get qGreat => 'Великолепный';

  @override
  String get qBest => 'Лучший ход';

  @override
  String get qExcellent => 'Отличный';

  @override
  String get qGood => 'Хороший';

  @override
  String get qInaccuracy => 'Неточность';

  @override
  String get qMistake => 'Ошибка';

  @override
  String get qMiss => 'Упущено';

  @override
  String get qBlunder => 'Зевок';

  @override
  String bannerBrilliant(String played) {
    return '$played · блестящий ход';
  }

  @override
  String bannerGreat(String played) {
    return '$played · великолепный ход';
  }

  @override
  String bannerBest(String played) {
    return '$played · лучший ход';
  }

  @override
  String bannerExcellent(String played, String best) {
    return '$played — отлично · лучше было $best';
  }

  @override
  String bannerGood(String played, String best) {
    return '$played — хорошо · лучше было $best';
  }

  @override
  String bannerInaccuracy(String played, String best) {
    return '$played — неточность · лучше было $best';
  }

  @override
  String bannerMistake(String played, String best) {
    return '$played — ошибка · лучше было $best';
  }

  @override
  String bannerMiss(String played, String best) {
    return '$played — упущено · лучше было $best';
  }

  @override
  String bannerBlunder(String played, String best) {
    return '$played — зевок · лучше было $best';
  }

  @override
  String get welcomeTitle => 'Добро пожаловать в Küşt';

  @override
  String get welcomeSub =>
      'Играйте с ботами, решайте задачи и становитесь сильнее с каждым ходом.';

  @override
  String get letsPlay => 'Играем';

  @override
  String get challengeBot => 'Бросьте вызов боту';

  @override
  String get newStudents => 'Новые ученики из Туркменистана';

  @override
  String helloName(String name) {
    return 'Здравствуйте, $name';
  }

  @override
  String get readyForGame => 'Готовы к партии?';

  @override
  String ratingBots(int rating, int beaten, int total) {
    return 'Рейтинг $rating · Побеждено ботов: $beaten из $total';
  }

  @override
  String get playAGame => 'Сыграть партию';

  @override
  String get pickOpponent => 'Выберите соперника';

  @override
  String get eloShows => 'Elo показывает силу игры бота';

  @override
  String get playAs => 'Играть за';

  @override
  String get selectOpponent => 'Выберите соперника';

  @override
  String playBot(String name) {
    return 'Играть с $name';
  }

  @override
  String get youMoveFirst => 'Вы ходите первыми';

  @override
  String botMovesFirst(String name) {
    return '$name ходит первым';
  }

  @override
  String get letFateDecide => 'Пусть решит судьба';

  @override
  String get blitz => 'Блиц';

  @override
  String get rapid => 'Рапид';

  @override
  String minutesShort(int n) {
    return '$n мин';
  }

  @override
  String get timeControl => 'Контроль времени';

  @override
  String get timeControlSub => 'Сколько времени у каждого игрока?';

  @override
  String get noClock => 'Без часов';

  @override
  String get noClockSub => 'Обычная партия без ограничения времени';

  @override
  String get startGame => 'Начать партию';

  @override
  String get newGame => 'Новая партия';

  @override
  String get playWithBots => 'Играть с ботами';

  @override
  String get playWithBotsSub => 'Бросьте вызов одному из наших ботов';

  @override
  String get playLocally => 'Играть вдвоём';

  @override
  String get playLocallySub => 'Игра вдвоём на одном устройстве';

  @override
  String get practiceMode => 'Режим тренировки';

  @override
  String get practiceModeSub =>
      'Разрешает отмену ходов, подсказки и оценку ходов';

  @override
  String get practiceTag => 'Тренировка';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get themeAuto => 'Авто';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get boardSection => 'Доска';

  @override
  String get piecesSection => 'Фигуры';

  @override
  String get movesSection => 'Ходы';

  @override
  String get castleOnRook => 'Рокировка ладьёй';

  @override
  String get castleOnRookSub =>
      'Нажмите на короля, затем на его ладью, чтобы сделать рокировку';

  @override
  String get premoves => 'Премувы';

  @override
  String get premovesSub => 'Задайте следующий ход, пока думает бот';

  @override
  String get feedbackSection => 'Отклик';

  @override
  String get soundEffects => 'Звуковые эффекты';

  @override
  String get haptics => 'Вибрация';

  @override
  String boardThemeSemantics(String theme) {
    return 'Доска: $theme';
  }

  @override
  String pieceSetSemantics(String set) {
    return 'Фигуры: $set';
  }

  @override
  String get boardBrown => 'Коричневая';

  @override
  String get boardGreen => 'Зелёная';

  @override
  String get boardDarkBlue => 'Тёмно-синяя';

  @override
  String get boardWood => 'Дерево';

  @override
  String get pieceClassic => 'Классические';

  @override
  String get pieceShaded => 'С тенью';

  @override
  String get pieceGraphite => 'Графит';

  @override
  String get pieceBrushed => 'Шлифованные';

  @override
  String get histNoGames => 'Партий пока нет';

  @override
  String get histNoGamesSub =>
      'Завершённые партии появятся здесь, чтобы вы могли их пересмотреть.';

  @override
  String get deleteGameTitle => 'Удалить эту партию?';

  @override
  String get deleteGameSub => 'Она будет удалена из вашей истории.';

  @override
  String get resultWhiteWon => 'Победили белые';

  @override
  String get resultBlackWon => 'Победили чёрные';

  @override
  String get resultWin => 'Победа';

  @override
  String get resultLoss => 'Поражение';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get monthsShort => 'янв,фев,мар,апр,мая,июн,июл,авг,сен,окт,ноя,дек';

  @override
  String dateShort(String month, int day) {
    return '$day $month';
  }

  @override
  String get semGamePassPlay => 'Игра вдвоём';

  @override
  String semGameVsBot(String name) {
    return 'Партия против $name';
  }

  @override
  String semAccuracy(String value) {
    return 'точность $value процентов';
  }

  @override
  String get analysisUnavailable =>
      'Анализ сейчас недоступен на этом устройстве';

  @override
  String get retryAnalysis => 'Повторить анализ';

  @override
  String get analyzeGame => 'Проанализировать партию';

  @override
  String get gameTitle => 'Партия';

  @override
  String get replaySettings => 'Настройки просмотра';

  @override
  String get evalBarReplaySub =>
      'Показывает, у кого лучше позиция после каждого хода';

  @override
  String get moveFeedbackReplaySub => 'Оценивает каждый ход при просмотре';

  @override
  String get showBestReplaySub => 'Стрелка к лучшему ходу, если сыгран другой';

  @override
  String get notAvailableHere => 'Недоступно на этом устройстве';

  @override
  String get evalUnavailable => 'Оценка сейчас недоступна';

  @override
  String get gameNotFound => 'Эта партия не найдена.';

  @override
  String get backToHistory => 'К истории';

  @override
  String puzzleN(int n) {
    return 'Задача $n';
  }

  @override
  String get allPuzzles => 'Все задачи';

  @override
  String get puzzleCouldNotLoad => 'Не удалось загрузить задачу';

  @override
  String get puzzlesCouldNotLoad => 'Не удалось загрузить задачи';

  @override
  String get noPuzzlesAvailable => 'Задач пока нет';

  @override
  String get noPuzzlesYet => 'Задач пока нет. Загляните позже.';

  @override
  String get puzzleSolved => 'Задача решена!';

  @override
  String get solutionShown => 'Решение показано';

  @override
  String get notThatOne => 'Не этот ход';

  @override
  String get whiteToMove => 'Ход белых';

  @override
  String get blackToMove => 'Ход чёрных';

  @override
  String get backToPuzzles => 'К задачам';

  @override
  String get solution => 'Решение';

  @override
  String get nextPuzzle => 'Следующая задача';

  @override
  String get nextLevel => 'Следующий уровень';

  @override
  String themeMateIn(int n) {
    return 'Мат в $n';
  }

  @override
  String get themeFork => 'Вилка';

  @override
  String get themePin => 'Связка';

  @override
  String get themeEndgame => 'Эндшпиль';

  @override
  String get themeWinMaterial => 'Выигрыш материала';

  @override
  String get loomMate1 => 'Мат в 1';

  @override
  String get loomMate2 => 'Мат в 2';

  @override
  String get loomForks => 'Вилки';

  @override
  String get loomPins => 'Связки';

  @override
  String get loomEndgames => 'Эндшпили';

  @override
  String get puzzlesAllWoven => 'Все задачи сплетены!';

  @override
  String puzzlesNext(String theme) {
    return 'Далее: $theme';
  }

  @override
  String get puzzlesMoreSoon => 'Скоро появятся новые.';

  @override
  String get reviewPuzzles => 'Повторить задачи';

  @override
  String get statRating => 'РЕЙТИНГ';

  @override
  String get statKnots => 'УЗЛЫ';

  @override
  String get statBest => 'РЕКОРД';

  @override
  String puzzlesSolvedOf(String theme, int solved, int total) {
    return '$theme · решено $solved из $total';
  }

  @override
  String loomProgress(String theme, int done, int total) {
    return '$theme, сплетено узлов: $done из $total';
  }

  @override
  String get levelWoven => 'Сплетено ✓';

  @override
  String levelKnots(int done, int total) {
    return '$done из $total узлов';
  }

  @override
  String get levelNotStarted => 'Не начато';

  @override
  String get levelComingSoon => 'Скоро';

  @override
  String golWovenSem(String tribe) {
    return 'Göl «$tribe» сплетён';
  }

  @override
  String golWoven(String tribe) {
    return 'Göl «$tribe» сплетён';
  }

  @override
  String golWholeCarpet(int knots) {
    return '$knots из $knots узлов. Весь ковёр готов.';
  }

  @override
  String golNext(int knots, String next) {
    return '$knots из $knots узлов. Дальше — göl «$next».';
  }

  @override
  String get dailyPuzzle => 'Задача дня';

  @override
  String get solvedToday => 'Решена сегодня';

  @override
  String get dailySolved => 'решена';

  @override
  String dailyStreakSem(String days) {
    return 'серия: $days';
  }

  @override
  String get coachMateIn1 =>
      'Один ход заканчивает партию. Видите его?\nНайдите ход, который ставит мат прямо сейчас.\nУ короля нет выхода. Закройте дверь!';

  @override
  String get coachMateIn2 =>
      'Можете ли вы поставить мат в два хода?\nНачните с шаха или сильной угрозы.\nДва хода до мата. Какой из них первый?';

  @override
  String get coachMateIn3 =>
      'Мат в три хода. Думайте о форсированных ходах.\nСначала шахи, потом смотрите, куда пойдёт король.';

  @override
  String get coachFork =>
      'Найдите ход, который атакует сразу две фигуры.\nВидите вилку?\nОдна фигура, две цели. Куда она встанет?';

  @override
  String get coachPin =>
      'Фигура не может двигаться. Сможете это использовать?\nНайдите связанную фигуру и усильте давление.\nЧто застряло перед своим королём?';

  @override
  String get coachEndgame =>
      'Мало фигур, большие идеи. Не торопитесь.\nВ эндшпиле король — боец.\nОсторожные ходы выигрывают эту позицию.';

  @override
  String get coachGeneric =>
      'Сначала ищите шахи, взятия и угрозы.\nЧто висит? Не торопитесь.\nЛучший ход обычно форсированный.';

  @override
  String get coachWrong =>
      'Почти, но не совсем. Попробуйте другой ход.\nНе этот. Подумайте о шахах и взятиях.\nХм, посмотрите ещё раз. У вас получится!\nТак соперник уходит от удара. Что ещё есть?';

  @override
  String get coachCorrect =>
      'Отличная работа! Переходим к следующей.\nВы это увидели. Отлично сыграно!\nОстрый глаз. Чисто сыграно.\nЕщё один узел сплетён. Так держать!';

  @override
  String get coachRetry =>
      'Изучите, затем попробуйте сами.\nТеперь вы знаете. Нажмите «Повторить»!\nСмотрите, как фигуры работают вместе.';

  @override
  String get coachDaily =>
      'Не пропускайте день задач!\nСначала ищите шахи, взятия и угрозы.\nОдна задача в день прогоняет зевки.\nНе торопитесь: лучший ход обычно форсированный.';

  @override
  String achEarnedOf(int earned, int total) {
    return 'Получено: $earned из $total';
  }

  @override
  String get achUnlocked => 'Достижение получено';

  @override
  String get achEarned => 'получено';

  @override
  String get achNotEarned => 'ещё не получено';

  @override
  String get ach_first_game_t => 'Первый ход';

  @override
  String get ach_first_game_d => 'Завершите партию против бота';

  @override
  String get ach_first_win_t => 'Первая победа';

  @override
  String get ach_first_win_d => 'Выиграйте партию у бота';

  @override
  String get ach_checkmate_t => 'Мат!';

  @override
  String get ach_checkmate_d => 'Выиграйте партию матом';

  @override
  String get ach_quick_mate_t => 'Молния';

  @override
  String get ach_quick_mate_d => 'Поставьте боту мат не более чем за 20 ходов';

  @override
  String get ach_giant_slayer_t => 'Убийца великанов';

  @override
  String get ach_giant_slayer_d =>
      'Победите бота с рейтингом выше вашего на 300 и больше';

  @override
  String get ach_three_bots_t => 'Восходящая звезда';

  @override
  String get ach_three_bots_d => 'Победите 3 разных ботов';

  @override
  String get ach_all_bots_t => 'Чемпион';

  @override
  String get ach_all_bots_d => 'Победите всех ботов';

  @override
  String get ach_marathon_t => 'Марафон';

  @override
  String get ach_marathon_d => 'Сыграйте партию в 60 ходов или больше';

  @override
  String get ach_accurate_t => 'Снайпер';

  @override
  String get ach_accurate_d => 'Сыграйте партию с точностью 90%';

  @override
  String get ach_brilliant_t => 'Блестяще!';

  @override
  String get ach_brilliant_d => 'Сыграйте блестящий ход';

  @override
  String get ach_first_puzzle_t => 'Решатель';

  @override
  String get ach_first_puzzle_d => 'Решите первую задачу';

  @override
  String get ach_puzzles_25_t => 'Узел за узлом';

  @override
  String get ach_puzzles_25_d => 'Решите 25 задач';

  @override
  String get ach_first_gol_t => 'Первый göl';

  @override
  String get ach_first_gol_d => 'Сплетите целый göl';

  @override
  String get ach_whole_carpet_t => 'Мастер-ткач';

  @override
  String get ach_whole_carpet_d => 'Сплетите все пять göl';

  @override
  String get ach_streak_3_t => 'В ударе';

  @override
  String get ach_streak_3_d => 'Решайте задачу дня 3 дня подряд';

  @override
  String get ach_streak_7_t => 'Огненная неделя';

  @override
  String get ach_streak_7_d => 'Решайте задачу дня 7 дней подряд';

  @override
  String get onbGetStarted => 'Начать';

  @override
  String get onbStartPlaying => 'Начать играть';

  @override
  String get onbSkip => 'Пропустить';

  @override
  String get onbTitle => 'Шахматы, которые помогают расти';

  @override
  String get onbIntro =>
      'Играйте с ботами своего уровня, тренируйтесь на задачах и пересматривайте партии, чтобы учиться на них.';

  @override
  String get onbPlayBots => 'Играйте с ботами';

  @override
  String get onbPlayBotsSub => 'От 400 до 2000 Elo или передайте телефон другу';

  @override
  String get onbSolve => 'Решайте задачи';

  @override
  String get onbSolveSub => 'Короткая тактика с подсказками и рейтингом';

  @override
  String get onbReview => 'Разбирайте партии';

  @override
  String get onbReviewSub =>
      'Каждая завершённая партия сохраняется для просмотра';

  @override
  String get onbNoAccount =>
      'Аккаунт не нужен. Ваши партии и прогресс хранятся на этом устройстве.';

  @override
  String get onbHowStrong => 'Насколько вы сильны?';

  @override
  String get onbHowStrongSub =>
      'Это задаёт ваш начальный рейтинг. Он меняется по ходу игры, так что не переживайте.';

  @override
  String get lvlBeginner => 'Новичок';

  @override
  String get lvlBeginnerD => 'Я только начинаю играть в шахматы.';

  @override
  String get lvlIntermediate => 'Любитель';

  @override
  String get lvlIntermediateD => 'Я знаю основы и играю регулярно.';

  @override
  String get lvlAdvanced => 'Продвинутый';

  @override
  String get lvlAdvancedD => 'Я разбираюсь в стратегии и сложных позициях.';

  @override
  String get lvlCompetitive => 'Соревнующийся';

  @override
  String get lvlCompetitiveD =>
      'Я играю всерьёз и могу участвовать в турнирах.';

  @override
  String get onbAllSet => 'Всё готово';

  @override
  String onbStartingRating(int rating) {
    return 'Ваш начальный рейтинг — $rating.\nПервая партия уже в одном касании.';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String get yourAvatar => 'Ваш аватар';

  @override
  String avatarOf(String name) {
    return '$name, ваш аватар';
  }

  @override
  String get language => 'Язык';

  @override
  String get languageAuto => 'Система';

  @override
  String get youWonGame => 'Вы победили.';

  @override
  String get youWonOnTime => 'Вы победили по времени.';

  @override
  String get botGreetBahar =>
      'Салам! Я Бахар. Я тоже учусь шахматам, давайте играть!';

  @override
  String get botGreetElizabeth => 'Добрый день. Сыграем приятную партию?';

  @override
  String get botGreetMark => 'Привет! Готовы к партии? Я готов!';

  @override
  String get botGreetApex => 'Думаете, сможете меня обыграть? Посмотрим.';

  @override
  String get botGreetKarl => 'Не торопитесь. Шахматы любят терпение.';

  @override
  String get botGreetEnejan => 'Добро пожаловать! Присаживайтесь, сыграем.';

  @override
  String get botGreetMaya => 'Привет! Люблю умные ходы. Покажите свои.';

  @override
  String get botGreetYura => 'Сыграем. Я не поддаюсь.';

  @override
  String get botGreetBerdi =>
      'Добро пожаловать. Шахматы — долгий путь. Пройдём его.';

  @override
  String get botCheerfulBlunder =>
      'О, спасибо за подарок!|Ого, это вы нарочно?';

  @override
  String get botCheerfulBrilliant => 'Вау, какой ход!|Вы здорово играете!';

  @override
  String get botCheerfulWin =>
      'Ура, победа! Отличная партия!|Было весело, сыграем ещё?';

  @override
  String get botCheerfulLoss =>
      'Вы победили! Отлично сыграно!|Ого, вы выиграли! Давайте ещё!';

  @override
  String get botCheerfulDraw =>
      'Ничья! Всё честно.|Никто не проиграл, значит, выиграли оба!';

  @override
  String get botCalmBlunder => 'Любопытный выбор.|Охотно это возьму.';

  @override
  String get botCalmBrilliant =>
      'Хороший ход. Тонко подмечено.|Впечатляет. Это было неожиданно.';

  @override
  String get botCalmWin => 'Хорошая партия. Спасибо.|В следующий раз повезёт.';

  @override
  String get botCalmLoss =>
      'Отлично сыграно. Победа заслуженна.|Поздравляю, победа по праву.';

  @override
  String get botCalmDraw => 'Справедливый результат.|Мы оказались равны.';

  @override
  String get botCockyBlunder => 'Ха! Слишком просто.|Это и был ваш план?';

  @override
  String get botCockyBrilliant => 'Повезло. Не привыкайте.|Ладно, неплохо.';

  @override
  String get botCockyWin =>
      'Ни секунды не сомневался.|В следующий раз повезёт, чемпион.';

  @override
  String get botCockyLoss =>
      'Ладно, это ваша победа. Реванш?|Новичкам везёт. Ещё раз!';

  @override
  String get botCockyDraw =>
      'Ничья? Я только разогревался.|Хм. В следующий раз я выиграю.';

  @override
  String get botWiseBlunder =>
      'Думайте, прежде чем ходить.|У каждого хода своя цена.';

  @override
  String get botWiseBrilliant =>
      'Ход, достойный запоминания.|Вот это настоящие шахматы.';

  @override
  String get botWiseWin =>
      'Каждая партия чему-то учит.|Извлеките урок из этой.';

  @override
  String get botWiseLoss =>
      'Сегодня вы меня кое-чему научили.|Хорошо сыграно, достойная победа.';

  @override
  String get botWiseDraw =>
      'Равновесие — тоже результат.|Спокойная партия, спокойный финал.';

  @override
  String get botChat => 'Чат ботов';

  @override
  String get botChatSub => 'Боты комментируют партию';

  @override
  String get reviewTitle => 'Разбор партии';

  @override
  String get reviewButton => 'Разбор';

  @override
  String reviewAnalyzing(int percent) {
    return 'Анализ партии… $percent%';
  }

  @override
  String get reviewAccuracy => 'Точность';

  @override
  String get reviewMoves => 'Ходы';

  @override
  String get reviewGraph => 'Кто был впереди';

  @override
  String get reviewKeyTitle => 'Ходы, из которых стоит извлечь урок';

  @override
  String get reviewNoBig => 'Грубых ошибок нет. Отлично сыграно!';

  @override
  String reviewBestWas(String san) {
    return 'Лучше было $san';
  }

  @override
  String reviewMoveNo(int n) {
    return 'Ход $n';
  }

  @override
  String get reviewOpenReplay => 'Открыть повтор';

  @override
  String get reviewNoEngine =>
      'Движок недоступен на этом устройстве, партию нельзя проанализировать.';

  @override
  String get reviewFailed => 'Анализ не завершён.';

  @override
  String get reviewTooShort => 'Партия слишком короткая для разбора.';
}
