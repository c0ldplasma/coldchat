// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Inloggad via $provider';
  }

  @override
  String get termsOfService => 'Användarvillkor';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get settings => 'Inställningar';

  @override
  String get expiresNever => 'Går aldrig ut';

  @override
  String get loginExpired => 'Inloggningen har gått ut';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch avvisade inloggningen för $login. Chatten förblir frånkopplad tills du loggar in igen.';
  }

  @override
  String get loginFailed => 'Inloggningen misslyckades';

  @override
  String get signInAgain => 'Logga in';

  @override
  String uploadingTo(String host) {
    return 'Laddar upp till $host';
  }

  @override
  String get uploadProcessing => 'Bearbetar…';

  @override
  String get uploadFailed => 'Uppladdningen misslyckades';

  @override
  String get uploadDone => 'Uppladdad';

  @override
  String get uploadRetry => 'Försök igen';

  @override
  String get uploadDismiss => 'Stäng';

  @override
  String get uploadCancel => 'Avbryt uppladdning';

  @override
  String get uploadErrorOffline => 'Ingen internetanslutning';

  @override
  String uploadErrorTimeout(String host) {
    return '$host svarar inte';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host avvisade uppladdningen (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host skickade ett oväntat svar';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Kunde inte ansluta till $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Kunde inte läsa filen';

  @override
  String uploadErrorUnknown(String host) {
    return 'Uppladdningen till $host misslyckades';
  }

  @override
  String get uploadErrorDetails => 'Detaljer';

  @override
  String uploadRetryingWith(String host) {
    return 'Försöker igen med $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Går ut om $time';
  }

  @override
  String get close => 'Stäng';

  @override
  String get add => 'Lägg till';

  @override
  String get cancel => 'Avbryt';

  @override
  String get tokenInput => 'Ange token';

  @override
  String get account => 'Konto';

  @override
  String get refreshAccount => 'Uppdatera konto';

  @override
  String get removeAccount => 'Ta bort konto';

  @override
  String get addAnotherAccount => 'Lägg till ett konto till';

  @override
  String get verifiedUserData => 'Användardata verifierad!';

  @override
  String loggedInAs(String user) {
    return 'Inloggad som $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Ett fel uppstod när användardata verifierades:';

  @override
  String get verifyingUserData => 'Verifierar användardata...';

  @override
  String get verifiedUserToken => 'Användartoken verifierad!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Ett fel uppstod när användartoken verifierades:';

  @override
  String get verifyingUserToken => 'Verifierar användartoken...';

  @override
  String get searchForChannels => 'Sök efter kanaler';

  @override
  String get recommendedChannels => 'Rekommenderade kanaler';

  @override
  String get popularChannels => 'Populära kanaler';

  @override
  String get channel => 'Kanal';

  @override
  String get leaveChannel => 'Lämna kanal';

  @override
  String joinUser(String user) {
    return 'Gå med i $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Stavningskontrollen misslyckades! Menade du $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Gå med i $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Skicka meddelande i $channel';
  }

  @override
  String get light => 'Ljust';

  @override
  String get dark => 'Mörkt';

  @override
  String get system => 'System';

  @override
  String get appearance => 'Utseende';

  @override
  String get highContrast => 'Hög kontrast';

  @override
  String get customCommand => 'Eget kommando';

  @override
  String get customCommands => 'Egna kommandon';

  @override
  String get newCustomCommand => 'Nytt kommando';

  @override
  String get commandTrigger => 'Utlösare';

  @override
  String get command => 'Kommando';

  @override
  String get save => 'Spara';

  @override
  String get openInBrowser => 'Öppna i webbläsaren';

  @override
  String get messageAppearance => 'Meddelandenas utseende';

  @override
  String get showTimestamps => 'Visa tidsstämplar';

  @override
  String get compactMessages => 'Kompakta meddelanden';

  @override
  String get showBadges => 'Visa märken';

  @override
  String get messageTrigger => 'Meddelandeutlösare';

  @override
  String get pattern => 'Mönster';

  @override
  String get mention => 'Omnämnande';

  @override
  String get block => 'Blockera';

  @override
  String get enableRegex => 'Använd regex';

  @override
  String get caseSensitive => 'Skiftlägeskänslig';

  @override
  String get messageTriggers => 'Meddelandeutlösare';

  @override
  String get newMessageTrigger => 'Ny meddelandeutlösare';

  @override
  String get reply => 'Svara';

  @override
  String get copyText => 'Kopiera text';

  @override
  String get copyTextSubtitle =>
      'Håll in för att kopiera texten med användarnamn';

  @override
  String get deleteMessage => 'Radera meddelande';

  @override
  String get mentionUser => 'Nämn användare';

  @override
  String get copyMessageId => 'Kopiera meddelande-ID';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Användarutlösare';

  @override
  String get userTriggers => 'Användarutlösare';

  @override
  String get chatHistory => 'Chatthistorik';

  @override
  String get login => 'Användarnamn';

  @override
  String get newUserTrigger => 'Ny användarutlösare';

  @override
  String get ban => 'Bannlys';

  @override
  String get unban => 'Häv bannlysning';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Ge användaren timeout i $duration';
  }

  @override
  String get chatCleared => 'Chatten rensades';

  @override
  String get permabanned => 'permanent bannlyst';

  @override
  String bannedForDuration(String duration) {
    return 'bannlyst i $duration';
  }

  @override
  String get replyingTo => 'Svarar på';

  @override
  String get blockedMessage => 'Blockerat meddelande';

  @override
  String get showMessage => 'Visa meddelande';

  @override
  String get hideMessage => 'Dölj meddelande';

  @override
  String get scrollToBottom => 'Rulla längst ned';

  @override
  String get appTagline => 'Twitch-chatt med emotes från 7TV, BTTV och FFZ';

  @override
  String get loginWithTwitch => 'Logga in med Twitch';

  @override
  String get addChannel => 'Lägg till kanal';

  @override
  String get chatSettings => 'Chattinställningar';

  @override
  String get autocompleteUsersWithAt => 'Autokomplettera användare med @';

  @override
  String get autocompleteEmotesWithColon => 'Autokomplettera emotes med :';

  @override
  String get language => 'Språk';

  @override
  String get locale => 'Region';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get justDefault => 'Standard';

  @override
  String get notifications => 'Aviseringar';

  @override
  String get noNotifications =>
      'Någon, någonstans, kommer att nämna dig en dag.';

  @override
  String get backgroundNotifications => 'Aviseringar i bakgrunden';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'Det här alternativet finns inte på din plattform.';

  @override
  String get optionNotAvailablePaywalled =>
      'Det här alternativet är bara för ColdChat-supportrar.';

  @override
  String get clearAll => 'Rensa allt';

  @override
  String get cache => 'Cache';

  @override
  String get clearCache => 'Rensa cache';

  @override
  String get chatters => 'Chattare';

  @override
  String lastSeenAgo(String time) {
    return 'Sågs senast för $time sedan';
  }

  @override
  String get credits => 'Medverkande';

  @override
  String get search => 'Sök';

  @override
  String get emoteMenuButton => 'Knapp för emote-menyn';

  @override
  String get emoteMenuButtonGrayscale =>
      'Visa knappen för emote-menyn i gråskala';

  @override
  String get chooseEmoteMenuButton =>
      'Tryck på en emote för att använda den som knapp för emote-menyn';

  @override
  String get resetToKappa => 'Återställ till Kappa';

  @override
  String get emoteMenuButtonDownloadFailed =>
      'Det gick inte att ladda ned den emoten. Knappen ändrades inte.';

  @override
  String get takePhoto => 'Ta foto';

  @override
  String get chooseFromLibrary => 'Välj från biblioteket';

  @override
  String get cameraUnavailable =>
      'Kameran kunde inte öppnas. Kontrollera att ColdChat har åtkomst till kameran.';

  @override
  String get about => 'Om';

  @override
  String get sourceCode => 'Källkod';

  @override
  String get license => 'Licens';

  @override
  String get basedOnChatsen => 'Baserad på Chatsen';

  @override
  String get openSourceLicenses => 'Licenser för öppen källkod';

  @override
  String get aboutLegalese =>
      'ColdChat är fri programvara: du får vidaredistribuera och ändra den enligt villkoren i GNU Affero General Public License, version 3. Den levereras HELT UTAN GARANTI.';

  @override
  String get unblock => 'Avblockera';

  @override
  String get report => 'Rapportera';

  @override
  String reportUserTitle(String name) {
    return 'Rapportera $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Rapporter hanteras av Twitch. Öppna ${name}s kanal på Twitch och välj Rapportera där. Du kan också blockera $name här för att dölja meddelandena.';
  }

  @override
  String get openOnTwitch => 'Öppna på Twitch';

  @override
  String get blockFailed =>
      'Blockeringslistan kunde inte ändras. Kontrollera din anslutning och försök igen.';

  @override
  String get contact => 'Kontakt och feedback';

  @override
  String get whisper => 'Viska';

  @override
  String whisperTo(String name) {
    return 'Viska till $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Viskning från $name';
  }

  @override
  String get openWhisper => 'Öppna';

  @override
  String get userCard => 'Användarkort';

  @override
  String get closeConversation => 'Stäng konversation';

  @override
  String get closeConversationSubtitle =>
      'Meddelandena finns kvar på den här enheten och kommer tillbaka med nästa viskning.';

  @override
  String get deleteConversation => 'Radera konversation';

  @override
  String get deleteConversationSubtitle =>
      'Raderar meddelandena från den här enheten. Twitch sparar ingen historik över viskningar.';

  @override
  String get whisperNeedsLogin =>
      'Logga in med Twitch för att skicka viskningar.';

  @override
  String get whisperNeedsScope =>
      'Logga in igen för att skicka och ta emot viskningar. Din inloggning är från innan ColdChat hade stöd för dem.';

  @override
  String get whisperUserNotFound =>
      'Det finns ingen Twitch-användare med det namnet.';

  @override
  String whisperFailed(String reason) {
    return 'Viskningen skickades inte: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Viskningar du får medan ColdChat är stängt visas inte här, eftersom Twitch inte delar historiken med appar. Du kan läsa dem på Twitch, bakom viskningsikonen uppe till höger.';

  @override
  String get gotIt => 'Uppfattat';

  @override
  String get openTwitch => 'Öppna Twitch';

  @override
  String showImage(String host) {
    return 'Visa bild · $host';
  }

  @override
  String get showImagesFromLinks => 'Visa bilder från länkar';

  @override
  String get showImagesFromLinksSubtitle =>
      'Twitch granskar inte de här bilderna. De kan vara olämpliga.';

  @override
  String get showImagesAutomatically => 'Visa bilder från länkar automatiskt?';

  @override
  String get turnOn => 'Slå på';

  @override
  String get themeIndigo => 'Indigo';

  @override
  String get themeBlue => 'Blå';

  @override
  String get themeTeal => 'Petrol';

  @override
  String get themeGreen => 'Grön';

  @override
  String get themeLime => 'Lime';

  @override
  String get themeAmber => 'Bärnsten';

  @override
  String get themeOrange => 'Orange';

  @override
  String get themeRed => 'Röd';

  @override
  String get themePink => 'Rosa';

  @override
  String get themePurple => 'Lila';

  @override
  String get accentColor => 'Accentfärg';

  @override
  String get oledBlack => 'OLED-svart';

  @override
  String get oledBlackSubtitle =>
      'Svart chattbakgrund i mörkt läge, för OLED-skärmar';

  @override
  String get customColor => 'Egen';

  @override
  String get hue => 'Nyans';

  @override
  String get saturation => 'Mättnad';

  @override
  String get themeIce => 'Is';
}
