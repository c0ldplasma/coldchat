// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return '$provider(으)로 로그인됨';
  }

  @override
  String get termsOfService => '이용약관';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get settings => '설정';

  @override
  String get expiresNever => '만료 없음';

  @override
  String get loginExpired => '로그인 만료됨';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitch에서 $login의 로그인을 거부했어요. 다시 로그인할 때까지 채팅 연결이 끊긴 상태로 유지돼요.';
  }

  @override
  String get loginFailed => '로그인 실패';

  @override
  String get signInAgain => '로그인';

  @override
  String uploadingTo(String host) {
    return '$host에 업로드 중';
  }

  @override
  String get uploadProcessing => '처리 중…';

  @override
  String get uploadFailed => '업로드 실패';

  @override
  String get uploadDone => '업로드 완료';

  @override
  String get uploadRetry => '다시 시도';

  @override
  String get uploadDismiss => '닫기';

  @override
  String get uploadCancel => '업로드 취소';

  @override
  String get uploadErrorOffline => '인터넷에 연결되어 있지 않아요';

  @override
  String uploadErrorTimeout(String host) {
    return '$host에서 응답이 없어요';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$host에서 업로드를 거부했어요 (HTTP $status)';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$host에서 예상치 못한 응답을 보냈어요';
  }

  @override
  String uploadErrorNetwork(String host) {
    return '$host에 연결할 수 없어요';
  }

  @override
  String get uploadErrorUnreadableFile => '파일을 읽을 수 없어요';

  @override
  String uploadErrorUnknown(String host) {
    return '$host에 업로드하지 못했어요';
  }

  @override
  String get uploadErrorDetails => '자세히';

  @override
  String uploadRetryingWith(String host) {
    return '$host(으)로 다시 시도하는 중…';
  }

  @override
  String expiresIn(String time) {
    return '$time 후 만료';
  }

  @override
  String get close => '닫기';

  @override
  String get add => '추가';

  @override
  String get cancel => '취소';

  @override
  String get tokenInput => '토큰 입력';

  @override
  String get account => '계정';

  @override
  String get refreshAccount => '계정 새로고침';

  @override
  String get removeAccount => '계정 제거';

  @override
  String get addAnotherAccount => '다른 계정 추가';

  @override
  String get verifiedUserData => '사용자 데이터 확인 완료!';

  @override
  String loggedInAs(String user) {
    return '$user(으)로 로그인됨';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => '사용자 데이터를 확인하는 중 오류가 발생했어요:';

  @override
  String get verifyingUserData => '사용자 데이터 확인 중...';

  @override
  String get verifiedUserToken => '사용자 토큰 확인 완료!';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken => '사용자 토큰을 확인하는 중 오류가 발생했어요:';

  @override
  String get verifyingUserToken => '사용자 토큰 확인 중...';

  @override
  String get searchForChannels => '채널 검색';

  @override
  String get channelSearchFailed => '채널을 검색할 수 없습니다';

  @override
  String get recommendedChannels => '추천 채널';

  @override
  String get popularChannels => '인기 채널';

  @override
  String get channel => '채널';

  @override
  String get leaveChannel => '채널 나가기';

  @override
  String joinUser(String user) {
    return '$user 참여';
  }

  @override
  String spellCheckFailed(String username) {
    return '맞춤법 검사에 실패했어요! $username을(를) 찾으셨나요?';
  }

  @override
  String joinChannelName(String channel) {
    return '$channel 참여';
  }

  @override
  String sendMessageIn(String channel) {
    return '$channel에 메시지 보내기';
  }

  @override
  String get light => '라이트';

  @override
  String get dark => '다크';

  @override
  String get system => '시스템 설정';

  @override
  String get appearance => '모양';

  @override
  String get highContrast => '고대비';

  @override
  String get customCommand => '사용자 지정 명령어';

  @override
  String get customCommands => '사용자 지정 명령어';

  @override
  String get newCustomCommand => '새 사용자 지정 명령어';

  @override
  String get commandTrigger => '트리거';

  @override
  String get command => '명령어';

  @override
  String get save => '저장';

  @override
  String get openInBrowser => '브라우저에서 열기';

  @override
  String get messageAppearance => '메시지 모양';

  @override
  String get showTimestamps => '타임스탬프 표시';

  @override
  String get compactMessages => '메시지 촘촘하게 표시';

  @override
  String get showBadges => '배지 표시';

  @override
  String get messageTrigger => '메시지 트리거';

  @override
  String get pattern => '패턴';

  @override
  String get mention => '멘션';

  @override
  String get block => '차단';

  @override
  String get enableRegex => 'regex 사용';

  @override
  String get invalidRegex => '유효하지 않은 regex입니다';

  @override
  String get caseSensitive => '대소문자 구분';

  @override
  String get messageTriggers => '메시지 트리거';

  @override
  String get newMessageTrigger => '새 메시지 트리거';

  @override
  String get reply => '답장';

  @override
  String get copyText => '텍스트 복사';

  @override
  String get copyTextSubtitle => '길게 누르면 사용자 이름과 함께 복사';

  @override
  String get deleteMessage => '메시지 삭제';

  @override
  String deleteMessageFailed(String reason) {
    return '메시지를 삭제하지 못했어요: $reason';
  }

  @override
  String get deleteMessageNeedsScope => '메시지를 삭제하려면 다시 로그인하세요. ColdChat이 삭제를 지원하기 전의 로그인이에요.';

  @override
  String get mentionUser => '사용자 멘션';

  @override
  String get copyMessageId => '메시지 ID 복사';

  @override
  String get theme => '테마';

  @override
  String get userTrigger => '사용자 트리거';

  @override
  String get userTriggers => '사용자 트리거';

  @override
  String get chatHistory => '채팅 기록';

  @override
  String get login => '로그인 이름';

  @override
  String get newUserTrigger => '새 사용자 트리거';

  @override
  String get ban => '밴';

  @override
  String get unban => '밴 해제';

  @override
  String timeoutUserForDuration(String duration) {
    return '사용자를 $duration 동안 타임아웃';
  }

  @override
  String get chatCleared => '채팅이 지워졌어요';

  @override
  String get permabanned => '영구 밴됨';

  @override
  String bannedForDuration(String duration) {
    return '$duration 동안 밴됨';
  }

  @override
  String get replyingTo => '답장 대상';

  @override
  String get blockedMessage => '차단된 메시지';

  @override
  String get showMessage => '메시지 보기';

  @override
  String get hideMessage => '메시지 숨기기';

  @override
  String get scrollToBottom => '맨 아래로 스크롤';

  @override
  String get appTagline => '7TV, BTTV, FFZ 이모티콘을 지원하는 Twitch 채팅';

  @override
  String get loginWithTwitch => 'Twitch로 로그인';

  @override
  String get addChannel => '채널 추가';

  @override
  String get chatSettings => '채팅 설정';

  @override
  String get autocompleteUsersWithAt => '@로 사용자 이름 자동 완성';

  @override
  String get autocompleteEmotesWithColon => ':로 이모티콘 자동 완성';

  @override
  String get language => '언어';

  @override
  String get locale => '언어 및 지역';

  @override
  String get systemDefault => '시스템 기본값';

  @override
  String get justDefault => '기본값';

  @override
  String get notifications => '알림';

  @override
  String get noNotifications => '언젠가, 어디선가, 누군가 당신을 멘션할 거예요.';

  @override
  String get backgroundNotifications => '백그라운드 알림';

  @override
  String get optionNotAvailableOnYourPlatform => '이 옵션은 현재 플랫폼에서 사용할 수 없어요.';

  @override
  String get optionNotAvailablePaywalled => '이 옵션은 ColdChat 후원자 전용이에요.';

  @override
  String get clearAll => '모두 지우기';

  @override
  String get cache => '캐시';

  @override
  String get clearCache => '캐시 지우기';

  @override
  String get chatters => '채팅 참여자';

  @override
  String lastSeenAgo(String time) {
    return '마지막 활동: $time 전';
  }

  @override
  String get credits => '크레딧';

  @override
  String get search => '검색';

  @override
  String get emoteMenuButton => '이모티콘 메뉴 버튼';

  @override
  String get emoteMenuButtonGrayscale => '이모티콘 메뉴 버튼을 흑백으로 표시';

  @override
  String get chooseEmoteMenuButton => '이모티콘을 탭해 이모티콘 메뉴 버튼으로 사용하세요';

  @override
  String get resetToKappa => 'Kappa로 초기화';

  @override
  String get emoteMenuButtonDownloadFailed => '이모티콘을 다운로드할 수 없어요. 버튼은 변경되지 않았어요.';

  @override
  String get takePhoto => '사진 찍기';

  @override
  String get chooseFromLibrary => '보관함에서 선택';

  @override
  String get cameraUnavailable => '카메라를 열 수 없어요. ColdChat에 카메라 접근 권한이 있는지 확인하세요.';

  @override
  String get about => '정보';

  @override
  String get sourceCode => '소스 코드';

  @override
  String get license => '라이선스';

  @override
  String get basedOnChatsen => 'Chatsen 기반';

  @override
  String get openSourceLicenses => '오픈 소스 라이선스';

  @override
  String get aboutLegalese =>
      'ColdChat은 자유 소프트웨어입니다. GNU Affero General Public License 버전 3의 조건에 따라 재배포하거나 수정할 수 있습니다. 이 소프트웨어는 어떠한 보증도 제공하지 않습니다.';

  @override
  String get unblock => '차단 해제';

  @override
  String get report => '신고';

  @override
  String reportUserTitle(String name) {
    return '$name 신고';
  }

  @override
  String reportUserDescription(String name) {
    return '신고는 Twitch에서 처리해요. Twitch에서 $name의 채널을 열고 거기서 신고를 선택하세요. 여기서 $name을(를) 차단해 메시지를 숨길 수도 있어요.';
  }

  @override
  String get openOnTwitch => 'Twitch에서 열기';

  @override
  String get blockFailed => '차단 목록을 변경할 수 없어요. 연결 상태를 확인하고 다시 시도하세요.';

  @override
  String get moderationNeedsLogin => '이 채널을 관리하려면 Twitch로 로그인하세요.';

  @override
  String get moderationNeedsScope => '사용자를 차단하거나 타임아웃하려면 다시 로그인하세요. 현재 로그인은 ColdChat이 이 기능을 지원하기 전의 것이에요.';

  @override
  String moderationFailed(String reason) {
    return '실패했어요: $reason';
  }

  @override
  String get contact => '문의 및 피드백';

  @override
  String get whisper => '귓속말';

  @override
  String whisperTo(String name) {
    return '$name에게 귓속말';
  }

  @override
  String whisperFrom(String name) {
    return '$name의 귓속말';
  }

  @override
  String get openWhisper => '열기';

  @override
  String get userCard => '사용자 카드';

  @override
  String get closeConversation => '대화 닫기';

  @override
  String get closeConversationSubtitle => '메시지는 이 기기에 남아 있다가 다음 귓속말이 오면 다시 표시돼요.';

  @override
  String get deleteConversation => '대화 삭제';

  @override
  String get deleteConversationSubtitle => '이 기기에서 메시지를 삭제해요. Twitch는 귓속말 기록을 보관하지 않아요.';

  @override
  String get whisperNeedsLogin => '귓속말을 보내려면 Twitch로 로그인하세요.';

  @override
  String get whisperNeedsScope => '귓속말을 주고받으려면 다시 로그인하세요. 현재 로그인은 ColdChat이 귓속말을 지원하기 전에 한 것이에요.';

  @override
  String get whisperUserNotFound => '해당 이름의 Twitch 사용자가 없어요.';

  @override
  String whisperFailed(String reason) {
    return '귓속말을 보내지 못했어요: $reason';
  }

  @override
  String get whisperHistoryHint =>
      'ColdChat이 닫혀 있는 동안 받은 귓속말은 여기에 표시되지 않아요. Twitch가 앱에 귓속말 기록을 공유하지 않기 때문이에요. Twitch 오른쪽 위의 귓속말 아이콘에서 확인할 수 있어요.';

  @override
  String get gotIt => '확인';

  @override
  String get openTwitch => 'Twitch 열기';

  @override
  String showImage(String host) {
    return '이미지 보기 · $host';
  }

  @override
  String get showImagesFromLinks => '링크 이미지 표시';

  @override
  String get showImagesFromLinksSubtitle => 'Twitch는 이 이미지들을 검사하지 않아요. 부적절한 이미지일 수 있어요.';

  @override
  String get showImagesAutomatically => '링크 이미지를 자동으로 표시할까요?';

  @override
  String get turnOn => '켜기';

  @override
  String get themeIndigo => '인디고';

  @override
  String get themeBlue => '블루';

  @override
  String get themeTeal => '틸';

  @override
  String get themeGreen => '그린';

  @override
  String get themeLime => '라임';

  @override
  String get themeAmber => '앰버';

  @override
  String get themeOrange => '오렌지';

  @override
  String get themeRed => '레드';

  @override
  String get themePink => '핑크';

  @override
  String get themePurple => '퍼플';

  @override
  String get accentColor => '강조 색상';

  @override
  String get oledBlack => 'OLED 블랙';

  @override
  String get oledBlackSubtitle => '다크 모드에서 채팅 배경을 검은색으로 표시합니다(OLED 화면용)';

  @override
  String get customColor => '사용자 지정';

  @override
  String get hue => '색조';

  @override
  String get saturation => '채도';

  @override
  String get themeIce => '아이스';

  @override
  String channelConnecting(String channel) {
    return '$channel에 연결 중…';
  }

  @override
  String channelConnected(String channel) {
    return '$channel에 연결됨';
  }

  @override
  String channelDisconnected(String channel) {
    return '$channel와(과) 연결이 끊어짐';
  }

  @override
  String channelSuspended(String channel) {
    return '$channel은(는) Twitch에 의해 정지되었습니다';
  }

  @override
  String channelBanned(String channel) {
    return '$channel에서 차단되었습니다';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count시간',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분',
    );
    return '$_temp0';
  }
}
