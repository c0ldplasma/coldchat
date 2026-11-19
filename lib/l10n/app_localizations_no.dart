// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class AppLocalizationsNo extends AppLocalizations {
  AppLocalizationsNo([String locale = 'no']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Logget inn via $provider';
  }

  @override
  String get termsOfService => 'Vilkår for bruk';

  @override
  String get privacyPolicy => 'Personvernerklæring';

  @override
  String get settings => 'Innstillinger';

  @override
  String get expiresNever => 'Utløper aldri';

  @override
  String get loginExpired => 'Innloggingen er utløpt';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch avviste innloggingen for $login. Chatten forblir frakoblet til du logger inn igjen.';
  }

  @override
  String get loginFailed => 'Innloggingen mislyktes';

  @override
  String get signInAgain => 'Logg inn';

  @override
  String uploadingTo(String host) {
    return 'Laster opp til $host';
  }

  @override
  String get uploadProcessing => 'Behandler…';

  @override
  String get uploadFailed => 'Opplastingen mislyktes';

  @override
  String get uploadDone => 'Lastet opp';

  @override
  String get uploadRetry => 'Prøv igjen';

  @override
  String get uploadDismiss => 'Lukk';

  @override
  String get uploadCancel => 'Avbryt opplasting';

  @override
  String get uploadErrorOffline => 'Ingen internettforbindelse';

  @override
  String uploadErrorTimeout(String host) {
    return '$host svarer ikke';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host avviste opplastingen (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host sendte et uventet svar';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Kunne ikke koble til $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Kunne ikke lese filen';

  @override
  String uploadErrorUnknown(String host) {
    return 'Opplasting til $host mislyktes';
  }

  @override
  String get uploadErrorDetails => 'Detaljer';

  @override
  String uploadRetryingWith(String host) {
    return 'Prøver igjen med $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Utløper om $time';
  }

  @override
  String get close => 'Lukk';

  @override
  String get add => 'Legg til';

  @override
  String get cancel => 'Avbryt';

  @override
  String get tokenInput => 'Skriv inn token';

  @override
  String get account => 'Konto';

  @override
  String get refreshAccount => 'Oppdater konto';

  @override
  String get removeAccount => 'Fjern konto';

  @override
  String get addAnotherAccount => 'Legg til en konto til';

  @override
  String get verifiedUserData => 'Brukerdata bekreftet!';

  @override
  String loggedInAs(String user) {
    return 'Logget inn som $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Det oppsto en feil under bekreftelse av brukerdata:';

  @override
  String get verifyingUserData => 'Bekrefter brukerdata...';

  @override
  String get verifiedUserToken => 'Brukertoken bekreftet!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Det oppsto en feil under bekreftelse av brukertoken:';

  @override
  String get verifyingUserToken => 'Bekrefter brukertoken...';

  @override
  String get searchForChannels => 'Søk etter kanaler';

  @override
  String get recommendedChannels => 'Anbefalte kanaler';

  @override
  String get popularChannels => 'Populære kanaler';

  @override
  String get channel => 'Kanal';

  @override
  String get leaveChannel => 'Forlat kanal';

  @override
  String joinUser(String user) {
    return 'Bli med i $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Stavekontrollen mislyktes! Mente du $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Bli med i $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Send melding i $channel';
  }

  @override
  String get light => 'Lyst';

  @override
  String get dark => 'Mørkt';

  @override
  String get system => 'System';

  @override
  String get appearance => 'Utseende';

  @override
  String get highContrast => 'Høy kontrast';

  @override
  String get customCommand => 'Egen kommando';

  @override
  String get customCommands => 'Egne kommandoer';

  @override
  String get newCustomCommand => 'Ny kommando';

  @override
  String get commandTrigger => 'Utløser';

  @override
  String get command => 'Kommando';

  @override
  String get save => 'Lagre';

  @override
  String get openInBrowser => 'Åpne i nettleseren';

  @override
  String get messageAppearance => 'Utseende på meldinger';

  @override
  String get showTimestamps => 'Vis tidsstempler';

  @override
  String get compactMessages => 'Kompakte meldinger';

  @override
  String get showBadges => 'Vis merker';

  @override
  String get messageTrigger => 'Meldingsutløser';

  @override
  String get pattern => 'Mønster';

  @override
  String get mention => 'Omtale';

  @override
  String get block => 'Blokker';

  @override
  String get enableRegex => 'Bruk regex';

  @override
  String get caseSensitive => 'Skill mellom store og små bokstaver';

  @override
  String get messageTriggers => 'Meldingsutløsere';

  @override
  String get newMessageTrigger => 'Ny meldingsutløser';

  @override
  String get reply => 'Svar';

  @override
  String get copyText => 'Kopier tekst';

  @override
  String get copyTextSubtitle =>
      'Hold inne for å kopiere teksten med brukernavn';

  @override
  String get deleteMessage => 'Slett melding';

  @override
  String get mentionUser => 'Nevn bruker';

  @override
  String get copyMessageId => 'Kopier meldings-ID';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Brukerutløser';

  @override
  String get userTriggers => 'Brukerutløsere';

  @override
  String get chatHistory => 'Chattelogg';

  @override
  String get login => 'Brukernavn';

  @override
  String get newUserTrigger => 'Ny brukerutløser';

  @override
  String get ban => 'Utesteng';

  @override
  String get unban => 'Opphev utestengelse';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Gi bruker timeout i $duration';
  }

  @override
  String get chatCleared => 'Chatten ble tømt';

  @override
  String get permabanned => 'permanent utestengt';

  @override
  String bannedForDuration(String duration) {
    return 'utestengt i $duration';
  }

  @override
  String get replyingTo => 'Svarer på';

  @override
  String get blockedMessage => 'Blokkert melding';

  @override
  String get showMessage => 'Vis melding';

  @override
  String get hideMessage => 'Skjul melding';

  @override
  String get scrollToBottom => 'Rull til bunnen';

  @override
  String get appTagline => 'Twitch-chat med emotes fra 7TV, BTTV og FFZ';

  @override
  String get loginWithTwitch => 'Logg inn med Twitch';

  @override
  String get addChannel => 'Legg til kanal';

  @override
  String get chatSettings => 'Chatteinnstillinger';

  @override
  String get autocompleteUsersWithAt => 'Autofullfør brukere med @';

  @override
  String get autocompleteEmotesWithColon => 'Autofullfør emotes med :';

  @override
  String get language => 'Språk';

  @override
  String get locale => 'Region';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get justDefault => 'Standard';

  @override
  String get notifications => 'Varsler';

  @override
  String get noNotifications => 'Noen, et sted, kommer til å nevne deg en dag.';

  @override
  String get backgroundNotifications => 'Varsler i bakgrunnen';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'Dette alternativet er ikke tilgjengelig på plattformen din.';

  @override
  String get optionNotAvailablePaywalled =>
      'Dette alternativet er bare for ColdChat-støttespillere.';

  @override
  String get clearAll => 'Fjern alt';

  @override
  String get cache => 'Hurtigbuffer';

  @override
  String get clearCache => 'Tøm hurtigbuffer';

  @override
  String get chatters => 'Chattere';

  @override
  String lastSeenAgo(String time) {
    return 'Sist sett for $time siden';
  }

  @override
  String get credits => 'Medvirkende';

  @override
  String get search => 'Søk';

  @override
  String get emoteMenuButton => 'Knapp for emote-menyen';

  @override
  String get emoteMenuButtonGrayscale =>
      'Vis knappen for emote-menyen i gråtoner';

  @override
  String get chooseEmoteMenuButton =>
      'Trykk på en emote for å bruke den som knapp for emote-menyen';

  @override
  String get resetToKappa => 'Tilbakestill til Kappa';

  @override
  String get emoteMenuButtonDownloadFailed =>
      'Kunne ikke laste ned den emoten. Knappen ble ikke endret.';

  @override
  String get takePhoto => 'Ta bilde';

  @override
  String get chooseFromLibrary => 'Velg fra biblioteket';

  @override
  String get cameraUnavailable =>
      'Kameraet kunne ikke åpnes. Sjekk at ColdChat har tilgang til kameraet.';

  @override
  String get about => 'Om';

  @override
  String get sourceCode => 'Kildekode';

  @override
  String get license => 'Lisens';

  @override
  String get basedOnChatsen => 'Basert på Chatsen';

  @override
  String get openSourceLicenses => 'Åpen kildekode-lisenser';

  @override
  String get aboutLegalese =>
      'ColdChat er fri programvare: Du kan videredistribuere og endre den under vilkårene i GNU Affero General Public License, versjon 3. Den leveres UTEN NOEN FORM FOR GARANTI.';

  @override
  String get unblock => 'Opphev blokkering';

  @override
  String get report => 'Rapporter';

  @override
  String reportUserTitle(String name) {
    return 'Rapporter $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Rapporter håndteres av Twitch. Åpne kanalen til $name på Twitch og velg Rapporter der. Du kan også blokkere $name her for å skjule meldingene.';
  }

  @override
  String get openOnTwitch => 'Åpne på Twitch';

  @override
  String get blockFailed =>
      'Blokkeringslisten kunne ikke endres. Sjekk tilkoblingen din og prøv igjen.';

  @override
  String get contact => 'Kontakt og tilbakemelding';

  @override
  String get whisper => 'Hvisk';

  @override
  String whisperTo(String name) {
    return 'Hvisk til $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Hviskemelding fra $name';
  }

  @override
  String get openWhisper => 'Åpne';

  @override
  String get userCard => 'Brukerkort';

  @override
  String get closeConversation => 'Lukk samtale';

  @override
  String get closeConversationSubtitle =>
      'Meldingene blir værende på denne enheten og kommer tilbake med neste hviskemelding.';

  @override
  String get deleteConversation => 'Slett samtale';

  @override
  String get deleteConversationSubtitle =>
      'Sletter meldingene fra denne enheten. Twitch lagrer ingen logg over hviskemeldinger.';

  @override
  String get whisperNeedsLogin =>
      'Logg inn med Twitch for å sende hviskemeldinger.';

  @override
  String get whisperNeedsScope =>
      'Logg inn igjen for å sende og motta hviskemeldinger. Innloggingen din er fra før ColdChat støttet dem.';

  @override
  String get whisperUserNotFound =>
      'Det finnes ingen Twitch-bruker med det navnet.';

  @override
  String whisperFailed(String reason) {
    return 'Hviskemeldingen ble ikke sendt: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Hviskemeldinger du får mens ColdChat er lukket, vises ikke her, fordi Twitch ikke deler loggen med apper. Du kan lese dem på Twitch, bak hviske-ikonet øverst til høyre.';

  @override
  String get gotIt => 'Forstått';

  @override
  String get openTwitch => 'Åpne Twitch';

  @override
  String showImage(String host) {
    return 'Vis bilde · $host';
  }

  @override
  String get showImagesFromLinks => 'Vis bilder fra lenker';

  @override
  String get showImagesFromLinksSubtitle =>
      'Twitch sjekker ikke disse bildene. De kan være upassende.';

  @override
  String get showImagesAutomatically => 'Vis bilder fra lenker automatisk?';

  @override
  String get turnOn => 'Slå på';

  @override
  String get themeIndigo => 'Indigo';

  @override
  String get themeBlue => 'Blå';

  @override
  String get themeTeal => 'Petrol';

  @override
  String get themeGreen => 'Grønn';

  @override
  String get themeLime => 'Lime';

  @override
  String get themeAmber => 'Rav';

  @override
  String get themeOrange => 'Oransje';

  @override
  String get themeRed => 'Rød';

  @override
  String get themePink => 'Rosa';

  @override
  String get themePurple => 'Lilla';

  @override
  String get accentColor => 'Aksentfarge';

  @override
  String get oledBlack => 'OLED-svart';

  @override
  String get oledBlackSubtitle =>
      'Svart chatbakgrunn i mørk modus, for OLED-skjermer';

  @override
  String get customColor => 'Egendefinert';

  @override
  String get hue => 'Fargetone';

  @override
  String get saturation => 'Metning';

  @override
  String get themeIce => 'Is';

  @override
  String channelConnecting(String channel) {
    return 'Kobler til $channel …';
  }

  @override
  String channelConnected(String channel) {
    return 'Koblet til $channel';
  }

  @override
  String channelDisconnected(String channel) {
    return 'Frakoblet fra $channel';
  }

  @override
  String channelSuspended(String channel) {
    return '$channel er suspendert av Twitch';
  }

  @override
  String channelBanned(String channel) {
    return 'Du er utestengt fra $channel';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dager',
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
      one: '1 minutt',
    );
    return '$_temp0';
  }
}
