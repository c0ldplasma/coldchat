# CLAUDE.md

ColdChat — a Flutter Twitch chat client, [c0ldplasma/coldchat](https://github.com/c0ldplasma/coldchat). The Dart package
is `coldchat`.
Ships as `com.plasmari.coldchat` (Apple team `RA25PYVUTF`), which is **not** the same app as upstream.

ColdChat supports **Android and iOS only**. Desktop and web support was removed; don't recreate the
`windows/`, `macos/`, `linux/` or `web/` folders.

`analysis_options.yaml` excludes `build/`, `android/` and `ios/`. Flutter itself adds an exclude for every
platform folder that exists before each command (`AnalysisOptionsMigration` in flutter_tools), so a stray
platform folder shows up as a change to this file.

This file documents the build, install and release procedures. Everything below has been run and verified
on macOS with Xcode 26.5 / Flutter 3.47.8 (stable).

**Flutter 3.47.8 / Dart 3.13.7 is the minimum** (enforced in `pubspec.yaml`). Older SDKs are affected by
[GHSA-frr6-h895-5pxp](https://github.com/dart-lang/sdk/security/advisories/GHSA-frr6-h895-5pxp): `dart:io` on
Android trusts compromised eMudhra intermediate CAs, which allows TLS MitM of e.g. the Twitch token.

## Localization

`lib/l10n/app_localizations*.dart` is **generated but checked in**. After editing any `lib/l10n/*.arb`:

```bash
flutter gen-l10n
```

Add every new string to **all** `lib/l10n/*.arb` files, translated (`app_en.arb` is the template, see `l10n.yaml`);
there is no translation service, translations are written along with the change. CI fails if a language
lacks a key (gen-l10n lists those in `build/untranslated_messages.json`) or if the checked-in
`app_localizations*.dart` don't match the arb files. Use `AppLocalizations.of(context).key` (no `!`: `nullable-getter: false` in `l10n.yaml`), and
don't put user-facing text in Dart string literals.

## CI and tooling

`.github/workflows/build.yml` runs on pushes to `main` and on PRs: `flutter analyze`, `flutter test`, a formatting check and the localization check,
and an Android and an unsigned iOS build. It pins the Flutter version; raise `FLUTTER_VERSION` there together with
the minimum in `pubspec.yaml`. Lints are `flutter_lints` plus stricter settings in
`analysis_options.yaml` (keep `flutter analyze` at "No issues found!"; `dart fix --apply` fixes the mechanical ones):
strict casts and inference, so JSON values need an explicit `as` and untyped calls like `showModalBottomSheet`
need a type argument; every future is awaited or wrapped in `unawaited(...)`; imports inside `lib/` are relative. Unit tests live in `test/` (`flutter test`; run `dart run build_runner build` first on a fresh checkout).
`test/data/hive_storage_test.dart` opens `test/fixtures/hive_models.hive`, a box written by an earlier version: if it
fails, a typeId or field number changed, so revert that rather than regenerating the fixture. Code is formatted with `dart format` at width 120 with trailing commas preserved (settings in
`analysis_options.yaml`): run `dart format lib` before committing. The commit that formatted everything is listed in
`.git-blame-ignore-revs`, which GitHub's blame skips; locally run `git config blame.ignoreRevsFile .git-blame-ignore-revs`
once. Dependabot (`.github/dependabot.yml`) opens monthly PRs for actions and pub
packages: minor and patch updates grouped, each major update on its own.

## Versioning

`pubspec.yaml`'s `version: <name>+<build>` on `main` is always the **last release**. Flutter maps it to
`CFBundleShortVersionString`/`CFBundleVersion` on iOS and `versionName`/`versionCode` on Android.

- **Version name** is semver, `MAJOR.MINOR.PATCH`. Bump MINOR for a release with new features, PATCH for
  a fix-only release, MAJOR only for big breaks. Never go below an already uploaded version: App Store
  Connect rejects a version lower than an approved one.
- **Build number** is one global counter shared by iOS and Android. It only ever goes up and is **never**
  reset when the version name changes. Every upload needs a number no earlier upload has used.
- 2.0.0 builds up to +119 went to TestFlight and local test installs went up to +123, so ColdChat's own
  versioning starts at **2.1.0+124**.

A release is one commit on `main` that sets the new version, followed by a tag and a GitHub release:

```bash
# pubspec.yaml:  version: 2.2.0+125
git commit -m "Release 2.2.0 (125)" pubspec.yaml
git tag v2.2.0+125 && git push origin main v2.2.0+125
gh release create v2.2.0+125 --repo c0ldplasma/coldchat --generate-notes --title "2.2.0 (125)"
```

Then build and upload from that commit (TestFlight and APK below). `--generate-notes` builds the changelog
from the PR titles merged since the previous release tag.

**Test builds never edit `pubspec.yaml`.** To tell a local install apart, pass the number at build time
instead, e.g. `flutter build ios --release --build-number=126`. Use a number above the last release, and
remember the next real release then has to go above it too.

The app shows its version and build at the bottom of Settings (`package_info_plus`), which makes it easy
to see which build a bug report is about.

## Analyze and build warnings

`flutter analyze` is **clean** — keep it at "No issues found!". `flutter build apk` and `flutter build ios`
also run without warnings; treat any new one as something to fix, not as noise.

All colors come from `lib/theme/coldchat_theme.dart`. Backgrounds are always Indigo's palette; the user's accent
color (Settings → Accent color; default Ice, the blue of the app icon) only changes `colorScheme.primary` and its
containers, and OLED black (Settings →
Appearance) makes the dark chat background pure black. Colors ColorScheme has no role for (tab bar and composer,
sheets, raised pills, links, chatter name readability) are in the `ChatColors` theme extension: use
`ChatColors.of(context)` instead of picking scheme colors or checking the brightness in a widget. Don't wrap widgets
in a `Theme(...)` to recolor them: a bottom sheet opened below one keeps a frozen copy of it and stops following
light/dark switches. Pass colors with `DefaultTextStyle`/`IconTheme` instead, like `Surface` does.

Gotcha: `ConnectionState` collides with Flutter's own `ConnectionState` from `package:flutter/material.dart`.
In any widget file, import the TMI one with a prefix:

```dart
import '../tmi/connection/connection_state.dart' as tmi;
```

## iOS — install on a connected iPhone without wiping app data

**Never use `flutter install` for this.** It calls `installApp(uninstall: true)`, which uninstalls the
existing app first and takes all Hive boxes with it (accounts, channels, settings, emote cache, seen
mentions). Use `devicectl`, which does an in-place upgrade and preserves the data container.

```bash
# 1. Find the device. Wireless discovery of unreachable paired devices can time out and
#    hide the attached one, so restrict to attached and allow a longer timeout.
flutter devices --device-connection attached --device-timeout 30

# 2. Build, codesigned (automatic signing, team RA25PYVUTF from the Xcode project).
flutter build ios --release

# 3. Install in place. Data is preserved because the bundle ID and signing team are unchanged.
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app

# 4. Verify which build actually landed.
xcrun devicectl device info apps --device <UDID> | grep -i coldchat
```

Pass `--build-number=<N>` to step 2 if you want to tell the new install apart from the old one (see
Versioning; don't edit `pubspec.yaml` for this). Otherwise step 4 shows the same version and proves nothing.

Data survives an in-place upgrade only while the bundle ID and signing identity stay the same. Changing
either makes iOS refuse the install outright (it fails, it does not silently wipe), and the only way
forward is delete + install, which loses the data.

## iOS — TestFlight release

Prerequisites, one time: an app-specific password from
appleid.apple.com → Sign-In and Security → App-Specific Passwords (the regular Apple ID password does not
work), stored in the keychain. Note the `--item` flag — `altool`'s own `--help` omits it and the documented
form fails with `Expected item argument is missing, --item`:

```bash
xcrun altool --store-password-in-keychain-item --item COLDCHAT_ASC \
  -u <apple-id> -p <app-specific-password>
```

Never paste that password into a chat, a script, or a commit. To recover which Apple ID the item belongs to:

```bash
security find-generic-password -l COLDCHAT_ASC | grep '"acct"'
```

Then, per release:

```bash
# 1. Make the release commit and tag (see Versioning). A build number can never be
#    reused once App Store Connect has accepted it.

# 2. Archive + export an App Store IPA. ios/ExportOptions.plist is ours
#    (method: app-store-connect, teamID: RA25PYVUTF).
flutter build ipa --export-options-plist=ios/ExportOptions.plist
# -> build/ios/ipa/ColdChat.ipa, build/ios/archive/Runner.xcarchive

# 3. Validate FIRST. Catches a missing app record, bad entitlements or a duplicate
#    build number without consuming the build number.
xcrun altool --validate-app --type ios -f build/ios/ipa/ColdChat.ipa \
  -u <apple-id> -p "@env:ASC_PW"

# 4. Upload.
xcrun altool --upload-app --type ios -f build/ios/ipa/ColdChat.ipa \
  -u <apple-id> -p "@env:ASC_PW"
```

For steps 3 and 4, supply the password from the keychain per-command so it never lands in your shell
history, in `ps` output, or in a transcript:

```bash
ASC_PW="$(security find-generic-password -l COLDCHAT_ASC -w)" xcrun altool --upload-app ... -p "@env:ASC_PW"
```

`-p "@keychain:COLDCHAT_ASC"` looks like the obvious alternative but **does not work** with Xcode 26.5's
`altool`: it stores the item under `--item <name>` and then fails to find it, with
`AuthenticationFailure("Failed to find item COLDCHAT_ASC ...")`. The `@env:` route above is the workaround.

The deployment target is iOS 15.0, which App Store Connect requires from Spring 2027. The app is iPhone-only
(`TARGETED_DEVICE_FAMILY = 1`), so the store needs no iPad screenshots. Processing on Apple's side takes a few
minutes after `UPLOAD SUCCEEDED` before the build appears in TestFlight.

`ios/Runner/PrivacyInfo.xcprivacy` is the app's privacy manifest: no tracking, no collected data, no
required-reason APIs (plugins and the Flutter engine ship their own). Update it if the app ever starts using
one, e.g. `UserDefaults` or file timestamps.

Uploading is irreversible — a build can be expired in TestFlight but its number is spent.

## Android — signing, APK and Play bundle

Release builds are signed with the **Play upload key** when `android/key.properties` exists; otherwise
`android/app/build.gradle.kts` falls back to the debug key, so CI and fresh clones still build (but those
builds can't go to Play).

- Keystore: `~/.android/coldchat-upload.jks`, alias `upload`. Its password is in the keychain as
  `COLDCHAT_UPLOAD_KEYSTORE`. Neither file is in the repo; `android/.gitignore` excludes `key.properties`, `*.jks`
  and `*.keystore`. **Back up the keystore.** With Play App Signing a lost upload key can be reset through Play
  support, but that takes days.
- `android/key.properties` (local only):

  ```properties
  storePassword=<from keychain>
  keyPassword=<from keychain>
  keyAlias=upload
  storeFile=/Users/<you>/.android/coldchat-upload.jks
  ```

```bash
flutter build appbundle --release   # -> build/app/outputs/bundle/release/app-release.aab, for Play
flutter build apk --release         # -> build/app/outputs/flutter-apk/app-release.apk, for sideloading
```

APKs sideloaded before 2.2.0 were signed with the debug key. Android refuses to update an app across signing
keys, so those installs have to be uninstalled (losing their data) before installing a properly signed build.

## App icon

`assets/icon.png` is the square, full-bleed 1024px source; iOS and Android launchers round the corners
themselves. After changing it, run `dart run flutter_launcher_icons` and commit the generated files in
`android/` and `ios/`. Android 8+ uses an adaptive icon (`adaptive_icon_*` in `pubspec.yaml`).

## Repo gotchas

- `origin` is `c0ldplasma/coldchat` (push here, open PRs against its `main`). It is public — keep Apple IDs,
  device UDIDs, passwords and API keys out of committed files.
- ColdChat talks only to Twitch and the emote/badge/upload services it names in `lib/api/`. User cards and the
  channel header come from Helix (`Twitch.profile`, needs a login); the chatter list and `@` autocomplete use
  `Channel.recentChatters`, the people who wrote in the loaded chat, because Twitch only gives the full viewer
  list to the channel's moderators.
- `*.g.dart` files (json_serializable, Hive adapters) are **generated and not tracked**. After a fresh checkout or
  after changing an annotated model, run `dart run build_runner build --delete-conflicting-outputs`.
- Storage is **`hive_ce`**, the maintained continuation of hive 2 (which stopped at 2.2.3); it reads boxes written by
  hive 2 unchanged. Never change a `@HiveType` typeId or a `@HiveField` number of a stored model, or existing data
  stops loading: add new fields with new numbers and a `defaultValue`. Adapters are registered by hand in `main.dart`;
  the generated `lib/hive_registrar.g.dart` lists them all for comparison.
- Twitch login uses ColdChat's own **public** Twitch app (`twitchClientId` in `lib/modal/login_flow.dart`) in the
  system's login sheet (ASWebAuthenticationSession / Android Custom Tab, via `flutter_web_auth_2`), not a web
  view. Twitch only redirects to web addresses, so the redirect is `docs/auth.html` on GitHub Pages
  (`https://c0ldplasma.github.io/coldchat/auth.html`, registered exactly like that in the dev.twitch.tv console),
  which forwards the answer to `coldchat://auth`. Android receives that in flutter_web_auth_2's
  `CallbackActivity` (`AndroidManifest.xml`). The relay must be live on GitHub Pages before a login can work.
  Long-pressing "Log in with Twitch" opens the access-token input instead (used by app review).
- The iOS project uses **Swift Package Manager only**; CocoaPods was removed (no `Podfile`). Don't run
  `pod install`. `android/` and `ios/` are tracked, because the AGPL requires publishing everything needed to build
  the shipped app. Their own `.gitignore` files keep generated files and signing keys out; never commit a keystore,
  `key.properties` or anything with an Apple ID in it.
- The app font is **Google Sans Flex** (OFL, `fonts/OFL.txt`), a variable font. `ColdChatTheme.fontVariations` narrows it
  to look like the Product Sans used before. Don't add a `wght` variation there: it overrides `FontWeight`, and bold
  text stops being bold. Product Sans itself is proprietary and must not be bundled.
- `docs/` is the website on GitHub Pages (`https://c0ldplasma.github.io/coldchat/`): the support page, the
  **privacy policy** and the terms, linked from the account sheet, Settings → About and the store listings. The
  privacy policy lists every host the app contacts and what it sends. **When adding, removing or changing a
  network service (`lib/api/`, upload hosts, image sources), update `docs/privacy.html` in the same PR** and bump
  its date; the App Store privacy label and Play data safety form must match it.
- Settings → About shows the AGPL notices and links the source of the installed build by its release tag.
- `build/` is currently untracked but present in the working tree; don't commit it.
- **Whispers** (`lib/tmi/whispers/`) arrive over EventSub WebSocket (`lib/api/twitch/eventsub_socket.dart`,
  `user.whisper.message`) and are sent with Helix `POST /whispers`; IRC whispers are not used. Both need the
  `user:manage:whispers` scope, which logins from before 2.3.0 lack (they have to sign in again). Twitch has no
  whisper history API, so conversations are stored on the device in the `Whispers` Hive box as IRC-shaped lines,
  and each conversation is a `WhisperChannel` (a `Channel` that is never joined) so the chat view and composer
  work unchanged. `/w <user> [message]` is handled in `ChannelView.sendMessage`.
- Twitch login uses the OAuth **implicit grant** (`response_type=token` in `lib/modal/login_flow.dart`),
  so there is no refresh token and an expired login can only be fixed by signing in again. See
  `lib/widgets/login_expired_banner.dart` and `Client.validateCredentials`.
