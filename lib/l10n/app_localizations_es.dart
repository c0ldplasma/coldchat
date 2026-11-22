// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Sesión iniciada con $provider';
  }

  @override
  String get termsOfService => 'Términos del servicio';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get settings => 'Ajustes';

  @override
  String get expiresNever => 'No caduca nunca';

  @override
  String get loginExpired => 'Sesión caducada';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch ha rechazado el inicio de sesión de $login. El chat seguirá desconectado hasta que vuelvas a iniciar sesión.';
  }

  @override
  String get loginFailed => 'Error al iniciar sesión';

  @override
  String get signInAgain => 'Iniciar sesión';

  @override
  String uploadingTo(String host) {
    return 'Subiendo a $host';
  }

  @override
  String get uploadProcessing => 'Procesando…';

  @override
  String get uploadFailed => 'Error al subir';

  @override
  String get uploadDone => 'Subido';

  @override
  String get uploadRetry => 'Reintentar';

  @override
  String get uploadDismiss => 'Descartar';

  @override
  String get uploadCancel => 'Cancelar subida';

  @override
  String get uploadErrorOffline => 'Sin conexión a internet';

  @override
  String uploadErrorTimeout(String host) {
    return '$host no responde';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host ha rechazado la subida (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host ha enviado una respuesta inesperada';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'No se ha podido conectar con $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'No se ha podido leer el archivo';

  @override
  String uploadErrorUnknown(String host) {
    return 'Error al subir a $host';
  }

  @override
  String get uploadErrorDetails => 'Detalles';

  @override
  String uploadRetryingWith(String host) {
    return 'Reintentando con $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Caduca en $time';
  }

  @override
  String get close => 'Cerrar';

  @override
  String get add => 'Añadir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get tokenInput => 'Introducir token';

  @override
  String get account => 'Cuenta';

  @override
  String get refreshAccount => 'Actualizar cuenta';

  @override
  String get removeAccount => 'Eliminar cuenta';

  @override
  String get addAnotherAccount => 'Añadir otra cuenta';

  @override
  String get verifiedUserData => '¡Datos de usuario verificados!';

  @override
  String loggedInAs(String user) {
    return 'Sesión iniciada como $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => 'Se ha producido un error al verificar los datos de usuario:';

  @override
  String get verifyingUserData => 'Verificando datos de usuario...';

  @override
  String get verifiedUserToken => '¡Token de usuario verificado!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken => 'Se ha producido un error al verificar el token de usuario:';

  @override
  String get verifyingUserToken => 'Verificando token de usuario...';

  @override
  String get searchForChannels => 'Buscar canales';

  @override
  String get channelSearchFailed => 'No se pudieron buscar canales';

  @override
  String get recommendedChannels => 'Canales recomendados';

  @override
  String get popularChannels => 'Canales populares';

  @override
  String get channel => 'Canal';

  @override
  String get leaveChannel => 'Salir del canal';

  @override
  String joinUser(String user) {
    return 'Unirse a $user';
  }

  @override
  String spellCheckFailed(String username) {
    return '¿Error al escribir? ¿Quizás querías buscar $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Unirse a $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Enviar mensaje en $channel';
  }

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get appearance => 'Apariencia';

  @override
  String get highContrast => 'Alto contraste';

  @override
  String get customCommand => 'Comando personalizado';

  @override
  String get customCommands => 'Comandos personalizados';

  @override
  String get newCustomCommand => 'Nuevo comando personalizado';

  @override
  String get commandTrigger => 'Activador';

  @override
  String get command => 'Comando';

  @override
  String get save => 'Guardar';

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String get messageAppearance => 'Apariencia de los mensajes';

  @override
  String get showTimestamps => 'Mostrar hora';

  @override
  String get compactMessages => 'Mensajes compactos';

  @override
  String get showBadges => 'Mostrar insignias';

  @override
  String get messageTrigger => 'Activador de mensaje';

  @override
  String get pattern => 'Patrón';

  @override
  String get mention => 'Mención';

  @override
  String get block => 'Bloquear';

  @override
  String get enableRegex => 'Usar regex';

  @override
  String get invalidRegex => 'No es un regex válido';

  @override
  String get caseSensitive => 'Distinguir mayúsculas y minúsculas';

  @override
  String get messageTriggers => 'Activadores de mensajes';

  @override
  String get newMessageTrigger => 'Nuevo activador';

  @override
  String get reply => 'Responder';

  @override
  String get copyText => 'Copiar texto';

  @override
  String get copyTextSubtitle => 'Mantén pulsado para copiar con el nombre de usuario';

  @override
  String get deleteMessage => 'Eliminar mensaje';

  @override
  String deleteMessageFailed(String reason) {
    return 'No se ha eliminado el mensaje: $reason';
  }

  @override
  String get deleteMessageNeedsScope =>
      'Vuelve a iniciar sesión para eliminar mensajes. Tu sesión es de antes de que ColdChat pudiera hacerlo.';

  @override
  String get mentionUser => 'Mencionar usuario';

  @override
  String get copyMessageId => 'Copiar ID del mensaje';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Activador de usuario';

  @override
  String get userTriggers => 'Activadores de usuarios';

  @override
  String get chatHistory => 'Historial del chat';

  @override
  String get login => 'Usuario';

  @override
  String get newUserTrigger => 'Nuevo activador';

  @override
  String get ban => 'Expulsar';

  @override
  String get unban => 'Readmitir';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Expulsar al usuario durante $duration';
  }

  @override
  String get chatCleared => 'Se ha borrado el chat';

  @override
  String get permabanned => 'expulsado permanentemente';

  @override
  String bannedForDuration(String duration) {
    return 'expulsado durante $duration';
  }

  @override
  String get replyingTo => 'Respondiendo a';

  @override
  String get blockedMessage => 'Mensaje bloqueado';

  @override
  String get showMessage => 'Mostrar mensaje';

  @override
  String get hideMessage => 'Ocultar mensaje';

  @override
  String get scrollToBottom => 'Ir al final';

  @override
  String get appTagline => 'Chat de Twitch con emotes de 7TV, BTTV y FFZ';

  @override
  String get loginWithTwitch => 'Iniciar sesión con Twitch';

  @override
  String get addChannel => 'Añadir canal';

  @override
  String get chatSettings => 'Ajustes del chat';

  @override
  String get autocompleteUsersWithAt => 'Autocompletar usuarios con @';

  @override
  String get autocompleteEmotesWithColon => 'Autocompletar emotes con :';

  @override
  String get language => 'Idioma';

  @override
  String get locale => 'Idioma y región';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get justDefault => 'Predeterminado';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get noNotifications => 'Alguien, en algún lugar, te mencionará algún día.';

  @override
  String get backgroundNotifications => 'Notificaciones en segundo plano';

  @override
  String get optionNotAvailableOnYourPlatform => 'Esta opción no está disponible en tu plataforma.';

  @override
  String get optionNotAvailablePaywalled => 'Esta opción es solo para quienes apoyan ColdChat.';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get cache => 'Caché';

  @override
  String get clearCache => 'Borrar caché';

  @override
  String get emoteCache => 'Caché de emotes';

  @override
  String emoteCacheUsage(String used, String limit) {
    return '$used de $limit';
  }

  @override
  String megabytes(String size) {
    return '$size MB';
  }

  @override
  String get chatters => 'Usuarios en el chat';

  @override
  String lastSeenAgo(String time) {
    return 'Visto por última vez hace $time';
  }

  @override
  String get credits => 'Créditos';

  @override
  String get search => 'Buscar';

  @override
  String get emoteMenuButton => 'Botón del menú de emotes';

  @override
  String get emoteMenuButtonGrayscale => 'Botón del menú de emotes en escala de grises';

  @override
  String get chooseEmoteMenuButton => 'Toca un emote para usarlo como botón del menú de emotes';

  @override
  String get resetToKappa => 'Restablecer a Kappa';

  @override
  String get emoteMenuButtonDownloadFailed => 'No se ha podido descargar ese emote. El botón no ha cambiado.';

  @override
  String get takePhoto => 'Hacer foto';

  @override
  String get chooseFromLibrary => 'Elegir de la galería';

  @override
  String get cameraUnavailable => 'No se ha podido abrir la cámara. Comprueba que ColdChat tenga acceso a la cámara.';

  @override
  String get about => 'Acerca de';

  @override
  String get sourceCode => 'Código fuente';

  @override
  String get license => 'Licencia';

  @override
  String get basedOnChatsen => 'Basado en Chatsen';

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String get aboutLegalese =>
      'ColdChat es software libre: puedes redistribuirlo y modificarlo según los términos de la GNU Affero General Public License, versión 3. Se ofrece SIN NINGUNA GARANTÍA.';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get report => 'Denunciar';

  @override
  String reportUserTitle(String name) {
    return 'Denunciar a $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Twitch se encarga de las denuncias. Abre el canal de $name en Twitch y elige Denunciar allí. También puedes bloquear a $name aquí para ocultar sus mensajes.';
  }

  @override
  String get openOnTwitch => 'Abrir en Twitch';

  @override
  String get blockFailed => 'No se ha podido cambiar la lista de bloqueos. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get moderationNeedsLogin => 'Inicia sesión con Twitch para moderar este canal.';

  @override
  String get moderationNeedsScope =>
      'Vuelve a iniciar sesión para banear y expulsar temporalmente a usuarios. Tu inicio de sesión es de antes de que ColdChat pudiera hacerlo.';

  @override
  String moderationFailed(String reason) {
    return 'No ha funcionado: $reason';
  }

  @override
  String get contact => 'Contacto y comentarios';

  @override
  String get whisper => 'Susurrar';

  @override
  String whisperTo(String name) {
    return 'Susurrar a $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Susurro de $name';
  }

  @override
  String get openWhisper => 'Abrir';

  @override
  String get userCard => 'Tarjeta de usuario';

  @override
  String get closeConversation => 'Cerrar conversación';

  @override
  String get closeConversationSubtitle =>
      'Los mensajes se quedan en este dispositivo y vuelven con el próximo susurro.';

  @override
  String get deleteConversation => 'Eliminar conversación';

  @override
  String get deleteConversationSubtitle =>
      'Elimina los mensajes de este dispositivo. Twitch no guarda el historial de susurros.';

  @override
  String get whisperNeedsLogin => 'Inicia sesión con Twitch para enviar susurros.';

  @override
  String get whisperNeedsScope =>
      'Vuelve a iniciar sesión para enviar y recibir susurros. Tu sesión es de antes de que ColdChat los admitiera.';

  @override
  String get whisperUserNotFound => 'No hay ningún usuario de Twitch con ese nombre.';

  @override
  String get messageNotSentNotConnected => 'Aún no hay conexión con este canal. Tu mensaje no se ha enviado.';

  @override
  String whisperFailed(String reason) {
    return 'Susurro no enviado: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Los susurros que recibes mientras ColdChat está cerrado no aparecen aquí, porque Twitch no comparte el historial de susurros con las apps. Puedes leerlos en Twitch, en el icono de susurros de arriba a la derecha.';

  @override
  String get gotIt => 'Entendido';

  @override
  String get openTwitch => 'Abrir Twitch';

  @override
  String showImage(String host) {
    return 'Mostrar imagen · $host';
  }

  @override
  String get showImagesFromLinks => 'Mostrar imágenes de enlaces';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch no revisa estas imágenes. Pueden ser inapropiadas.';

  @override
  String get showImagesAutomatically => '¿Mostrar automáticamente las imágenes de los enlaces?';

  @override
  String get turnOn => 'Activar';

  @override
  String get themeIndigo => 'Índigo';

  @override
  String get themeBlue => 'Azul';

  @override
  String get themeTeal => 'Verde azulado';

  @override
  String get themeGreen => 'Verde';

  @override
  String get themeLime => 'Lima';

  @override
  String get themeAmber => 'Ámbar';

  @override
  String get themeOrange => 'Naranja';

  @override
  String get themeRed => 'Rojo';

  @override
  String get themePink => 'Rosa';

  @override
  String get themePurple => 'Morado';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get oledBlack => 'Negro OLED';

  @override
  String get oledBlackSubtitle => 'Fondo del chat negro en modo oscuro, para pantallas OLED';

  @override
  String get customColor => 'Personalizado';

  @override
  String get hue => 'Tono';

  @override
  String get saturation => 'Saturación';

  @override
  String get themeIce => 'Hielo';

  @override
  String channelConnecting(String channel) {
    return 'Conectando a $channel…';
  }

  @override
  String channelConnected(String channel) {
    return 'Conectado a $channel';
  }

  @override
  String channelDisconnected(String channel) {
    return 'Desconectado de $channel';
  }

  @override
  String channelSuspended(String channel) {
    return 'Twitch ha suspendido $channel';
  }

  @override
  String channelBanned(String channel) {
    return 'Estás baneado de $channel';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
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
