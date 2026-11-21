// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Connecté via $provider';
  }

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get settings => 'Paramètres';

  @override
  String get expiresNever => 'N\'expire jamais';

  @override
  String get loginExpired => 'Connexion expirée';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch a refusé la connexion de $login. Le chat reste déconnecté jusqu\'à ce que tu te reconnectes.';
  }

  @override
  String get loginFailed => 'Échec de la connexion';

  @override
  String get signInAgain => 'Se connecter';

  @override
  String uploadingTo(String host) {
    return 'Envoi vers $host';
  }

  @override
  String get uploadProcessing => 'Traitement…';

  @override
  String get uploadFailed => 'Échec de l\'envoi';

  @override
  String get uploadDone => 'Envoyé';

  @override
  String get uploadRetry => 'Réessayer';

  @override
  String get uploadDismiss => 'Ignorer';

  @override
  String get uploadCancel => 'Annuler l\'envoi';

  @override
  String get uploadErrorOffline => 'Pas de connexion Internet';

  @override
  String uploadErrorTimeout(String host) {
    return '$host ne répond pas';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host a refusé l\'envoi (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host a envoyé une réponse inattendue';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Impossible de se connecter à $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Impossible de lire le fichier';

  @override
  String uploadErrorUnknown(String host) {
    return 'Échec de l\'envoi vers $host';
  }

  @override
  String get uploadErrorDetails => 'Détails';

  @override
  String uploadRetryingWith(String host) {
    return 'Nouvel essai avec $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Expire dans $time';
  }

  @override
  String get close => 'Fermer';

  @override
  String get add => 'Ajouter';

  @override
  String get cancel => 'Annuler';

  @override
  String get tokenInput => 'Saisir un token';

  @override
  String get account => 'Compte';

  @override
  String get refreshAccount => 'Actualiser le compte';

  @override
  String get removeAccount => 'Supprimer le compte';

  @override
  String get addAnotherAccount => 'Ajouter un autre compte';

  @override
  String get verifiedUserData => 'Données utilisateur vérifiées !';

  @override
  String loggedInAs(String user) {
    return 'Connecté en tant que $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Une erreur est survenue lors de la vérification des données utilisateur :';

  @override
  String get verifyingUserData => 'Vérification des données utilisateur...';

  @override
  String get verifiedUserToken => 'Token utilisateur vérifié !';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Une erreur est survenue lors de la vérification du token utilisateur :';

  @override
  String get verifyingUserToken => 'Vérification du token utilisateur...';

  @override
  String get searchForChannels => 'Rechercher des chaînes';

  @override
  String get channelSearchFailed => 'Impossible de rechercher des chaînes';

  @override
  String get recommendedChannels => 'Chaînes recommandées';

  @override
  String get popularChannels => 'Chaînes populaires';

  @override
  String get channel => 'Chaîne';

  @override
  String get leaveChannel => 'Quitter la chaîne';

  @override
  String joinUser(String user) {
    return 'Rejoindre $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Faute de frappe ? Tu voulais peut-être chercher $username ?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Rejoindre $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Envoyer un message dans $channel';
  }

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get system => 'Système';

  @override
  String get appearance => 'Apparence';

  @override
  String get highContrast => 'Contraste élevé';

  @override
  String get customCommand => 'Commande personnalisée';

  @override
  String get customCommands => 'Commandes personnalisées';

  @override
  String get newCustomCommand => 'Nouvelle commande personnalisée';

  @override
  String get commandTrigger => 'Déclencheur';

  @override
  String get command => 'Commande';

  @override
  String get save => 'Enregistrer';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get messageAppearance => 'Apparence des messages';

  @override
  String get showTimestamps => 'Afficher l\'heure';

  @override
  String get compactMessages => 'Messages compacts';

  @override
  String get showBadges => 'Afficher les badges';

  @override
  String get messageTrigger => 'Déclencheur de message';

  @override
  String get pattern => 'Motif';

  @override
  String get mention => 'Mention';

  @override
  String get block => 'Bloquer';

  @override
  String get enableRegex => 'Activer les regex';

  @override
  String get invalidRegex => 'Regex non valide';

  @override
  String get caseSensitive => 'Respecter la casse';

  @override
  String get messageTriggers => 'Déclencheurs de message';

  @override
  String get newMessageTrigger => 'Nouveau déclencheur';

  @override
  String get reply => 'Répondre';

  @override
  String get copyText => 'Copier le texte';

  @override
  String get copyTextSubtitle => 'Maintiens pour copier avec le nom d\'utilisateur';

  @override
  String get deleteMessage => 'Supprimer le message';

  @override
  String deleteMessageFailed(String reason) {
    return 'Message non supprimé : $reason';
  }

  @override
  String get deleteMessageNeedsScope =>
      'Reconnecte-toi pour supprimer des messages. Ta connexion date d\'avant que ColdChat puisse le faire.';

  @override
  String get mentionUser => 'Mentionner l\'utilisateur';

  @override
  String get copyMessageId => 'Copier l\'ID du message';

  @override
  String get theme => 'Thème';

  @override
  String get userTrigger => 'Déclencheur d\'utilisateur';

  @override
  String get userTriggers => 'Déclencheurs d\'utilisateur';

  @override
  String get chatHistory => 'Historique du chat';

  @override
  String get login => 'Identifiant';

  @override
  String get newUserTrigger => 'Nouveau déclencheur';

  @override
  String get ban => 'Bannir';

  @override
  String get unban => 'Débannir';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Exclure l\'utilisateur pendant $duration';
  }

  @override
  String get chatCleared => 'Le chat a été effacé';

  @override
  String get permabanned => 'banni définitivement';

  @override
  String bannedForDuration(String duration) {
    return 'banni pendant $duration';
  }

  @override
  String get replyingTo => 'En réponse à';

  @override
  String get blockedMessage => 'Message bloqué';

  @override
  String get showMessage => 'Afficher le message';

  @override
  String get hideMessage => 'Masquer le message';

  @override
  String get scrollToBottom => 'Aller en bas';

  @override
  String get appTagline => 'Le chat Twitch avec les emotes 7TV, BTTV et FFZ';

  @override
  String get loginWithTwitch => 'Se connecter avec Twitch';

  @override
  String get addChannel => 'Ajouter une chaîne';

  @override
  String get chatSettings => 'Paramètres du chat';

  @override
  String get autocompleteUsersWithAt => 'Compléter les noms d\'utilisateur avec @';

  @override
  String get autocompleteEmotesWithColon => 'Compléter les emotes avec :';

  @override
  String get language => 'Langue';

  @override
  String get locale => 'Langue et région';

  @override
  String get systemDefault => 'Par défaut du système';

  @override
  String get justDefault => 'Par défaut';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'Quelqu\'un, quelque part, te mentionnera un jour.';

  @override
  String get backgroundNotifications => 'Notifications en arrière-plan';

  @override
  String get optionNotAvailableOnYourPlatform => 'Cette option n\'est pas disponible sur ta plateforme.';

  @override
  String get optionNotAvailablePaywalled => 'Cette option est réservée aux soutiens de ColdChat.';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get cache => 'Cache';

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get chatters => 'Utilisateurs du chat';

  @override
  String lastSeenAgo(String time) {
    return 'Vu il y a $time';
  }

  @override
  String get credits => 'Crédits';

  @override
  String get search => 'Rechercher';

  @override
  String get emoteMenuButton => 'Bouton du menu des emotes';

  @override
  String get emoteMenuButtonGrayscale => 'Bouton du menu des emotes en niveaux de gris';

  @override
  String get chooseEmoteMenuButton => 'Touche une emote pour l\'utiliser comme bouton du menu des emotes';

  @override
  String get resetToKappa => 'Revenir à Kappa';

  @override
  String get emoteMenuButtonDownloadFailed => 'Impossible de télécharger cette emote. Le bouton n\'a pas été modifié.';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromLibrary => 'Choisir dans la photothèque';

  @override
  String get cameraUnavailable =>
      'Impossible d\'ouvrir l\'appareil photo. Vérifie que ColdChat a accès à l\'appareil photo.';

  @override
  String get about => 'À propos';

  @override
  String get sourceCode => 'Code source';

  @override
  String get license => 'Licence';

  @override
  String get basedOnChatsen => 'Basé sur Chatsen';

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get aboutLegalese =>
      'ColdChat est un logiciel libre : tu peux le redistribuer et le modifier selon les termes de la GNU Affero General Public License, version 3. Il est fourni SANS AUCUNE GARANTIE.';

  @override
  String get unblock => 'Débloquer';

  @override
  String get report => 'Signaler';

  @override
  String reportUserTitle(String name) {
    return 'Signaler $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Les signalements sont traités par Twitch. Ouvre la chaîne de $name sur Twitch et choisis Signaler. Tu peux aussi bloquer $name ici pour masquer ses messages.';
  }

  @override
  String get openOnTwitch => 'Ouvrir sur Twitch';

  @override
  String get blockFailed => 'Impossible de modifier la liste de blocage. Vérifie ta connexion et réessaie.';

  @override
  String get contact => 'Contact et avis';

  @override
  String get whisper => 'Chuchoter';

  @override
  String whisperTo(String name) {
    return 'Chuchoter à $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Chuchotement de $name';
  }

  @override
  String get openWhisper => 'Ouvrir';

  @override
  String get userCard => 'Carte utilisateur';

  @override
  String get closeConversation => 'Fermer la conversation';

  @override
  String get closeConversationSubtitle =>
      'Les messages restent sur cet appareil et reviennent au prochain chuchotement.';

  @override
  String get deleteConversation => 'Supprimer la conversation';

  @override
  String get deleteConversationSubtitle =>
      'Supprime les messages de cet appareil. Twitch ne conserve aucun historique des chuchotements.';

  @override
  String get whisperNeedsLogin => 'Connecte-toi avec Twitch pour envoyer des chuchotements.';

  @override
  String get whisperNeedsScope =>
      'Reconnecte-toi pour envoyer et recevoir des chuchotements. Ta connexion date d\'avant leur prise en charge par ColdChat.';

  @override
  String get whisperUserNotFound => 'Aucun utilisateur Twitch ne porte ce nom.';

  @override
  String whisperFailed(String reason) {
    return 'Chuchotement non envoyé : $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Les chuchotements reçus pendant que ColdChat était fermé n\'apparaissent pas ici, car Twitch ne partage pas l\'historique des chuchotements avec les applis. Tu peux les lire sur Twitch, derrière l\'icône des chuchotements en haut à droite.';

  @override
  String get gotIt => 'Compris';

  @override
  String get openTwitch => 'Ouvrir Twitch';

  @override
  String showImage(String host) {
    return 'Afficher l\'image · $host';
  }

  @override
  String get showImagesFromLinks => 'Afficher les images des liens';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch ne vérifie pas ces images. Elles peuvent être inappropriées.';

  @override
  String get showImagesAutomatically => 'Afficher automatiquement les images des liens ?';

  @override
  String get turnOn => 'Activer';

  @override
  String get themeIndigo => 'Indigo';

  @override
  String get themeBlue => 'Bleu';

  @override
  String get themeTeal => 'Bleu canard';

  @override
  String get themeGreen => 'Vert';

  @override
  String get themeLime => 'Citron vert';

  @override
  String get themeAmber => 'Ambre';

  @override
  String get themeOrange => 'Orange';

  @override
  String get themeRed => 'Rouge';

  @override
  String get themePink => 'Rose';

  @override
  String get themePurple => 'Violet';

  @override
  String get accentColor => 'Couleur d\'accent';

  @override
  String get oledBlack => 'Noir OLED';

  @override
  String get oledBlackSubtitle => 'Fond du chat noir en mode sombre, pour les écrans OLED';

  @override
  String get customColor => 'Personnalisée';

  @override
  String get hue => 'Teinte';

  @override
  String get saturation => 'Saturation';

  @override
  String get themeIce => 'Glace';

  @override
  String channelConnecting(String channel) {
    return 'Connexion à $channel…';
  }

  @override
  String channelConnected(String channel) {
    return 'Connecté à $channel';
  }

  @override
  String channelDisconnected(String channel) {
    return 'Déconnecté de $channel';
  }

  @override
  String channelSuspended(String channel) {
    return '$channel a été suspendue par Twitch';
  }

  @override
  String channelBanned(String channel) {
    return 'Tu es banni de $channel';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }
}
