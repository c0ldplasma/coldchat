/// Someone the Credits thank for parts of the translation into [language].
class Credit {
  final String name;

  /// Their Twitch channel.
  final String url;

  /// The language they translated into, as a locale tag like `pt_BR`.
  final String language;

  const Credit({required this.name, required this.url, required this.language});
}

/// The people who translated ColdChat (Chatsen at the time). They wrote parts of their language's translation; texts
/// added later, and the languages without a translator here, were translated with AI. (Chatsen's logo designer isn't
/// listed: ColdChat has a logo of its own.)
const credits = [
  Credit(name: '21mtd', url: 'https://twitch.tv/21mtd', language: 'vi'),
  Credit(name: 'badpixel134', url: 'https://twitch.tv/badpixel134', language: 'ko'),
  Credit(name: 'copperrum', url: 'https://twitch.tv/copperrum', language: 'ru'),
  Credit(name: 'LosFarmosCTL', url: 'https://twitch.tv/losfarmosctl', language: 'de'),
  Credit(name: 'rix', url: 'https://twitch.tv/rix_ow', language: 'el'),
  Credit(name: 'captkayy', url: 'https://twitch.tv/captkayy', language: 'hi'),
  Credit(name: 'supdos', url: 'https://twitch.tv/supdos', language: 'es'),
  Credit(name: 'Boleto', url: 'https://twitch.tv/boletodosub', language: 'pt_BR'),
  Credit(name: 'Symphonystars', url: 'https://twitch.tv/symphonystars', language: 'it'),
];
