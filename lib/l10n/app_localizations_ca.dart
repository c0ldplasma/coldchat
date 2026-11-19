// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Sessió iniciada amb $provider';
  }

  @override
  String get termsOfService => 'Condicions del servei';

  @override
  String get privacyPolicy => 'Política de privadesa';

  @override
  String get settings => 'Configuració';

  @override
  String get expiresNever => 'No caduca mai';

  @override
  String get loginExpired => 'La sessió ha caducat';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch ha rebutjat l\'inici de sessió de $login. El xat seguirà desconnectat fins que tornis a iniciar la sessió.';
  }

  @override
  String get loginFailed => 'No s\'ha pogut iniciar la sessió';

  @override
  String get signInAgain => 'Inicia la sessió';

  @override
  String uploadingTo(String host) {
    return 'S\'està pujant a $host';
  }

  @override
  String get uploadProcessing => 'S\'està processant…';

  @override
  String get uploadFailed => 'No s\'ha pogut pujar';

  @override
  String get uploadDone => 'Pujat';

  @override
  String get uploadRetry => 'Torna-ho a provar';

  @override
  String get uploadDismiss => 'Descarta';

  @override
  String get uploadCancel => 'Cancel·la la pujada';

  @override
  String get uploadErrorOffline => 'No hi ha connexió a internet';

  @override
  String uploadErrorTimeout(String host) {
    return '$host no respon';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host ha rebutjat la pujada (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host ha enviat una resposta inesperada';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'No s\'ha pogut connectar amb $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'No s\'ha pogut llegir el fitxer';

  @override
  String uploadErrorUnknown(String host) {
    return 'No s\'ha pogut pujar a $host';
  }

  @override
  String get uploadErrorDetails => 'Detalls';

  @override
  String uploadRetryingWith(String host) {
    return 'S\'està tornant a provar amb $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Caduca d\'aquí a $time';
  }

  @override
  String get close => 'Tanca';

  @override
  String get add => 'Afegeix';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get tokenInput => 'Introdueix el token';

  @override
  String get account => 'Compte';

  @override
  String get refreshAccount => 'Actualitza el compte';

  @override
  String get removeAccount => 'Suprimeix el compte';

  @override
  String get addAnotherAccount => 'Afegeix un altre compte';

  @override
  String get verifiedUserData => 'Dades d\'usuari verificades!';

  @override
  String loggedInAs(String user) {
    return 'Sessió iniciada com a $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'S\'ha produït un error en verificar les dades d\'usuari:';

  @override
  String get verifyingUserData => 'S\'estan verificant les dades d\'usuari...';

  @override
  String get verifiedUserToken => 'Token d\'usuari verificat!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'S\'ha produït un error en verificar el token d\'usuari:';

  @override
  String get verifyingUserToken => 'S\'està verificant el token d\'usuari...';

  @override
  String get searchForChannels => 'Cerca canals';

  @override
  String get recommendedChannels => 'Canals recomanats';

  @override
  String get popularChannels => 'Canals populars';

  @override
  String get channel => 'Canal';

  @override
  String get leaveChannel => 'Surt del canal';

  @override
  String joinUser(String user) {
    return 'Entra a $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'T\'has equivocat en escriure? Potser volies cercar $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Entra a $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Envia un missatge a $channel';
  }

  @override
  String get light => 'Clar';

  @override
  String get dark => 'Fosc';

  @override
  String get system => 'Sistema';

  @override
  String get appearance => 'Aparença';

  @override
  String get highContrast => 'Contrast alt';

  @override
  String get customCommand => 'Ordre personalitzada';

  @override
  String get customCommands => 'Ordres personalitzades';

  @override
  String get newCustomCommand => 'Ordre personalitzada nova';

  @override
  String get commandTrigger => 'Activador';

  @override
  String get command => 'Ordre';

  @override
  String get save => 'Desa';

  @override
  String get openInBrowser => 'Obre al navegador';

  @override
  String get messageAppearance => 'Aparença dels missatges';

  @override
  String get showTimestamps => 'Mostra l\'hora';

  @override
  String get compactMessages => 'Missatges compactes';

  @override
  String get showBadges => 'Mostra les insígnies';

  @override
  String get messageTrigger => 'Activador de missatges';

  @override
  String get pattern => 'Patró';

  @override
  String get mention => 'Menció';

  @override
  String get block => 'Bloqueja';

  @override
  String get enableRegex => 'Fes servir regex';

  @override
  String get caseSensitive => 'Distingeix majúscules i minúscules';

  @override
  String get messageTriggers => 'Activadors de missatges';

  @override
  String get newMessageTrigger => 'Activador nou';

  @override
  String get reply => 'Respon';

  @override
  String get copyText => 'Copia el text';

  @override
  String get copyTextSubtitle =>
      'Mantén premut per copiar amb el nom d\'usuari';

  @override
  String get deleteMessage => 'Suprimeix el missatge';

  @override
  String get mentionUser => 'Esmenta l\'usuari';

  @override
  String get copyMessageId => 'Copia l\'ID del missatge';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Activador d\'usuaris';

  @override
  String get userTriggers => 'Activadors d\'usuaris';

  @override
  String get chatHistory => 'Historial del xat';

  @override
  String get login => 'Nom d\'usuari';

  @override
  String get newUserTrigger => 'Activador nou';

  @override
  String get ban => 'Expulsa';

  @override
  String get unban => 'Readmet';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Expulsa l\'usuari durant $duration';
  }

  @override
  String get chatCleared => 'S\'ha esborrat el xat';

  @override
  String get permabanned => 'expulsat permanentment';

  @override
  String bannedForDuration(String duration) {
    return 'expulsat durant $duration';
  }

  @override
  String get replyingTo => 'En resposta a';

  @override
  String get blockedMessage => 'Missatge bloquejat';

  @override
  String get showMessage => 'Mostra el missatge';

  @override
  String get hideMessage => 'Amaga el missatge';

  @override
  String get scrollToBottom => 'Ves al final';

  @override
  String get appTagline => 'Xat de Twitch amb emotes de 7TV, BTTV i FFZ';

  @override
  String get loginWithTwitch => 'Inicia la sessió amb Twitch';

  @override
  String get addChannel => 'Afegeix un canal';

  @override
  String get chatSettings => 'Configuració del xat';

  @override
  String get autocompleteUsersWithAt => 'Completa els usuaris amb @';

  @override
  String get autocompleteEmotesWithColon => 'Completa els emotes amb :';

  @override
  String get language => 'Llengua';

  @override
  String get locale => 'Llengua i regió';

  @override
  String get systemDefault => 'Predeterminat del sistema';

  @override
  String get justDefault => 'Predeterminat';

  @override
  String get notifications => 'Notificacions';

  @override
  String get noNotifications => 'Algú, en algun lloc, t\'esmentarà algun dia.';

  @override
  String get backgroundNotifications => 'Notificacions en segon pla';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'Aquesta opció no està disponible a la teva plataforma.';

  @override
  String get optionNotAvailablePaywalled =>
      'Aquesta opció és només per a qui dona suport a ColdChat.';

  @override
  String get clearAll => 'Esborra-ho tot';

  @override
  String get cache => 'Memòria cau';

  @override
  String get clearCache => 'Buida la memòria cau';

  @override
  String get chatters => 'Usuaris del xat';

  @override
  String lastSeenAgo(String time) {
    return 'Vist per última vegada fa $time';
  }

  @override
  String get credits => 'Crèdits';

  @override
  String get search => 'Cerca';

  @override
  String get emoteMenuButton => 'Botó del menú d\'emotes';

  @override
  String get emoteMenuButtonGrayscale =>
      'Botó del menú d\'emotes en escala de grisos';

  @override
  String get chooseEmoteMenuButton =>
      'Toca un emote per fer-lo servir com a botó del menú d\'emotes';

  @override
  String get resetToKappa => 'Restableix a Kappa';

  @override
  String get emoteMenuButtonDownloadFailed =>
      'No s\'ha pogut baixar aquest emote. El botó no s\'ha canviat.';

  @override
  String get takePhoto => 'Fes una foto';

  @override
  String get chooseFromLibrary => 'Tria de la galeria';

  @override
  String get cameraUnavailable =>
      'No s\'ha pogut obrir la càmera. Comprova que ColdChat hi tingui accés.';

  @override
  String get about => 'Quant a';

  @override
  String get sourceCode => 'Codi font';

  @override
  String get license => 'Llicència';

  @override
  String get basedOnChatsen => 'Basat en Chatsen';

  @override
  String get openSourceLicenses => 'Llicències de codi obert';

  @override
  String get aboutLegalese =>
      'ColdChat és programari lliure: pots redistribuir-lo i modificar-lo d\'acord amb els termes de la GNU Affero General Public License, versió 3. Es distribueix SENSE CAP GARANTIA.';

  @override
  String get unblock => 'Desbloqueja';

  @override
  String get report => 'Denuncia';

  @override
  String reportUserTitle(String name) {
    return 'Denuncia $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Twitch gestiona les denúncies. Obre el canal de $name a Twitch i tria Denuncia allà. També pots bloquejar $name aquí per amagar-ne els missatges.';
  }

  @override
  String get openOnTwitch => 'Obre a Twitch';

  @override
  String get blockFailed =>
      'No s\'ha pogut canviar la llista de bloquejos. Comprova la connexió i torna-ho a provar.';

  @override
  String get contact => 'Contacte i comentaris';

  @override
  String get whisper => 'Xiuxiueja';

  @override
  String whisperTo(String name) {
    return 'Xiuxiueja a $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Xiuxiueig de $name';
  }

  @override
  String get openWhisper => 'Obre';

  @override
  String get userCard => 'Fitxa d\'usuari';

  @override
  String get closeConversation => 'Tanca la conversa';

  @override
  String get closeConversationSubtitle =>
      'Els missatges es queden en aquest dispositiu i tornen amb el proper xiuxiueig.';

  @override
  String get deleteConversation => 'Suprimeix la conversa';

  @override
  String get deleteConversationSubtitle =>
      'Suprimeix els missatges d\'aquest dispositiu. Twitch no desa l\'historial de xiuxiueigs.';

  @override
  String get whisperNeedsLogin =>
      'Inicia la sessió amb Twitch per enviar xiuxiueigs.';

  @override
  String get whisperNeedsScope =>
      'Torna a iniciar la sessió per enviar i rebre xiuxiueigs. La teva sessió és d\'abans que ColdChat els admetés.';

  @override
  String get whisperUserNotFound =>
      'No hi ha cap usuari de Twitch amb aquest nom.';

  @override
  String whisperFailed(String reason) {
    return 'No s\'ha enviat el xiuxiueig: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Els xiuxiueigs que reps mentre ColdChat està tancat no apareixen aquí, perquè Twitch no comparteix l\'historial de xiuxiueigs amb les aplicacions. Els pots llegir a Twitch, darrere la icona de xiuxiueigs a dalt a la dreta.';

  @override
  String get gotIt => 'Entesos';

  @override
  String get openTwitch => 'Obre Twitch';

  @override
  String showImage(String host) {
    return 'Mostra la imatge · $host';
  }

  @override
  String get showImagesFromLinks => 'Mostra les imatges dels enllaços';

  @override
  String get showImagesFromLinksSubtitle =>
      'Twitch no revisa aquestes imatges. Poden ser inadequades.';

  @override
  String get showImagesAutomatically =>
      'Vols mostrar automàticament les imatges dels enllaços?';

  @override
  String get turnOn => 'Activa';

  @override
  String get themeIndigo => 'Índigo';

  @override
  String get themeBlue => 'Blau';

  @override
  String get themeTeal => 'Verd blavós';

  @override
  String get themeGreen => 'Verd';

  @override
  String get themeLime => 'Llima';

  @override
  String get themeAmber => 'Ambre';

  @override
  String get themeOrange => 'Taronja';

  @override
  String get themeRed => 'Vermell';

  @override
  String get themePink => 'Rosa';

  @override
  String get themePurple => 'Porpra';

  @override
  String get accentColor => 'Color d\'accent';

  @override
  String get oledBlack => 'Negre OLED';

  @override
  String get oledBlackSubtitle =>
      'Fons del xat negre en mode fosc, per a pantalles OLED';

  @override
  String get customColor => 'Personalitzat';

  @override
  String get hue => 'To';

  @override
  String get saturation => 'Saturació';

  @override
  String get themeIce => 'Gel';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dies',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hores',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuts',
      one: '1 minut',
    );
    return '$_temp0';
  }
}
