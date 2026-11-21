import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../api/twitch/twitch_oauth.dart';

/// Gives the browser a head start before a login opens in it.
///
/// On Android the login opens in a Custom Tab of the default browser. Starting that browser from cold took
/// 0.25–0.75 s before its first frame (measured on a Galaxy A27 with Firefox and DuckDuckGo), with nothing happening on
/// screen meanwhile. Warming it up while a login button is shown starts its engine in the background and opens the
/// connection to Twitch early. iOS's login sheet belongs to the system and can't be warmed up, so this does nothing
/// there.
class BrowserWarmup {
  BrowserWarmup._();

  @visibleForTesting
  static const MethodChannel channel = MethodChannel('coldchat/browser');

  /// Where every Twitch login starts. The browser only needs the host to connect early; the full URL with its random
  /// `state` is made when the login starts.
  static final Uri twitchLogin = twitchAuthorizeEndpoint;

  /// Asks the default browser to start up and to expect [url]. Never throws: without a warm-up the login still works,
  /// just a little slower.
  static Future<void> warmUp(Uri url) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await channel.invokeMethod<void>('warmUp', {'url': url.toString()});
    } on PlatformException catch (e) {
      debugPrint('Browser warm-up failed: ${e.message}');
    } on MissingPluginException {
      // No Android host (widget tests).
    }
  }
}

/// Warms up the browser for the Twitch login once when [child] (something with a login button) is first shown.
class WarmsUpTwitchLogin extends StatefulWidget {
  final Widget child;

  const WarmsUpTwitchLogin({super.key, required this.child});

  @override
  State<WarmsUpTwitchLogin> createState() => _WarmsUpTwitchLoginState();
}

class _WarmsUpTwitchLoginState extends State<WarmsUpTwitchLogin> {
  @override
  void initState() {
    super.initState();
    BrowserWarmup.warmUp(BrowserWarmup.twitchLogin).ignore();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
