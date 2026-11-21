import '../data/emote.dart';
import 'chat_source.dart';

// TODO: Migrate EmoteSource to use a Map instead of a List
mixin EmoteSource on ChatSource {
  Future<List<Emote>> globalEmotes() async => throw UnimplementedError();
  Future<List<Emote>> channelEmotes(String uid) async => throw UnimplementedError();
  String? emoteUrl(String id) => throw UnimplementedError();
}
