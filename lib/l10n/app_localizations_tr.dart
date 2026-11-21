// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return '$provider ile giriş yapıldı';
  }

  @override
  String get termsOfService => 'Kullanım Şartları';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get settings => 'Ayarlar';

  @override
  String get expiresNever => 'Süresi dolmaz';

  @override
  String get loginExpired => 'Oturumun süresi doldu';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch, $login için girişi reddetti. Tekrar giriş yapana kadar sohbet bağlantısı kesik kalır.';
  }

  @override
  String get loginFailed => 'Giriş başarısız';

  @override
  String get signInAgain => 'Giriş yap';

  @override
  String uploadingTo(String host) {
    return '$host sunucusuna yükleniyor';
  }

  @override
  String get uploadProcessing => 'İşleniyor…';

  @override
  String get uploadFailed => 'Yükleme başarısız';

  @override
  String get uploadDone => 'Yüklendi';

  @override
  String get uploadRetry => 'Tekrar dene';

  @override
  String get uploadDismiss => 'Kapat';

  @override
  String get uploadCancel => 'Yüklemeyi iptal et';

  @override
  String get uploadErrorOffline => 'İnternet bağlantısı yok';

  @override
  String uploadErrorTimeout(String host) {
    return '$host yanıt vermiyor';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host yüklemeyi reddetti (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host beklenmeyen bir yanıt gönderdi';
  }

  @override
  String uploadErrorNetwork(String host) {
    return '$host sunucusuna bağlanılamadı';
  }

  @override
  String get uploadErrorUnreadableFile => 'Dosya okunamadı';

  @override
  String uploadErrorUnknown(String host) {
    return '$host sunucusuna yükleme başarısız';
  }

  @override
  String get uploadErrorDetails => 'Ayrıntılar';

  @override
  String uploadRetryingWith(String host) {
    return '$host ile tekrar deneniyor…';
  }

  @override
  String expiresIn(String time) {
    return '$time sonra sona erecek';
  }

  @override
  String get close => 'Kapat';

  @override
  String get add => 'Ekle';

  @override
  String get cancel => 'İptal';

  @override
  String get tokenInput => 'Token girişi';

  @override
  String get account => 'Hesap';

  @override
  String get refreshAccount => 'Hesabı yenile';

  @override
  String get removeAccount => 'Hesabı kaldır';

  @override
  String get addAnotherAccount => 'Başka bir hesap ekle';

  @override
  String get verifiedUserData => 'Kullanıcı verileri doğrulandı!';

  @override
  String loggedInAs(String user) {
    return '$user olarak giriş yapıldı';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => 'Kullanıcı verileri doğrulanırken bir hata oluştu:';

  @override
  String get verifyingUserData => 'Kullanıcı verileri doğrulanıyor...';

  @override
  String get verifiedUserToken => 'Kullanıcı token\'ı doğrulandı!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken => 'Kullanıcı token\'ı doğrulanırken bir hata oluştu:';

  @override
  String get verifyingUserToken => 'Kullanıcı token\'ı doğrulanıyor...';

  @override
  String get searchForChannels => 'Kanal ara';

  @override
  String get channelSearchFailed => 'Kanallar aranamadı';

  @override
  String get recommendedChannels => 'Önerilen kanallar';

  @override
  String get popularChannels => 'Popüler kanallar';

  @override
  String get channel => 'Kanal';

  @override
  String get leaveChannel => 'Kanaldan ayrıl';

  @override
  String joinUser(String user) {
    return '$user kanalına katıl';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Yazım hatası olabilir! $username kullanıcısını mı arıyorsun?';
  }

  @override
  String joinChannelName(String channel) {
    return '$channel kanalına katıl';
  }

  @override
  String sendMessageIn(String channel) {
    return '$channel kanalına mesaj gönder';
  }

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get system => 'Sistem';

  @override
  String get appearance => 'Görünüm';

  @override
  String get highContrast => 'Yüksek kontrast';

  @override
  String get customCommand => 'Özel komut';

  @override
  String get customCommands => 'Özel komutlar';

  @override
  String get newCustomCommand => 'Yeni özel komut';

  @override
  String get commandTrigger => 'Tetikleyici';

  @override
  String get command => 'Komut';

  @override
  String get save => 'Kaydet';

  @override
  String get openInBrowser => 'Tarayıcıda aç';

  @override
  String get messageAppearance => 'Mesaj görünümü';

  @override
  String get showTimestamps => 'Saati göster';

  @override
  String get compactMessages => 'Kompakt mesajlar';

  @override
  String get showBadges => 'Rozetleri göster';

  @override
  String get messageTrigger => 'Mesaj tetikleyicisi';

  @override
  String get pattern => 'Kalıp';

  @override
  String get mention => 'Vurgula';

  @override
  String get block => 'Engelle';

  @override
  String get enableRegex => 'Regex kullan';

  @override
  String get caseSensitive => 'Büyük/küçük harfe duyarlı';

  @override
  String get messageTriggers => 'Mesaj tetikleyicileri';

  @override
  String get newMessageTrigger => 'Yeni mesaj tetikleyicisi';

  @override
  String get reply => 'Yanıtla';

  @override
  String get copyText => 'Metni kopyala';

  @override
  String get copyTextSubtitle => 'Kullanıcı adıyla kopyalamak için basılı tut';

  @override
  String get deleteMessage => 'Mesajı sil';

  @override
  String get mentionUser => 'Kullanıcıdan bahset';

  @override
  String get copyMessageId => 'Mesaj kimliğini kopyala';

  @override
  String get theme => 'Tema';

  @override
  String get userTrigger => 'Kullanıcı tetikleyicisi';

  @override
  String get userTriggers => 'Kullanıcı tetikleyicileri';

  @override
  String get chatHistory => 'Sohbet geçmişi';

  @override
  String get login => 'Kullanıcı adı';

  @override
  String get newUserTrigger => 'Yeni kullanıcı tetikleyicisi';

  @override
  String get ban => 'Yasakla';

  @override
  String get unban => 'Yasağı kaldır';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Kullanıcıya $duration zaman aşımı ver';
  }

  @override
  String get chatCleared => 'Sohbet temizlendi';

  @override
  String get permabanned => 'kalıcı olarak yasaklandı';

  @override
  String bannedForDuration(String duration) {
    return '$duration süreyle yasaklandı';
  }

  @override
  String get replyingTo => 'Yanıtlanan:';

  @override
  String get blockedMessage => 'Engellenen mesaj';

  @override
  String get showMessage => 'Mesajı göster';

  @override
  String get hideMessage => 'Mesajı gizle';

  @override
  String get scrollToBottom => 'En alta kaydır';

  @override
  String get appTagline => '7TV, BTTV ve FFZ ifadeleriyle Twitch sohbeti';

  @override
  String get loginWithTwitch => 'Twitch ile giriş yap';

  @override
  String get addChannel => 'Kanal ekle';

  @override
  String get chatSettings => 'Sohbet ayarları';

  @override
  String get autocompleteUsersWithAt => '@ ile kullanıcı adlarını tamamla';

  @override
  String get autocompleteEmotesWithColon => ': ile ifadeleri tamamla';

  @override
  String get language => 'Dil';

  @override
  String get locale => 'Dil ve bölge';

  @override
  String get systemDefault => 'Sistem varsayılanı';

  @override
  String get justDefault => 'Varsayılan';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get noNotifications => 'Biri, bir yerde, bir gün senden bahsedecek.';

  @override
  String get backgroundNotifications => 'Arka plan bildirimleri';

  @override
  String get optionNotAvailableOnYourPlatform => 'Bu seçenek platformunda kullanılamıyor.';

  @override
  String get optionNotAvailablePaywalled => 'Bu seçenek yalnızca ColdChat destekçileri için.';

  @override
  String get clearAll => 'Tümünü temizle';

  @override
  String get cache => 'Önbellek';

  @override
  String get clearCache => 'Önbelleği temizle';

  @override
  String get chatters => 'Sohbettekiler';

  @override
  String lastSeenAgo(String time) {
    return 'Son görülme: $time önce';
  }

  @override
  String get credits => 'Emeği geçenler';

  @override
  String get search => 'Ara';

  @override
  String get emoteMenuButton => 'İfade menüsü düğmesi';

  @override
  String get emoteMenuButtonGrayscale => 'İfade menüsü düğmesini gri tonlamalı göster';

  @override
  String get chooseEmoteMenuButton => 'İfade menüsü düğmesi olarak kullanmak için bir ifadeye dokun';

  @override
  String get resetToKappa => 'Kappa\'ya sıfırla';

  @override
  String get emoteMenuButtonDownloadFailed => 'İfade indirilemedi. Düğme değiştirilmedi.';

  @override
  String get takePhoto => 'Fotoğraf çek';

  @override
  String get chooseFromLibrary => 'Galeriden seç';

  @override
  String get cameraUnavailable => 'Kamera açılamadı. ColdChat\'in kameraya erişimi olup olmadığını kontrol et.';

  @override
  String get about => 'Hakkında';

  @override
  String get sourceCode => 'Kaynak kodu';

  @override
  String get license => 'Lisans';

  @override
  String get basedOnChatsen => 'Chatsen tabanlı';

  @override
  String get openSourceLicenses => 'Açık kaynak lisansları';

  @override
  String get aboutLegalese =>
      'ColdChat özgür bir yazılımdır: GNU Affero General Public License sürüm 3\'ün koşulları altında yeniden dağıtabilir ve değiştirebilirsin. HİÇBİR GARANTİ OLMADAN sunulur.';

  @override
  String get unblock => 'Engeli kaldır';

  @override
  String get report => 'Bildir';

  @override
  String reportUserTitle(String name) {
    return '$name adlı kullanıcıyı bildir';
  }

  @override
  String reportUserDescription(String name) {
    return 'Bildirimleri Twitch inceler. Twitch\'te $name kanalını aç ve orada Bildir\'i seç. Mesajlarını gizlemek için $name adlı kullanıcıyı burada engelleyebilirsin de.';
  }

  @override
  String get openOnTwitch => 'Twitch\'te aç';

  @override
  String get blockFailed => 'Engellenenler listesi değiştirilemedi. Bağlantını kontrol et ve tekrar dene.';

  @override
  String get moderationNeedsLogin => 'Bu kanalı yönetmek için Twitch ile giriş yap.';

  @override
  String get moderationNeedsScope =>
      'Kullanıcıları yasaklamak ve zaman aşımı vermek için tekrar giriş yap. Girişin, ColdChat bunu yapabilmeden önceye ait.';

  @override
  String moderationFailed(String reason) {
    return 'Olmadı: $reason';
  }

  @override
  String get contact => 'İletişim ve geri bildirim';

  @override
  String get whisper => 'Fısıltı';

  @override
  String whisperTo(String name) {
    return '$name kullanıcısına fısılda';
  }

  @override
  String whisperFrom(String name) {
    return '$name kullanıcısından fısıltı';
  }

  @override
  String get openWhisper => 'Aç';

  @override
  String get userCard => 'Kullanıcı kartı';

  @override
  String get closeConversation => 'Sohbeti kapat';

  @override
  String get closeConversationSubtitle => 'Mesajlar bu cihazda kalır ve bir sonraki fısıltıyla geri gelir.';

  @override
  String get deleteConversation => 'Sohbeti sil';

  @override
  String get deleteConversationSubtitle => 'Mesajları bu cihazdan siler. Twitch fısıltı geçmişi tutmaz.';

  @override
  String get whisperNeedsLogin => 'Fısıltı göndermek için Twitch ile giriş yap.';

  @override
  String get whisperNeedsScope =>
      'Fısıltı gönderip almak için tekrar giriş yap. Girişin, ColdChat fısıltıları desteklemeden önceye ait.';

  @override
  String get whisperUserNotFound => 'Bu adda bir Twitch kullanıcısı yok.';

  @override
  String whisperFailed(String reason) {
    return 'Fısıltı gönderilmedi: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'ColdChat kapalıyken gelen fısıltılar burada görünmez, çünkü Twitch fısıltı geçmişini uygulamalarla paylaşmaz. Onları Twitch\'te sağ üstteki fısıltı simgesinden okuyabilirsin.';

  @override
  String get gotIt => 'Anladım';

  @override
  String get openTwitch => 'Twitch\'i aç';

  @override
  String showImage(String host) {
    return 'Görseli göster · $host';
  }

  @override
  String get showImagesFromLinks => 'Bağlantılardaki görselleri göster';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch bu görselleri denetlemez. Uygunsuz olabilirler.';

  @override
  String get showImagesAutomatically => 'Bağlantılardaki görseller otomatik gösterilsin mi?';

  @override
  String get turnOn => 'Aç';

  @override
  String get themeIndigo => 'Çivit';

  @override
  String get themeBlue => 'Mavi';

  @override
  String get themeTeal => 'Petrol mavisi';

  @override
  String get themeGreen => 'Yeşil';

  @override
  String get themeLime => 'Limon yeşili';

  @override
  String get themeAmber => 'Kehribar';

  @override
  String get themeOrange => 'Turuncu';

  @override
  String get themeRed => 'Kırmızı';

  @override
  String get themePink => 'Pembe';

  @override
  String get themePurple => 'Mor';

  @override
  String get accentColor => 'Vurgu rengi';

  @override
  String get oledBlack => 'OLED siyahı';

  @override
  String get oledBlackSubtitle => 'Karanlık modda siyah sohbet arka planı, OLED ekranlar için';

  @override
  String get customColor => 'Özel';

  @override
  String get hue => 'Ton';

  @override
  String get saturation => 'Doygunluk';

  @override
  String get themeIce => 'Buz';

  @override
  String channelConnecting(String channel) {
    return '$channel kanalına bağlanılıyor…';
  }

  @override
  String channelConnected(String channel) {
    return '$channel kanalına bağlanıldı';
  }

  @override
  String channelDisconnected(String channel) {
    return '$channel kanalıyla bağlantı kesildi';
  }

  @override
  String channelSuspended(String channel) {
    return '$channel Twitch tarafından askıya alındı';
  }

  @override
  String channelBanned(String channel) {
    return '$channel kanalından banlandın';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika',
    );
    return '$_temp0';
  }
}
