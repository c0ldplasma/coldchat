# ColdChat for iOS (native SwiftUI)

A native SwiftUI port of the Flutter app in this repository, with the same features. It ships as the same app
(`com.plasmari.coldchat`, team `RA25PYVUTF`), so installing it replaces the Flutter build on a device.

- iOS 18.0+, iPhone only, no third-party dependencies.
- Open `ColdChat.xcodeproj` in Xcode 26, or build from the command line:

  ```bash
  xcodebuild -project ios-native/ColdChat.xcodeproj -scheme ColdChat \
    -destination 'platform=iOS Simulator,name=iPhone 17' build
  ```

- The version comes from `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in the project's build settings. Keep them
  in step with `pubspec.yaml` (see Versioning in `CLAUDE.md`).

## Layout

| Folder | What |
| --- | --- |
| `ColdChat/App` | App entry, `AppModel`, mention notifications |
| `ColdChat/Core` | IRC parser, connections, `Client`, `Channel`, chat message model, emote/badge cache |
| `ColdChat/API` | Helix and the 7TV, BetterTTV, FrankerFaceZ, DankChat, emoji and recent-messages providers |
| `ColdChat/Storage` | Settings (UserDefaults), accounts (Keychain), emote button icon |
| `ColdChat/Uploads` | Image upload hosts and the upload queue |
| `ColdChat/UI` | Views: root pager and channel bar, home tab, chat, composer, emote picker, sheets |
| `ColdChat/Localization` | Generated `L10n` accessors and the in-app language override |

## Localization

The strings come from the Flutter app's ARB files, which stay the single source (Crowdin manages them). After
editing `lib/l10n/*.arb`, regenerate both outputs:

```bash
python3 ios-native/tools/arb2xcstrings.py
```

That writes `ColdChat/Resources/Localizable.xcstrings` and `ColdChat/Localization/L10n.swift`. Commit both.

## Differences from the Flutter app

- Chat can be read without an account (anonymous `justinfan` connection); sending needs a login.
- Logins are stored in the Keychain. Data from the Flutter app's Hive boxes is not migrated: after switching, accounts
  have to sign in again and channels have to be re-added.
- The system font (SF Pro) instead of Google Sans Flex.
- The chat history setting is honored, high contrast applies everywhere, and emotes grow with the message scale.
- Dark name colors are lightened in dark mode (and light ones darkened in light mode) so every name stays readable.
- No connection log screen and no open-source licenses page (there are no bundled third-party packages).
