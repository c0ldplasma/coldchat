import '../sources/chat_source.dart';

class CustomBadge {
  String id;
  String name;
  String? description;
  List<String> mipmap;
  int flags;
  ChatSource source;

  CustomBadge({
    required this.id,
    required this.name,
    this.description,
    required this.mipmap,
    this.flags = 0,
    required this.source,
  });
}
