// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Вход через $provider';
  }

  @override
  String get termsOfService => 'Условия использования';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get settings => 'Настройки';

  @override
  String get expiresNever => 'Бессрочно';

  @override
  String get loginExpired => 'Срок входа истёк';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch отклонил вход для $login. Чат останется отключённым, пока ты не войдёшь снова.';
  }

  @override
  String get loginFailed => 'Не удалось войти';

  @override
  String get signInAgain => 'Войти';

  @override
  String uploadingTo(String host) {
    return 'Загрузка на $host';
  }

  @override
  String get uploadProcessing => 'Обработка…';

  @override
  String get uploadFailed => 'Ошибка загрузки';

  @override
  String get uploadDone => 'Загружено';

  @override
  String get uploadRetry => 'Повторить';

  @override
  String get uploadDismiss => 'Скрыть';

  @override
  String get uploadCancel => 'Отменить загрузку';

  @override
  String get uploadErrorOffline => 'Нет подключения к интернету';

  @override
  String uploadErrorTimeout(String host) {
    return '$host не отвечает';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host отклонил загрузку (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host прислал неожиданный ответ';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Не удалось подключиться к $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Не удалось прочитать файл';

  @override
  String uploadErrorUnknown(String host) {
    return 'Не удалось загрузить на $host';
  }

  @override
  String get uploadErrorDetails => 'Подробнее';

  @override
  String uploadRetryingWith(String host) {
    return 'Повторная попытка через $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Истекает через $time';
  }

  @override
  String get close => 'Закрыть';

  @override
  String get add => 'Добавить';

  @override
  String get cancel => 'Отмена';

  @override
  String get tokenInput => 'Ввод токена';

  @override
  String get account => 'Аккаунт';

  @override
  String get refreshAccount => 'Обновить аккаунт';

  @override
  String get removeAccount => 'Удалить аккаунт';

  @override
  String get addAnotherAccount => 'Добавить ещё аккаунт';

  @override
  String get verifiedUserData => 'Данные пользователя подтверждены!';

  @override
  String loggedInAs(String user) {
    return 'Вход выполнен как $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => 'Ошибка при проверке данных пользователя:';

  @override
  String get verifyingUserData => 'Проверка данных пользователя...';

  @override
  String get verifiedUserToken => 'Токен пользователя подтверждён!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken => 'Ошибка при проверке токена пользователя:';

  @override
  String get verifyingUserToken => 'Проверка токена пользователя...';

  @override
  String get searchForChannels => 'Поиск каналов';

  @override
  String get channelSearchFailed => 'Не удалось выполнить поиск каналов';

  @override
  String get recommendedChannels => 'Рекомендуемые каналы';

  @override
  String get popularChannels => 'Популярные каналы';

  @override
  String get channel => 'Канал';

  @override
  String get leaveChannel => 'Покинуть канал';

  @override
  String joinUser(String user) {
    return 'Зайти в чат $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Ой, кажется, опечатка! Может, ищешь $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Зайти в чат $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Сообщение в $channel';
  }

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get system => 'Как в системе';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get highContrast => 'Высокий контраст';

  @override
  String get customCommand => 'Своя команда';

  @override
  String get customCommands => 'Свои команды';

  @override
  String get newCustomCommand => 'Новая команда';

  @override
  String get commandTrigger => 'Ключевое слово';

  @override
  String get command => 'Команда';

  @override
  String get save => 'Сохранить';

  @override
  String get openInBrowser => 'Открыть в браузере';

  @override
  String get messageAppearance => 'Вид сообщений';

  @override
  String get showTimestamps => 'Показывать время';

  @override
  String get compactMessages => 'Компактные сообщения';

  @override
  String get showBadges => 'Показывать значки';

  @override
  String get messageTrigger => 'Правило для сообщений';

  @override
  String get pattern => 'Шаблон';

  @override
  String get mention => 'Выделить';

  @override
  String get block => 'Заблокировать';

  @override
  String get enableRegex => 'Использовать regex';

  @override
  String get caseSensitive => 'Учитывать регистр';

  @override
  String get messageTriggers => 'Правила для сообщений';

  @override
  String get newMessageTrigger => 'Новое правило';

  @override
  String get reply => 'Ответить';

  @override
  String get copyText => 'Копировать текст';

  @override
  String get copyTextSubtitle => 'Удерживай, чтобы скопировать с именем пользователя';

  @override
  String get deleteMessage => 'Удалить сообщение';

  @override
  String get mentionUser => 'Упомянуть пользователя';

  @override
  String get copyMessageId => 'Копировать ID сообщения';

  @override
  String get theme => 'Тема';

  @override
  String get userTrigger => 'Правило для пользователя';

  @override
  String get userTriggers => 'Правила для пользователей';

  @override
  String get chatHistory => 'История чата';

  @override
  String get login => 'Логин';

  @override
  String get newUserTrigger => 'Новое правило';

  @override
  String get ban => 'Забанить';

  @override
  String get unban => 'Разбанить';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Тайм-аут на $duration';
  }

  @override
  String get chatCleared => 'Чат очищен';

  @override
  String get permabanned => 'бан навсегда';

  @override
  String bannedForDuration(String duration) {
    return 'бан на $duration';
  }

  @override
  String get replyingTo => 'Ответ для';

  @override
  String get blockedMessage => 'Скрытое сообщение';

  @override
  String get showMessage => 'Показать сообщение';

  @override
  String get hideMessage => 'Скрыть сообщение';

  @override
  String get scrollToBottom => 'Прокрутить вниз';

  @override
  String get appTagline => 'Чат Twitch со смайликами 7TV, BTTV и FFZ';

  @override
  String get loginWithTwitch => 'Войти через Twitch';

  @override
  String get addChannel => 'Добавить канал';

  @override
  String get chatSettings => 'Настройки чата';

  @override
  String get autocompleteUsersWithAt => 'Дополнять имена пользователей после @';

  @override
  String get autocompleteEmotesWithColon => 'Дополнять смайлики после :';

  @override
  String get language => 'Язык';

  @override
  String get locale => 'Язык и регион';

  @override
  String get systemDefault => 'Как в системе';

  @override
  String get justDefault => 'По умолчанию';

  @override
  String get notifications => 'Уведомления';

  @override
  String get noNotifications => 'Кто-нибудь, где-нибудь, когда-нибудь тебя упомянет.';

  @override
  String get backgroundNotifications => 'Фоновые уведомления';

  @override
  String get optionNotAvailableOnYourPlatform => 'Эта функция недоступна на твоей платформе.';

  @override
  String get optionNotAvailablePaywalled => 'Эта функция только для тех, кто поддерживает ColdChat.';

  @override
  String get clearAll => 'Очистить всё';

  @override
  String get cache => 'Кэш';

  @override
  String get clearCache => 'Очистить кэш';

  @override
  String get chatters => 'Участники чата';

  @override
  String lastSeenAgo(String time) {
    return 'Последняя активность $time назад';
  }

  @override
  String get credits => 'Благодарности';

  @override
  String get search => 'Поиск';

  @override
  String get emoteMenuButton => 'Кнопка меню смайликов';

  @override
  String get emoteMenuButtonGrayscale => 'Кнопка меню смайликов в оттенках серого';

  @override
  String get chooseEmoteMenuButton => 'Нажми на смайлик, чтобы сделать его кнопкой меню смайликов';

  @override
  String get resetToKappa => 'Вернуть Kappa';

  @override
  String get emoteMenuButtonDownloadFailed => 'Не удалось скачать смайлик. Кнопка не изменилась.';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get chooseFromLibrary => 'Выбрать из галереи';

  @override
  String get cameraUnavailable => 'Не удалось открыть камеру. Проверь, есть ли у ColdChat доступ к камере.';

  @override
  String get about => 'О приложении';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get license => 'Лицензия';

  @override
  String get basedOnChatsen => 'На основе Chatsen';

  @override
  String get openSourceLicenses => 'Лицензии открытого ПО';

  @override
  String get aboutLegalese =>
      'ColdChat — свободное программное обеспечение: ты можешь распространять и изменять его на условиях GNU Affero General Public License версии 3. Оно предоставляется БЕЗ КАКИХ-ЛИБО ГАРАНТИЙ.';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get report => 'Пожаловаться';

  @override
  String reportUserTitle(String name) {
    return 'Пожаловаться на $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Жалобы рассматривает Twitch. Открой канал $name на Twitch и выбери там «Пожаловаться». Ещё ты можешь заблокировать $name здесь, чтобы скрыть сообщения.';
  }

  @override
  String get openOnTwitch => 'Открыть на Twitch';

  @override
  String get blockFailed => 'Не удалось изменить список блокировки. Проверь подключение и попробуй ещё раз.';

  @override
  String get moderationNeedsLogin => 'Войди через Twitch, чтобы модерировать этот канал.';

  @override
  String get moderationNeedsScope =>
      'Войди заново, чтобы банить пользователей и давать им тайм-ауты. Твой вход был выполнен до того, как ColdChat научился это делать.';

  @override
  String moderationFailed(String reason) {
    return 'Не получилось: $reason';
  }

  @override
  String get contact => 'Связь и отзывы';

  @override
  String get whisper => 'Шепот';

  @override
  String whisperTo(String name) {
    return 'Шепнуть $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Шепот от $name';
  }

  @override
  String get openWhisper => 'Открыть';

  @override
  String get userCard => 'Карточка пользователя';

  @override
  String get closeConversation => 'Закрыть диалог';

  @override
  String get closeConversationSubtitle => 'Сообщения останутся на этом устройстве и вернутся со следующим шепотом.';

  @override
  String get deleteConversation => 'Удалить диалог';

  @override
  String get deleteConversationSubtitle => 'Удаляет сообщения с этого устройства. Twitch не хранит историю шепота.';

  @override
  String get whisperNeedsLogin => 'Войди через Twitch, чтобы отправлять шепот.';

  @override
  String get whisperNeedsScope =>
      'Войди снова, чтобы отправлять и получать шепот. Твой вход сделан ещё до того, как ColdChat начал его поддерживать.';

  @override
  String get whisperUserNotFound => 'Пользователя Twitch с таким именем нет.';

  @override
  String whisperFailed(String reason) {
    return 'Шепот не отправлен: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Шепот, который приходит, пока ColdChat закрыт, здесь не появится: Twitch не передаёт историю шепота приложениям. Его можно прочитать на Twitch, нажав значок шепота справа вверху.';

  @override
  String get gotIt => 'Понятно';

  @override
  String get openTwitch => 'Открыть Twitch';

  @override
  String showImage(String host) {
    return 'Показать изображение · $host';
  }

  @override
  String get showImagesFromLinks => 'Показывать изображения из ссылок';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch не проверяет эти изображения. Они могут быть неприемлемыми.';

  @override
  String get showImagesAutomatically => 'Показывать изображения из ссылок автоматически?';

  @override
  String get turnOn => 'Включить';

  @override
  String get themeIndigo => 'Индиго';

  @override
  String get themeBlue => 'Синий';

  @override
  String get themeTeal => 'Бирюзовый';

  @override
  String get themeGreen => 'Зелёный';

  @override
  String get themeLime => 'Лаймовый';

  @override
  String get themeAmber => 'Янтарный';

  @override
  String get themeOrange => 'Оранжевый';

  @override
  String get themeRed => 'Красный';

  @override
  String get themePink => 'Розовый';

  @override
  String get themePurple => 'Фиолетовый';

  @override
  String get accentColor => 'Цвет акцента';

  @override
  String get oledBlack => 'Чёрный OLED';

  @override
  String get oledBlackSubtitle => 'Чёрный фон чата в тёмном режиме, для OLED-экранов';

  @override
  String get customColor => 'Свой';

  @override
  String get hue => 'Оттенок';

  @override
  String get saturation => 'Насыщенность';

  @override
  String get themeIce => 'Лёд';

  @override
  String channelConnecting(String channel) {
    return 'Подключение к $channel…';
  }

  @override
  String channelConnected(String channel) {
    return 'Подключено к $channel';
  }

  @override
  String channelDisconnected(String channel) {
    return 'Отключено от $channel';
  }

  @override
  String channelSuspended(String channel) {
    return 'Канал $channel заблокирован Twitch';
  }

  @override
  String channelBanned(String channel) {
    return 'Ты забанен на $channel';
  }

  @override
  String durationDays(int count) {
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
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа',
      many: '$count часов',
      few: '$count часа',
      one: '$count час',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минуты',
      many: '$count минут',
      few: '$count минуты',
      one: '$count минуту',
    );
    return '$_temp0';
  }
}
