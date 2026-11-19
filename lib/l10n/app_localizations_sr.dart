// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Пријављено преко $provider';
  }

  @override
  String get termsOfService => 'Услови коришћења';

  @override
  String get privacyPolicy => 'Политика приватности';

  @override
  String get settings => 'Подешавања';

  @override
  String get expiresNever => 'Никад не истиче';

  @override
  String get loginExpired => 'Пријава је истекла';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch је одбио пријаву за $login. Чет остаје неповезан док се поново не пријавиш.';
  }

  @override
  String get loginFailed => 'Пријава није успела';

  @override
  String get signInAgain => 'Пријави се';

  @override
  String uploadingTo(String host) {
    return 'Отпремање на $host';
  }

  @override
  String get uploadProcessing => 'Обрада…';

  @override
  String get uploadFailed => 'Отпремање није успело';

  @override
  String get uploadDone => 'Отпремљено';

  @override
  String get uploadRetry => 'Покушај поново';

  @override
  String get uploadDismiss => 'Одбаци';

  @override
  String get uploadCancel => 'Откажи отпремање';

  @override
  String get uploadErrorOffline => 'Нема интернет везе';

  @override
  String uploadErrorTimeout(String host) {
    return '$host не одговара';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return 'Сервер $host је одбио отпремање (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return 'Сервер $host је послао неочекиван одговор';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Повезивање са $host није успело';
  }

  @override
  String get uploadErrorUnreadableFile => 'Датотека не може да се прочита';

  @override
  String uploadErrorUnknown(String host) {
    return 'Отпремање на $host није успело';
  }

  @override
  String get uploadErrorDetails => 'Детаљи';

  @override
  String uploadRetryingWith(String host) {
    return 'Нови покушај преко $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Истиче за $time';
  }

  @override
  String get close => 'Затвори';

  @override
  String get add => 'Додај';

  @override
  String get cancel => 'Откажи';

  @override
  String get tokenInput => 'Унос токена';

  @override
  String get account => 'Налог';

  @override
  String get refreshAccount => 'Освежи налог';

  @override
  String get removeAccount => 'Уклони налог';

  @override
  String get addAnotherAccount => 'Додај још један налог';

  @override
  String get verifiedUserData => 'Кориснички подаци су потврђени!';

  @override
  String loggedInAs(String user) {
    return 'Пријављено као $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Дошло је до грешке при провери корисничких података:';

  @override
  String get verifyingUserData => 'Провера корисничких података...';

  @override
  String get verifiedUserToken => 'Кориснички токен је потврђен!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Дошло је до грешке при провери корисничког токена:';

  @override
  String get verifyingUserToken => 'Провера корисничког токена...';

  @override
  String get searchForChannels => 'Претражи канале';

  @override
  String get recommendedChannels => 'Препоручени канали';

  @override
  String get popularChannels => 'Популарни канали';

  @override
  String get channel => 'Канал';

  @override
  String get leaveChannel => 'Напусти канал';

  @override
  String joinUser(String user) {
    return 'Придружи се каналу $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Провера правописа није успела! Да ли тражиш $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Придружи се каналу $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Пошаљи поруку у $channel';
  }

  @override
  String get light => 'Светла';

  @override
  String get dark => 'Тамна';

  @override
  String get system => 'Према систему';

  @override
  String get appearance => 'Изглед';

  @override
  String get highContrast => 'Висок контраст';

  @override
  String get customCommand => 'Прилагођена команда';

  @override
  String get customCommands => 'Прилагођене команде';

  @override
  String get newCustomCommand => 'Нова прилагођена команда';

  @override
  String get commandTrigger => 'Окидач';

  @override
  String get command => 'Команда';

  @override
  String get save => 'Сачувај';

  @override
  String get openInBrowser => 'Отвори у прегледачу';

  @override
  String get messageAppearance => 'Изглед порука';

  @override
  String get showTimestamps => 'Прикажи време';

  @override
  String get compactMessages => 'Компактне поруке';

  @override
  String get showBadges => 'Прикажи значке';

  @override
  String get messageTrigger => 'Окидач порука';

  @override
  String get pattern => 'Образац';

  @override
  String get mention => 'Помињање';

  @override
  String get block => 'Блокирај';

  @override
  String get enableRegex => 'Укључи regex';

  @override
  String get caseSensitive => 'Разликуј велика и мала слова';

  @override
  String get messageTriggers => 'Окидачи порука';

  @override
  String get newMessageTrigger => 'Нови окидач порука';

  @override
  String get reply => 'Одговори';

  @override
  String get copyText => 'Копирај текст';

  @override
  String get copyTextSubtitle =>
      'Задржи за копирање текста са корисничким именом';

  @override
  String get deleteMessage => 'Избриши поруку';

  @override
  String get mentionUser => 'Помени корисника';

  @override
  String get copyMessageId => 'Копирај ID поруке';

  @override
  String get theme => 'Тема';

  @override
  String get userTrigger => 'Окидач корисника';

  @override
  String get userTriggers => 'Окидачи корисника';

  @override
  String get chatHistory => 'Историја чета';

  @override
  String get login => 'Корисничко име';

  @override
  String get newUserTrigger => 'Нови окидач корисника';

  @override
  String get ban => 'Бануј';

  @override
  String get unban => 'Одбануј';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Дај тајмаут на $duration';
  }

  @override
  String get chatCleared => 'Чет је очишћен';

  @override
  String get permabanned => 'добија трајни бан';

  @override
  String bannedForDuration(String duration) {
    return 'добија бан на $duration';
  }

  @override
  String get replyingTo => 'Одговор на';

  @override
  String get blockedMessage => 'Блокирана порука';

  @override
  String get showMessage => 'Прикажи поруку';

  @override
  String get hideMessage => 'Сакриј поруку';

  @override
  String get scrollToBottom => 'Скочи на дно';

  @override
  String get appTagline => 'Twitch чет са емотиконима из 7TV, BTTV и FFZ';

  @override
  String get loginWithTwitch => 'Пријави се преко Twitch-а';

  @override
  String get addChannel => 'Додај канал';

  @override
  String get chatSettings => 'Подешавања чета';

  @override
  String get autocompleteUsersWithAt => 'Довршавање корисника са @';

  @override
  String get autocompleteEmotesWithColon => 'Довршавање емотикона са :';

  @override
  String get language => 'Језик';

  @override
  String get locale => 'Језик и регион';

  @override
  String get systemDefault => 'Подразумевано у систему';

  @override
  String get justDefault => 'Подразумевано';

  @override
  String get notifications => 'Обавештења';

  @override
  String get noNotifications => 'Неко, негде, једног дана ће те поменути.';

  @override
  String get backgroundNotifications => 'Обавештења у позадини';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'Ова опција није доступна на твојој платформи.';

  @override
  String get optionNotAvailablePaywalled =>
      'Ова опција је само за оне који подржавају ColdChat.';

  @override
  String get clearAll => 'Обриши све';

  @override
  String get cache => 'Кеш';

  @override
  String get clearCache => 'Обриши кеш';

  @override
  String get chatters => 'Учесници чета';

  @override
  String lastSeenAgo(String time) {
    return 'Последња активност пре $time';
  }

  @override
  String get credits => 'Заслуге';

  @override
  String get search => 'Претражи';

  @override
  String get emoteMenuButton => 'Дугме менија емотикона';

  @override
  String get emoteMenuButtonGrayscale =>
      'Дугме менија емотикона у нијансама сиве';

  @override
  String get chooseEmoteMenuButton =>
      'Додирни емотикон који желиш као дугме менија емотикона';

  @override
  String get resetToKappa => 'Врати на Kappa';

  @override
  String get emoteMenuButtonDownloadFailed =>
      'Преузимање емотикона није успело. Дугме није промењено.';

  @override
  String get takePhoto => 'Сними фотографију';

  @override
  String get chooseFromLibrary => 'Изабери из галерије';

  @override
  String get cameraUnavailable =>
      'Камера није могла да се отвори. Провери да ли ColdChat има приступ камери.';

  @override
  String get about => 'О апликацији';

  @override
  String get sourceCode => 'Изворни код';

  @override
  String get license => 'Лиценца';

  @override
  String get basedOnChatsen => 'Засновано на Chatsen-у';

  @override
  String get openSourceLicenses => 'Лиценце отвореног кода';

  @override
  String get aboutLegalese =>
      'ColdChat је слободан софтвер: можеш да га делиш и мењаш под условима лиценце GNU Affero General Public License, верзија 3. Долази АПСОЛУТНО БЕЗ ИКАКВЕ ГАРАНЦИЈЕ.';

  @override
  String get unblock => 'Деблокирај';

  @override
  String get report => 'Пријави';

  @override
  String reportUserTitle(String name) {
    return 'Пријави $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Пријаве обрађује Twitch. Отвори канал $name на Twitch-у и тамо изабери Пријави. $name можеш да блокираш и овде, па ти се поруке више неће приказивати.';
  }

  @override
  String get openOnTwitch => 'Отвори на Twitch-у';

  @override
  String get blockFailed =>
      'Листа блокираних не може да се промени. Провери везу и покушај поново.';

  @override
  String get contact => 'Контакт и повратне информације';

  @override
  String get whisper => 'Шапни';

  @override
  String whisperTo(String name) {
    return 'Шапни $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Шапат од $name';
  }

  @override
  String get openWhisper => 'Отвори';

  @override
  String get userCard => 'Корисничка картица';

  @override
  String get closeConversation => 'Затвори разговор';

  @override
  String get closeConversationSubtitle =>
      'Поруке остају на овом уређају и враћају се са следећим шапатом.';

  @override
  String get deleteConversation => 'Избриши разговор';

  @override
  String get deleteConversationSubtitle =>
      'Брише поруке са овог уређаја. Twitch не чува историју шапата.';

  @override
  String get whisperNeedsLogin => 'Пријави се на Twitch за слање шапата.';

  @override
  String get whisperNeedsScope =>
      'Поново се пријави за слање и примање шапата. Твоја пријава потиче из времена пре него што их је ColdChat подржавао.';

  @override
  String get whisperUserNotFound => 'Не постоји Twitch корисник са тим именом.';

  @override
  String whisperFailed(String reason) {
    return 'Шапат није послат: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Шапати које примиш док је ColdChat затворен не приказују се овде, јер Twitch не дели историју шапата са апликацијама. Можеш да их прочиташ на Twitch-у, иза иконе шапата горе десно.';

  @override
  String get gotIt => 'Разумем';

  @override
  String get openTwitch => 'Отвори Twitch';

  @override
  String showImage(String host) {
    return 'Прикажи слику · $host';
  }

  @override
  String get showImagesFromLinks => 'Прикажи слике из линкова';

  @override
  String get showImagesFromLinksSubtitle =>
      'Twitch не проверава ове слике. Могу бити неприкладне.';

  @override
  String get showImagesAutomatically =>
      'Аутоматски приказивати слике из линкова?';

  @override
  String get turnOn => 'Укључи';

  @override
  String get themeIndigo => 'Индиго';

  @override
  String get themeBlue => 'Плава';

  @override
  String get themeTeal => 'Петролеј';

  @override
  String get themeGreen => 'Зелена';

  @override
  String get themeLime => 'Лајм';

  @override
  String get themeAmber => 'Ћилибар';

  @override
  String get themeOrange => 'Наранџаста';

  @override
  String get themeRed => 'Црвена';

  @override
  String get themePink => 'Розе';

  @override
  String get themePurple => 'Љубичаста';

  @override
  String get accentColor => 'Боја акцента';

  @override
  String get oledBlack => 'OLED црна';

  @override
  String get oledBlackSubtitle =>
      'Црна позадина чета у тамном режиму, за OLED екране';

  @override
  String get customColor => 'Прилагођено';

  @override
  String get hue => 'Нијанса';

  @override
  String get saturation => 'Засићеност';

  @override
  String get themeIce => 'Лед';
}
