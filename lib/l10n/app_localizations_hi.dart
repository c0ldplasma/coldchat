// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return '$provider से लॉग इन किया गया';
  }

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get expiresNever => 'कभी समाप्त नहीं होगा';

  @override
  String get loginExpired => 'लॉगिन की अवधि समाप्त हो गई';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch ने $login का लॉगिन अस्वीकार कर दिया। जब तक आप फिर से साइन इन नहीं करते, चैट डिस्कनेक्ट रहेगी।';
  }

  @override
  String get loginFailed => 'लॉगिन विफल रहा';

  @override
  String get signInAgain => 'साइन इन करें';

  @override
  String uploadingTo(String host) {
    return '$host पर अपलोड हो रहा है';
  }

  @override
  String get uploadProcessing => 'प्रोसेस हो रहा है…';

  @override
  String get uploadFailed => 'अपलोड विफल रहा';

  @override
  String get uploadDone => 'अपलोड हो गया';

  @override
  String get uploadRetry => 'फिर से कोशिश करें';

  @override
  String get uploadDismiss => 'खारिज करें';

  @override
  String get uploadCancel => 'अपलोड रद्द करें';

  @override
  String get uploadErrorOffline => 'इंटरनेट कनेक्शन नहीं है';

  @override
  String uploadErrorTimeout(String host) {
    return '$host जवाब नहीं दे रहा है';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host ने अपलोड अस्वीकार कर दिया (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host ने अनपेक्षित जवाब भेजा';
  }

  @override
  String uploadErrorNetwork(String host) {
    return '$host से कनेक्ट नहीं हो सका';
  }

  @override
  String get uploadErrorUnreadableFile => 'फ़ाइल पढ़ी नहीं जा सकी';

  @override
  String uploadErrorUnknown(String host) {
    return '$host पर अपलोड विफल रहा';
  }

  @override
  String get uploadErrorDetails => 'विवरण';

  @override
  String uploadRetryingWith(String host) {
    return '$host के साथ फिर से कोशिश की जा रही है…';
  }

  @override
  String expiresIn(String time) {
    return '$time में समाप्त होगा';
  }

  @override
  String get close => 'बंद करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get tokenInput => 'टोकन डालें';

  @override
  String get account => 'खाता';

  @override
  String get refreshAccount => 'खाता रीफ़्रेश करें';

  @override
  String get removeAccount => 'खाता हटाएं';

  @override
  String get addAnotherAccount => 'एक और खाता जोड़ें';

  @override
  String get verifiedUserData => 'उपयोगकर्ता डेटा सत्यापित हो गया!';

  @override
  String loggedInAs(String user) {
    return '$user के रूप में लॉग इन';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => 'उपयोगकर्ता डेटा सत्यापित करते समय एक त्रुटि हुई:';

  @override
  String get verifyingUserData => 'उपयोगकर्ता डेटा सत्यापित किया जा रहा है...';

  @override
  String get verifiedUserToken => 'उपयोगकर्ता टोकन सत्यापित हो गया!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken => 'उपयोगकर्ता टोकन सत्यापित करते समय एक त्रुटि हुई:';

  @override
  String get verifyingUserToken => 'उपयोगकर्ता टोकन सत्यापित किया जा रहा है...';

  @override
  String get searchForChannels => 'चैनल खोजें';

  @override
  String get channelSearchFailed => 'चैनल नहीं खोजे जा सके';

  @override
  String get recommendedChannels => 'सुझाए गए चैनल';

  @override
  String get popularChannels => 'लोकप्रिय चैनल';

  @override
  String get channel => 'चैनल';

  @override
  String get leaveChannel => 'चैनल छोड़ें';

  @override
  String joinUser(String user) {
    return '$user से जुड़ें';
  }

  @override
  String spellCheckFailed(String username) {
    return 'वर्तनी जांच विफल रही! क्या आप $username खोजना चाहते थे?';
  }

  @override
  String joinChannelName(String channel) {
    return '$channel से जुड़ें';
  }

  @override
  String sendMessageIn(String channel) {
    return '$channel में संदेश भेजें';
  }

  @override
  String get light => 'लाइट';

  @override
  String get dark => 'डार्क';

  @override
  String get system => 'सिस्टम';

  @override
  String get appearance => 'रूप-रंग';

  @override
  String get highContrast => 'हाई कॉन्ट्रास्ट';

  @override
  String get customCommand => 'कस्टम कमांड';

  @override
  String get customCommands => 'कस्टम कमांड';

  @override
  String get newCustomCommand => 'नई कस्टम कमांड';

  @override
  String get commandTrigger => 'ट्रिगर';

  @override
  String get command => 'कमांड';

  @override
  String get save => 'सेव करें';

  @override
  String get openInBrowser => 'ब्राउज़र में खोलें';

  @override
  String get messageAppearance => 'संदेशों का रूप';

  @override
  String get showTimestamps => 'टाइमस्टैम्प दिखाएं';

  @override
  String get compactMessages => 'कॉम्पैक्ट संदेश';

  @override
  String get showBadges => 'बैज दिखाएं';

  @override
  String get messageTrigger => 'संदेश ट्रिगर';

  @override
  String get pattern => 'पैटर्न';

  @override
  String get mention => 'मेंशन';

  @override
  String get block => 'ब्लॉक';

  @override
  String get enableRegex => 'regex चालू करें';

  @override
  String get invalidRegex => 'यह मान्य regex नहीं है';

  @override
  String get caseSensitive => 'केस-सेंसिटिव';

  @override
  String get messageTriggers => 'संदेश ट्रिगर';

  @override
  String get newMessageTrigger => 'नया संदेश ट्रिगर';

  @override
  String get reply => 'जवाब दें';

  @override
  String get copyText => 'टेक्स्ट कॉपी करें';

  @override
  String get copyTextSubtitle => 'उपयोगकर्ता नाम के साथ कॉपी करने के लिए दबाकर रखें';

  @override
  String get deleteMessage => 'संदेश मिटाएं';

  @override
  String deleteMessageFailed(String reason) {
    return 'संदेश नहीं हटाया गया: $reason';
  }

  @override
  String get deleteMessageNeedsScope =>
      'संदेश हटाने के लिए फिर से साइन इन करें। आपका लॉगिन उस समय का है जब ColdChat संदेश नहीं हटा सकता था।';

  @override
  String get mentionUser => 'उपयोगकर्ता को मेंशन करें';

  @override
  String get copyMessageId => 'संदेश ID कॉपी करें';

  @override
  String get theme => 'थीम';

  @override
  String get userTrigger => 'उपयोगकर्ता ट्रिगर';

  @override
  String get userTriggers => 'उपयोगकर्ता ट्रिगर';

  @override
  String get chatHistory => 'चैट इतिहास';

  @override
  String get login => 'लॉगिन नाम';

  @override
  String get newUserTrigger => 'नया उपयोगकर्ता ट्रिगर';

  @override
  String get ban => 'बैन करें';

  @override
  String get unban => 'बैन हटाएं';

  @override
  String timeoutUserForDuration(String duration) {
    return 'उपयोगकर्ता को $duration के लिए टाइमआउट करें';
  }

  @override
  String get chatCleared => 'चैट साफ़ कर दी गई';

  @override
  String get permabanned => 'स्थायी रूप से बैन';

  @override
  String bannedForDuration(String duration) {
    return '$duration के लिए बैन';
  }

  @override
  String get replyingTo => 'जवाब:';

  @override
  String get blockedMessage => 'ब्लॉक किया गया संदेश';

  @override
  String get showMessage => 'संदेश दिखाएं';

  @override
  String get hideMessage => 'संदेश छिपाएं';

  @override
  String get scrollToBottom => 'सबसे नीचे जाएं';

  @override
  String get appTagline => '7TV, BTTV और FFZ इमोट के साथ Twitch चैट';

  @override
  String get continueWithoutLogin => 'लॉग इन किए बिना जारी रखें';

  @override
  String get logInForSearch => 'चैनल खोजने और लाइव स्ट्रीम देखने के लिए लॉग इन करें';

  @override
  String get loginWithTwitch => 'Twitch से लॉग इन करें';

  @override
  String get addChannel => 'चैनल जोड़ें';

  @override
  String get chatSettings => 'चैट सेटिंग्स';

  @override
  String get autocompleteUsersWithAt => '@ से उपयोगकर्ता नाम ऑटोकम्प्लीट करें';

  @override
  String get autocompleteEmotesWithColon => ': से इमोट ऑटोकम्प्लीट करें';

  @override
  String get language => 'भाषा';

  @override
  String get locale => 'भाषा और क्षेत्र';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get justDefault => 'डिफ़ॉल्ट';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get noNotifications => 'कोई न कोई, कहीं न कहीं, किसी दिन आपको मेंशन करेगा।';

  @override
  String get backgroundNotifications => 'बैकग्राउंड सूचनाएं';

  @override
  String get optionNotAvailableOnYourPlatform => 'यह विकल्प आपके प्लेटफ़ॉर्म पर उपलब्ध नहीं है।';

  @override
  String get optionNotAvailablePaywalled => 'यह विकल्प केवल ColdChat समर्थकों के लिए है।';

  @override
  String get clearAll => 'सब साफ़ करें';

  @override
  String get cache => 'कैश';

  @override
  String get clearCache => 'कैश साफ़ करें';

  @override
  String get emoteCache => 'इमोट कैश';

  @override
  String emoteCacheUsage(String used, String limit) {
    return '$limit में से $used';
  }

  @override
  String megabytes(String size) {
    return '$size MB';
  }

  @override
  String get chatters => 'चैटर्स';

  @override
  String lastSeenAgo(String time) {
    return '$time पहले देखा गया';
  }

  @override
  String get credits => 'क्रेडिट';

  @override
  String get search => 'खोजें';

  @override
  String get emoteMenuButton => 'इमोट मेनू बटन';

  @override
  String get emoteMenuButtonGrayscale => 'इमोट मेनू बटन ग्रेस्केल में दिखाएं';

  @override
  String get chooseEmoteMenuButton => 'किसी इमोट को इमोट मेनू बटन बनाने के लिए उस पर टैप करें';

  @override
  String get resetToKappa => 'Kappa पर रीसेट करें';

  @override
  String get emoteMenuButtonDownloadFailed => 'वह इमोट डाउनलोड नहीं हो सका। बटन नहीं बदला गया।';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get chooseFromLibrary => 'लाइब्रेरी से चुनें';

  @override
  String get cameraUnavailable => 'कैमरा नहीं खुल सका। जांचें कि ColdChat को कैमरा एक्सेस की अनुमति है।';

  @override
  String get about => 'परिचय';

  @override
  String get sourceCode => 'सोर्स कोड';

  @override
  String get license => 'लाइसेंस';

  @override
  String get basedOnChatsen => 'Chatsen पर आधारित';

  @override
  String get openSourceLicenses => 'ओपन सोर्स लाइसेंस';

  @override
  String get aboutLegalese =>
      'ColdChat एक मुक्त सॉफ़्टवेयर है: आप इसे GNU Affero General Public License, संस्करण 3 की शर्तों के तहत पुनर्वितरित और संशोधित कर सकते हैं। इसके साथ कोई भी वारंटी नहीं दी जाती।';

  @override
  String get unblock => 'अनब्लॉक करें';

  @override
  String get report => 'रिपोर्ट करें';

  @override
  String reportUserTitle(String name) {
    return '$name की रिपोर्ट करें';
  }

  @override
  String reportUserDescription(String name) {
    return 'रिपोर्ट Twitch द्वारा संभाली जाती हैं। Twitch पर $name का चैनल खोलें और वहां रिपोर्ट करें चुनें। आप यहां $name को ब्लॉक करके उनके संदेश छिपा भी सकते हैं।';
  }

  @override
  String get openOnTwitch => 'Twitch पर खोलें';

  @override
  String get blockFailed => 'ब्लॉक सूची नहीं बदली जा सकी। अपना कनेक्शन जांचें और फिर से कोशिश करें।';

  @override
  String get moderationNeedsLogin => 'इस चैनल को मॉडरेट करने के लिए Twitch से लॉग इन करें।';

  @override
  String get moderationNeedsScope =>
      'यूज़र्स को बैन और टाइमआउट करने के लिए फिर से साइन इन करें। आपका लॉगिन उस समय का है जब ColdChat यह नहीं कर सकता था।';

  @override
  String moderationFailed(String reason) {
    return 'यह नहीं हो सका: $reason';
  }

  @override
  String get contact => 'संपर्क और फ़ीडबैक';

  @override
  String get whisper => 'व्हिस्पर';

  @override
  String whisperTo(String name) {
    return '$name को व्हिस्पर करें';
  }

  @override
  String whisperFrom(String name) {
    return '$name का व्हिस्पर';
  }

  @override
  String get openWhisper => 'खोलें';

  @override
  String get userCard => 'यूज़र कार्ड';

  @override
  String get closeConversation => 'बातचीत बंद करें';

  @override
  String get closeConversationSubtitle => 'संदेश इस डिवाइस पर रहेंगे और अगले व्हिस्पर के साथ वापस आ जाएंगे।';

  @override
  String get deleteConversation => 'बातचीत मिटाएं';

  @override
  String get deleteConversationSubtitle => 'इस डिवाइस से संदेश मिटा देता है। Twitch व्हिस्पर का इतिहास नहीं रखता।';

  @override
  String get whisperNeedsLogin => 'व्हिस्पर भेजने के लिए Twitch से साइन इन करें।';

  @override
  String get whisperNeedsScope =>
      'व्हिस्पर भेजने और पाने के लिए फिर से साइन इन करें। आपका लॉगिन उस समय का है जब ColdChat इन्हें सपोर्ट नहीं करता था।';

  @override
  String get whisperUserNotFound => 'इस नाम का कोई Twitch उपयोगकर्ता नहीं है।';

  @override
  String get messageNotSentNotConnected => 'अभी इस चैनल से कनेक्ट नहीं है। आपका संदेश नहीं भेजा गया।';

  @override
  String whisperFailed(String reason) {
    return 'व्हिस्पर नहीं भेजा गया: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'ColdChat बंद रहने के दौरान आपको भेजे गए व्हिस्पर यहां नहीं दिखते, क्योंकि Twitch ऐप्स के साथ व्हिस्पर का इतिहास साझा नहीं करता। आप उन्हें Twitch पर, ऊपर दाईं ओर व्हिस्पर आइकन में पढ़ सकते हैं।';

  @override
  String get gotIt => 'ठीक है';

  @override
  String get openTwitch => 'Twitch खोलें';

  @override
  String showImage(String host) {
    return 'इमेज दिखाएं · $host';
  }

  @override
  String get showImagesFromLinks => 'लिंक से इमेज दिखाएं';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch इन इमेज की जांच नहीं करता। ये अनुचित हो सकती हैं।';

  @override
  String get showImagesAutomatically => 'लिंक से इमेज अपने-आप दिखाएं?';

  @override
  String get turnOn => 'चालू करें';

  @override
  String get themeIndigo => 'इंडिगो';

  @override
  String get themeBlue => 'नीला';

  @override
  String get themeTeal => 'टील';

  @override
  String get themeGreen => 'हरा';

  @override
  String get themeLime => 'लाइम';

  @override
  String get themeAmber => 'एम्बर';

  @override
  String get themeOrange => 'नारंगी';

  @override
  String get themeRed => 'लाल';

  @override
  String get themePink => 'गुलाबी';

  @override
  String get themePurple => 'बैंगनी';

  @override
  String get accentColor => 'एक्सेंट रंग';

  @override
  String get oledBlack => 'OLED काला';

  @override
  String get oledBlackSubtitle => 'डार्क मोड में काला चैट बैकग्राउंड, OLED स्क्रीन के लिए';

  @override
  String get customColor => 'कस्टम';

  @override
  String get hue => 'रंगत';

  @override
  String get saturation => 'संतृप्ति';

  @override
  String get themeIce => 'बर्फ़';

  @override
  String channelConnecting(String channel) {
    return '$channel से कनेक्ट हो रहा है…';
  }

  @override
  String channelConnected(String channel) {
    return '$channel से कनेक्ट हो गया';
  }

  @override
  String channelDisconnected(String channel) {
    return '$channel से डिस्कनेक्ट हो गया';
  }

  @override
  String channelSuspended(String channel) {
    return 'Twitch ने $channel को निलंबित कर दिया है';
  }

  @override
  String channelBanned(String channel) {
    return 'तुम $channel में बैन हो';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे',
      one: '1 घंटे',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मिनट',
      one: '1 मिनट',
    );
    return '$_temp0';
  }

  @override
  String durationDaysShort(int count) {
    return '$count दिन';
  }

  @override
  String durationHoursShort(int count) {
    return '$count घं॰';
  }

  @override
  String durationMinutesShort(int count) {
    return '$count मि॰';
  }

  @override
  String durationSecondsShort(int count) {
    return '$count से॰';
  }

  @override
  String durationPair(String larger, String smaller) {
    return '$larger $smaller';
  }
}
