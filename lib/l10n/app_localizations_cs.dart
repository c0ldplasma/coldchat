// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Přihlášeno přes $provider';
  }

  @override
  String get termsOfService => 'Podmínky služby';

  @override
  String get privacyPolicy => 'Zásady ochrany osobních údajů';

  @override
  String get settings => 'Nastavení';

  @override
  String get expiresNever => 'Nikdy nevyprší';

  @override
  String get loginExpired => 'Přihlášení vypršelo';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch odmítl přihlášení pro $login. Chat zůstane odpojený, dokud se znovu nepřihlásíš.';
  }

  @override
  String get loginFailed => 'Přihlášení se nezdařilo';

  @override
  String get signInAgain => 'Přihlásit se';

  @override
  String uploadingTo(String host) {
    return 'Nahrávání na $host';
  }

  @override
  String get uploadProcessing => 'Zpracování…';

  @override
  String get uploadFailed => 'Nahrávání se nezdařilo';

  @override
  String get uploadDone => 'Nahráno';

  @override
  String get uploadRetry => 'Zkusit znovu';

  @override
  String get uploadDismiss => 'Skrýt';

  @override
  String get uploadCancel => 'Zrušit nahrávání';

  @override
  String get uploadErrorOffline => 'Žádné připojení k internetu';

  @override
  String uploadErrorTimeout(String host) {
    return '$host neodpovídá';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return 'Server $host nahrání odmítl (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return 'Server $host vrátil neočekávanou odpověď';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Nelze se připojit k $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Soubor nelze přečíst';

  @override
  String uploadErrorUnknown(String host) {
    return 'Nahrávání na $host se nezdařilo';
  }

  @override
  String get uploadErrorDetails => 'Podrobnosti';

  @override
  String uploadRetryingWith(String host) {
    return 'Nový pokus přes $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Vyprší za $time';
  }

  @override
  String get close => 'Zavřít';

  @override
  String get add => 'Přidat';

  @override
  String get cancel => 'Zrušit';

  @override
  String get tokenInput => 'Zadání tokenu';

  @override
  String get account => 'Účet';

  @override
  String get refreshAccount => 'Obnovit účet';

  @override
  String get removeAccount => 'Odebrat účet';

  @override
  String get addAnotherAccount => 'Přidat další účet';

  @override
  String get verifiedUserData => 'Uživatelská data ověřena!';

  @override
  String loggedInAs(String user) {
    return 'Přihlášeno jako $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => 'Při ověřování uživatelských dat došlo k chybě:';

  @override
  String get verifyingUserData => 'Ověřování uživatelských dat...';

  @override
  String get verifiedUserToken => 'Uživatelský token ověřen!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken => 'Při ověřování uživatelského tokenu došlo k chybě:';

  @override
  String get verifyingUserToken => 'Ověřování uživatelského tokenu...';

  @override
  String get searchForChannels => 'Hledat kanály';

  @override
  String get channelSearchFailed => 'Kanály se nepodařilo vyhledat';

  @override
  String get recommendedChannels => 'Doporučené kanály';

  @override
  String get popularChannels => 'Populární kanály';

  @override
  String get channel => 'Kanál';

  @override
  String get leaveChannel => 'Opustit kanál';

  @override
  String joinUser(String user) {
    return 'Připojit se k $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Kontrola pravopisu selhala! Nehledáš $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Připojit se k $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Poslat zprávu do $channel';
  }

  @override
  String get light => 'Světlý';

  @override
  String get dark => 'Tmavý';

  @override
  String get system => 'Podle systému';

  @override
  String get appearance => 'Vzhled';

  @override
  String get highContrast => 'Vysoký kontrast';

  @override
  String get customCommand => 'Vlastní příkaz';

  @override
  String get customCommands => 'Vlastní příkazy';

  @override
  String get newCustomCommand => 'Nový vlastní příkaz';

  @override
  String get commandTrigger => 'Spouštěč';

  @override
  String get command => 'Příkaz';

  @override
  String get save => 'Uložit';

  @override
  String get openInBrowser => 'Otevřít v prohlížeči';

  @override
  String get messageAppearance => 'Vzhled zpráv';

  @override
  String get showTimestamps => 'Zobrazit čas';

  @override
  String get compactMessages => 'Kompaktní zprávy';

  @override
  String get showBadges => 'Zobrazit odznaky';

  @override
  String get messageTrigger => 'Spouštěč zpráv';

  @override
  String get pattern => 'Vzor';

  @override
  String get mention => 'Zmínka';

  @override
  String get block => 'Zablokovat';

  @override
  String get enableRegex => 'Povolit regex';

  @override
  String get invalidRegex => 'Neplatný regex';

  @override
  String get caseSensitive => 'Rozlišovat velká a malá písmena';

  @override
  String get messageTriggers => 'Spouštěče zpráv';

  @override
  String get newMessageTrigger => 'Nový spouštěč zpráv';

  @override
  String get reply => 'Odpovědět';

  @override
  String get copyText => 'Kopírovat text';

  @override
  String get copyTextSubtitle => 'Podržením zkopíruješ text i s uživatelským jménem';

  @override
  String get deleteMessage => 'Smazat zprávu';

  @override
  String deleteMessageFailed(String reason) {
    return 'Zpráva nebyla smazána: $reason';
  }

  @override
  String get deleteMessageNeedsScope =>
      'Pro mazání zpráv se přihlas znovu. Tvoje přihlášení je z doby, kdy to ColdChat ještě neuměl.';

  @override
  String get mentionUser => 'Zmínit uživatele';

  @override
  String get copyMessageId => 'Kopírovat ID zprávy';

  @override
  String get theme => 'Motiv';

  @override
  String get userTrigger => 'Spouštěč uživatele';

  @override
  String get userTriggers => 'Spouštěče uživatelů';

  @override
  String get chatHistory => 'Historie chatu';

  @override
  String get login => 'Uživatelské jméno';

  @override
  String get newUserTrigger => 'Nový spouštěč uživatele';

  @override
  String get ban => 'Zabanovat';

  @override
  String get unban => 'Odbanovat';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Dát uživateli timeout na $duration';
  }

  @override
  String get chatCleared => 'Chat byl vymazán';

  @override
  String get permabanned => 'dostává trvalý ban';

  @override
  String bannedForDuration(String duration) {
    return 'dostává ban na $duration';
  }

  @override
  String get replyingTo => 'Odpověď na';

  @override
  String get blockedMessage => 'Zablokovaná zpráva';

  @override
  String get showMessage => 'Zobrazit zprávu';

  @override
  String get hideMessage => 'Skrýt zprávu';

  @override
  String get scrollToBottom => 'Přejít na konec';

  @override
  String get appTagline => 'Chat na Twitchi s emotikony ze 7TV, BTTV a FFZ';

  @override
  String get loginWithTwitch => 'Přihlásit se přes Twitch';

  @override
  String get addChannel => 'Přidat kanál';

  @override
  String get chatSettings => 'Nastavení chatu';

  @override
  String get autocompleteUsersWithAt => 'Doplňovat uživatele pomocí @';

  @override
  String get autocompleteEmotesWithColon => 'Doplňovat emotikony pomocí :';

  @override
  String get language => 'Jazyk';

  @override
  String get locale => 'Místní nastavení';

  @override
  String get systemDefault => 'Podle systému';

  @override
  String get justDefault => 'Výchozí';

  @override
  String get notifications => 'Oznámení';

  @override
  String get noNotifications => 'Někdo, někde se o tobě jednou zmíní.';

  @override
  String get backgroundNotifications => 'Oznámení na pozadí';

  @override
  String get optionNotAvailableOnYourPlatform => 'Tato možnost není na tvé platformě dostupná.';

  @override
  String get optionNotAvailablePaywalled => 'Tato možnost je jen pro ty, kdo podporují ColdChat.';

  @override
  String get clearAll => 'Vymazat vše';

  @override
  String get cache => 'Mezipaměť';

  @override
  String get clearCache => 'Vymazat mezipaměť';

  @override
  String get emoteCache => 'Mezipaměť emotů';

  @override
  String emoteCacheUsage(String used, String limit) {
    return '$used z $limit';
  }

  @override
  String megabytes(String size) {
    return '$size MB';
  }

  @override
  String get chatters => 'Chatující';

  @override
  String lastSeenAgo(String time) {
    return 'Naposledy aktivní před $time';
  }

  @override
  String get credits => 'Poděkování';

  @override
  String get search => 'Hledat';

  @override
  String get emoteMenuButton => 'Tlačítko nabídky emotikonů';

  @override
  String get emoteMenuButtonGrayscale => 'Tlačítko nabídky emotikonů ve stupních šedi';

  @override
  String get chooseEmoteMenuButton => 'Klepni na emotikon, který chceš použít jako tlačítko nabídky emotikonů';

  @override
  String get resetToKappa => 'Obnovit na Kappa';

  @override
  String get emoteMenuButtonDownloadFailed => 'Emotikon se nepodařilo stáhnout. Tlačítko zůstalo beze změny.';

  @override
  String get takePhoto => 'Vyfotit';

  @override
  String get chooseFromLibrary => 'Vybrat z knihovny';

  @override
  String get cameraUnavailable =>
      'Fotoaparát se nepodařilo otevřít. Zkontroluj, jestli má ColdChat přístup k fotoaparátu.';

  @override
  String get about => 'O aplikaci';

  @override
  String get sourceCode => 'Zdrojový kód';

  @override
  String get license => 'Licence';

  @override
  String get basedOnChatsen => 'Založeno na Chatsen';

  @override
  String get openSourceLicenses => 'Licence open source';

  @override
  String get aboutLegalese =>
      'ColdChat je svobodný software: můžeš ho šířit a upravovat za podmínek GNU Affero General Public License, verze 3. Je poskytován ABSOLUTNĚ BEZ ZÁRUKY.';

  @override
  String get unblock => 'Odblokovat';

  @override
  String get report => 'Nahlásit';

  @override
  String reportUserTitle(String name) {
    return 'Nahlásit $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Nahlášení vyřizuje Twitch. Otevři kanál $name na Twitchi a zvol tam Nahlásit. Nebo $name zablokuj tady a zprávy se ti přestanou zobrazovat.';
  }

  @override
  String get openOnTwitch => 'Otevřít na Twitchi';

  @override
  String get blockFailed => 'Seznam blokovaných se nepodařilo změnit. Zkontroluj připojení a zkus to znovu.';

  @override
  String get moderationNeedsLogin => 'Pro moderování tohoto kanálu se přihlas přes Twitch.';

  @override
  String get moderationNeedsScope =>
      'Pro banování a timeouty uživatelů se přihlas znovu. Tvoje přihlášení je starší, než to ColdChat uměl.';

  @override
  String moderationFailed(String reason) {
    return 'Nepovedlo se: $reason';
  }

  @override
  String get contact => 'Kontakt a zpětná vazba';

  @override
  String get whisper => 'Šeptat';

  @override
  String whisperTo(String name) {
    return 'Šepot pro $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Šepot od $name';
  }

  @override
  String get openWhisper => 'Otevřít';

  @override
  String get userCard => 'Karta uživatele';

  @override
  String get closeConversation => 'Zavřít konverzaci';

  @override
  String get closeConversationSubtitle => 'Zprávy zůstanou v tomto zařízení a vrátí se s dalším šepotem.';

  @override
  String get deleteConversation => 'Smazat konverzaci';

  @override
  String get deleteConversationSubtitle => 'Smaže zprávy z tohoto zařízení. Twitch historii šepotů neukládá.';

  @override
  String get logInToChat => 'Přihlas se a chatuj';

  @override
  String get logInToSeeMore => 'Přihlas se a uvidíš víc';

  @override
  String get uploadNeedsLogin => 'Přihlas se a sdílej fotky v chatu';

  @override
  String get whisperNeedsLogin => 'Pro posílání šepotů se přihlas přes Twitch.';

  @override
  String get whisperNeedsScope =>
      'Pro posílání a příjem šepotů se přihlas znovu. Tvoje přihlášení je z doby, kdy je ColdChat ještě nepodporoval.';

  @override
  String get whisperUserNotFound => 'Na Twitchi není žádný uživatel s tímto jménem.';

  @override
  String get messageNotSentNotConnected => 'K tomuto kanálu ještě nejsi připojen. Tvoje zpráva nebyla odeslána.';

  @override
  String whisperFailed(String reason) {
    return 'Šepot nebyl odeslán: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Šepoty, které ti přijdou, když je ColdChat zavřený, se tu nezobrazí, protože Twitch aplikacím historii šepotů neposkytuje. Přečteš si je na Twitchi pod ikonou šepotů vpravo nahoře.';

  @override
  String get gotIt => 'Rozumím';

  @override
  String get openTwitch => 'Otevřít Twitch';

  @override
  String showImage(String host) {
    return 'Zobrazit obrázek · $host';
  }

  @override
  String get showImagesFromLinks => 'Zobrazovat obrázky z odkazů';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch tyto obrázky nekontroluje. Mohou být nevhodné.';

  @override
  String get showImagesAutomatically => 'Zobrazovat obrázky z odkazů automaticky?';

  @override
  String get turnOn => 'Zapnout';

  @override
  String get themeIndigo => 'Indigo';

  @override
  String get themeBlue => 'Modrá';

  @override
  String get themeTeal => 'Petrolejová';

  @override
  String get themeGreen => 'Zelená';

  @override
  String get themeLime => 'Limetková';

  @override
  String get themeAmber => 'Jantarová';

  @override
  String get themeOrange => 'Oranžová';

  @override
  String get themeRed => 'Červená';

  @override
  String get themePink => 'Růžová';

  @override
  String get themePurple => 'Fialová';

  @override
  String get accentColor => 'Barva zvýraznění';

  @override
  String get oledBlack => 'OLED černá';

  @override
  String get oledBlackSubtitle => 'Černé pozadí chatu v tmavém režimu, pro OLED displeje';

  @override
  String get customColor => 'Vlastní';

  @override
  String get hue => 'Odstín';

  @override
  String get saturation => 'Sytost';

  @override
  String get themeIce => 'Ledová';

  @override
  String channelConnecting(String channel) {
    return 'Připojování k $channel…';
  }

  @override
  String channelConnected(String channel) {
    return 'Připojeno k $channel';
  }

  @override
  String channelDisconnected(String channel) {
    return 'Odpojeno od $channel';
  }

  @override
  String channelSuspended(String channel) {
    return 'Kanál $channel byl pozastaven Twitchem';
  }

  @override
  String channelBanned(String channel) {
    return 'Na kanálu $channel máš ban';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      few: '$count dny',
      one: '$count den',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hodin',
      few: '$count hodiny',
      one: '$count hodinu',
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
      one: '$count minutu',
    );
    return '$_temp0';
  }

  @override
  String durationDaysShort(int count) {
    return '$count d';
  }

  @override
  String durationHoursShort(int count) {
    return '$count h';
  }

  @override
  String durationMinutesShort(int count) {
    return '$count min';
  }

  @override
  String durationSecondsShort(int count) {
    return '$count s';
  }

  @override
  String durationPair(String larger, String smaller) {
    return '$larger $smaller';
  }
}
