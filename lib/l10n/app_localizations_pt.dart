// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Conectado via $provider';
  }

  @override
  String get termsOfService => 'Termos de Serviço';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get settings => 'Configurações';

  @override
  String get expiresNever => 'Nunca expira';

  @override
  String get loginExpired => 'Login expirado';

  @override
  String loginExpiredDescription(String login) {
    return 'A Twitch recusou o login de $login. O chat fica desconectado até você entrar de novo.';
  }

  @override
  String get loginFailed => 'Falha no login';

  @override
  String get signInAgain => 'Entrar';

  @override
  String uploadingTo(String host) {
    return 'Enviando para $host';
  }

  @override
  String get uploadProcessing => 'Processando…';

  @override
  String get uploadFailed => 'Falha no envio';

  @override
  String get uploadDone => 'Enviado';

  @override
  String get uploadRetry => 'Tentar de novo';

  @override
  String get uploadDismiss => 'Dispensar';

  @override
  String get uploadCancel => 'Cancelar envio';

  @override
  String get uploadErrorOffline => 'Sem conexão com a internet';

  @override
  String uploadErrorTimeout(String host) {
    return '$host não está respondendo';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host recusou o envio (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host enviou uma resposta inesperada';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Não foi possível conectar a $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Não foi possível ler o arquivo';

  @override
  String uploadErrorUnknown(String host) {
    return 'Falha no envio para $host';
  }

  @override
  String get uploadErrorDetails => 'Detalhes';

  @override
  String uploadRetryingWith(String host) {
    return 'Tentando de novo com $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Expira em $time';
  }

  @override
  String get close => 'Fechar';

  @override
  String get add => 'Adicionar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get tokenInput => 'Inserir token';

  @override
  String get account => 'Conta';

  @override
  String get refreshAccount => 'Atualizar conta';

  @override
  String get removeAccount => 'Remover conta';

  @override
  String get addAnotherAccount => 'Adicionar outra conta';

  @override
  String get verifiedUserData => 'Dados do usuário verificados!';

  @override
  String loggedInAs(String user) {
    return 'Conectado como $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Ocorreu um erro ao verificar os dados do usuário:';

  @override
  String get verifyingUserData => 'Verificando dados do usuário...';

  @override
  String get verifiedUserToken => 'Token do usuário verificado!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Ocorreu um erro ao verificar o token do usuário:';

  @override
  String get verifyingUserToken => 'Verificando token do usuário...';

  @override
  String get searchForChannels => 'Pesquisar canais';

  @override
  String get recommendedChannels => 'Canais recomendados';

  @override
  String get popularChannels => 'Canais populares';

  @override
  String get channel => 'Canal';

  @override
  String get leaveChannel => 'Sair do canal';

  @override
  String joinUser(String user) {
    return 'Entrar no canal de $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'A verificação ortográfica falhou! Você quis pesquisar $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Entrar em $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Enviar mensagem em $channel';
  }

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get system => 'Sistema';

  @override
  String get appearance => 'Aparência';

  @override
  String get highContrast => 'Alto contraste';

  @override
  String get customCommand => 'Comando personalizado';

  @override
  String get customCommands => 'Comandos personalizados';

  @override
  String get newCustomCommand => 'Novo comando personalizado';

  @override
  String get commandTrigger => 'Gatilho';

  @override
  String get command => 'Comando';

  @override
  String get save => 'Salvar';

  @override
  String get openInBrowser => 'Abrir no navegador';

  @override
  String get messageAppearance => 'Aparência das mensagens';

  @override
  String get showTimestamps => 'Mostrar horários';

  @override
  String get compactMessages => 'Mensagens compactas';

  @override
  String get showBadges => 'Mostrar emblemas';

  @override
  String get messageTrigger => 'Gatilho de mensagem';

  @override
  String get pattern => 'Padrão';

  @override
  String get mention => 'Menção';

  @override
  String get block => 'Bloquear';

  @override
  String get enableRegex => 'Ativar regex';

  @override
  String get caseSensitive => 'Diferenciar maiúsculas e minúsculas';

  @override
  String get messageTriggers => 'Gatilhos de mensagem';

  @override
  String get newMessageTrigger => 'Novo gatilho de mensagem';

  @override
  String get reply => 'Responder';

  @override
  String get copyText => 'Copiar texto';

  @override
  String get copyTextSubtitle =>
      'Segure para copiar o texto com o nome de usuário';

  @override
  String get deleteMessage => 'Excluir mensagem';

  @override
  String get mentionUser => 'Mencionar usuário';

  @override
  String get copyMessageId => 'Copiar ID da mensagem';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Gatilho de usuário';

  @override
  String get userTriggers => 'Gatilhos de usuário';

  @override
  String get chatHistory => 'Histórico do chat';

  @override
  String get login => 'Login';

  @override
  String get newUserTrigger => 'Novo gatilho de usuário';

  @override
  String get ban => 'Banir';

  @override
  String get unban => 'Desbanir';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Suspender usuário por $duration';
  }

  @override
  String get chatCleared => 'O chat foi limpo';

  @override
  String get permabanned => 'banido permanentemente';

  @override
  String bannedForDuration(String duration) {
    return 'banido por $duration';
  }

  @override
  String get replyingTo => 'Respondendo a';

  @override
  String get blockedMessage => 'Mensagem bloqueada';

  @override
  String get showMessage => 'Mostrar mensagem';

  @override
  String get hideMessage => 'Ocultar mensagem';

  @override
  String get scrollToBottom => 'Rolar até o fim';

  @override
  String get appTagline => 'Chat da Twitch com emotes do 7TV, BTTV e FFZ';

  @override
  String get loginWithTwitch => 'Entrar com a Twitch';

  @override
  String get addChannel => 'Adicionar canal';

  @override
  String get chatSettings => 'Configurações do chat';

  @override
  String get autocompleteUsersWithAt => 'Autocompletar usuários com @';

  @override
  String get autocompleteEmotesWithColon => 'Autocompletar emotes com :';

  @override
  String get language => 'Idioma';

  @override
  String get locale => 'Região';

  @override
  String get systemDefault => 'Padrão do sistema';

  @override
  String get justDefault => 'Padrão';

  @override
  String get notifications => 'Notificações';

  @override
  String get noNotifications =>
      'Alguém, em algum lugar, vai te mencionar um dia.';

  @override
  String get backgroundNotifications => 'Notificações em segundo plano';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'Essa opção não está disponível na sua plataforma.';

  @override
  String get optionNotAvailablePaywalled =>
      'Essa opção é só para apoiadores do ColdChat.';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String get cache => 'Cache';

  @override
  String get clearCache => 'Limpar cache';

  @override
  String get chatters => 'Participantes';

  @override
  String lastSeenAgo(String time) {
    return 'Visto pela última vez há $time';
  }

  @override
  String get credits => 'Créditos';

  @override
  String get search => 'Pesquisar';

  @override
  String get emoteMenuButton => 'Botão do menu de emotes';

  @override
  String get emoteMenuButtonGrayscale =>
      'Mostrar o botão do menu de emotes em escala de cinza';

  @override
  String get chooseEmoteMenuButton =>
      'Toque em um emote para usá-lo como botão do menu de emotes';

  @override
  String get resetToKappa => 'Redefinir para Kappa';

  @override
  String get emoteMenuButtonDownloadFailed =>
      'Não foi possível baixar esse emote. O botão não foi alterado.';

  @override
  String get takePhoto => 'Tirar foto';

  @override
  String get chooseFromLibrary => 'Escolher da galeria';

  @override
  String get cameraUnavailable =>
      'Não foi possível abrir a câmera. Verifique se o ColdChat tem acesso à câmera.';

  @override
  String get about => 'Sobre';

  @override
  String get sourceCode => 'Código-fonte';

  @override
  String get license => 'Licença';

  @override
  String get basedOnChatsen => 'Baseado no Chatsen';

  @override
  String get openSourceLicenses => 'Licenças de código aberto';

  @override
  String get aboutLegalese =>
      'O ColdChat é software livre: você pode redistribuí-lo e modificá-lo nos termos da GNU Affero General Public License, versão 3. Ele vem SEM NENHUMA GARANTIA.';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get report => 'Denunciar';

  @override
  String reportUserTitle(String name) {
    return 'Denunciar $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'As denúncias são tratadas pela Twitch. Abra o canal de $name na Twitch e escolha Denunciar lá. Você também pode bloquear $name aqui para ocultar as mensagens.';
  }

  @override
  String get openOnTwitch => 'Abrir na Twitch';

  @override
  String get blockFailed =>
      'Não foi possível alterar a lista de bloqueios. Verifique sua conexão e tente de novo.';

  @override
  String get contact => 'Contato e feedback';

  @override
  String get whisper => 'Sussurrar';

  @override
  String whisperTo(String name) {
    return 'Sussurrar para $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Sussurro de $name';
  }

  @override
  String get openWhisper => 'Abrir';

  @override
  String get userCard => 'Cartão do usuário';

  @override
  String get closeConversation => 'Fechar conversa';

  @override
  String get closeConversationSubtitle =>
      'As mensagens ficam neste dispositivo e voltam com o próximo sussurro.';

  @override
  String get deleteConversation => 'Excluir conversa';

  @override
  String get deleteConversationSubtitle =>
      'Exclui as mensagens deste dispositivo. A Twitch não guarda histórico de sussurros.';

  @override
  String get whisperNeedsLogin => 'Entre com a Twitch para enviar sussurros.';

  @override
  String get whisperNeedsScope =>
      'Entre de novo para enviar e receber sussurros. Seu login é de antes de o ColdChat ter suporte a eles.';

  @override
  String get whisperUserNotFound =>
      'Não existe usuário da Twitch com esse nome.';

  @override
  String whisperFailed(String reason) {
    return 'Sussurro não enviado: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Sussurros recebidos enquanto o ColdChat estava fechado não aparecem aqui, porque a Twitch não compartilha o histórico de sussurros com aplicativos. Você pode lê-los na Twitch, no ícone de sussurros no canto superior direito.';

  @override
  String get gotIt => 'Entendi';

  @override
  String get openTwitch => 'Abrir a Twitch';

  @override
  String showImage(String host) {
    return 'Mostrar imagem · $host';
  }

  @override
  String get showImagesFromLinks => 'Mostrar imagens de links';

  @override
  String get showImagesFromLinksSubtitle =>
      'A Twitch não verifica essas imagens. Elas podem ser impróprias.';

  @override
  String get showImagesAutomatically =>
      'Mostrar imagens de links automaticamente?';

  @override
  String get turnOn => 'Ativar';

  @override
  String get themeIndigo => 'Índigo';

  @override
  String get themeBlue => 'Azul';

  @override
  String get themeTeal => 'Azul-petróleo';

  @override
  String get themeGreen => 'Verde';

  @override
  String get themeLime => 'Lima';

  @override
  String get themeAmber => 'Âmbar';

  @override
  String get themeOrange => 'Laranja';

  @override
  String get themeRed => 'Vermelho';

  @override
  String get themePink => 'Rosa';

  @override
  String get themePurple => 'Roxo';

  @override
  String get accentColor => 'Cor de destaque';

  @override
  String get oledBlack => 'Preto OLED';

  @override
  String get oledBlackSubtitle =>
      'Fundo do chat preto no modo escuro, para ecrãs OLED';

  @override
  String get customColor => 'Personalizada';

  @override
  String get hue => 'Matiz';

  @override
  String get saturation => 'Saturação';

  @override
  String get themeIce => 'Gelo';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
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
}
