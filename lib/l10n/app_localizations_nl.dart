// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Ingelogd via $provider';
  }

  @override
  String get termsOfService => 'Servicevoorwaarden';

  @override
  String get privacyPolicy => 'Privacybeleid';

  @override
  String get settings => 'Instellingen';

  @override
  String get expiresNever => 'Verloopt nooit';

  @override
  String get loginExpired => 'Login verlopen';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch heeft de login voor $login geweigerd. De chat blijft verbroken tot je opnieuw inlogt.';
  }

  @override
  String get loginFailed => 'Inloggen mislukt';

  @override
  String get signInAgain => 'Inloggen';

  @override
  String uploadingTo(String host) {
    return 'Uploaden naar $host';
  }

  @override
  String get uploadProcessing => 'Verwerken…';

  @override
  String get uploadFailed => 'Uploaden mislukt';

  @override
  String get uploadDone => 'Geüpload';

  @override
  String get uploadRetry => 'Opnieuw proberen';

  @override
  String get uploadDismiss => 'Sluiten';

  @override
  String get uploadCancel => 'Upload annuleren';

  @override
  String get uploadErrorOffline => 'Geen internetverbinding';

  @override
  String uploadErrorTimeout(String host) {
    return '$host reageert niet';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host heeft de upload geweigerd (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host gaf een onverwacht antwoord';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Kan geen verbinding maken met $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Kan het bestand niet lezen';

  @override
  String uploadErrorUnknown(String host) {
    return 'Uploaden naar $host mislukt';
  }

  @override
  String get uploadErrorDetails => 'Details';

  @override
  String uploadRetryingWith(String host) {
    return 'Opnieuw proberen met $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Verloopt over $time';
  }

  @override
  String get close => 'Sluiten';

  @override
  String get add => 'Toevoegen';

  @override
  String get cancel => 'Annuleren';

  @override
  String get tokenInput => 'Token invoeren';

  @override
  String get account => 'Account';

  @override
  String get refreshAccount => 'Account vernieuwen';

  @override
  String get removeAccount => 'Account verwijderen';

  @override
  String get addAnotherAccount => 'Nog een account toevoegen';

  @override
  String get verifiedUserData => 'Gebruikersgegevens geverifieerd!';

  @override
  String loggedInAs(String user) {
    return 'Ingelogd als $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Er is een fout opgetreden bij het verifiëren van de gebruikersgegevens:';

  @override
  String get verifyingUserData => 'Gebruikersgegevens verifiëren...';

  @override
  String get verifiedUserToken => 'Gebruikerstoken geverifieerd!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Er is een fout opgetreden bij het verifiëren van de gebruikerstoken:';

  @override
  String get verifyingUserToken => 'Gebruikerstoken verifiëren...';

  @override
  String get searchForChannels => 'Kanalen zoeken';

  @override
  String get channelSearchFailed => 'Kanalen zoeken is mislukt';

  @override
  String get recommendedChannels => 'Aanbevolen kanalen';

  @override
  String get popularChannels => 'Populaire kanalen';

  @override
  String get channel => 'Kanaal';

  @override
  String get leaveChannel => 'Kanaal verlaten';

  @override
  String joinUser(String user) {
    return 'Kanaal van $user openen';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Spellingcontrole mislukt! Bedoelde je $username?';
  }

  @override
  String joinChannelName(String channel) {
    return '$channel openen';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Bericht sturen in $channel';
  }

  @override
  String get light => 'Licht';

  @override
  String get dark => 'Donker';

  @override
  String get system => 'Systeem';

  @override
  String get appearance => 'Weergave';

  @override
  String get highContrast => 'Hoog contrast';

  @override
  String get customCommand => 'Eigen commando';

  @override
  String get customCommands => 'Eigen commando\'s';

  @override
  String get newCustomCommand => 'Nieuw commando';

  @override
  String get commandTrigger => 'Trigger';

  @override
  String get command => 'Commando';

  @override
  String get save => 'Opslaan';

  @override
  String get openInBrowser => 'Openen in browser';

  @override
  String get messageAppearance => 'Berichtweergave';

  @override
  String get showTimestamps => 'Tijdstempels tonen';

  @override
  String get compactMessages => 'Compacte berichten';

  @override
  String get showBadges => 'Badges tonen';

  @override
  String get messageTrigger => 'Berichttrigger';

  @override
  String get pattern => 'Patroon';

  @override
  String get mention => 'Vermelding';

  @override
  String get block => 'Blokkeren';

  @override
  String get enableRegex => 'Regex gebruiken';

  @override
  String get invalidRegex => 'Geen geldige regex';

  @override
  String get caseSensitive => 'Hoofdlettergevoelig';

  @override
  String get messageTriggers => 'Berichttriggers';

  @override
  String get newMessageTrigger => 'Nieuwe berichttrigger';

  @override
  String get reply => 'Beantwoorden';

  @override
  String get copyText => 'Tekst kopiëren';

  @override
  String get copyTextSubtitle => 'Houd vast om de tekst met gebruikersnaam te kopiëren';

  @override
  String get deleteMessage => 'Bericht verwijderen';

  @override
  String deleteMessageFailed(String reason) {
    return 'Bericht niet verwijderd: $reason';
  }

  @override
  String get deleteMessageNeedsScope =>
      'Log opnieuw in om berichten te verwijderen. Je login is van voordat ColdChat dat kon.';

  @override
  String get mentionUser => 'Gebruiker vermelden';

  @override
  String get copyMessageId => 'Bericht-ID kopiëren';

  @override
  String get theme => 'Thema';

  @override
  String get userTrigger => 'Gebruikerstrigger';

  @override
  String get userTriggers => 'Gebruikerstriggers';

  @override
  String get chatHistory => 'Chatgeschiedenis';

  @override
  String get login => 'Gebruikersnaam';

  @override
  String get newUserTrigger => 'Nieuwe gebruikerstrigger';

  @override
  String get ban => 'Verbannen';

  @override
  String get unban => 'Verbanning opheffen';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Gebruiker $duration time-out geven';
  }

  @override
  String get chatCleared => 'Chat is gewist';

  @override
  String get permabanned => 'permanent verbannen';

  @override
  String bannedForDuration(String duration) {
    return 'verbannen voor $duration';
  }

  @override
  String get replyingTo => 'Antwoord aan';

  @override
  String get blockedMessage => 'Geblokkeerd bericht';

  @override
  String get showMessage => 'Bericht tonen';

  @override
  String get hideMessage => 'Bericht verbergen';

  @override
  String get scrollToBottom => 'Naar beneden scrollen';

  @override
  String get appTagline => 'Twitch-chat met emotes van 7TV, BTTV en FFZ';

  @override
  String get loginWithTwitch => 'Inloggen met Twitch';

  @override
  String get addChannel => 'Kanaal toevoegen';

  @override
  String get chatSettings => 'Chatinstellingen';

  @override
  String get autocompleteUsersWithAt => 'Gebruikers aanvullen met @';

  @override
  String get autocompleteEmotesWithColon => 'Emotes aanvullen met :';

  @override
  String get language => 'Taal';

  @override
  String get locale => 'Regio';

  @override
  String get systemDefault => 'Systeemstandaard';

  @override
  String get justDefault => 'Standaard';

  @override
  String get notifications => 'Meldingen';

  @override
  String get noNotifications => 'Iemand, ergens, gaat je ooit vermelden.';

  @override
  String get backgroundNotifications => 'Meldingen op de achtergrond';

  @override
  String get optionNotAvailableOnYourPlatform => 'Deze optie is niet beschikbaar op jouw platform.';

  @override
  String get optionNotAvailablePaywalled => 'Deze optie is alleen voor ColdChat-supporters.';

  @override
  String get clearAll => 'Alles wissen';

  @override
  String get cache => 'Cache';

  @override
  String get clearCache => 'Cache wissen';

  @override
  String get chatters => 'Chatters';

  @override
  String lastSeenAgo(String time) {
    return '$time geleden voor het laatst gezien';
  }

  @override
  String get credits => 'Credits';

  @override
  String get search => 'Zoeken';

  @override
  String get emoteMenuButton => 'Emotemenuknop';

  @override
  String get emoteMenuButtonGrayscale => 'Emotemenuknop in grijstinten tonen';

  @override
  String get chooseEmoteMenuButton => 'Tik op een emote om die als emotemenuknop te gebruiken';

  @override
  String get resetToKappa => 'Terugzetten naar Kappa';

  @override
  String get emoteMenuButtonDownloadFailed => 'Kan die emote niet downloaden. De knop is niet gewijzigd.';

  @override
  String get takePhoto => 'Foto maken';

  @override
  String get chooseFromLibrary => 'Kiezen uit bibliotheek';

  @override
  String get cameraUnavailable =>
      'De camera kan niet worden geopend. Controleer of ColdChat toegang heeft tot de camera.';

  @override
  String get about => 'Over';

  @override
  String get sourceCode => 'Broncode';

  @override
  String get license => 'Licentie';

  @override
  String get basedOnChatsen => 'Gebaseerd op Chatsen';

  @override
  String get openSourceLicenses => 'Opensourcelicenties';

  @override
  String get aboutLegalese =>
      'ColdChat is vrije software: je mag het verder verspreiden en aanpassen onder de voorwaarden van de GNU Affero General Public License, versie 3. Het wordt geleverd ZONDER ENIGE GARANTIE.';

  @override
  String get unblock => 'Deblokkeren';

  @override
  String get report => 'Rapporteren';

  @override
  String reportUserTitle(String name) {
    return '$name rapporteren';
  }

  @override
  String reportUserDescription(String name) {
    return 'Meldingen worden door Twitch afgehandeld. Open het kanaal van $name op Twitch en kies daar Rapporteren. Je kunt $name hier ook blokkeren om de berichten te verbergen.';
  }

  @override
  String get openOnTwitch => 'Openen op Twitch';

  @override
  String get blockFailed =>
      'De blokkeerlijst kan niet worden gewijzigd. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get moderationNeedsLogin => 'Log in met Twitch om dit kanaal te modereren.';

  @override
  String get moderationNeedsScope =>
      'Log opnieuw in om gebruikers te bannen en een time-out te geven. Je login is van voordat ColdChat dat kon.';

  @override
  String moderationFailed(String reason) {
    return 'Dat is niet gelukt: $reason';
  }

  @override
  String get contact => 'Contact & feedback';

  @override
  String get whisper => 'Fluisteren';

  @override
  String whisperTo(String name) {
    return 'Fluisteren naar $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Fluisterbericht van $name';
  }

  @override
  String get openWhisper => 'Openen';

  @override
  String get userCard => 'Gebruikerskaart';

  @override
  String get closeConversation => 'Gesprek sluiten';

  @override
  String get closeConversationSubtitle =>
      'De berichten blijven op dit apparaat en komen terug bij het volgende fluisterbericht.';

  @override
  String get deleteConversation => 'Gesprek verwijderen';

  @override
  String get deleteConversationSubtitle =>
      'Verwijdert de berichten van dit apparaat. Twitch bewaart geen geschiedenis van fluisterberichten.';

  @override
  String get whisperNeedsLogin => 'Log in met Twitch om fluisterberichten te sturen.';

  @override
  String get whisperNeedsScope =>
      'Log opnieuw in om fluisterberichten te sturen en te ontvangen. Je login is van voordat ColdChat ze ondersteunde.';

  @override
  String get whisperUserNotFound => 'Er is geen Twitch-gebruiker met die naam.';

  @override
  String whisperFailed(String reason) {
    return 'Fluisterbericht niet verstuurd: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Fluisterberichten die je krijgt terwijl ColdChat gesloten is, verschijnen hier niet, omdat Twitch de geschiedenis niet met apps deelt. Je kunt ze op Twitch lezen, achter het fluistericoon rechtsboven.';

  @override
  String get gotIt => 'Begrepen';

  @override
  String get openTwitch => 'Twitch openen';

  @override
  String showImage(String host) {
    return 'Afbeelding tonen · $host';
  }

  @override
  String get showImagesFromLinks => 'Afbeeldingen uit links tonen';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch controleert deze afbeeldingen niet. Ze kunnen ongepast zijn.';

  @override
  String get showImagesAutomatically => 'Afbeeldingen uit links automatisch tonen?';

  @override
  String get turnOn => 'Inschakelen';

  @override
  String get themeIndigo => 'Indigo';

  @override
  String get themeBlue => 'Blauw';

  @override
  String get themeTeal => 'Petrol';

  @override
  String get themeGreen => 'Groen';

  @override
  String get themeLime => 'Limoen';

  @override
  String get themeAmber => 'Amber';

  @override
  String get themeOrange => 'Oranje';

  @override
  String get themeRed => 'Rood';

  @override
  String get themePink => 'Roze';

  @override
  String get themePurple => 'Paars';

  @override
  String get accentColor => 'Accentkleur';

  @override
  String get oledBlack => 'OLED-zwart';

  @override
  String get oledBlackSubtitle => 'Zwarte chatachtergrond in donkere modus, voor OLED-schermen';

  @override
  String get customColor => 'Eigen';

  @override
  String get hue => 'Tint';

  @override
  String get saturation => 'Verzadiging';

  @override
  String get themeIce => 'IJs';

  @override
  String channelConnecting(String channel) {
    return 'Verbinden met $channel…';
  }

  @override
  String channelConnected(String channel) {
    return 'Verbonden met $channel';
  }

  @override
  String channelDisconnected(String channel) {
    return 'Verbinding met $channel verbroken';
  }

  @override
  String channelSuspended(String channel) {
    return '$channel is door Twitch geschorst';
  }

  @override
  String channelBanned(String channel) {
    return 'Je bent verbannen uit $channel';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur',
      one: '1 uur',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuten',
      one: '1 minuut',
    );
    return '$_temp0';
  }
}
