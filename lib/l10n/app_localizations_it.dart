// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Accesso tramite $provider';
  }

  @override
  String get termsOfService => 'Termini di servizio';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get settings => 'Impostazioni';

  @override
  String get expiresNever => 'Non scade mai';

  @override
  String get loginExpired => 'Accesso scaduto';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch ha rifiutato l\'accesso di $login. La chat resta disconnessa finché non accedi di nuovo.';
  }

  @override
  String get loginFailed => 'Accesso non riuscito';

  @override
  String get signInAgain => 'Accedi';

  @override
  String uploadingTo(String host) {
    return 'Caricamento su $host';
  }

  @override
  String get uploadProcessing => 'Elaborazione…';

  @override
  String get uploadFailed => 'Caricamento non riuscito';

  @override
  String get uploadDone => 'Caricato';

  @override
  String get uploadRetry => 'Riprova';

  @override
  String get uploadDismiss => 'Ignora';

  @override
  String get uploadCancel => 'Annulla caricamento';

  @override
  String get uploadErrorOffline => 'Nessuna connessione a Internet';

  @override
  String uploadErrorTimeout(String host) {
    return '$host non risponde';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host ha rifiutato il caricamento (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host ha inviato una risposta inattesa';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Impossibile connettersi a $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Impossibile leggere il file';

  @override
  String uploadErrorUnknown(String host) {
    return 'Caricamento su $host non riuscito';
  }

  @override
  String get uploadErrorDetails => 'Dettagli';

  @override
  String uploadRetryingWith(String host) {
    return 'Nuovo tentativo con $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Scade tra $time';
  }

  @override
  String get close => 'Chiudi';

  @override
  String get add => 'Aggiungi';

  @override
  String get cancel => 'Annulla';

  @override
  String get tokenInput => 'Inserisci token';

  @override
  String get account => 'Account';

  @override
  String get refreshAccount => 'Aggiorna account';

  @override
  String get removeAccount => 'Rimuovi account';

  @override
  String get addAnotherAccount => 'Aggiungi un altro account';

  @override
  String get verifiedUserData => 'Dati utente verificati!';

  @override
  String loggedInAs(String user) {
    return 'Accesso effettuato come $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => 'Si è verificato un errore durante la verifica dei dati utente:';

  @override
  String get verifyingUserData => 'Verifica dei dati utente...';

  @override
  String get verifiedUserToken => 'Token utente verificato!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Si è verificato un errore durante la verifica del token utente:';

  @override
  String get verifyingUserToken => 'Verifica del token utente...';

  @override
  String get searchForChannels => 'Cerca canali';

  @override
  String get channelSearchFailed => 'Impossibile cercare i canali';

  @override
  String get recommendedChannels => 'Canali consigliati';

  @override
  String get popularChannels => 'Canali popolari';

  @override
  String get channel => 'Canale';

  @override
  String get leaveChannel => 'Esci dal canale';

  @override
  String joinUser(String user) {
    return 'Entra in $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Errore di battitura? Forse volevi cercare $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Entra in $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Invia un messaggio in $channel';
  }

  @override
  String get light => 'Chiaro';

  @override
  String get dark => 'Scuro';

  @override
  String get system => 'Sistema';

  @override
  String get appearance => 'Aspetto';

  @override
  String get highContrast => 'Contrasto elevato';

  @override
  String get customCommand => 'Comando personalizzato';

  @override
  String get customCommands => 'Comandi personalizzati';

  @override
  String get newCustomCommand => 'Nuovo comando personalizzato';

  @override
  String get commandTrigger => 'Attivatore';

  @override
  String get command => 'Comando';

  @override
  String get save => 'Salva';

  @override
  String get openInBrowser => 'Apri nel browser';

  @override
  String get messageAppearance => 'Aspetto dei messaggi';

  @override
  String get showTimestamps => 'Mostra orario';

  @override
  String get compactMessages => 'Messaggi compatti';

  @override
  String get showBadges => 'Mostra badge';

  @override
  String get messageTrigger => 'Attivatore messaggio';

  @override
  String get pattern => 'Modello';

  @override
  String get mention => 'Menzione';

  @override
  String get block => 'Blocca';

  @override
  String get enableRegex => 'Usa regex';

  @override
  String get invalidRegex => 'Regex non valida';

  @override
  String get caseSensitive => 'Distingui maiuscole/minuscole';

  @override
  String get messageTriggers => 'Attivatori messaggio';

  @override
  String get newMessageTrigger => 'Nuovo attivatore';

  @override
  String get reply => 'Rispondi';

  @override
  String get copyText => 'Copia testo';

  @override
  String get copyTextSubtitle => 'Tieni premuto per copiare con il nome utente';

  @override
  String get deleteMessage => 'Elimina messaggio';

  @override
  String deleteMessageFailed(String reason) {
    return 'Messaggio non eliminato: $reason';
  }

  @override
  String get deleteMessageNeedsScope =>
      'Accedi di nuovo per eliminare i messaggi. Il tuo accesso risale a prima che ColdChat potesse farlo.';

  @override
  String get mentionUser => 'Menziona utente';

  @override
  String get copyMessageId => 'Copia ID messaggio';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Attivatore utente';

  @override
  String get userTriggers => 'Attivatori utente';

  @override
  String get chatHistory => 'Cronologia chat';

  @override
  String get login => 'Nome utente';

  @override
  String get newUserTrigger => 'Nuovo attivatore';

  @override
  String get ban => 'Banna';

  @override
  String get unban => 'Sbanna';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Banna l\'utente per $duration';
  }

  @override
  String get chatCleared => 'La chat è stata cancellata';

  @override
  String get permabanned => 'bannato permanentemente';

  @override
  String bannedForDuration(String duration) {
    return 'bannato per $duration';
  }

  @override
  String get replyingTo => 'In risposta a';

  @override
  String get blockedMessage => 'Messaggio bloccato';

  @override
  String get showMessage => 'Mostra messaggio';

  @override
  String get hideMessage => 'Nascondi messaggio';

  @override
  String get scrollToBottom => 'Vai in fondo';

  @override
  String get appTagline => 'La chat di Twitch con le emote di 7TV, BTTV e FFZ';

  @override
  String get continueWithoutLogin => 'Continua senza accedere';

  @override
  String get logInForSearch => 'Accedi per vedere i risultati di ricerca e i canali popolari in diretta';

  @override
  String get loginWithTwitch => 'Accedi con Twitch';

  @override
  String get addChannel => 'Aggiungi canale';

  @override
  String get chatSettings => 'Impostazioni chat';

  @override
  String get autocompleteUsersWithAt => 'Completa i nomi utente con @';

  @override
  String get autocompleteEmotesWithColon => 'Completa le emote con :';

  @override
  String get language => 'Lingua';

  @override
  String get locale => 'Lingua e area geografica';

  @override
  String get systemDefault => 'Predefinita di sistema';

  @override
  String get justDefault => 'Predefinita';

  @override
  String get notifications => 'Notifiche';

  @override
  String get noNotifications => 'Qualcuno, da qualche parte, prima o poi ti menzionerà.';

  @override
  String get backgroundNotifications => 'Notifiche in background';

  @override
  String get optionNotAvailableOnYourPlatform => 'Questa opzione non è disponibile sulla tua piattaforma.';

  @override
  String get optionNotAvailablePaywalled => 'Questa opzione è riservata a chi sostiene ColdChat.';

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String get cache => 'Cache';

  @override
  String get clearCache => 'Svuota cache';

  @override
  String get emoteCache => 'Cache delle emote';

  @override
  String emoteCacheUsage(String used, String limit) {
    return '$used su $limit';
  }

  @override
  String megabytes(String size) {
    return '$size MB';
  }

  @override
  String get chatters => 'Utenti in chat';

  @override
  String lastSeenAgo(String time) {
    return 'Visto $time fa';
  }

  @override
  String get credits => 'Riconoscimenti';

  @override
  String get search => 'Cerca';

  @override
  String get emoteMenuButton => 'Pulsante del menu emote';

  @override
  String get emoteMenuButtonGrayscale => 'Pulsante del menu emote in scala di grigi';

  @override
  String get chooseEmoteMenuButton => 'Tocca un\'emote per usarla come pulsante del menu emote';

  @override
  String get resetToKappa => 'Ripristina Kappa';

  @override
  String get emoteMenuButtonDownloadFailed => 'Impossibile scaricare l\'emote. Il pulsante non è stato cambiato.';

  @override
  String get takePhoto => 'Scatta foto';

  @override
  String get chooseFromLibrary => 'Scegli dalla libreria';

  @override
  String get cameraUnavailable =>
      'Impossibile aprire la fotocamera. Controlla che ColdChat abbia accesso alla fotocamera.';

  @override
  String get about => 'Informazioni';

  @override
  String get sourceCode => 'Codice sorgente';

  @override
  String get license => 'Licenza';

  @override
  String get basedOnChatsen => 'Basato su Chatsen';

  @override
  String get openSourceLicenses => 'Licenze open source';

  @override
  String get aboutLegalese =>
      'ColdChat è software libero: puoi ridistribuirlo e modificarlo secondo i termini della GNU Affero General Public License, versione 3. Viene fornito SENZA ALCUNA GARANZIA.';

  @override
  String get unblock => 'Sblocca';

  @override
  String get report => 'Segnala';

  @override
  String reportUserTitle(String name) {
    return 'Segnala $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Le segnalazioni sono gestite da Twitch. Apri il canale di $name su Twitch e scegli Segnala. Puoi anche bloccare $name qui per nasconderne i messaggi.';
  }

  @override
  String get openOnTwitch => 'Apri su Twitch';

  @override
  String get blockFailed => 'Impossibile modificare la lista dei blocchi. Controlla la connessione e riprova.';

  @override
  String get moderationNeedsLogin => 'Accedi con Twitch per moderare questo canale.';

  @override
  String get moderationNeedsScope =>
      'Accedi di nuovo per bannare e silenziare temporaneamente gli utenti. Il tuo accesso risale a prima che ColdChat lo permettesse.';

  @override
  String moderationFailed(String reason) {
    return 'Non ha funzionato: $reason';
  }

  @override
  String get contact => 'Contatti e feedback';

  @override
  String get whisper => 'Sussurra';

  @override
  String whisperTo(String name) {
    return 'Sussurra a $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Sussurro da $name';
  }

  @override
  String get openWhisper => 'Apri';

  @override
  String get userCard => 'Scheda utente';

  @override
  String get closeConversation => 'Chiudi conversazione';

  @override
  String get closeConversationSubtitle =>
      'I messaggi restano su questo dispositivo e ricompaiono con il prossimo sussurro.';

  @override
  String get deleteConversation => 'Elimina conversazione';

  @override
  String get deleteConversationSubtitle =>
      'Elimina i messaggi da questo dispositivo. Twitch non conserva la cronologia dei sussurri.';

  @override
  String get logInToChat => 'Accedi per chattare';

  @override
  String get logInToSeeMore => 'Accedi per vedere di più';

  @override
  String get uploadNeedsLogin => 'Accedi per condividere foto in chat';

  @override
  String get whisperNeedsLogin => 'Accedi con Twitch per inviare sussurri.';

  @override
  String get whisperNeedsScope =>
      'Accedi di nuovo per inviare e ricevere sussurri. Il tuo accesso risale a prima che ColdChat li supportasse.';

  @override
  String get whisperUserNotFound => 'Non esiste nessun utente Twitch con questo nome.';

  @override
  String get messageNotSentNotConnected =>
      'Non sei ancora connesso a questo canale. Il tuo messaggio non è stato inviato.';

  @override
  String whisperFailed(String reason) {
    return 'Sussurro non inviato: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'I sussurri ricevuti mentre ColdChat era chiusa non compaiono qui, perché Twitch non condivide la cronologia dei sussurri con le app. Puoi leggerli su Twitch, dietro l\'icona dei sussurri in alto a destra.';

  @override
  String get gotIt => 'Ho capito';

  @override
  String get openTwitch => 'Apri Twitch';

  @override
  String showImage(String host) {
    return 'Mostra immagine · $host';
  }

  @override
  String get showImagesFromLinks => 'Mostra immagini dai link';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch non controlla queste immagini. Potrebbero essere inappropriate.';

  @override
  String get showImagesAutomatically => 'Mostrare automaticamente le immagini dai link?';

  @override
  String get turnOn => 'Attiva';

  @override
  String get themeIndigo => 'Indaco';

  @override
  String get themeBlue => 'Blu';

  @override
  String get themeTeal => 'Verde acqua';

  @override
  String get themeGreen => 'Verde';

  @override
  String get themeLime => 'Lime';

  @override
  String get themeAmber => 'Ambra';

  @override
  String get themeOrange => 'Arancione';

  @override
  String get themeRed => 'Rosso';

  @override
  String get themePink => 'Rosa';

  @override
  String get themePurple => 'Viola';

  @override
  String get accentColor => 'Colore d\'accento';

  @override
  String get oledBlack => 'Nero OLED';

  @override
  String get oledBlackSubtitle => 'Sfondo della chat nero in modalità scura, per schermi OLED';

  @override
  String get customColor => 'Personalizzato';

  @override
  String get hue => 'Tonalità';

  @override
  String get saturation => 'Saturazione';

  @override
  String get themeIce => 'Ghiaccio';

  @override
  String channelConnecting(String channel) {
    return 'Connessione a $channel…';
  }

  @override
  String channelConnected(String channel) {
    return 'Connesso a $channel';
  }

  @override
  String channelDisconnected(String channel) {
    return 'Disconnesso da $channel';
  }

  @override
  String channelSuspended(String channel) {
    return '$channel è stato sospeso da Twitch';
  }

  @override
  String channelBanned(String channel) {
    return 'Sei bannato da $channel';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore',
      one: '1 ora',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String durationDaysShort(int count) {
    return '$count g';
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

  @override
  String get watchOnTwitch => 'Guarda su Twitch';
}
