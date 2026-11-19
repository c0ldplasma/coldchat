// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'התחברת דרך $provider';
  }

  @override
  String get termsOfService => 'תנאי השירות';

  @override
  String get privacyPolicy => 'מדיניות הפרטיות';

  @override
  String get settings => 'הגדרות';

  @override
  String get expiresNever => 'ללא תפוגה';

  @override
  String get loginExpired => 'פג תוקף ההתחברות';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch דחתה את ההתחברות של $login. הצ׳אט יישאר מנותק עד להתחברות מחדש.';
  }

  @override
  String get loginFailed => 'ההתחברות נכשלה';

  @override
  String get signInAgain => 'התחברות';

  @override
  String uploadingTo(String host) {
    return 'העלאה אל $host';
  }

  @override
  String get uploadProcessing => 'בעיבוד…';

  @override
  String get uploadFailed => 'ההעלאה נכשלה';

  @override
  String get uploadDone => 'הועלה';

  @override
  String get uploadRetry => 'ניסיון חוזר';

  @override
  String get uploadDismiss => 'סגירה';

  @override
  String get uploadCancel => 'ביטול ההעלאה';

  @override
  String get uploadErrorOffline => 'אין חיבור לאינטרנט';

  @override
  String uploadErrorTimeout(String host) {
    return '$host לא מגיב';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host דחה את ההעלאה (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host שלח תגובה לא צפויה';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'לא ניתן להתחבר אל $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'לא ניתן לקרוא את הקובץ';

  @override
  String uploadErrorUnknown(String host) {
    return 'ההעלאה אל $host נכשלה';
  }

  @override
  String get uploadErrorDetails => 'פרטים';

  @override
  String uploadRetryingWith(String host) {
    return 'ניסיון חוזר עם $host…';
  }

  @override
  String expiresIn(String time) {
    return 'פג תוקף בעוד $time';
  }

  @override
  String get close => 'סגירה';

  @override
  String get add => 'הוספה';

  @override
  String get cancel => 'ביטול';

  @override
  String get tokenInput => 'הזנת טוקן';

  @override
  String get account => 'חשבון';

  @override
  String get refreshAccount => 'רענון החשבון';

  @override
  String get removeAccount => 'הסרת החשבון';

  @override
  String get addAnotherAccount => 'הוספת חשבון נוסף';

  @override
  String get verifiedUserData => 'נתוני המשתמש אומתו!';

  @override
  String loggedInAs(String user) {
    return 'התחברת בתור $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'אירעה שגיאה באימות נתוני המשתמש:';

  @override
  String get verifyingUserData => 'אימות נתוני המשתמש...';

  @override
  String get verifiedUserToken => 'טוקן המשתמש אומת!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'אירעה שגיאה באימות טוקן המשתמש:';

  @override
  String get verifyingUserToken => 'אימות טוקן המשתמש...';

  @override
  String get searchForChannels => 'חיפוש ערוצים';

  @override
  String get recommendedChannels => 'ערוצים מומלצים';

  @override
  String get popularChannels => 'ערוצים פופולריים';

  @override
  String get channel => 'ערוץ';

  @override
  String get leaveChannel => 'יציאה מהערוץ';

  @override
  String joinUser(String user) {
    return 'הצטרפות אל $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'בדיקת האיות נכשלה! אולי הכוונה ל-$username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'הצטרפות אל $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'שליחת הודעה ב-$channel';
  }

  @override
  String get light => 'בהיר';

  @override
  String get dark => 'כהה';

  @override
  String get system => 'לפי המערכת';

  @override
  String get appearance => 'מראה';

  @override
  String get highContrast => 'ניגודיות גבוהה';

  @override
  String get customCommand => 'פקודה מותאמת אישית';

  @override
  String get customCommands => 'פקודות מותאמות אישית';

  @override
  String get newCustomCommand => 'פקודה מותאמת אישית חדשה';

  @override
  String get commandTrigger => 'מילת הפעלה';

  @override
  String get command => 'פקודה';

  @override
  String get save => 'שמירה';

  @override
  String get openInBrowser => 'פתיחה בדפדפן';

  @override
  String get messageAppearance => 'מראה ההודעות';

  @override
  String get showTimestamps => 'הצגת שעה';

  @override
  String get compactMessages => 'הודעות דחוסות';

  @override
  String get showBadges => 'הצגת תגים';

  @override
  String get messageTrigger => 'טריגר הודעה';

  @override
  String get pattern => 'תבנית';

  @override
  String get mention => 'אזכור';

  @override
  String get block => 'חסימה';

  @override
  String get enableRegex => 'שימוש ב-regex';

  @override
  String get caseSensitive => 'תלוי רישיות';

  @override
  String get messageTriggers => 'טריגרים להודעות';

  @override
  String get newMessageTrigger => 'טריגר הודעה חדש';

  @override
  String get reply => 'תגובה';

  @override
  String get copyText => 'העתקת טקסט';

  @override
  String get copyTextSubtitle => 'לחיצה ארוכה מעתיקה יחד עם שם המשתמש';

  @override
  String get deleteMessage => 'מחיקת ההודעה';

  @override
  String get mentionUser => 'אזכור המשתמש';

  @override
  String get copyMessageId => 'העתקת מזהה ההודעה';

  @override
  String get theme => 'ערכת נושא';

  @override
  String get userTrigger => 'טריגר משתמש';

  @override
  String get userTriggers => 'טריגרים למשתמשים';

  @override
  String get chatHistory => 'היסטוריית צ׳אט';

  @override
  String get login => 'שם משתמש';

  @override
  String get newUserTrigger => 'טריגר משתמש חדש';

  @override
  String get ban => 'הרחקה';

  @override
  String get unban => 'ביטול הרחקה';

  @override
  String timeoutUserForDuration(String duration) {
    return 'השעיית המשתמש ל-$duration';
  }

  @override
  String get chatCleared => 'הצ׳אט נוקה';

  @override
  String get permabanned => 'הרחקה לצמיתות';

  @override
  String bannedForDuration(String duration) {
    return 'הרחקה ל-$duration';
  }

  @override
  String get replyingTo => 'תגובה אל';

  @override
  String get blockedMessage => 'הודעה חסומה';

  @override
  String get showMessage => 'הצגת ההודעה';

  @override
  String get hideMessage => 'הסתרת ההודעה';

  @override
  String get scrollToBottom => 'גלילה לסוף';

  @override
  String get appTagline => 'צ\'אט של Twitch עם אימוטים מ-7TV, ‏BTTV ו-FFZ';

  @override
  String get loginWithTwitch => 'התחברות עם Twitch';

  @override
  String get addChannel => 'הוספת ערוץ';

  @override
  String get chatSettings => 'הגדרות צ׳אט';

  @override
  String get autocompleteUsersWithAt => 'השלמה אוטומטית של משתמשים עם @';

  @override
  String get autocompleteEmotesWithColon => 'השלמה אוטומטית של אימוטים עם :';

  @override
  String get language => 'שפה';

  @override
  String get locale => 'שפה ואזור';

  @override
  String get systemDefault => 'ברירת המחדל של המערכת';

  @override
  String get justDefault => 'ברירת מחדל';

  @override
  String get notifications => 'התראות';

  @override
  String get noNotifications => 'מישהו, איפשהו, יזכיר אותך מתישהו.';

  @override
  String get backgroundNotifications => 'התראות ברקע';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'האפשרות הזו אינה זמינה בפלטפורמה שלך.';

  @override
  String get optionNotAvailablePaywalled =>
      'האפשרות הזו זמינה רק לתומכי ColdChat.';

  @override
  String get clearAll => 'ניקוי הכול';

  @override
  String get cache => 'מטמון';

  @override
  String get clearCache => 'ניקוי המטמון';

  @override
  String get chatters => 'משתתפי הצ׳אט';

  @override
  String lastSeenAgo(String time) {
    return 'פעילות אחרונה: לפני $time';
  }

  @override
  String get credits => 'קרדיטים';

  @override
  String get search => 'חיפוש';

  @override
  String get emoteMenuButton => 'כפתור תפריט האימוטים';

  @override
  String get emoteMenuButtonGrayscale =>
      'הצגת כפתור תפריט האימוטים בגווני אפור';

  @override
  String get chooseEmoteMenuButton =>
      'הקשה על אימוט תהפוך אותו לכפתור תפריט האימוטים';

  @override
  String get resetToKappa => 'איפוס ל-Kappa';

  @override
  String get emoteMenuButtonDownloadFailed =>
      'לא ניתן להוריד את האימוט. הכפתור לא שונה.';

  @override
  String get takePhoto => 'צילום תמונה';

  @override
  String get chooseFromLibrary => 'בחירה מהספרייה';

  @override
  String get cameraUnavailable =>
      'לא ניתן לפתוח את המצלמה. יש לוודא של-ColdChat יש גישה למצלמה.';

  @override
  String get about => 'אודות';

  @override
  String get sourceCode => 'קוד מקור';

  @override
  String get license => 'רישיון';

  @override
  String get basedOnChatsen => 'מבוסס על Chatsen';

  @override
  String get openSourceLicenses => 'רישיונות קוד פתוח';

  @override
  String get aboutLegalese =>
      'ColdChat היא תוכנה חופשית: מותר להפיץ אותה מחדש ולשנות אותה בהתאם לתנאי GNU Affero General Public License, גרסה 3. היא מסופקת ללא כל אחריות.';

  @override
  String get unblock => 'ביטול חסימה';

  @override
  String get report => 'דיווח';

  @override
  String reportUserTitle(String name) {
    return 'דיווח על $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Twitch מטפלת בדיווחים. יש לפתוח את הערוץ של $name ב-Twitch ולבחור שם ״דיווח״. אפשר גם לחסום את $name כאן כדי להסתיר את ההודעות.';
  }

  @override
  String get openOnTwitch => 'פתיחה ב-Twitch';

  @override
  String get blockFailed =>
      'לא ניתן לשנות את רשימת החסימות. יש לבדוק את החיבור ולנסות שוב.';

  @override
  String get contact => 'יצירת קשר ומשוב';

  @override
  String get whisper => 'לחישה';

  @override
  String whisperTo(String name) {
    return 'לחישה אל $name';
  }

  @override
  String whisperFrom(String name) {
    return 'לחישה מ-$name';
  }

  @override
  String get openWhisper => 'פתיחה';

  @override
  String get userCard => 'כרטיס משתמש';

  @override
  String get closeConversation => 'סגירת השיחה';

  @override
  String get closeConversationSubtitle =>
      'ההודעות נשמרות במכשיר הזה ויחזרו עם הלחישה הבאה.';

  @override
  String get deleteConversation => 'מחיקת השיחה';

  @override
  String get deleteConversationSubtitle =>
      'מוחק את ההודעות מהמכשיר הזה. Twitch לא שומרת היסטוריית לחישות.';

  @override
  String get whisperNeedsLogin => 'כדי לשלוח לחישות, יש להתחבר עם Twitch.';

  @override
  String get whisperNeedsScope =>
      'כדי לשלוח ולקבל לחישות, יש להתחבר מחדש. ההתחברות הנוכחית היא מלפני ש-ColdChat תמכה בהן.';

  @override
  String get whisperUserNotFound => 'אין משתמש Twitch בשם הזה.';

  @override
  String whisperFailed(String reason) {
    return 'הלחישה לא נשלחה: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'לחישות שנשלחו אליך בזמן ש-ColdChat הייתה סגורה לא מופיעות כאן, כי Twitch לא משתפת את היסטוריית הלחישות עם אפליקציות. אפשר לקרוא אותן ב-Twitch, מאחורי סמל הלחישות בפינה הימנית העליונה.';

  @override
  String get gotIt => 'הבנתי';

  @override
  String get openTwitch => 'פתיחת Twitch';

  @override
  String showImage(String host) {
    return 'הצגת התמונה · $host';
  }

  @override
  String get showImagesFromLinks => 'הצגת תמונות מקישורים';

  @override
  String get showImagesFromLinksSubtitle =>
      'Twitch לא בודקת את התמונות האלה. הן עשויות להיות לא הולמות.';

  @override
  String get showImagesAutomatically => 'להציג תמונות מקישורים באופן אוטומטי?';

  @override
  String get turnOn => 'הפעלה';

  @override
  String get themeIndigo => 'אינדיגו';

  @override
  String get themeBlue => 'כחול';

  @override
  String get themeCyan => 'ציאן';

  @override
  String get themeTeal => 'כחול-ירקרק';

  @override
  String get themeGreen => 'ירוק';

  @override
  String get themeLime => 'ליים';

  @override
  String get themeAmber => 'ענבר';

  @override
  String get themeOrange => 'כתום';

  @override
  String get themeRed => 'אדום';

  @override
  String get themePink => 'ורוד';

  @override
  String get themePurple => 'סגול';

  @override
  String get accentColor => 'צבע הדגשה';

  @override
  String get oledBlack => 'שחור OLED';

  @override
  String get oledBlackSubtitle => 'רקע צ\'אט שחור במצב כהה, למסכי OLED';
}
