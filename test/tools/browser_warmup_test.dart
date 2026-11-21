import 'package:coldchat/tools/browser_warmup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(BrowserWarmup.channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(BrowserWarmup.channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('warmUp', () {
    test('asks Android to warm up the browser for the URL', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await BrowserWarmup.warmUp(BrowserWarmup.twitchLogin);

      expect(calls, hasLength(1));
      expect(calls.single.method, 'warmUp');
      expect(calls.single.arguments, {'url': 'https://id.twitch.tv/oauth2/authorize'});
    });

    test('does nothing on iOS, whose login sheet belongs to the system', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await BrowserWarmup.warmUp(BrowserWarmup.twitchLogin);

      expect(calls, isEmpty);
    });

    test('swallows a failing or missing Android side', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      messenger.setMockMethodCallHandler(BrowserWarmup.channel, (call) async => throw PlatformException(code: 'x'));
      await expectLater(BrowserWarmup.warmUp(BrowserWarmup.twitchLogin), completes);

      messenger.setMockMethodCallHandler(BrowserWarmup.channel, null);
      await expectLater(BrowserWarmup.warmUp(BrowserWarmup.twitchLogin), completes);
    });
  });

  testWidgets('WarmsUpTwitchLogin warms up once when shown, not on every rebuild', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await tester.pumpWidget(const WarmsUpTwitchLogin(child: SizedBox()));
    await tester.pumpWidget(const WarmsUpTwitchLogin(child: SizedBox(width: 1)));

    expect(calls.map((call) => call.method), ['warmUp']);
    debugDefaultTargetPlatformOverride = null;
  });
}
