import 'package:json_annotation/json_annotation.dart';

import '../json_isolate.dart';

part 'twitch_badge.g.dart';

@JsonSerializable()
class TwitchBadge {
  @JsonKey(name: 'image_url_1x')
  String imageUrl1x;

  @JsonKey(name: 'image_url_2x')
  String imageUrl2x;

  @JsonKey(name: 'image_url_4x')
  String imageUrl4x;

  @JsonKey(name: 'description')
  String? description;

  @JsonKey(name: 'title')
  String title;

  // @JsonKey(name: 'version', ignore: true)
  // String? version;

  TwitchBadge({
    required this.imageUrl1x,
    required this.imageUrl2x,
    required this.imageUrl4x,
    required this.description,
    required this.title,
    // this.version,
  });

  factory TwitchBadge.fromJson(Map<String, dynamic> json) => _$TwitchBadgeFromJson(json);

  Map<String, dynamic> toJson() => _$TwitchBadgeToJson(this);
}

/// Badge versions by version id, by set id, from a list of badge sets as Helix and ivr.fi return them
/// (`[{set_id, versions: [{id, image_url_1x, …}]}]`).
Map<String, Map<String, TwitchBadge>> twitchBadgeSetsFromJson(List<dynamic> badgeSets) => {
  for (final badgeSet in badgeSets)
    (badgeSet as JsonMap)['set_id'] as String: {
      for (final badgeVersion in badgeSet['versions'] as List<dynamic>)
        (badgeVersion as JsonMap)['id'] as String: TwitchBadge.fromJson(badgeVersion),
    },
};
