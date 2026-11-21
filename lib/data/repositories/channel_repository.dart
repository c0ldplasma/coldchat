import 'package:hive_ce/hive_ce.dart';

/// The channels the user has open as tabs (box `Channels`, a list of channel names in tab order) and the tab that was
/// open last (key `lastChannel` in the `Settings` box).
class ChannelRepository {
  static const String boxName = 'Channels';
  static const String settingsBoxName = 'Settings';
  static const String lastChannelKey = 'lastChannel';

  final Box<dynamic> _channels;
  final Box<dynamic> _settings;

  /// Takes the open `Channels` and `Settings` boxes; [open] opens them.
  ChannelRepository(this._channels, this._settings);

  static Future<ChannelRepository> open() async {
    final boxes = await Future.wait([Hive.openBox<dynamic>(boxName), Hive.openBox<dynamic>(settingsBoxName)]);
    return ChannelRepository(boxes[0], boxes[1]);
  }

  /// The names of the open channels, in tab order.
  List<String> get channels => _channels.values.whereType<String>().toList();

  Future<void> add(String channelName) => _channels.add(channelName);

  Future<void> addAll(Iterable<String> channelNames) => _channels.addAll(channelNames);

  /// Removes the first entry for [channelName], if there is one.
  Future<void> remove(String channelName) async {
    final index = _channels.values.toList().indexOf(channelName);
    if (index >= 0) await _channels.deleteAt(index);
  }

  /// The name of the tab that was open last: a channel, a whisper tab's `@login`, or empty for the home tab. Null
  /// before any tab was opened.
  String? get lastChannel {
    final name = _settings.get(lastChannelKey);
    return name is String ? name : null;
  }

  Future<void> setLastChannel(String name) => _settings.put(lastChannelKey, name);
}
