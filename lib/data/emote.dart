import '../providers/provider.dart';

class EmoteFlags {
  /// Zero-width (7TV, BetterTTV): drawn on top of the emote before it.
  static const int overlay = 1 << 0;

  /// A hidden FrankerFaceZ effect modifier: not drawn, but changes the emote before it with the effects below.
  static const int modifier = 1 << 1;

  static const int flipX = 1 << 2;
  static const int flipY = 1 << 3;
  static const int growX = 1 << 4;
  static const int rotate90 = 1 << 5;
  static const int greyscale = 1 << 6;
  static const int sepia = 1 << 7;

  static const int effects = flipX | flipY | growX | rotate90 | greyscale | sepia;
}

class Emote {
  String id;
  String name;
  String? code;
  String? description;
  List<String> mipmap;
  int flags;
  Provider provider;
  String? category;

  Emote({
    required this.id,
    required this.name,
    this.code,
    this.description,
    required this.mipmap,
    this.flags = 0,
    required this.provider,
    this.category,
  });
}

/// An emote in a message together with the zero-width emotes drawn over it and the FrankerFaceZ modifiers
/// applied to it, e.g. `Kappa RainTime ffzX`.
class EmoteStack {
  final Emote base;
  final List<Emote> overlays = [];
  final List<Emote> modifiers = [];

  EmoteStack(this.base);

  /// The [EmoteFlags.effects] of all modifiers.
  int get effects => modifiers.fold(0, (flags, modifier) => flags | (modifier.flags & EmoteFlags.effects));

  List<Emote> get emotes => [base, ...overlays, ...modifiers];
}
