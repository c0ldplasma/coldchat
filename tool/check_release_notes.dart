// Checks the store release notes in fastlane/metadata/android/<language>/changelogs/<build>.txt, which the store
// workflows upload to Play and App Store Connect: every language has notes for the build in pubspec.yaml (the last
// release), no file is empty or longer than Play allows, and there are no folders for other languages.
//
// Run from the repository root: dart run tool/check_release_notes.dart
import 'dart:io';

/// The languages of the Play listing. App Store Connect gets the ones its listing has (today only en-US).
const languages = ['en-US', 'de-DE'];

/// Play's limit per language. App Store Connect allows 4000.
const maxLength = 500;

const notesPath = 'fastlane/metadata/android';

void main() {
  final errors = <String>[];

  final version = RegExp(
    r'^version:\s*\S+\+(\d+)\s*$',
    multiLine: true,
  ).firstMatch(File('pubspec.yaml').readAsStringSync());
  if (version == null) {
    errors.add('pubspec.yaml has no version with a build number.');
  }
  final build = version?.group(1);

  for (final entry in Directory(notesPath).listSync().whereType<Directory>()) {
    final name = entry.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty);
    if (!languages.contains(name)) {
      errors.add('$notesPath/$name: not a language of the Play listing ($languages).');
    }
  }

  for (final language in languages) {
    final changelogs = Directory('$notesPath/$language/changelogs');
    if (build != null && !File('${changelogs.path}/$build.txt').existsSync()) {
      errors.add('${changelogs.path}/$build.txt is missing: every release needs notes in all of $languages.');
    }
    if (!changelogs.existsSync()) continue;
    for (final file in changelogs.listSync().whereType<File>()) {
      final text = file.readAsStringSync();
      final length = text.runes.length;
      if (text.trim().isEmpty) {
        errors.add('${file.path} is empty.');
      } else if (length > maxLength) {
        errors.add('${file.path} has $length characters, Play allows $maxLength.');
      }
    }
  }

  if (errors.isEmpty) {
    stdout.writeln('Release notes for build $build are complete.');
  } else {
    errors.forEach(stderr.writeln);
    exitCode = 1;
  }
}
