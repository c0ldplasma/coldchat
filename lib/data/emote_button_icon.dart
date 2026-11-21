import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../providers/emojis.dart';
import 'emote.dart';
import 'repositories/settings_repository.dart';

/// The emote shown on the button that opens the emote menu. Defaults to Kappa.
///
/// Image emotes are downloaded once and kept in the app's support directory,
/// so the button survives the emote being removed from its provider, the
/// image cache being cleared, and being offline. Emojis are stored as text.
class EmoteButtonIcon {
  final SettingsRepository settings;

  // Resolved once at startup so the button can build synchronously. Only file
  // names are stored: the absolute container path changes between iOS
  // installs and updates.
  final Directory? directory;

  EmoteButtonIcon(this.settings, {this.directory});

  static Future<EmoteButtonIcon> open(SettingsRepository settings) async => EmoteButtonIcon(
    settings,
    directory: Directory('${(await getApplicationSupportDirectory()).path}/emote_button'),
  );

  /// Fires when the button's emote or [grayscale] changes.
  Listenable get changes => settings.emoteButtonChanges;

  bool get grayscale => settings.emoteButtonGrayscale;
  Future<void> setGrayscale(bool value) => settings.setEmoteButtonGrayscale(value);

  /// The saved image, or null for an emoji or the default Kappa.
  File? get file {
    final name = settings.emoteButtonIcon?['file'];
    final directory = this.directory;
    if (name is! String || directory == null) return null;
    final file = File('${directory.path}/$name');
    return file.existsSync() ? file : null;
  }

  String? get emoji {
    final emoji = settings.emoteButtonIcon?['emoji'];
    return emoji is String ? emoji : null;
  }

  String? get name {
    final name = settings.emoteButtonIcon?['name'];
    return name is String ? name : null;
  }

  /// Downloads [emote] and makes it the button. Throws if it can't be
  /// downloaded or isn't a decodable image; the current button is kept then.
  Future<void> set(Emote emote) async {
    if (emote.provider is EmojiProvider && emote.code != null) {
      final previous = file;
      await settings.setEmoteButtonIcon({'name': emote.name, 'emoji': emote.code});
      _deleteQuietly(previous);
      return;
    }

    final response = await http.get(Uri.parse(emote.mipmap.last)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(emote.mipmap.last));
    }
    // Make sure it's an image before replacing the current button with it.
    final codec = await ui.instantiateImageCodec(response.bodyBytes);
    codec.dispose();

    // A fresh name each time: Image.file caches by path, so overwriting the
    // same file would keep showing the old emote.
    final directory = this.directory!;
    await directory.create(recursive: true);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${_extension(response, emote.mipmap.last)}';
    await File('${directory.path}/$fileName').writeAsBytes(response.bodyBytes, flush: true);

    final previous = file;
    await settings.setEmoteButtonIcon({'name': emote.name, 'file': fileName});
    _deleteQuietly(previous);
  }

  Future<void> reset() async {
    final previous = file;
    await settings.setEmoteButtonIcon(null);
    _deleteQuietly(previous);
  }

  static String _extension(http.Response response, String url) {
    final type = response.headers['content-type'] ?? '';
    if (type.contains('gif')) return '.gif';
    if (type.contains('webp')) return '.webp';
    if (type.contains('png')) return '.png';
    final path = Uri.parse(url).path;
    final dot = path.lastIndexOf('.');
    return dot != -1 && path.length - dot <= 5 ? path.substring(dot) : '';
  }

  static void _deleteQuietly(File? file) {
    unawaited(file?.delete().catchError((_) => file));
  }
}
