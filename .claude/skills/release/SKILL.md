---
name: release
description: Make a ColdChat release - version bump commit, tag, GitHub release, TestFlight upload and Play bundle. Use when asked to release, publish a new version, upload to TestFlight or build for the Play Store.
---

# Release ColdChat

Read "Versioning" in CLAUDE.md first: semver version name, one global build number that only goes up and must be
above every earlier upload **and** every test build installed on devices. Uploads are irreversible: a build number is
spent once App Store Connect accepts it. Confirm the version and build number with the user before starting.

## 1. Release commit, tag and GitHub release

```bash
# pubspec.yaml:  version: 2.6.0+157
git commit -m "Release 2.6.0 (157)" pubspec.yaml
git tag v2.6.0+157 && git push origin main v2.6.0+157
gh release create v2.6.0+157 --repo c0ldplasma/coldchat --generate-notes --title "2.6.0 (157)"
```

`main` is protected, so the release commit may need to go through a PR instead (see CLAUDE.md, "Pull requests"); tag
the merged commit then. `--generate-notes` builds the changelog from the PR titles since the previous tag. Build
everything below from the tagged commit, after `dart run build_runner build --delete-conflicting-outputs`.

## 2. iOS: TestFlight

One-time prerequisite: an app-specific password (appleid.apple.com → Sign-In and Security → App-Specific Passwords;
the regular Apple ID password doesn't work), stored in the keychain. `altool --help` omits the required `--item`:

```bash
xcrun altool --store-password-in-keychain-item --item COLDCHAT_ASC -u <apple-id> -p <app-specific-password>
```

**Never paste, print or echo that password.** The Apple ID it belongs to:

```bash
security find-generic-password -l COLDCHAT_ASC | grep '"acct"'
```

Per release:

```bash
# Archive and export (ios/ExportOptions.plist: app-store-connect, team RA25PYVUTF)
flutter build ipa --export-options-plist=ios/ExportOptions.plist
# -> build/ios/ipa/ColdChat.ipa

# Validate first: catches a missing app record, bad entitlements or a duplicate build number without spending it
ASC_PW="$(security find-generic-password -l COLDCHAT_ASC -w)" \
  xcrun altool --validate-app --type ios -f build/ios/ipa/ColdChat.ipa -u <apple-id> -p "@env:ASC_PW"

# Upload
ASC_PW="$(security find-generic-password -l COLDCHAT_ASC -w)" \
  xcrun altool --upload-app --type ios -f build/ios/ipa/ColdChat.ipa -u <apple-id> -p "@env:ASC_PW"
```

The password goes in per command through `@env:`, so it never reaches shell history, `ps` or a transcript.
`-p "@keychain:COLDCHAT_ASC"` does **not** work with Xcode 26.5's altool (`Failed to find item COLDCHAT_ASC`).
After `UPLOAD SUCCEEDED`, Apple takes a few minutes before the build shows up in TestFlight.

For App Store review, the review note must say that long-pressing "Log in with Twitch" opens the access-token input.

## 3. Android: Play bundle

Needs `android/key.properties` with the upload key (CLAUDE.md, "Android signing"); without it the build is signed
with the debug key and Play rejects it.

```bash
flutter build appbundle --release   # -> build/app/outputs/bundle/release/app-release.aab, upload in the Play Console
flutter build apk --release         # -> build/app/outputs/flutter-apk/app-release.apk, for sideloading
```

## 4. Report

List what was created and uploaded (tag, GitHub release URL, TestFlight build, AAB path) and what the user still has
to do by hand (Play Console upload, review submission).
