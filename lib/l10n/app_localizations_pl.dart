// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Zalogowano przez $provider';
  }

  @override
  String get termsOfService => 'Regulamin';

  @override
  String get privacyPolicy => 'Polityka prywatności';

  @override
  String get settings => 'Ustawienia';

  @override
  String get expiresNever => 'Nigdy nie wygasa';

  @override
  String get loginExpired => 'Logowanie wygasło';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch odrzucił logowanie dla $login. Czat pozostanie rozłączony, dopóki nie zalogujesz się ponownie.';
  }

  @override
  String get loginFailed => 'Logowanie nie powiodło się';

  @override
  String get signInAgain => 'Zaloguj się';

  @override
  String uploadingTo(String host) {
    return 'Przesyłanie do $host';
  }

  @override
  String get uploadProcessing => 'Przetwarzanie…';

  @override
  String get uploadFailed => 'Przesyłanie nie powiodło się';

  @override
  String get uploadDone => 'Przesłano';

  @override
  String get uploadRetry => 'Ponów';

  @override
  String get uploadDismiss => 'Ukryj';

  @override
  String get uploadCancel => 'Anuluj przesyłanie';

  @override
  String get uploadErrorOffline => 'Brak połączenia z internetem';

  @override
  String uploadErrorTimeout(String host) {
    return '$host nie odpowiada';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return 'Serwer $host odrzucił plik (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return 'Serwer $host zwrócił nieoczekiwaną odpowiedź';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Nie można połączyć się z $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Nie można odczytać pliku';

  @override
  String uploadErrorUnknown(String host) {
    return 'Przesyłanie do $host nie powiodło się';
  }

  @override
  String get uploadErrorDetails => 'Szczegóły';

  @override
  String uploadRetryingWith(String host) {
    return 'Ponawiam przez $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Wygasa za $time';
  }

  @override
  String get close => 'Zamknij';

  @override
  String get add => 'Dodaj';

  @override
  String get cancel => 'Anuluj';

  @override
  String get tokenInput => 'Wprowadź token';

  @override
  String get account => 'Konto';

  @override
  String get refreshAccount => 'Odśwież konto';

  @override
  String get removeAccount => 'Usuń konto';

  @override
  String get addAnotherAccount => 'Dodaj kolejne konto';

  @override
  String get verifiedUserData => 'Zweryfikowano dane użytkownika!';

  @override
  String loggedInAs(String user) {
    return 'Zalogowano jako $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Podczas weryfikacji danych użytkownika wystąpił błąd:';

  @override
  String get verifyingUserData => 'Weryfikowanie danych użytkownika...';

  @override
  String get verifiedUserToken => 'Zweryfikowano token użytkownika!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Podczas weryfikacji tokenu użytkownika wystąpił błąd:';

  @override
  String get verifyingUserToken => 'Weryfikowanie tokenu użytkownika...';

  @override
  String get searchForChannels => 'Wyszukaj kanały';

  @override
  String get recommendedChannels => 'Polecane kanały';

  @override
  String get popularChannels => 'Popularne kanały';

  @override
  String get channel => 'Kanał';

  @override
  String get leaveChannel => 'Opuść kanał';

  @override
  String joinUser(String user) {
    return 'Dołącz do $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Sprawdzanie pisowni nie powiodło się! Czy chodziło ci o $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Dołącz do $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Wyślij wiadomość na $channel';
  }

  @override
  String get light => 'Jasny';

  @override
  String get dark => 'Ciemny';

  @override
  String get system => 'Systemowy';

  @override
  String get appearance => 'Wygląd';

  @override
  String get highContrast => 'Wysoki kontrast';

  @override
  String get customCommand => 'Własne polecenie';

  @override
  String get customCommands => 'Własne polecenia';

  @override
  String get newCustomCommand => 'Nowe polecenie';

  @override
  String get commandTrigger => 'Wyzwalacz';

  @override
  String get command => 'Polecenie';

  @override
  String get save => 'Zapisz';

  @override
  String get openInBrowser => 'Otwórz w przeglądarce';

  @override
  String get messageAppearance => 'Wygląd wiadomości';

  @override
  String get showTimestamps => 'Pokaż godzinę';

  @override
  String get compactMessages => 'Kompaktowe wiadomości';

  @override
  String get showBadges => 'Pokaż odznaki';

  @override
  String get messageTrigger => 'Wyzwalacz wiadomości';

  @override
  String get pattern => 'Wzorzec';

  @override
  String get mention => 'Wzmianka';

  @override
  String get block => 'Zablokuj';

  @override
  String get enableRegex => 'Włącz regex';

  @override
  String get caseSensitive => 'Rozróżniaj wielkość liter';

  @override
  String get messageTriggers => 'Wyzwalacze wiadomości';

  @override
  String get newMessageTrigger => 'Nowy wyzwalacz';

  @override
  String get reply => 'Odpowiedz';

  @override
  String get copyText => 'Kopiuj tekst';

  @override
  String get copyTextSubtitle =>
      'Przytrzymaj, aby skopiować z nazwą użytkownika';

  @override
  String get deleteMessage => 'Usuń wiadomość';

  @override
  String get mentionUser => 'Oznacz użytkownika';

  @override
  String get copyMessageId => 'Kopiuj ID wiadomości';

  @override
  String get theme => 'Motyw';

  @override
  String get userTrigger => 'Wyzwalacz użytkownika';

  @override
  String get userTriggers => 'Wyzwalacze użytkowników';

  @override
  String get chatHistory => 'Historia czatu';

  @override
  String get login => 'Nazwa użytkownika';

  @override
  String get newUserTrigger => 'Nowy wyzwalacz';

  @override
  String get ban => 'Zbanuj';

  @override
  String get unban => 'Odbanuj';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Wyklucz użytkownika na $duration';
  }

  @override
  String get chatCleared => 'Czat został wyczyszczony';

  @override
  String get permabanned => 'dostaje bana na stałe';

  @override
  String bannedForDuration(String duration) {
    return 'dostaje bana na $duration';
  }

  @override
  String get replyingTo => 'Odpowiedź na';

  @override
  String get blockedMessage => 'Zablokowana wiadomość';

  @override
  String get showMessage => 'Pokaż wiadomość';

  @override
  String get hideMessage => 'Ukryj wiadomość';

  @override
  String get scrollToBottom => 'Przewiń na dół';

  @override
  String get appTagline => 'Czat Twitcha z emotkami z 7TV, BTTV i FFZ';

  @override
  String get loginWithTwitch => 'Zaloguj się przez Twitcha';

  @override
  String get addChannel => 'Dodaj kanał';

  @override
  String get chatSettings => 'Ustawienia czatu';

  @override
  String get autocompleteUsersWithAt => 'Uzupełniaj użytkowników po @';

  @override
  String get autocompleteEmotesWithColon => 'Uzupełniaj emotki po :';

  @override
  String get language => 'Język';

  @override
  String get locale => 'Ustawienia regionalne';

  @override
  String get systemDefault => 'Ustawienie systemowe';

  @override
  String get justDefault => 'Domyślny';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get noNotifications => 'Ktoś, gdzieś, kiedyś o tobie wspomni.';

  @override
  String get backgroundNotifications => 'Powiadomienia w tle';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'Ta opcja nie jest dostępna na twojej platformie.';

  @override
  String get optionNotAvailablePaywalled =>
      'Ta opcja jest tylko dla osób wspierających ColdChat.';

  @override
  String get clearAll => 'Wyczyść wszystko';

  @override
  String get cache => 'Pamięć podręczna';

  @override
  String get clearCache => 'Wyczyść pamięć podręczną';

  @override
  String get chatters => 'Czatujący';

  @override
  String lastSeenAgo(String time) {
    return 'Ostatnia aktywność $time temu';
  }

  @override
  String get credits => 'Podziękowania';

  @override
  String get search => 'Szukaj';

  @override
  String get emoteMenuButton => 'Przycisk menu emotek';

  @override
  String get emoteMenuButtonGrayscale =>
      'Przycisk menu emotek w odcieniach szarości';

  @override
  String get chooseEmoteMenuButton =>
      'Stuknij emotkę, aby ustawić ją jako przycisk menu emotek';

  @override
  String get resetToKappa => 'Przywróć Kappę';

  @override
  String get emoteMenuButtonDownloadFailed =>
      'Nie udało się pobrać tej emotki. Przycisk się nie zmienił.';

  @override
  String get takePhoto => 'Zrób zdjęcie';

  @override
  String get chooseFromLibrary => 'Wybierz z galerii';

  @override
  String get cameraUnavailable =>
      'Nie udało się otworzyć aparatu. Sprawdź, czy ColdChat ma dostęp do aparatu.';

  @override
  String get about => 'O aplikacji';

  @override
  String get sourceCode => 'Kod źródłowy';

  @override
  String get license => 'Licencja';

  @override
  String get basedOnChatsen => 'Oparte na Chatsen';

  @override
  String get openSourceLicenses => 'Licencje open source';

  @override
  String get aboutLegalese =>
      'ColdChat jest wolnym oprogramowaniem: możesz je rozpowszechniać i modyfikować na warunkach GNU Affero General Public License w wersji 3. Jest dostarczany BEZ JAKIEJKOLWIEK GWARANCJI.';

  @override
  String get unblock => 'Odblokuj';

  @override
  String get report => 'Zgłoś';

  @override
  String reportUserTitle(String name) {
    return 'Zgłoś $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Zgłoszenia obsługuje Twitch. Otwórz kanał $name na Twitchu i wybierz tam „Zgłoś”. Możesz też zablokować $name tutaj, aby ukryć wiadomości tej osoby.';
  }

  @override
  String get openOnTwitch => 'Otwórz na Twitchu';

  @override
  String get blockFailed =>
      'Nie udało się zmienić listy zablokowanych. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get contact => 'Kontakt i opinie';

  @override
  String get whisper => 'Szepnij';

  @override
  String whisperTo(String name) {
    return 'Szepnij do $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Szept od $name';
  }

  @override
  String get openWhisper => 'Otwórz';

  @override
  String get userCard => 'Karta użytkownika';

  @override
  String get closeConversation => 'Zamknij rozmowę';

  @override
  String get closeConversationSubtitle =>
      'Wiadomości zostają na tym urządzeniu i wrócą przy następnym szepcie.';

  @override
  String get deleteConversation => 'Usuń rozmowę';

  @override
  String get deleteConversationSubtitle =>
      'Usuwa wiadomości z tego urządzenia. Twitch nie przechowuje historii szeptów.';

  @override
  String get whisperNeedsLogin =>
      'Zaloguj się przez Twitcha, aby wysyłać szepty.';

  @override
  String get whisperNeedsScope =>
      'Zaloguj się ponownie, aby wysyłać i odbierać szepty. Twoje logowanie pochodzi z czasu, zanim ColdChat zaczął je obsługiwać.';

  @override
  String get whisperUserNotFound =>
      'Na Twitchu nie ma użytkownika o tej nazwie.';

  @override
  String whisperFailed(String reason) {
    return 'Nie wysłano szeptu: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Szepty wysłane do ciebie, gdy ColdChat był zamknięty, nie pojawiają się tutaj, bo Twitch nie udostępnia aplikacjom historii szeptów. Przeczytasz je na Twitchu pod ikoną szeptów w prawym górnym rogu.';

  @override
  String get gotIt => 'Rozumiem';

  @override
  String get openTwitch => 'Otwórz Twitcha';

  @override
  String showImage(String host) {
    return 'Pokaż obraz · $host';
  }

  @override
  String get showImagesFromLinks => 'Pokazuj obrazy z linków';

  @override
  String get showImagesFromLinksSubtitle =>
      'Twitch nie sprawdza tych obrazów. Mogą być nieodpowiednie.';

  @override
  String get showImagesAutomatically =>
      'Automatycznie pokazywać obrazy z linków?';

  @override
  String get turnOn => 'Włącz';

  @override
  String get themeIndigo => 'Indygo';

  @override
  String get themeBlue => 'Niebieski';

  @override
  String get themeTeal => 'Morski';

  @override
  String get themeGreen => 'Zielony';

  @override
  String get themeLime => 'Limonkowy';

  @override
  String get themeAmber => 'Bursztynowy';

  @override
  String get themeOrange => 'Pomarańczowy';

  @override
  String get themeRed => 'Czerwony';

  @override
  String get themePink => 'Różowy';

  @override
  String get themePurple => 'Fioletowy';

  @override
  String get accentColor => 'Kolor akcentu';

  @override
  String get oledBlack => 'Czerń OLED';

  @override
  String get oledBlackSubtitle =>
      'Czarne tło czatu w trybie ciemnym, dla ekranów OLED';

  @override
  String get customColor => 'Własny';

  @override
  String get hue => 'Odcień';

  @override
  String get saturation => 'Nasycenie';

  @override
  String get themeIce => 'Lodowy';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni',
      one: '1 dzień',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count godzin',
      few: '$count godziny',
      one: '$count godzinę',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minut',
      few: '$count minuty',
      one: '$count minutę',
    );
    return '$_temp0';
  }
}
