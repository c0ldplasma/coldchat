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

/// An adapter registered by hand instead of through the generated `Hive.registerAdapters()`.
final _handRegisteredAdapter = RegExp(r'\bregisterAdapter\(');

/// A color picked in code rather than taken from the theme: a hex literal or a named Material color. Black, white
/// and transparent stay allowed for scrims, overlays on images and invisible backgrounds.
final _hardcodedColor = RegExp(r'\bColor\(0x|\bColors\.(?!black|white|transparent)\w+');

/// A string literal given to something that shows text: a `Text`, or a tooltip, title, label or hint.
final _shownLiteral = RegExp(
  r'''(?:\bText\(|\b(?:tooltip|message|title|subtitle|description|label|labelText|hintText|helperText|semanticLabel|semanticsLabel):)\s*(?:'([^'\n]*)'|"([^"\n]*)")''',
);

/// Interpolations in a literal, which aren't text of their own.
final _interpolation = RegExp(r'\$\{[^}]*\}|\$\w+');

/// A word in a literal: two letters or more.
final _word = RegExp(r'\p{L}{2,}', unicode: true);

/// A web address, which isn't translated.
final _webAddress = RegExp(r'^(?:https?://)?[\w-]+(?:\.[\w-]+)+(?:/\S*)?$');

/// The lines of [files] that show a word in a string literal instead of a text from AppLocalizations. A line saying
/// `// Not translated: <why>` is a deliberate exception, e.g. a license's name.
List<String> _untranslatedLines(List<File> files) => [
  for (final file in files)
    for (final (i, line) in _code(file.readAsStringSync()).split('\n').indexed)
      if (!line.contains('// Not translated:') &&
          _shownLiteral.allMatches(line).any((match) {
            final text = (match[1] ?? match[2]!).replaceAll(_interpolation, '').trim();
            return _word.hasMatch(text) && !_webAddress.hasMatch(text);
          }))
        '${_relative(file)}:${i + 1}: ${line.trim()}',
];

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

  // Keep in sync with the colors paragraph in CLAUDE.md.
  test('colors come from lib/theme', () {
    final files = [
      for (final file in _dartFiles('lib'))
        if (!_relative(file).startsWith('lib${Platform.pathSeparator}theme${Platform.pathSeparator}')) file,
    ];
    expect(files, isNotEmpty);
    expect(
      _matchingLines(files, _hardcodedColor),
      isEmpty,
      reason: 'Name the color in lib/theme/coldchat_theme.dart (ColorScheme or ChatColors) and use it from there.',
    );
  });

  // Keep in sync with "Localization" in CLAUDE.md. gen-l10n only checks that every language has every key of the
  // .arb files; text typed into the code instead stays English in every language.
  test('the UI shows no text typed into the code', () {
    final files = [for (final folder in _uiFolders) ..._dartFiles(folder)];
    expect(files, isNotEmpty);
    expect(
      _untranslatedLines(files),
      isEmpty,
      reason:
          'Add the text to every lib/l10n/*.arb and use AppLocalizations.of(context). For a deliberate exception, '
          'end the line with // Not translated: <why>.',
    );
  });

  // Emote and badge images share a byte-limited cache (lib/data/emote_cache.dart); in the default one, 200 files, they
  // get evicted and downloaded again within a day.
  test('emote and badge images use the emote cache', () {
    final files = _dartFiles('lib');
    final calls = [
      for (final file in files)
        for (final call in _calls(_code(file.readAsStringSync()), RegExp(r'\bCachedNetworkImage(Provider)?\(')))
          if (call.contains('mipmap')) (file: _relative(file), call: call),
    ];
    expect(calls, isNotEmpty, reason: 'The check finds no emote images, so it checks nothing.');
    expect(
      [
        for (final c in calls)
          if (!c.call.contains('cacheManager: EmoteCacheManager.instance')) '${c.file}: ${c.call}',
      ],
      isEmpty,
      reason: 'Pass cacheManager: EmoteCacheManager.instance to emote and badge images.',
    );
  });

  // A stored model whose adapter isn't registered makes opening its box throw, and main() never reaches runApp.
  // The tests register the generated list too, so only this check catches main.dart not using it.
  group('Hive adapters', () {
    test('main.dart registers the generated adapter list', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(_code(main), contains('Hive.registerAdapters()'), reason: _hiveHint);
    });

    test('no adapter is registered by hand', () {
      expect(_matchingLines(_dartFiles('lib'), _handRegisteredAdapter), isEmpty, reason: _hiveHint);
    });
  });
}

/// The calls in [code] that start with [start] (ending in the opening parenthesis), up to their closing one.
List<String> _calls(String code, RegExp start) => [
  for (final match in start.allMatches(code)) _untilClosingParenthesis(code, match.end),
];

String _untilClosingParenthesis(String code, int afterOpening) {
  var depth = 1;
  for (var i = afterOpening; i < code.length; i++) {
    if (code[i] == '(') depth++;
    if (code[i] == ')' && --depth == 0) return code.substring(afterOpening - 1, i + 1);
  }
  return code.substring(afterOpening - 1);
}

const _hint =
    'Widgets only render state and forward user actions. Move the request into a Cubit, a repository or a function '
    'in lib/data/, lib/tmi/ or lib/tools/ and test it there (see CLAUDE.md).';

const _stateHint =
    'Runtime state lives in a Cubit/Bloc provided with BlocProvider (or owned by Client/Channel) and rendered with '
    'BlocBuilder; saved settings in a repository\'s changes Listenable rendered with ListenableBuilder. Widgets reach '
    'shared state through those, never through another widget\'s State (see CLAUDE.md).';

const _hiveHint =
    'Register Hive adapters only with Hive.registerAdapters() from the generated lib/hive_registrar.g.dart, in '
    'main.dart before the boxes are opened; it lists every @HiveType, so none can be forgotten (see CLAUDE.md).';
