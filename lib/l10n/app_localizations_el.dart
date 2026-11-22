// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Σύνδεση μέσω $provider';
  }

  @override
  String get termsOfService => 'Όροι χρήσης';

  @override
  String get privacyPolicy => 'Πολιτική απορρήτου';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get expiresNever => 'Δεν λήγει ποτέ';

  @override
  String get loginExpired => 'Η σύνδεση έληξε';

  @override
  String loginExpiredDescription(String login) {
    return 'Το Twitch απέρριψε τη σύνδεση για τον λογαριασμό $login. Η συνομιλία μένει αποσυνδεδεμένη μέχρι να συνδεθείς ξανά.';
  }

  @override
  String get loginFailed => 'Η σύνδεση απέτυχε';

  @override
  String get signInAgain => 'Σύνδεση';

  @override
  String uploadingTo(String host) {
    return 'Μεταφόρτωση στο $host';
  }

  @override
  String get uploadProcessing => 'Επεξεργασία…';

  @override
  String get uploadFailed => 'Η μεταφόρτωση απέτυχε';

  @override
  String get uploadDone => 'Μεταφορτώθηκε';

  @override
  String get uploadRetry => 'Επανάληψη';

  @override
  String get uploadDismiss => 'Απόρριψη';

  @override
  String get uploadCancel => 'Ακύρωση μεταφόρτωσης';

  @override
  String get uploadErrorOffline => 'Δεν υπάρχει σύνδεση στο διαδίκτυο';

  @override
  String uploadErrorTimeout(String host) {
    return 'Το $host δεν αποκρίνεται';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return 'Το $host απέρριψε τη μεταφόρτωση (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return 'Το $host έστειλε μια απροσδόκητη απάντηση';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Δεν ήταν δυνατή η σύνδεση με το $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Δεν ήταν δυνατή η ανάγνωση του αρχείου';

  @override
  String uploadErrorUnknown(String host) {
    return 'Η μεταφόρτωση στο $host απέτυχε';
  }

  @override
  String get uploadErrorDetails => 'Λεπτομέρειες';

  @override
  String uploadRetryingWith(String host) {
    return 'Νέα προσπάθεια με $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Λήγει σε $time';
  }

  @override
  String get close => 'Κλείσιμο';

  @override
  String get add => 'Προσθήκη';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get tokenInput => 'Εισαγωγή token';

  @override
  String get account => 'Λογαριασμός';

  @override
  String get refreshAccount => 'Ανανέωση λογαριασμού';

  @override
  String get removeAccount => 'Αφαίρεση λογαριασμού';

  @override
  String get addAnotherAccount => 'Προσθήκη άλλου λογαριασμού';

  @override
  String get verifiedUserData => 'Τα στοιχεία χρήστη επαληθεύτηκαν!';

  @override
  String loggedInAs(String user) {
    return 'Σύνδεση ως $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => 'Παρουσιάστηκε σφάλμα κατά την επαλήθευση των στοιχείων χρήστη:';

  @override
  String get verifyingUserData => 'Επαλήθευση στοιχείων χρήστη...';

  @override
  String get verifiedUserToken => 'Το token χρήστη επαληθεύτηκε!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken => 'Παρουσιάστηκε σφάλμα κατά την επαλήθευση του token χρήστη:';

  @override
  String get verifyingUserToken => 'Επαλήθευση token χρήστη...';

  @override
  String get searchForChannels => 'Αναζήτηση καναλιών';

  @override
  String get channelSearchFailed => 'Δεν ήταν δυνατή η αναζήτηση καναλιών';

  @override
  String get recommendedChannels => 'Προτεινόμενα κανάλια';

  @override
  String get popularChannels => 'Δημοφιλή κανάλια';

  @override
  String get channel => 'Κανάλι';

  @override
  String get leaveChannel => 'Αποχώρηση από το κανάλι';

  @override
  String joinUser(String user) {
    return 'Είσοδος στο κανάλι $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Ωπ, μάλλον ορθογραφικό λάθος! Μήπως ψάχνεις τον χρήστη $username;';
  }

  @override
  String joinChannelName(String channel) {
    return 'Είσοδος στο $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Μήνυμα στο $channel';
  }

  @override
  String get light => 'Ανοιχτό';

  @override
  String get dark => 'Σκούρο';

  @override
  String get system => 'Συστήματος';

  @override
  String get appearance => 'Εμφάνιση';

  @override
  String get highContrast => 'Υψηλή αντίθεση';

  @override
  String get customCommand => 'Προσαρμοσμένη εντολή';

  @override
  String get customCommands => 'Προσαρμοσμένες εντολές';

  @override
  String get newCustomCommand => 'Νέα προσαρμοσμένη εντολή';

  @override
  String get commandTrigger => 'Συντόμευση';

  @override
  String get command => 'Εντολή';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get openInBrowser => 'Άνοιγμα στο πρόγραμμα περιήγησης';

  @override
  String get messageAppearance => 'Εμφάνιση μηνυμάτων';

  @override
  String get showTimestamps => 'Εμφάνιση ώρας';

  @override
  String get compactMessages => 'Συμπαγή μηνύματα';

  @override
  String get showBadges => 'Εμφάνιση εμβλημάτων';

  @override
  String get messageTrigger => 'Κανόνας μηνυμάτων';

  @override
  String get pattern => 'Μοτίβο';

  @override
  String get mention => 'Επισήμανση';

  @override
  String get block => 'Φραγή';

  @override
  String get enableRegex => 'Χρήση regex';

  @override
  String get invalidRegex => 'Μη έγκυρο regex';

  @override
  String get caseSensitive => 'Διάκριση πεζών-κεφαλαίων';

  @override
  String get messageTriggers => 'Κανόνες μηνυμάτων';

  @override
  String get newMessageTrigger => 'Νέος κανόνας μηνυμάτων';

  @override
  String get reply => 'Απάντηση';

  @override
  String get copyText => 'Αντιγραφή κειμένου';

  @override
  String get copyTextSubtitle => 'Κράτα πατημένο για αντιγραφή μαζί με το όνομα χρήστη';

  @override
  String get deleteMessage => 'Διαγραφή μηνύματος';

  @override
  String deleteMessageFailed(String reason) {
    return 'Το μήνυμα δεν διαγράφηκε: $reason';
  }

  @override
  String get deleteMessageNeedsScope =>
      'Συνδέσου ξανά για να διαγράφεις μηνύματα. Η σύνδεσή σου είναι από πριν το ColdChat μπορεί να τα διαγράφει.';

  @override
  String get mentionUser => 'Αναφορά χρήστη';

  @override
  String get copyMessageId => 'Αντιγραφή ID μηνύματος';

  @override
  String get theme => 'Θέμα';

  @override
  String get userTrigger => 'Κανόνας χρήστη';

  @override
  String get userTriggers => 'Κανόνες χρηστών';

  @override
  String get chatHistory => 'Ιστορικό συνομιλίας';

  @override
  String get login => 'Όνομα σύνδεσης';

  @override
  String get newUserTrigger => 'Νέος κανόνας χρήστη';

  @override
  String get ban => 'Αποκλεισμός';

  @override
  String get unban => 'Άρση αποκλεισμού';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Timeout χρήστη για $duration';
  }

  @override
  String get chatCleared => 'Η συνομιλία εκκαθαρίστηκε';

  @override
  String get permabanned => 'αποκλείστηκε μόνιμα';

  @override
  String bannedForDuration(String duration) {
    return 'αποκλείστηκε για $duration';
  }

  @override
  String get replyingTo => 'Απάντηση σε';

  @override
  String get blockedMessage => 'Κρυφό μήνυμα';

  @override
  String get showMessage => 'Εμφάνιση μηνύματος';

  @override
  String get hideMessage => 'Απόκρυψη μηνύματος';

  @override
  String get scrollToBottom => 'Μετάβαση στο τέλος';

  @override
  String get appTagline => 'Συνομιλία Twitch με emote από 7TV, BTTV και FFZ';

  @override
  String get continueWithoutLogin => 'Συνέχεια χωρίς σύνδεση';

  @override
  String get logInForSearch => 'Συνδέσου για να ψάχνεις κανάλια και να βλέπεις ζωντανές μεταδόσεις';

  @override
  String get loginWithTwitch => 'Σύνδεση με Twitch';

  @override
  String get addChannel => 'Προσθήκη καναλιού';

  @override
  String get chatSettings => 'Ρυθμίσεις συνομιλίας';

  @override
  String get autocompleteUsersWithAt => 'Αυτόματη συμπλήρωση χρηστών με @';

  @override
  String get autocompleteEmotesWithColon => 'Αυτόματη συμπλήρωση emote με :';

  @override
  String get language => 'Γλώσσα';

  @override
  String get locale => 'Γλώσσα και περιοχή';

  @override
  String get systemDefault => 'Προεπιλογή συστήματος';

  @override
  String get justDefault => 'Προεπιλογή';

  @override
  String get notifications => 'Ειδοποιήσεις';

  @override
  String get noNotifications => 'Κάποιος, κάπου, κάποια μέρα θα σε αναφέρει.';

  @override
  String get backgroundNotifications => 'Ειδοποιήσεις στο παρασκήνιο';

  @override
  String get optionNotAvailableOnYourPlatform => 'Αυτή η επιλογή δεν είναι διαθέσιμη στην πλατφόρμα σου.';

  @override
  String get optionNotAvailablePaywalled => 'Αυτή η επιλογή είναι μόνο για όσους υποστηρίζουν το ColdChat.';

  @override
  String get clearAll => 'Εκκαθάριση όλων';

  @override
  String get cache => 'Προσωρινή μνήμη';

  @override
  String get clearCache => 'Εκκαθάριση προσωρινής μνήμης';

  @override
  String get emoteCache => 'Προσωρινή μνήμη emotes';

  @override
  String emoteCacheUsage(String used, String limit) {
    return '$used από $limit';
  }

  @override
  String megabytes(String size) {
    return '$size MB';
  }

  @override
  String get chatters => 'Συμμετέχοντες';

  @override
  String lastSeenAgo(String time) {
    return 'Τελευταία δραστηριότητα πριν από $time';
  }

  @override
  String get credits => 'Συντελεστές';

  @override
  String get search => 'Αναζήτηση';

  @override
  String get emoteMenuButton => 'Κουμπί μενού emote';

  @override
  String get emoteMenuButtonGrayscale => 'Κουμπί μενού emote σε αποχρώσεις του γκρι';

  @override
  String get chooseEmoteMenuButton => 'Πάτησε ένα emote για να το κάνεις κουμπί του μενού emote';

  @override
  String get resetToKappa => 'Επαναφορά σε Kappa';

  @override
  String get emoteMenuButtonDownloadFailed => 'Δεν ήταν δυνατή η λήψη του emote. Το κουμπί δεν άλλαξε.';

  @override
  String get takePhoto => 'Λήψη φωτογραφίας';

  @override
  String get chooseFromLibrary => 'Επιλογή από τη βιβλιοθήκη';

  @override
  String get cameraUnavailable =>
      'Δεν ήταν δυνατό να ανοίξει η κάμερα. Έλεγξε αν το ColdChat έχει πρόσβαση στην κάμερα.';

  @override
  String get about => 'Σχετικά';

  @override
  String get sourceCode => 'Πηγαίος κώδικας';

  @override
  String get license => 'Άδεια χρήσης';

  @override
  String get basedOnChatsen => 'Βασισμένο στο Chatsen';

  @override
  String get openSourceLicenses => 'Άδειες ανοιχτού κώδικα';

  @override
  String get aboutLegalese =>
      'Το ColdChat είναι ελεύθερο λογισμικό: μπορείς να το αναδιανέμεις και να το τροποποιείς σύμφωνα με τους όρους της GNU Affero General Public License, έκδοση 3. Παρέχεται ΧΩΡΙΣ ΑΠΟΛΥΤΩΣ ΚΑΜΙΑ ΕΓΓΥΗΣΗ.';

  @override
  String get unblock => 'Άρση φραγής';

  @override
  String get report => 'Αναφορά';

  @override
  String reportUserTitle(String name) {
    return 'Αναφορά χρήστη $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Τις αναφορές τις χειρίζεται το Twitch. Άνοιξε το κανάλι του χρήστη $name στο Twitch και επίλεξε εκεί «Αναφορά». Μπορείς επίσης να κάνεις εδώ φραγή στον χρήστη $name, για να κρύψεις τα μηνύματά του.';
  }

  @override
  String get openOnTwitch => 'Άνοιγμα στο Twitch';

  @override
  String get blockFailed => 'Δεν ήταν δυνατή η αλλαγή της λίστας φραγής. Έλεγξε τη σύνδεσή σου και δοκίμασε ξανά.';

  @override
  String get moderationNeedsLogin => 'Συνδέσου με το Twitch για να κάνεις συντονισμό σε αυτό το κανάλι.';

  @override
  String get moderationNeedsScope =>
      'Συνδέσου ξανά για να αποκλείεις χρήστες και να τους βάζεις timeout. Η σύνδεσή σου είναι από πριν το ColdChat υποστηρίξει αυτή τη λειτουργία.';

  @override
  String moderationFailed(String reason) {
    return 'Δεν λειτούργησε: $reason';
  }

  @override
  String get contact => 'Επικοινωνία & σχόλια';

  @override
  String get whisper => 'Ψίθυρος';

  @override
  String whisperTo(String name) {
    return 'Ψίθυρος προς $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Ψίθυρος από $name';
  }

  @override
  String get openWhisper => 'Άνοιγμα';

  @override
  String get userCard => 'Κάρτα χρήστη';

  @override
  String get closeConversation => 'Κλείσιμο συνομιλίας';

  @override
  String get closeConversationSubtitle =>
      'Τα μηνύματα μένουν σε αυτήν τη συσκευή και επιστρέφουν με τον επόμενο ψίθυρο.';

  @override
  String get deleteConversation => 'Διαγραφή συνομιλίας';

  @override
  String get deleteConversationSubtitle =>
      'Διαγράφει τα μηνύματα από αυτήν τη συσκευή. Το Twitch δεν κρατά ιστορικό ψιθύρων.';

  @override
  String get whisperNeedsLogin => 'Συνδέσου με το Twitch για να στέλνεις ψιθύρους.';

  @override
  String get whisperNeedsScope =>
      'Συνδέσου ξανά για να στέλνεις και να λαμβάνεις ψιθύρους. Η σύνδεσή σου είναι από πριν το ColdChat τους υποστηρίξει.';

  @override
  String get whisperUserNotFound => 'Δεν υπάρχει χρήστης του Twitch με αυτό το όνομα.';

  @override
  String get messageNotSentNotConnected => 'Δεν έχεις συνδεθεί ακόμα σε αυτό το κανάλι. Το μήνυμά σου δεν στάλθηκε.';

  @override
  String whisperFailed(String reason) {
    return 'Ο ψίθυρος δεν στάλθηκε: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Οι ψίθυροι που λαμβάνεις όσο το ColdChat είναι κλειστό δεν εμφανίζονται εδώ, γιατί το Twitch δεν δίνει το ιστορικό ψιθύρων σε εφαρμογές. Μπορείς να τους διαβάσεις στο Twitch, από το εικονίδιο ψιθύρων πάνω δεξιά.';

  @override
  String get gotIt => 'Εντάξει';

  @override
  String get openTwitch => 'Άνοιγμα Twitch';

  @override
  String showImage(String host) {
    return 'Εμφάνιση εικόνας · $host';
  }

  @override
  String get showImagesFromLinks => 'Εμφάνιση εικόνων από συνδέσμους';

  @override
  String get showImagesFromLinksSubtitle => 'Το Twitch δεν ελέγχει αυτές τις εικόνες. Μπορεί να είναι ακατάλληλες.';

  @override
  String get showImagesAutomatically => 'Αυτόματη εμφάνιση εικόνων από συνδέσμους;';

  @override
  String get turnOn => 'Ενεργοποίηση';

  @override
  String get themeIndigo => 'Λουλακί';

  @override
  String get themeBlue => 'Μπλε';

  @override
  String get themeTeal => 'Πετρόλ';

  @override
  String get themeGreen => 'Πράσινο';

  @override
  String get themeLime => 'Λάιμ';

  @override
  String get themeAmber => 'Κεχριμπαρί';

  @override
  String get themeOrange => 'Πορτοκαλί';

  @override
  String get themeRed => 'Κόκκινο';

  @override
  String get themePink => 'Ροζ';

  @override
  String get themePurple => 'Μωβ';

  @override
  String get accentColor => 'Χρώμα έμφασης';

  @override
  String get oledBlack => 'Μαύρο OLED';

  @override
  String get oledBlackSubtitle => 'Μαύρο φόντο συνομιλίας στη σκοτεινή λειτουργία, για οθόνες OLED';

  @override
  String get customColor => 'Προσαρμοσμένο';

  @override
  String get hue => 'Απόχρωση';

  @override
  String get saturation => 'Κορεσμός';

  @override
  String get themeIce => 'Πάγος';

  @override
  String channelConnecting(String channel) {
    return 'Σύνδεση στο $channel…';
  }

  @override
  String channelConnected(String channel) {
    return 'Συνδέθηκες στο $channel';
  }

  @override
  String channelDisconnected(String channel) {
    return 'Αποσυνδέθηκες από το $channel';
  }

  @override
  String channelSuspended(String channel) {
    return 'Το $channel έχει ανασταλεί από το Twitch';
  }

  @override
  String channelBanned(String channel) {
    return 'Έχεις αποκλειστεί από το $channel';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ημέρες',
      one: '1 ημέρα',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ώρες',
      one: '1 ώρα',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count λεπτά',
      one: '1 λεπτό',
    );
    return '$_temp0';
  }

  @override
  String durationDaysShort(int count) {
    return '$count ημ.';
  }

  @override
  String durationHoursShort(int count) {
    return '$count ώ.';
  }

  @override
  String durationMinutesShort(int count) {
    return '$count λ.';
  }

  @override
  String durationSecondsShort(int count) {
    return '$count δ.';
  }

  @override
  String durationPair(String larger, String smaller) {
    return '$larger $smaller';
  }
}
