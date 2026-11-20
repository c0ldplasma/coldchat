---
name: install-on-devices
description: Build ColdChat and install it on a connected iPhone and/or Android phone without losing the app's data (in-place update). Use when asked to install, put a build or a PR on a phone, or test a change on a device.
---

# Install ColdChat on connected devices

Installs update the app **in place**, so accounts, channels and settings (Hive boxes) survive. **Never use
`flutter install`**: it uninstalls first and wipes all data.

## 1. Find the devices

```bash
flutter devices --device-connection attached --device-timeout 30
```

Restricting to attached devices avoids a timeout from unreachable wireless ones. Note the iOS UDID and the Android
serial. Install on what the user asked for; if they named one phone, only that one.

## 2. Pick a build number

Pass a build number so the installed build can be told apart from the previous one. **Never edit `pubspec.yaml`**
for it. Use a number above both the last release (`version:` in `pubspec.yaml`) and every earlier test build, and
tell the user the next real release has to go above it. Reuse the same number for iOS and Android builds of the same
code.

## 3. Generate sources

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 4. iOS

```bash
flutter build ios --release --build-number=<N>
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app
xcrun devicectl device info apps --device <UDID> | grep -i coldchat   # shows version and build
```

Signing is automatic (team `RA25PYVUTF`). If `devicectl` fails with `CoreDeviceError 4016` ("not able to fulfill the
requested usage assertion requirements"), the phone is locked or the connection dropped: ask the user to unlock it
and retry.

## 5. Android

`adb` is usually not on the PATH; use the SDK's copy.

```bash
ADB=~/Library/Android/sdk/platform-tools/adb
flutter build apk --release --build-number=<N>
$ADB -s <serial> install -r build/app/outputs/flutter-apk/app-release.apk
$ADB -s <serial> shell dumpsys package com.plasmari.coldchat | grep -m2 -E 'versionCode|versionName'
```

The APK is signed with the upload key when `android/key.properties` exists (see CLAUDE.md, "Android signing"). If
the install fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, the installed app has another signature, usually the
Play Store build. Only uninstalling helps, which loses its data: ask the user to do it, never uninstall yourself.

## 6. Report

Say which build (version and build number) landed on which device, and what to check on it for the change being
tested.
