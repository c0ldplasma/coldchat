// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'ColdChat';

  @override
  String get translationAuthorNames => '';

  @override
  String loggedInVia(String provider) {
    return '$providerでログイン中';
  }

  @override
  String get termsOfService => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get settings => '設定';

  @override
  String get expiresNever => '無期限';

  @override
  String get loginExpired => 'ログインの有効期限切れ';

  @override
  String loginExpiredDescription(String login) {
    return 'Twitchが$loginのログインを拒否しました。再度ログインするまで、チャットは切断されたままになります。';
  }

  @override
  String get loginFailed => 'ログインに失敗しました';

  @override
  String get signInAgain => 'ログイン';

  @override
  String uploadingTo(String host) {
    return '$hostにアップロード中';
  }

  @override
  String get uploadProcessing => '処理中…';

  @override
  String get uploadFailed => 'アップロードに失敗しました';

  @override
  String get uploadDone => 'アップロード完了';

  @override
  String get uploadRetry => '再試行';

  @override
  String get uploadDismiss => '閉じる';

  @override
  String get uploadCancel => 'アップロードをキャンセル';

  @override
  String get uploadErrorOffline => 'インターネットに接続されていません';

  @override
  String uploadErrorTimeout(String host) {
    return '$hostが応答しません';
  }

  @override
  String uploadErrorRejected(String host, String status) {
    return '$hostがアップロードを拒否しました（HTTP $status）';
  }

  @override
  String uploadErrorBadResponse(String host) {
    return '$hostから予期しない応答がありました';
  }

  @override
  String uploadErrorNetwork(String host) {
    return '$hostに接続できませんでした';
  }

  @override
  String get uploadErrorUnreadableFile => 'ファイルを読み込めませんでした';

  @override
  String uploadErrorUnknown(String host) {
    return '$hostへのアップロードに失敗しました';
  }

  @override
  String get uploadErrorDetails => '詳細';

  @override
  String uploadRetryingWith(String host) {
    return '$hostで再試行中…';
  }

  @override
  String expiresIn(String time) {
    return 'あと$timeで期限切れ';
  }

  @override
  String get close => '閉じる';

  @override
  String get add => '追加';

  @override
  String get cancel => 'キャンセル';

  @override
  String get tokenInput => 'トークン入力';

  @override
  String get account => 'アカウント';

  @override
  String get refreshAccount => 'アカウントを更新';

  @override
  String get removeAccount => 'アカウントを削除';

  @override
  String get addAnotherAccount => '別のアカウントを追加';

  @override
  String get verifiedUserData => 'ユーザーデータを確認しました！';

  @override
  String loggedInAs(String user) {
    return '$userとしてログイン中';
  }

  @override
  String get anErrorHasOccuredWhenVerifyingUserData => 'ユーザーデータの確認中にエラーが発生しました：';

  @override
  String get verifyingUserData => 'ユーザーデータを確認中...';

  @override
  String get verifiedUserToken => 'ユーザートークンを確認しました！';

  @override
  String get anErrorHasOccuredWhenVerifyingUserToken => 'ユーザートークンの確認中にエラーが発生しました：';

  @override
  String get verifyingUserToken => 'ユーザートークンを確認中...';

  @override
  String get searchForChannels => 'チャンネルを検索';

  @override
  String get channelSearchFailed => 'チャンネルを検索できませんでした';

  @override
  String get recommendedChannels => 'おすすめチャンネル';

  @override
  String get popularChannels => '人気のチャンネル';

  @override
  String get channel => 'チャンネル';

  @override
  String get leaveChannel => 'チャンネルから退出';

  @override
  String joinUser(String user) {
    return '$userに参加';
  }

  @override
  String spellCheckFailed(String username) {
    return 'スペルチェックに失敗しました！もしかして$usernameですか？';
  }

  @override
  String joinChannelName(String channel) {
    return '$channelに参加';
  }

  @override
  String sendMessageIn(String channel) {
    return '$channelにメッセージを送信';
  }

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get system => 'システム';

  @override
  String get appearance => '外観';

  @override
  String get highContrast => 'ハイコントラスト';

  @override
  String get customCommand => 'カスタムコマンド';

  @override
  String get customCommands => 'カスタムコマンド';

  @override
  String get newCustomCommand => '新しいカスタムコマンド';

  @override
  String get commandTrigger => 'トリガー';

  @override
  String get command => 'コマンド';

  @override
  String get save => '保存';

  @override
  String get openInBrowser => 'ブラウザで開く';

  @override
  String get messageAppearance => 'メッセージの表示';

  @override
  String get showTimestamps => 'タイムスタンプを表示';

  @override
  String get compactMessages => 'メッセージをコンパクトに表示';

  @override
  String get showBadges => 'バッジを表示';

  @override
  String get messageTrigger => 'メッセージトリガー';

  @override
  String get pattern => 'パターン';

  @override
  String get mention => 'メンション';

  @override
  String get block => 'ブロック';

  @override
  String get enableRegex => '正規表現（regex）を使用';

  @override
  String get caseSensitive => '大文字と小文字を区別';

  @override
  String get messageTriggers => 'メッセージトリガー';

  @override
  String get newMessageTrigger => '新しいメッセージトリガー';

  @override
  String get reply => '返信';

  @override
  String get copyText => 'テキストをコピー';

  @override
  String get copyTextSubtitle => '長押しでユーザー名ごとコピー';

  @override
  String get deleteMessage => 'メッセージを削除';

  @override
  String deleteMessageFailed(String reason) {
    return 'メッセージを削除できませんでした: $reason';
  }

  @override
  String get deleteMessageNeedsScope => 'メッセージを削除するには、もう一度サインインしてください。ColdChat が削除に対応する前のログインです。';

  @override
  String get mentionUser => 'ユーザーをメンション';

  @override
  String get copyMessageId => 'メッセージIDをコピー';

  @override
  String get theme => 'テーマ';

  @override
  String get userTrigger => 'ユーザートリガー';

  @override
  String get userTriggers => 'ユーザートリガー';

  @override
  String get chatHistory => 'チャット履歴';

  @override
  String get login => 'ログイン名';

  @override
  String get newUserTrigger => '新しいユーザートリガー';

  @override
  String get ban => 'BAN';

  @override
  String get unban => 'BAN解除';

  @override
  String timeoutUserForDuration(String duration) {
    return 'ユーザーを$durationタイムアウト';
  }

  @override
  String get chatCleared => 'チャットがクリアされました';

  @override
  String get permabanned => '永久BAN';

  @override
  String bannedForDuration(String duration) {
    return '$durationのBAN';
  }

  @override
  String get replyingTo => '返信先';

  @override
  String get blockedMessage => 'ブロックされたメッセージ';

  @override
  String get showMessage => 'メッセージを表示';

  @override
  String get hideMessage => 'メッセージを非表示';

  @override
  String get scrollToBottom => '最下部へスクロール';

  @override
  String get appTagline => '7TV・BTTV・FFZのエモートが使えるTwitchチャット';

  @override
  String get loginWithTwitch => 'Twitchでログイン';

  @override
  String get addChannel => 'チャンネルを追加';

  @override
  String get chatSettings => 'チャット設定';

  @override
  String get autocompleteUsersWithAt => '@でユーザー名を補完';

  @override
  String get autocompleteEmotesWithColon => ':でエモートを補完';

  @override
  String get language => '言語';

  @override
  String get locale => '言語と地域';

  @override
  String get systemDefault => 'システムのデフォルト';

  @override
  String get justDefault => 'デフォルト';

  @override
  String get notifications => '通知';

  @override
  String get noNotifications => 'いつか、どこかで、誰かがあなたにメンションしてくれるはず。';

  @override
  String get backgroundNotifications => 'バックグラウンド通知';

  @override
  String get optionNotAvailableOnYourPlatform => 'このオプションはお使いのプラットフォームでは利用できません。';

  @override
  String get optionNotAvailablePaywalled => 'このオプションはColdChatサポーター専用です。';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String get cache => 'キャッシュ';

  @override
  String get clearCache => 'キャッシュをクリア';

  @override
  String get chatters => 'チャッター';

  @override
  String lastSeenAgo(String time) {
    return '最終確認：$time前';
  }

  @override
  String get credits => 'クレジット';

  @override
  String get search => '検索';

  @override
  String get emoteMenuButton => 'エモートメニューボタン';

  @override
  String get emoteMenuButtonGrayscale => 'エモートメニューボタンをグレースケールで表示';

  @override
  String get chooseEmoteMenuButton => 'エモートをタップしてエモートメニューボタンに設定';

  @override
  String get resetToKappa => 'Kappaに戻す';

  @override
  String get emoteMenuButtonDownloadFailed => 'エモートをダウンロードできませんでした。ボタンは変更されていません。';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get chooseFromLibrary => 'ライブラリから選択';

  @override
  String get cameraUnavailable => 'カメラを開けませんでした。ColdChatにカメラへのアクセスが許可されているか確認してください。';

  @override
  String get about => 'このアプリについて';

  @override
  String get sourceCode => 'ソースコード';

  @override
  String get license => 'ライセンス';

  @override
  String get basedOnChatsen => 'Chatsenをベースに開発';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get aboutLegalese =>
      'ColdChatはフリーソフトウェアです。GNU Affero General Public License バージョン3の条件に従って、再配布や改変を行うことができます。本ソフトウェアには一切の保証がありません。';

  @override
  String get unblock => 'ブロック解除';

  @override
  String get report => '報告';

  @override
  String reportUserTitle(String name) {
    return '$nameを報告';
  }

  @override
  String reportUserDescription(String name) {
    return '報告はTwitchが対応します。Twitchで$nameのチャンネルを開き、そこで「報告」を選んでください。ここで$nameをブロックして、メッセージを非表示にすることもできます。';
  }

  @override
  String get openOnTwitch => 'Twitchで開く';

  @override
  String get blockFailed => 'ブロックリストを変更できませんでした。接続を確認して、もう一度お試しください。';

  @override
  String get contact => 'お問い合わせ・フィードバック';

  @override
  String get whisper => 'ウィスパー';

  @override
  String whisperTo(String name) {
    return '$nameにウィスパー';
  }

  @override
  String whisperFrom(String name) {
    return '$nameからのウィスパー';
  }

  @override
  String get openWhisper => '開く';

  @override
  String get userCard => 'ユーザーカード';

  @override
  String get closeConversation => '会話を閉じる';

  @override
  String get closeConversationSubtitle => 'メッセージはこの端末に残り、次のウィスパーで再び表示されます。';

  @override
  String get deleteConversation => '会話を削除';

  @override
  String get deleteConversationSubtitle => 'この端末からメッセージを削除します。Twitchはウィスパーの履歴を保存しません。';

  @override
  String get whisperNeedsLogin => 'ウィスパーを送るには、Twitchでログインしてください。';

  @override
  String get whisperNeedsScope => 'ウィスパーを送受信するには、もう一度ログインしてください。現在のログインはColdChatがウィスパーに対応する前のものです。';

  @override
  String get whisperUserNotFound => 'その名前のTwitchユーザーは存在しません。';

  @override
  String whisperFailed(String reason) {
    return 'ウィスパーを送信できませんでした：$reason';
  }

  @override
  String get whisperHistoryHint =>
      'ColdChatを閉じている間に届いたウィスパーは、ここには表示されません。Twitchがウィスパーの履歴をアプリと共有しないためです。Twitchの右上にあるウィスパーアイコンから確認できます。';

  @override
  String get gotIt => 'OK';

  @override
  String get openTwitch => 'Twitchを開く';

  @override
  String showImage(String host) {
    return '画像を表示 · $host';
  }

  @override
  String get showImagesFromLinks => 'リンクの画像を表示';

  @override
  String get showImagesFromLinksSubtitle => 'これらの画像はTwitchによる確認を受けていません。不適切な内容が含まれる可能性があります。';

  @override
  String get showImagesAutomatically => 'リンクの画像を自動で表示しますか？';

  @override
  String get turnOn => 'オンにする';

  @override
  String get themeIndigo => 'インディゴ';

  @override
  String get themeBlue => 'ブルー';

  @override
  String get themeTeal => 'ティール';

  @override
  String get themeGreen => 'グリーン';

  @override
  String get themeLime => 'ライム';

  @override
  String get themeAmber => 'アンバー';

  @override
  String get themeOrange => 'オレンジ';

  @override
  String get themeRed => 'レッド';

  @override
  String get themePink => 'ピンク';

  @override
  String get themePurple => 'パープル';

  @override
  String get accentColor => 'アクセントカラー';

  @override
  String get oledBlack => 'OLEDブラック';

  @override
  String get oledBlackSubtitle => 'ダークモードでチャットの背景を黒にします（OLED画面向け）';

  @override
  String get customColor => 'カスタム';

  @override
  String get hue => '色相';

  @override
  String get saturation => '彩度';

  @override
  String get themeIce => 'アイス';

  @override
  String channelConnecting(String channel) {
    return '$channelに接続中…';
  }

  @override
  String channelConnected(String channel) {
    return '$channelに接続しました';
  }

  @override
  String channelDisconnected(String channel) {
    return '$channelから切断されました';
  }

  @override
  String channelSuspended(String channel) {
    return '$channelはTwitchにより停止されています';
  }

  @override
  String channelBanned(String channel) {
    return '$channelからBANされています';
  }

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count時間',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count分',
    );
    return '$_temp0';
  }
}
