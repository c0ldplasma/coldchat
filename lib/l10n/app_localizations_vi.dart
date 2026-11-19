// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return 'Đã đăng nhập qua $provider';
  }

  @override
  String get termsOfService => 'Điều khoản dịch vụ';

  @override
  String get privacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get settings => 'Cài đặt';

  @override
  String get expiresNever => 'Không bao giờ hết hạn';

  @override
  String get loginExpired => 'Phiên đăng nhập đã hết hạn';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch đã từ chối thông tin đăng nhập của $login. Chat sẽ bị ngắt kết nối cho đến khi bạn đăng nhập lại.';
  }

  @override
  String get loginFailed => 'Đăng nhập thất bại';

  @override
  String get signInAgain => 'Đăng nhập';

  @override
  String uploadingTo(String host) {
    return 'Đang tải lên $host';
  }

  @override
  String get uploadProcessing => 'Đang xử lý…';

  @override
  String get uploadFailed => 'Tải lên thất bại';

  @override
  String get uploadDone => 'Đã tải lên';

  @override
  String get uploadRetry => 'Thử lại';

  @override
  String get uploadDismiss => 'Bỏ qua';

  @override
  String get uploadCancel => 'Hủy tải lên';

  @override
  String get uploadErrorOffline => 'Không có kết nối Internet';

  @override
  String uploadErrorTimeout(String host) {
    return '$host không phản hồi';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host đã từ chối tệp tải lên (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host đã gửi phản hồi không mong muốn';
  }

  @override
  String uploadErrorNetwork(String host) {
    return 'Không thể kết nối với $host';
  }

  @override
  String get uploadErrorUnreadableFile => 'Không thể đọc tệp';

  @override
  String uploadErrorUnknown(String host) {
    return 'Tải lên $host thất bại';
  }

  @override
  String get uploadErrorDetails => 'Chi tiết';

  @override
  String uploadRetryingWith(String host) {
    return 'Đang thử lại với $host…';
  }

  @override
  String expiresIn(String time) {
    return 'Hết hạn sau $time';
  }

  @override
  String get close => 'Đóng';

  @override
  String get add => 'Thêm';

  @override
  String get cancel => 'Hủy';

  @override
  String get tokenInput => 'Nhập token';

  @override
  String get account => 'Tài khoản';

  @override
  String get refreshAccount => 'Làm mới tài khoản';

  @override
  String get removeAccount => 'Xóa tài khoản';

  @override
  String get addAnotherAccount => 'Thêm tài khoản khác';

  @override
  String get verifiedUserData => 'Đã xác minh dữ liệu người dùng!';

  @override
  String loggedInAs(String user) {
    return 'Đã đăng nhập với tên $user';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData =>
      'Đã xảy ra lỗi khi xác minh dữ liệu người dùng:';

  @override
  String get verifyingUserData => 'Đang xác minh dữ liệu người dùng...';

  @override
  String get verifiedUserToken => 'Đã xác minh token người dùng!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken =>
      'Đã xảy ra lỗi khi xác minh token người dùng:';

  @override
  String get verifyingUserToken => 'Đang xác minh token người dùng...';

  @override
  String get searchForChannels => 'Tìm kiếm kênh';

  @override
  String get recommendedChannels => 'Kênh đề xuất';

  @override
  String get popularChannels => 'Kênh phổ biến';

  @override
  String get channel => 'Kênh';

  @override
  String get leaveChannel => 'Rời kênh';

  @override
  String joinUser(String user) {
    return 'Vào kênh $user';
  }

  @override
  String spellCheckFailed(String username) {
    return 'Kiểm tra chính tả thất bại! Có phải bạn muốn tìm $username?';
  }

  @override
  String joinChannelName(String channel) {
    return 'Vào kênh $channel';
  }

  @override
  String sendMessageIn(String channel) {
    return 'Gửi tin nhắn trong $channel';
  }

  @override
  String get light => 'Sáng';

  @override
  String get dark => 'Tối';

  @override
  String get system => 'Theo hệ thống';

  @override
  String get appearance => 'Giao diện';

  @override
  String get highContrast => 'Độ tương phản cao';

  @override
  String get customCommand => 'Lệnh tùy chỉnh';

  @override
  String get customCommands => 'Lệnh tùy chỉnh';

  @override
  String get newCustomCommand => 'Lệnh tùy chỉnh mới';

  @override
  String get commandTrigger => 'Từ khóa kích hoạt';

  @override
  String get command => 'Lệnh';

  @override
  String get save => 'Lưu';

  @override
  String get openInBrowser => 'Mở trong trình duyệt';

  @override
  String get messageAppearance => 'Giao diện tin nhắn';

  @override
  String get showTimestamps => 'Hiển thị thời gian';

  @override
  String get compactMessages => 'Tin nhắn thu gọn';

  @override
  String get showBadges => 'Hiển thị huy hiệu';

  @override
  String get messageTrigger => 'Bộ lọc tin nhắn';

  @override
  String get pattern => 'Mẫu';

  @override
  String get mention => 'Nhắc đến';

  @override
  String get block => 'Chặn';

  @override
  String get enableRegex => 'Bật regex';

  @override
  String get caseSensitive => 'Phân biệt chữ hoa/thường';

  @override
  String get messageTriggers => 'Bộ lọc tin nhắn';

  @override
  String get newMessageTrigger => 'Bộ lọc tin nhắn mới';

  @override
  String get reply => 'Trả lời';

  @override
  String get copyText => 'Sao chép văn bản';

  @override
  String get copyTextSubtitle => 'Nhấn giữ để sao chép kèm tên người dùng';

  @override
  String get deleteMessage => 'Xóa tin nhắn';

  @override
  String get mentionUser => 'Nhắc đến người dùng';

  @override
  String get copyMessageId => 'Sao chép ID tin nhắn';

  @override
  String get theme => 'Chủ đề';

  @override
  String get userTrigger => 'Bộ lọc người dùng';

  @override
  String get userTriggers => 'Bộ lọc người dùng';

  @override
  String get chatHistory => 'Lịch sử chat';

  @override
  String get login => 'Tên đăng nhập';

  @override
  String get newUserTrigger => 'Bộ lọc người dùng mới';

  @override
  String get ban => 'Cấm';

  @override
  String get unban => 'Bỏ cấm';

  @override
  String timeoutUserForDuration(String duration) {
    return 'Tạm khóa chat người dùng trong $duration';
  }

  @override
  String get chatCleared => 'Chat đã được xóa';

  @override
  String get permabanned => 'bị cấm vĩnh viễn';

  @override
  String bannedForDuration(String duration) {
    return 'bị cấm trong $duration';
  }

  @override
  String get replyingTo => 'Đang trả lời';

  @override
  String get blockedMessage => 'Tin nhắn bị chặn';

  @override
  String get showMessage => 'Hiện tin nhắn';

  @override
  String get hideMessage => 'Ẩn tin nhắn';

  @override
  String get scrollToBottom => 'Cuộn xuống cuối';

  @override
  String get appTagline =>
      'Chat Twitch với biểu tượng cảm xúc từ 7TV, BTTV và FFZ';

  @override
  String get loginWithTwitch => 'Đăng nhập bằng Twitch';

  @override
  String get addChannel => 'Thêm kênh';

  @override
  String get chatSettings => 'Cài đặt chat';

  @override
  String get autocompleteUsersWithAt => 'Tự động gợi ý người dùng với @';

  @override
  String get autocompleteEmotesWithColon =>
      'Tự động gợi ý biểu tượng cảm xúc với :';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get locale => 'Ngôn ngữ và khu vực';

  @override
  String get systemDefault => 'Mặc định của hệ thống';

  @override
  String get justDefault => 'Mặc định';

  @override
  String get notifications => 'Thông báo';

  @override
  String get noNotifications =>
      'Một ai đó, ở đâu đó, rồi sẽ nhắc đến bạn vào một ngày nào đó.';

  @override
  String get backgroundNotifications => 'Thông báo chạy nền';

  @override
  String get optionNotAvailableOnYourPlatform =>
      'Tùy chọn này không khả dụng trên nền tảng của bạn.';

  @override
  String get optionNotAvailablePaywalled =>
      'Tùy chọn này chỉ dành cho người ủng hộ ColdChat.';

  @override
  String get clearAll => 'Xóa tất cả';

  @override
  String get cache => 'Bộ nhớ đệm';

  @override
  String get clearCache => 'Xóa bộ nhớ đệm';

  @override
  String get chatters => 'Người chat';

  @override
  String lastSeenAgo(String time) {
    return 'Hoạt động $time trước';
  }

  @override
  String get credits => 'Ghi công';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get emoteMenuButton => 'Nút menu biểu tượng cảm xúc';

  @override
  String get emoteMenuButtonGrayscale =>
      'Hiển thị nút menu biểu tượng cảm xúc dạng đen trắng';

  @override
  String get chooseEmoteMenuButton =>
      'Nhấn vào một biểu tượng cảm xúc để dùng làm nút menu';

  @override
  String get resetToKappa => 'Đặt lại về Kappa';

  @override
  String get emoteMenuButtonDownloadFailed =>
      'Không thể tải biểu tượng cảm xúc đó. Nút chưa được thay đổi.';

  @override
  String get takePhoto => 'Chụp ảnh';

  @override
  String get chooseFromLibrary => 'Chọn từ thư viện';

  @override
  String get cameraUnavailable =>
      'Không thể mở camera. Hãy kiểm tra xem ColdChat đã được cấp quyền truy cập camera chưa.';

  @override
  String get about => 'Giới thiệu';

  @override
  String get sourceCode => 'Mã nguồn';

  @override
  String get license => 'Giấy phép';

  @override
  String get basedOnChatsen => 'Dựa trên Chatsen';

  @override
  String get openSourceLicenses => 'Giấy phép mã nguồn mở';

  @override
  String get aboutLegalese =>
      'ColdChat là phần mềm tự do: bạn có thể phân phối lại và chỉnh sửa theo các điều khoản của GNU Affero General Public License, phiên bản 3. Phần mềm được cung cấp HOÀN TOÀN KHÔNG CÓ BẢO HÀNH.';

  @override
  String get unblock => 'Bỏ chặn';

  @override
  String get report => 'Báo cáo';

  @override
  String reportUserTitle(String name) {
    return 'Báo cáo $name';
  }

  @override
  String reportUserDescription(String name) {
    return 'Báo cáo do Twitch xử lý. Hãy mở kênh của $name trên Twitch và chọn Báo cáo ở đó. Bạn cũng có thể chặn $name tại đây để ẩn tin nhắn của họ.';
  }

  @override
  String get openOnTwitch => 'Mở trên Twitch';

  @override
  String get blockFailed =>
      'Không thể thay đổi danh sách chặn. Hãy kiểm tra kết nối và thử lại.';

  @override
  String get contact => 'Liên hệ & góp ý';

  @override
  String get whisper => 'Thì thầm';

  @override
  String whisperTo(String name) {
    return 'Thì thầm với $name';
  }

  @override
  String whisperFrom(String name) {
    return 'Tin thì thầm từ $name';
  }

  @override
  String get openWhisper => 'Mở';

  @override
  String get userCard => 'Thẻ người dùng';

  @override
  String get closeConversation => 'Đóng cuộc trò chuyện';

  @override
  String get closeConversationSubtitle =>
      'Tin nhắn vẫn được lưu trên thiết bị này và sẽ hiện lại khi có tin thì thầm tiếp theo.';

  @override
  String get deleteConversation => 'Xóa cuộc trò chuyện';

  @override
  String get deleteConversationSubtitle =>
      'Xóa tin nhắn khỏi thiết bị này. Twitch không lưu lịch sử tin thì thầm.';

  @override
  String get whisperNeedsLogin => 'Hãy đăng nhập Twitch để gửi tin thì thầm.';

  @override
  String get whisperNeedsScope =>
      'Hãy đăng nhập lại để gửi và nhận tin thì thầm. Phiên đăng nhập của bạn có từ trước khi ColdChat hỗ trợ tính năng này.';

  @override
  String get whisperUserNotFound =>
      'Không có người dùng Twitch nào có tên này.';

  @override
  String whisperFailed(String reason) {
    return 'Chưa gửi được tin thì thầm: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'Tin thì thầm bạn nhận được khi ColdChat đang đóng sẽ không hiện ở đây, vì Twitch không chia sẻ lịch sử tin thì thầm với các ứng dụng. Bạn có thể đọc chúng trên Twitch, qua biểu tượng thì thầm ở góc trên bên phải.';

  @override
  String get gotIt => 'Đã hiểu';

  @override
  String get openTwitch => 'Mở Twitch';

  @override
  String showImage(String host) {
    return 'Hiện ảnh · $host';
  }

  @override
  String get showImagesFromLinks => 'Hiện ảnh từ liên kết';

  @override
  String get showImagesFromLinksSubtitle =>
      'Twitch không kiểm duyệt những ảnh này. Chúng có thể có nội dung không phù hợp.';

  @override
  String get showImagesAutomatically => 'Tự động hiện ảnh từ liên kết?';

  @override
  String get turnOn => 'Bật';

  @override
  String get themeIndigo => 'Chàm';

  @override
  String get themeBlue => 'Xanh dương';

  @override
  String get themeTeal => 'Xanh mòng két';

  @override
  String get themeGreen => 'Xanh lá';

  @override
  String get themeLime => 'Xanh chanh';

  @override
  String get themeAmber => 'Hổ phách';

  @override
  String get themeOrange => 'Cam';

  @override
  String get themeRed => 'Đỏ';

  @override
  String get themePink => 'Hồng';

  @override
  String get themePurple => 'Tím';

  @override
  String get accentColor => 'Màu nhấn';

  @override
  String get oledBlack => 'Đen OLED';

  @override
  String get oledBlackSubtitle =>
      'Nền trò chuyện màu đen ở chế độ tối, cho màn hình OLED';

  @override
  String get customColor => 'Tùy chỉnh';

  @override
  String get hue => 'Sắc độ';

  @override
  String get saturation => 'Độ bão hòa';

  @override
  String get themeIce => 'Băng';
}
