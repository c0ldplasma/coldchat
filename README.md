<h1 align="middle">ColdChat</h1>

<p align="middle">A Twitch chat client for Android and iOS, focused on chat: fast startup, reliable reconnects, emotes from 7TV, BetterTTV and FrankerFaceZ, and image uploads straight from the chat input.</p>

# 🛠️ Building the application

```sh
dart run build_runner build --delete-conflicting-outputs   # generates the *.g.dart files

flutter build apk --release        # Android
flutter build ios --no-codesign    # iOS
```

Flutter 3.47.8 or newer is required. See [CLAUDE.md](CLAUDE.md) for installing on a device without losing app data, releases and versioning.

# 📜 Licensing

ColdChat is distributed under the AGPLv3 licence. A copy may be found in the [LICENSE](LICENSE) file. ColdChat is a modified version of [Chatsen](https://github.com/chatsen/chatsen), which is distributed under the same licence. All the dependencies remain under their original licenses. The bundled font, [Google Sans Flex](https://github.com/googlefonts/googlesans-flex), is licensed under the [SIL Open Font License 1.1](fonts/OFL.txt).
