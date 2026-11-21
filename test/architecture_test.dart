import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The folders that hold the UI: widgets, pages, shared components and sheets.
const _uiFolders = ['lib/widgets', 'lib/pages', 'lib/components', 'lib/modal'];

/// What a file in `lib/api/` must not contain for the UI to import it: then it talks to the network itself instead of
/// only declaring models or exceptions.
final _networkCode = RegExp(r'\bApiClient\b|package:http/|\bWebSocket\b|web_socket_channel');

/// Code in the UI that reaches the network directly: the client's Helix or [ApiClient], or dart:io's HTTP and
/// sockets.
final _networkAccess = RegExp(r'\.(helix|api)\b|\bHttpClient\b|\bWebSocket\b|\bSocket\.connect\b');

final _import = RegExp(r'''^import\s+'([^']+)'(?:\s+as\s+\w+)?;''', multiLine: true);

/// [file]'s path from the package root.
String _relative(File file) => file.path.replaceFirst('${Directory.current.path}${Platform.pathSeparator}', '');

/// The code of [source] without comments, so commented-out code doesn't count.
String _code(String source) => source
    .split('\n')
    .map((line) => line.trimLeft().startsWith('//') ? '' : line)
    .join('\n')
    .replaceAllMapped(RegExp(r'/\*.*?\*/', dotAll: true), (m) => '\n' * '\n'.allMatches(m[0]!).length);

void main() {
  // Keep in sync with "Widgets only render state" in CLAUDE.md.
  group('the UI does not talk to the network itself', () {
    for (final folder in _uiFolders) {
      test('$folder exists', () {
        // A renamed folder must be renamed here too, or the checks below would pass by checking nothing.
        expect(Directory(folder).existsSync(), isTrue, reason: 'update _uiFolders in test/architecture_test.dart');
      });
    }

    final files = [
      for (final folder in _uiFolders)
        if (Directory(folder).existsSync())
          for (final entity in Directory(folder).absolute.listSync(recursive: true))
            if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('.g.dart')) entity,
    ];

    test('finds the UI files', () => expect(files, isNotEmpty));

    test('imports neither package:http nor network code from lib/api', () {
      final violations = <String>[];
      for (final file in files) {
        for (final match in _import.allMatches(file.readAsStringSync())) {
          final uri = match.group(1)!;
          if (uri.startsWith('package:http/')) {
            violations.add('${_relative(file)}: imports $uri');
            continue;
          }
          if (uri.startsWith('package:') || uri.startsWith('dart:')) continue;
          final target = File(file.parent.uri.resolve(uri).toFilePath());
          if (!target.path.contains('${Platform.pathSeparator}lib${Platform.pathSeparator}api')) continue;
          if (_networkCode.hasMatch(target.readAsStringSync())) {
            violations.add('${_relative(file)}: imports ${_relative(target)}, which makes requests');
          }
        }
      }
      expect(violations, isEmpty, reason: _hint);
    });

    test('reaches neither Helix, the ApiClient nor dart:io networking', () {
      final violations = <String>[];
      for (final file in files) {
        final lines = _code(file.readAsStringSync()).split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (_networkAccess.hasMatch(lines[i])) violations.add('${_relative(file)}:${i + 1}: ${lines[i].trim()}');
        }
      }
      expect(violations, isEmpty, reason: _hint);
    });
  });
}

const _hint =
    'Widgets only render state and forward user actions. Move the request into a Cubit, a repository or a function '
    'in lib/data/, lib/tmi/ or lib/tools/ and test it there (see CLAUDE.md).';
