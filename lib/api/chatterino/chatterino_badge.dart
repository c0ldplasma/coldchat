import 'package:json_annotation/json_annotation.dart';

part 'chatterino_badge.g.dart';

/// One badge from `api.chatterino.com/badges`: its tooltip, the image at 1x, 2x and 3x, and the Twitch user ids that
/// have it. Every field may be missing; the source skips badges without a tooltip or an image.
@JsonSerializable()
class ChatterinoBadge {
  String? tooltip;
  String? image1;
  String? image2;
  String? image3;

  @JsonKey(fromJson: _ids, defaultValue: <String>[])
  List<String> users;

  ChatterinoBadge({
    this.tooltip,
    this.image1,
    this.image2,
    this.image3,
    this.users = const [],
  });

  factory ChatterinoBadge.fromJson(Map<String, dynamic> json) => _$ChatterinoBadgeFromJson(json);

  Map<String, dynamic> toJson() => _$ChatterinoBadgeToJson(this);

  // Ids are strings today; take numbers too rather than dropping the whole list.
  static List<String> _ids(Object? json) => [
    if (json is List)
      for (final id in json)
        if (id != null) id.toString(),
  ];
}
