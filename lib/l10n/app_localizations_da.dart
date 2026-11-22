// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Logget ind via $provider';
  }

  @override
  String get termsOfService => 'Servicevilkår';

  @override
  String get privacyPolicy => 'Privatlivspolitik';

  @override
  String get settings => 'Indstillinger';

  @override
  String get expiresNever => 'Udløber aldrig';

  @override
  String get loginExpired => 'Login udløbet';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch afviste login for $login. Chatten forbliver afbrudt, indtil du logger ind igen.';
  }

  @override
  String get loginFailed => 'Login mislykkedes';

  @override
  String get signInAgain => 'Log ind';

  @override
  String uploadingTo(String host) {
    return 'Uploader til $host';
  }

  @override
  String get uploadProcessing => 'Behandler…';

  @override
  String get uploadFailed => 'Upload mislykkedes';

  @override
  String get uploadDone => 'Uploadet';

  @override
  String get uploadRetry => 'Prøv igen';

  @override
  String get uploadDismiss => 'Luk';

  @override
  String get uploadCancel => 'Annuller upload';

  @override
  String get uploadErrorOffline => 'Ingen internetforbindelse';

  @override
  String uploadErrorTimeout(String host) {
    return '$host svarer ikke';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host afviste uploaden (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host sendte et uventet svar';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Kunne ikke oprette forbindelse til $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Kunne ikke læse filen';

  @override
  String uploadErrorUnknown(String host) {
    return 'Upload til $host mislykkedes';
  }

  @override
  String get uploadErrorDetails => 'Detaljer';

  @override
  String uploadRetryingWith(String host) {
    return 'Prøver igen med $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Udløber om $time';
  }

  @override
  String get close => 'Luk';

  @override
  String get add => 'Tilføj';

  @override
  String get cancel => 'Annuller';

  @override
  String get tokenInput => 'Indtast token';

  @override
  String get account => 'Konto';

  @override
  String get refreshAccount => 'Opdater konto';

  @override
  String get removeAccount => 'Fjern konto';

  @override
  String get addAnotherAccount => 'Tilføj en konto mere';

  @override
  String get verifiedUserData => 'Brugerdata bekræftet!';

  @override
  String loggedInAs(String user) {
    return 'Logget ind som $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => 'Der opstod en fejl under bekræftelse af brugerdata:';

  @override
  String get verifyingUserData => 'Bekræfter brugerdata...';

  @override
  String get verifiedUserToken => 'Brugertoken bekræftet!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken => 'Der opstod en fejl under bekræftelse af brugertoken:';

  @override
  String get verifyingUserToken => 'Bekræfter brugertoken...';

  @override
  String get searchForChannels => 'Søg efter kanaler';

  @override
  String get channelSearchFailed => 'Kunne ikke søge efter kanaler';

  @override
  String get recommendedChannels => 'Anbefalede kanaler';

  @override
  String get popularChannels => 'Populære kanaler';

  @override
  String get channel => 'Kanal';

  @override
  String get leaveChannel => 'Forlad kanal';

  @override
  String joinUser(String user) {
    return 'Deltag i $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Stavekontrollen mislykkedes! Mente du $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Deltag i $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Send besked i $channel';
  }

  @override
  String get light => 'Lyst';

  @override
  String get dark => 'Mørkt';

  @override
  String get system => 'System';

  @override
  String get appearance => 'Udseende';

  @override
  String get highContrast => 'Høj kontrast';

  @override
  String get customCommand => 'Egen kommando';

  @override
  String get customCommands => 'Egne kommandoer';

  @override
  String get newCustomCommand => 'Ny kommando';

  @override
  String get commandTrigger => 'Udløser';

  @override
  String get command => 'Kommando';

  @override
  String get save => 'Gem';

  @override
  String get openInBrowser => 'Åbn i browser';

  @override
  String get messageAppearance => 'Beskeders udseende';

  @override
  String get showTimestamps => 'Vis tidsstempler';

  @override
  String get compactMessages => 'Kompakte beskeder';

  @override
  String get showBadges => 'Vis emblemer';

  @override
  String get messageTrigger => 'Beskedudløser';

  @override
  String get pattern => 'Mønster';

  @override
  String get mention => 'Omtale';

  @override
  String get block => 'Bloker';

  @override
  String get enableRegex => 'Brug regex';

  @override
  String get invalidRegex => 'Ikke et gyldigt regex';

  @override
  String get caseSensitive => 'Skeln mellem store og små bogstaver';

  @override
  String get messageTriggers => 'Beskedudløsere';

  @override
  String get newMessageTrigger => 'Ny beskedudløser';

  @override
  String get reply => 'Svar';

  @override
  String get copyText => 'Kopier tekst';

  @override
  String get copyTextSubtitle => 'Hold nede for at kopiere teksten med brugernavn';

  @override
  String get deleteMessage => 'Slet besked';

  @override
  String deleteMessageFailed(String reason) {
    return 'Beskeden blev ikke slettet: $reason';
  }

  @override
  String get deleteMessageNeedsScope =>
      'Log ind igen for at slette beskeder. Dit login er fra før ColdChat kunne slette dem.';

  @override
  String get mentionUser => 'Omtal bruger';

  @override
  String get copyMessageId => 'Kopier besked-id';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Brugerudløser';

  @override
  String get userTriggers => 'Brugerudløsere';

  @override
  String get chatHistory => 'Chathistorik';

  @override
  String get login => 'Brugernavn';

  @override
  String get newUserTrigger => 'Ny brugerudløser';

  @override
  String get ban => 'Udeluk';

  @override
  String get unban => 'Ophæv udelukkelse';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Giv bruger timeout i $duration';
  }

  @override
  String get chatCleared => 'Chatten blev ryddet';

  @override
  String get permabanned => 'permanent udelukket';

  @override
  String bannedForDuration(String duration) {
    return 'udelukket i $duration';
  }

  @override
  String get replyingTo => 'Svarer på';

  @override
  String get blockedMessage => 'Blokeret besked';

  @override
  String get showMessage => 'Vis besked';

  @override
  String get hideMessage => 'Skjul besked';

  @override
  String get scrollToBottom => 'Rul til bunden';

  @override
  String get appTagline => 'Twitch-chat med emotes fra 7TV, BTTV og FFZ';

  @override
  String get continueWithoutLogin => 'Fortsæt uden at logge ind';

  @override
  String get logInForSearch => 'Log ind for at søge efter kanaler og se livestreams';

  @override
  String get loginWithTwitch => 'Log ind med Twitch';

  @override
  String get addChannel => 'Tilføj kanal';

  @override
  String get chatSettings => 'Chatindstillinger';

  @override
  String get autocompleteUsersWithAt => 'Autofuldfør brugere med @';

  @override
  String get autocompleteEmotesWithColon => 'Autofuldfør emotes med :';

  @override
  String get language => 'Sprog';

  @override
  String get locale => 'Område';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get justDefault => 'Standard';

  @override
  String get notifications => 'Notifikationer';

  @override
  String get noNotifications => 'En eller anden, et eller andet sted, nævner dig en dag.';

  @override
  String get backgroundNotifications => 'Notifikationer i baggrunden';

  @override
  String get optionNotAvailableOnYourPlatform => 'Denne indstilling er ikke tilgængelig på din platform.';

  @override
  String get optionNotAvailablePaywalled => 'Denne indstilling er kun for ColdChat-supportere.';

  @override
  String get clearAll => 'Ryd alt';

  @override
  String get cache => 'Cache';

  @override
  String get clearCache => 'Ryd cache';

  @override
  String get emoteCache => 'Emote-cache';

  @override
  String emoteCacheUsage(String used, String limit) {
    return '$used af $limit';
  }

  @override
  String megabytes(String size) {
    return '$size MB';
  }

  @override
  String get chatters => 'Chattere';

  @override
  String lastSeenAgo(String time) {
    return 'Sidst set for $time siden';
  }

  @override
  String get credits => 'Krediteringer';

  @override
  String get search => 'Søg';

  @override
  String get emoteMenuButton => 'Knap til emote-menuen';

  @override
  String get emoteMenuButtonGrayscale => 'Vis knappen til emote-menuen i gråtoner';

  @override
  String get chooseEmoteMenuButton => 'Tryk på en emote for at bruge den som knap til emote-menuen';

  @override
  String get resetToKappa => 'Nulstil til Kappa';

  @override
  String get emoteMenuButtonDownloadFailed => 'Kunne ikke downloade den emote. Knappen blev ikke ændret.';

  @override
  String get takePhoto => 'Tag billede';

  @override
  String get chooseFromLibrary => 'Vælg fra biblioteket';

  @override
  String get cameraUnavailable => 'Kameraet kunne ikke åbnes. Tjek, at ColdChat har adgang til kameraet.';

  @override
  String get about => 'Om';

  @override
  String get sourceCode => 'Kildekode';

  @override
  String get license => 'Licens';

  @override
  String get basedOnChatsen => 'Baseret på Chatsen';

  @override
  String get openSourceLicenses => 'Open source-licenser';

  @override
  String get aboutLegalese =>
      'ColdChat er fri software: Du må videredistribuere og ændre den under betingelserne i GNU Affero General Public License, version 3. Den leveres UDEN NOGEN FORM FOR GARANTI.';

  @override
  String get unblock => 'Fjern blokering';

  @override
  String get report => 'Anmeld';

  @override
  String reportUserTitle(String name) {
    return 'Anmeld $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Anmeldelser håndteres af Twitch. Åbn kanalen for $name på Twitch, og vælg Anmeld dér. Du kan også blokere $name her for at skjule beskederne.';
  }

  @override
  String get openOnTwitch => 'Åbn på Twitch';

  @override
  String get blockFailed => 'Bloklisten kunne ikke ændres. Tjek din forbindelse, og prøv igen.';

  @override
  String get moderationNeedsLogin => 'Log ind med Twitch for at moderere denne kanal.';

  @override
  String get moderationNeedsScope =>
      'Log ind igen for at bandlyse og give brugere timeout. Dit login er fra før ColdChat kunne det.';

  @override
  String moderationFailed(String reason) {
    return 'Det virkede ikke: $reason';
  }

  @override
  String get contact => 'Kontakt og feedback';

  @override
  String get whisper => 'Hvisk';

  @override
  String whisperTo(String name) {
    return 'Hvisk til $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Hviskebesked fra $name';
  }

  @override
  String get openWhisper => 'Åbn';

  @override
  String get userCard => 'Brugerkort';

  @override
  String get closeConversation => 'Luk samtale';

  @override
  String get closeConversationSubtitle => 'Beskederne bliver på denne enhed og kommer tilbage med næste hviskebesked.';

  @override
  String get deleteConversation => 'Slet samtale';

  @override
  String get deleteConversationSubtitle =>
      'Sletter beskederne fra denne enhed. Twitch gemmer ingen historik over hviskebeskeder.';

  @override
  String get whisperNeedsLogin => 'Log ind med Twitch for at sende hviskebeskeder.';

  @override
  String get whisperNeedsScope =>
      'Log ind igen for at sende og modtage hviskebeskeder. Dit login er fra før ColdChat understøttede dem.';

  @override
  String get whisperUserNotFound => 'Der findes ingen Twitch-bruger med det navn.';

  @override
  String get messageNotSentNotConnected => 'Ikke forbundet til denne kanal endnu. Din besked blev ikke sendt.';

  @override
  String whisperFailed(String reason) {
    return 'Hviskebesked ikke sendt: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Hviskebeskeder, du får, mens ColdChat er lukket, vises ikke her, fordi Twitch ikke deler historikken med apps. Du kan læse dem på Twitch bag hviske-ikonet øverst til højre.';

  @override
  String get gotIt => 'Forstået';

  @override
  String get openTwitch => 'Åbn Twitch';

  @override
  String showImage(String host) {
    return 'Vis billede · $host';
  }

  @override
  String get showImagesFromLinks => 'Vis billeder fra links';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch tjekker ikke disse billeder. De kan være upassende.';

  @override
  String get showImagesAutomatically => 'Vis billeder fra links automatisk?';

  @override
  String get turnOn => 'Slå til';

  @override
  String get themeIndigo => 'Indigo';

  @override
  String get themeBlue => 'Blå';

  @override
  String get themeTeal => 'Petrol';

  @override
  String get themeGreen => 'Grøn';

  @override
  String get themeLime => 'Lime';

  @override
  String get themeAmber => 'Rav';

  @override
  String get themeOrange => 'Orange';

  @override
  String get themeRed => 'Rød';

  @override
  String get themePink => 'Pink';

  @override
  String get themePurple => 'Lilla';

  @override
  String get accentColor => 'Accentfarve';

  @override
  String get oledBlack => 'OLED-sort';

  @override
  String get oledBlackSubtitle => 'Sort chatbaggrund i mørk tilstand, til OLED-skærme';

  @override
  String get customColor => 'Egen';

  @override
  String get hue => 'Nuance';

  @override
  String get saturation => 'Mætning';

  @override
  String get themeIce => 'Is';

  @override
  String channelConnecting(String channel) {
    return 'Opretter forbindelse til $channel …';
  }

  @override
  String channelConnected(String channel) {
    return 'Forbundet til $channel';
  }

  @override
  String channelDisconnected(String channel) {
    return 'Afbrudt fra $channel';
  }

  @override
  String channelSuspended(String channel) {
    return '$channel er blevet suspenderet af Twitch';
  }

  @override
  String channelBanned(String channel) {
    return 'Du er bannet fra $channel';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dage',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count timer',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutter',
      one: '1 minut',
    );
    return '$_temp0';
  }

  @override
  String durationDaysShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dage',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String durationHoursShort(int count) {
    return '$count t.';
  }

  @override
  String durationMinutesShort(int count) {
    return '$count min.';
  }

  @override
  String durationSecondsShort(int count) {
    return '$count sek.';
  }

  @override
  String durationPair(String larger, String smaller) {
    return '$larger $smaller';
  }
}
