// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Prijavljeno putem $provider';
  }

  @override
  String get termsOfService => 'Uvjeti korištenja';

  @override
  String get privacyPolicy => 'Pravila privatnosti';

  @override
  String get settings => 'Postavke';

  @override
  String get expiresNever => 'Nikad ne istječe';

  @override
  String get loginExpired => 'Prijava je istekla';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch je odbio prijavu za $login. Chat ostaje odspojen dok se ponovno ne prijaviš.';
  }

  @override
  String get loginFailed => 'Prijava nije uspjela';

  @override
  String get signInAgain => 'Prijavi se';

  @override
  String uploadingTo(String host) {
    return 'Prijenos na $host';
  }

  @override
  String get uploadProcessing => 'Obrada…';

  @override
  String get uploadFailed => 'Prijenos nije uspio';

  @override
  String get uploadDone => 'Preneseno';

  @override
  String get uploadRetry => 'Pokušaj ponovno';

  @override
  String get uploadDismiss => 'Odbaci';

  @override
  String get uploadCancel => 'Otkaži prijenos';

  @override
  String get uploadErrorOffline => 'Nema internetske veze';

  @override
  String uploadErrorTimeout(String host) {
    return '$host ne odgovara';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return 'Poslužitelj $host odbio je prijenos (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return 'Poslužitelj $host poslao je neočekivan odgovor';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Povezivanje s $host nije uspjelo';
  }

  @override
  String get uploadErrorUnreadableFile => 'Datoteku nije moguće pročitati';

  @override
  String uploadErrorUnknown(String host) {
    return 'Prijenos na $host nije uspio';
  }

  @override
  String get uploadErrorDetails => 'Pojedinosti';

  @override
  String uploadRetryingWith(String host) {
    return 'Novi pokušaj preko $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Istječe za $time';
  }

  @override
  String get close => 'Zatvori';

  @override
  String get add => 'Dodaj';

  @override
  String get cancel => 'Odustani';

  @override
  String get tokenInput => 'Unos tokena';

  @override
  String get account => 'Račun';

  @override
  String get refreshAccount => 'Osvježi račun';

  @override
  String get removeAccount => 'Ukloni račun';

  @override
  String get addAnotherAccount => 'Dodaj još jedan račun';

  @override
  String get verifiedUserData => 'Korisnički podaci provjereni!';

  @override
  String loggedInAs(String user) {
    return 'Prijavljeno kao $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => 'Došlo je do pogreške pri provjeri korisničkih podataka:';

  @override
  String get verifyingUserData => 'Provjera korisničkih podataka...';

  @override
  String get verifiedUserToken => 'Korisnički token provjeren!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken => 'Došlo je do pogreške pri provjeri korisničkog tokena:';

  @override
  String get verifyingUserToken => 'Provjera korisničkog tokena...';

  @override
  String get searchForChannels => 'Pretraži kanale';

  @override
  String get channelSearchFailed => 'Pretraživanje kanala nije uspjelo';

  @override
  String get recommendedChannels => 'Preporučeni kanali';

  @override
  String get popularChannels => 'Popularni kanali';

  @override
  String get channel => 'Kanal';

  @override
  String get leaveChannel => 'Napusti kanal';

  @override
  String joinUser(String user) {
    return 'Pridruži se kanalu $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Provjera pravopisa nije uspjela! Tražiš li $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Pridruži se kanalu $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Pošalji poruku u $channel';
  }

  @override
  String get light => 'Svijetla';

  @override
  String get dark => 'Tamna';

  @override
  String get system => 'Prema sustavu';

  @override
  String get appearance => 'Izgled';

  @override
  String get highContrast => 'Visoki kontrast';

  @override
  String get customCommand => 'Prilagođena naredba';

  @override
  String get customCommands => 'Prilagođene naredbe';

  @override
  String get newCustomCommand => 'Nova prilagođena naredba';

  @override
  String get commandTrigger => 'Okidač';

  @override
  String get command => 'Naredba';

  @override
  String get save => 'Spremi';

  @override
  String get openInBrowser => 'Otvori u pregledniku';

  @override
  String get messageAppearance => 'Izgled poruka';

  @override
  String get showTimestamps => 'Prikaži vrijeme';

  @override
  String get compactMessages => 'Kompaktne poruke';

  @override
  String get showBadges => 'Prikaži značke';

  @override
  String get messageTrigger => 'Okidač poruka';

  @override
  String get pattern => 'Uzorak';

  @override
  String get mention => 'Spominjanje';

  @override
  String get block => 'Blokiraj';

  @override
  String get enableRegex => 'Uključi regex';

  @override
  String get invalidRegex => 'Neispravan regex';

  @override
  String get caseSensitive => 'Razlikuj velika i mala slova';

  @override
  String get messageTriggers => 'Okidači poruka';

  @override
  String get newMessageTrigger => 'Novi okidač poruka';

  @override
  String get reply => 'Odgovori';

  @override
  String get copyText => 'Kopiraj tekst';

  @override
  String get copyTextSubtitle => 'Zadrži za kopiranje teksta s korisničkim imenom';

  @override
  String get deleteMessage => 'Izbriši poruku';

  @override
  String deleteMessageFailed(String reason) {
    return 'Poruka nije izbrisana: $reason';
  }

  @override
  String get deleteMessageNeedsScope =>
      'Prijavi se ponovno za brisanje poruka. Tvoja prijava je iz vremena prije nego što je ColdChat to mogao.';

  @override
  String get mentionUser => 'Spomeni korisnika';

  @override
  String get copyMessageId => 'Kopiraj ID poruke';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Okidač korisnika';

  @override
  String get userTriggers => 'Okidači korisnika';

  @override
  String get chatHistory => 'Povijest chata';

  @override
  String get login => 'Korisničko ime';

  @override
  String get newUserTrigger => 'Novi okidač korisnika';

  @override
  String get ban => 'Banaj';

  @override
  String get unban => 'Odbanaj';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Daj timeout na $duration';
  }

  @override
  String get chatCleared => 'Chat je očišćen';

  @override
  String get permabanned => 'dobiva trajni ban';

  @override
  String bannedForDuration(String duration) {
    return 'dobiva ban na $duration';
  }

  @override
  String get replyingTo => 'Odgovor na';

  @override
  String get blockedMessage => 'Blokirana poruka';

  @override
  String get showMessage => 'Prikaži poruku';

  @override
  String get hideMessage => 'Sakrij poruku';

  @override
  String get scrollToBottom => 'Skoči na dno';

  @override
  String get appTagline => 'Twitch chat s emotikonima iz 7TV-a, BTTV-a i FFZ-a';

  @override
  String get continueWithoutLogin => 'Nastavi bez prijave';

  @override
  String get logInForSearch => 'Prijavi se za rezultate pretraživanja i popularne kanale uživo';

  @override
  String get loginWithTwitch => 'Prijavi se putem Twitcha';

  @override
  String get addChannel => 'Dodaj kanal';

  @override
  String get chatSettings => 'Postavke chata';

  @override
  String get autocompleteUsersWithAt => 'Dovršavanje korisnika s @';

  @override
  String get autocompleteEmotesWithColon => 'Dovršavanje emotikona s :';

  @override
  String get language => 'Jezik';

  @override
  String get locale => 'Jezik i regija';

  @override
  String get systemDefault => 'Zadano sustavom';

  @override
  String get justDefault => 'Zadano';

  @override
  String get notifications => 'Obavijesti';

  @override
  String get noNotifications => 'Netko, negdje, jednog će te dana spomenuti.';

  @override
  String get backgroundNotifications => 'Obavijesti u pozadini';

  @override
  String get optionNotAvailableOnYourPlatform => 'Ova opcija nije dostupna na tvojoj platformi.';

  @override
  String get optionNotAvailablePaywalled => 'Ova je opcija samo za one koji podržavaju ColdChat.';

  @override
  String get clearAll => 'Očisti sve';

  @override
  String get cache => 'Predmemorija';

  @override
  String get clearCache => 'Očisti predmemoriju';

  @override
  String get emoteCache => 'Predmemorija emotea';

  @override
  String emoteCacheUsage(String used, String limit) {
    return '$used od $limit';
  }

  @override
  String megabytes(String size) {
    return '$size MB';
  }

  @override
  String get chatters => 'Sudionici chata';

  @override
  String lastSeenAgo(String time) {
    return 'Zadnja aktivnost prije $time';
  }

  @override
  String get credits => 'Zasluge';

  @override
  String get search => 'Traži';

  @override
  String get emoteMenuButton => 'Gumb izbornika emotikona';

  @override
  String get emoteMenuButtonGrayscale => 'Gumb izbornika emotikona u sivim tonovima';

  @override
  String get chooseEmoteMenuButton => 'Dodirni emotikon koji želiš kao gumb izbornika emotikona';

  @override
  String get resetToKappa => 'Vrati na Kappa';

  @override
  String get emoteMenuButtonDownloadFailed => 'Preuzimanje emotikona nije uspjelo. Gumb nije promijenjen.';

  @override
  String get takePhoto => 'Snimi fotografiju';

  @override
  String get chooseFromLibrary => 'Odaberi iz galerije';

  @override
  String get cameraUnavailable => 'Kamera se nije mogla otvoriti. Provjeri ima li ColdChat pristup kameri.';

  @override
  String get about => 'O aplikaciji';

  @override
  String get sourceCode => 'Izvorni kôd';

  @override
  String get license => 'Licenca';

  @override
  String get basedOnChatsen => 'Temeljeno na Chatsenu';

  @override
  String get openSourceLicenses => 'Licence otvorenog koda';

  @override
  String get aboutLegalese =>
      'ColdChat je slobodan softver: možeš ga dijeliti i mijenjati pod uvjetima licence GNU Affero General Public License, verzija 3. Dolazi APSOLUTNO BEZ IKAKVOG JAMSTVA.';

  @override
  String get unblock => 'Deblokiraj';

  @override
  String get report => 'Prijavi';

  @override
  String reportUserTitle(String name) {
    return 'Prijavi $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Prijave obrađuje Twitch. Otvori kanal $name na Twitchu i ondje odaberi Prijavi. $name možeš blokirati i ovdje pa ti se poruke više neće prikazivati.';
  }

  @override
  String get openOnTwitch => 'Otvori na Twitchu';

  @override
  String get blockFailed => 'Popis blokiranih nije moguće promijeniti. Provjeri vezu i pokušaj ponovno.';

  @override
  String get moderationNeedsLogin => 'Prijavi se putem Twitcha za moderiranje ovog kanala.';

  @override
  String get moderationNeedsScope =>
      'Prijavi se ponovno za banove i timeoute korisnika. Tvoja prijava je starija od te mogućnosti u ColdChatu.';

  @override
  String moderationFailed(String reason) {
    return 'Nije uspjelo: $reason';
  }

  @override
  String get contact => 'Kontakt i povratne informacije';

  @override
  String get whisper => 'Šapni';

  @override
  String whisperTo(String name) {
    return 'Šapni $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Šapat od $name';
  }

  @override
  String get openWhisper => 'Otvori';

  @override
  String get userCard => 'Korisnička kartica';

  @override
  String get closeConversation => 'Zatvori razgovor';

  @override
  String get closeConversationSubtitle => 'Poruke ostaju na ovom uređaju i vraćaju se sa sljedećim šapatom.';

  @override
  String get deleteConversation => 'Izbriši razgovor';

  @override
  String get deleteConversationSubtitle => 'Briše poruke s ovog uređaja. Twitch ne čuva povijest šapata.';

  @override
  String get whisperNeedsLogin => 'Prijavi se na Twitch za slanje šapata.';

  @override
  String get whisperNeedsScope =>
      'Ponovno se prijavi za slanje i primanje šapata. Tvoja prijava potječe iz vremena prije nego što ih je ColdChat podržavao.';

  @override
  String get whisperUserNotFound => 'Ne postoji Twitch korisnik s tim imenom.';

  @override
  String get messageNotSentNotConnected => 'Još nisi povezan s ovim kanalom. Tvoja poruka nije poslana.';

  @override
  String whisperFailed(String reason) {
    return 'Šapat nije poslan: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Šapati koje primiš dok je ColdChat zatvoren ne prikazuju se ovdje jer Twitch ne dijeli povijest šapata s aplikacijama. Možeš ih pročitati na Twitchu, iza ikone šapata gore desno.';

  @override
  String get gotIt => 'Razumijem';

  @override
  String get openTwitch => 'Otvori Twitch';

  @override
  String showImage(String host) {
    return 'Prikaži sliku · $host';
  }

  @override
  String get showImagesFromLinks => 'Prikaži slike iz poveznica';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch ne provjerava te slike. Mogu biti neprikladne.';

  @override
  String get showImagesAutomatically => 'Automatski prikazivati slike iz poveznica?';

  @override
  String get turnOn => 'Uključi';

  @override
  String get themeIndigo => 'Indigo';

  @override
  String get themeBlue => 'Plava';

  @override
  String get themeTeal => 'Petrolej';

  @override
  String get themeGreen => 'Zelena';

  @override
  String get themeLime => 'Limeta';

  @override
  String get themeAmber => 'Jantar';

  @override
  String get themeOrange => 'Narančasta';

  @override
  String get themeRed => 'Crvena';

  @override
  String get themePink => 'Ružičasta';

  @override
  String get themePurple => 'Ljubičasta';

  @override
  String get accentColor => 'Boja naglaska';

  @override
  String get oledBlack => 'OLED crna';

  @override
  String get oledBlackSubtitle => 'Crna pozadina chata u tamnom načinu, za OLED zaslone';

  @override
  String get customColor => 'Prilagođeno';

  @override
  String get hue => 'Nijansa';

  @override
  String get saturation => 'Zasićenost';

  @override
  String get themeIce => 'Led';

  @override
  String channelConnecting(String channel) {
    return 'Povezivanje s $channel…';
  }

  @override
  String channelConnected(String channel) {
    return 'Povezano s $channel';
  }

  @override
  String channelDisconnected(String channel) {
    return 'Veza s $channel prekinuta';
  }

  @override
  String channelSuspended(String channel) {
    return 'Twitch je suspendirao $channel';
  }

  @override
  String channelBanned(String channel) {
    return 'Imaš ban na $channel';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dana',
      one: '$count dan',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sati',
      few: '$count sata',
      one: '$count sat',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuta',
      few: '$count minute',
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
