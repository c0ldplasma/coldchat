import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The folders that hold the UI: widgets, pages, shared components and sheets.
const _uiFolders = ['lib/widgets', 'lib/pages', 'lib/components', 'lib/sheets'];

/// What a file in `lib/api/` must not contain for the UI to import it: then it talks to the network itself instead of
/// only declaring models or exceptions.
final _networkCode = RegExp(r'\bApiClient\b|package:http/|\bWebSocket\b|web_socket_channel');

/// Code in the UI that reaches the network directly: the client's Helix or [ApiClient], or dart:io's HTTP and
/// sockets.
final _networkAccess = RegExp(r'\.(helix|api)\b|\bHttpClient\b|\bWebSocket\b|\bSocket\.connect\b');

/// A widget reaching another widget's [State] instead of the state both render.
final _stateLookup = RegExp(r'\bfindAncestorStateOfType\b');

/// A Cubit or Bloc provided with plain `Provider`, which never closes it; `BlocProvider` does.
final _cubitInPlainProvider = RegExp(r'\bProvider<\w*(Cubit|Bloc)>');

final _import = RegExp(r'''^import\s+'([^']+)'(?:\s+as\s+\w+)?;''', multiLine: true);

/// The Dart files in [folder], without generated ones.
List<File> _dartFiles(String folder) => [
  if (Directory(folder).existsSync())
    for (final entity in Directory(folder).absolute.listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('.g.dart')) entity,
];

/// The lines of [files] that match [pattern], as `path:line: code`, comments left out.
List<String> _matchingLines(List<File> files, RegExp pattern) => [
  for (final file in files)
    for (final (i, line) in _code(file.readAsStringSync()).split('\n').indexed)
      if (pattern.hasMatch(line)) '${_relative(file)}:${i + 1}: ${line.trim()}',
];

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

    final files = [for (final folder in _uiFolders) ..._dartFiles(folder)];

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
      expect(_matchingLines(files, _networkAccess), isEmpty, reason: _hint);
    });
  });

  // Keep in sync with "One state-management style" in CLAUDE.md.
  group('one state-management style', () {
    final files = _dartFiles('lib');

    test('finds the lib files', () => expect(files, isNotEmpty));

    test('no widget looks up another widget\'s State', () {
      expect(_matchingLines(files, _stateLookup), isEmpty, reason: _stateHint);
    });

    test('Cubits and Blocs are provided with BlocProvider', () {
      expect(_matchingLines(files, _cubitInPlainProvider), isEmpty, reason: _stateHint);
    });
  });
}

const _hint =
    'Widgets only render state and forward user actions. Move the request into a Cubit, a repository or a function '
    'in lib/data/, lib/tmi/ or lib/tools/ and test it there (see CLAUDE.md).';

const _stateHint =
    'Runtime state lives in a Cubit/Bloc provided with BlocProvider (or owned by Client/Channel) and rendered with '
    'BlocBuilder; saved settings in a repository\'s changes Listenable rendered with ListenableBuilder. Widgets reach '
    'shared state through those, never through another widget\'s State (see CLAUDE.md).';
