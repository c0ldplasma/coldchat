import 'package:json_annotation/json_annotation.dart';

import 'seventv_badge.dart';

part 'seventv_cosmetics.g.dart';

@JsonSerializable()
class SevenTVCosmetics {
  List<SevenTVBadge> badges;

  SevenTVCosmetics({
    required this.badges,
  });

  factory SevenTVCosmetics.fromJson(Map<String, dynamic> json) => _$SevenTVCosmeticsFromJson(json);
  Map<String, dynamic> toJson() => _$SevenTVCosmeticsToJson(this);
}
