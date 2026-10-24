import Foundation

/// A JSON cache of emotes, badges and chat history, so the first paint after launch or after opening a channel
/// doesn't wait on provider requests. Lives in Caches: iOS may purge it, and everything in it can be refetched.
@MainActor
final class EmoteBadgeCache {
    /// Channels whose emotes, badges and history are kept; the least recently used ones are dropped beyond this.
    static let maxCachedChannels = 60

    static let globalEmotesKey = "globalEmotes"
    static let globalBadgesKey = "globalBadges"
    static let globalUserBadgesKey = "globalUserBadges"
    static func twitchUserEmotesKey(_ userId: String) -> String { "twitchUserEmotes-\(userId)" }
    private static let bttvProBadgesKey = "bttvProBadges"
    private static let lruKey = "channelLru"

    private let directory: URL
    private let queue = DispatchQueue(label: "com.plasmari.coldchat.cache", qos: .utility)
    /// Channel access order, most recent last.
    private var lru: [String]

    init() {
        directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("EmoteBadgeCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        lru = []
        lru = load([String].self, Self.lruKey) ?? []
    }

    private func url(_ key: String) -> URL {
        directory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key).appendingPathExtension("json")
    }

    private func load<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = try? Data(contentsOf: url(key)) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T, _ key: String) {
        let target = url(key)
        guard let data = try? JSONEncoder().encode(value) else { return }
        queue.async { try? data.write(to: target, options: .atomic) }
    }

    private func delete(_ key: String) {
        let target = url(key)
        queue.async { try? FileManager.default.removeItem(at: target) }
    }

    /// Moves [login] to the most recent position and evicts the oldest channels beyond the cap.
    private func touch(_ login: String) {
        if lru.last == login { return }
        lru.removeAll { $0 == login }
        lru.append(login)
        while lru.count > Self.maxCachedChannels {
            let evicted = lru.removeFirst()
            delete(channelEmotesKey(evicted))
            delete(channelBadgesKey(evicted))
            delete(historyKey(evicted))
        }
        save(lru, Self.lruKey)
    }

    private func channelEmotesKey(_ login: String) -> String { "channelEmotes-\(login)" }
    private func channelBadgesKey(_ login: String) -> String { "channelBadges-\(login)" }
    private func historyKey(_ login: String) -> String { "history-\(login)" }

    // Emotes from a provider that no longer exists fail to decode and drop the whole list, which is then refetched.

    func loadEmotes(_ key: String) -> [Emote] { load([Emote].self, key) ?? [] }
    func saveEmotes(_ key: String, _ emotes: [Emote]) { save(emotes, key) }
    func loadBadges(_ key: String) -> [CustomBadge] { load([CustomBadge].self, key) ?? [] }
    func saveBadges(_ key: String, _ badges: [CustomBadge]) { save(badges, key) }
    func loadUserBadges(_ key: String) -> [BadgeUsers] { load([BadgeUsers].self, key) ?? [] }
    func saveUserBadges(_ key: String, _ badges: [BadgeUsers]) { save(badges, key) }

    /// BetterTTV Pro badge urls by Twitch user id, as ordered pairs so the oldest sighting stays first.
    func loadBttvProBadges() -> [(String, String)] {
        (load([[String]].self, Self.bttvProBadgesKey) ?? []).compactMap { $0.count == 2 ? ($0[0], $0[1]) : nil }
    }

    func saveBttvProBadges(_ badges: [(String, String)]) { save(badges.map { [$0.0, $0.1] }, Self.bttvProBadgesKey) }

    func loadChannelEmotes(_ login: String) -> [Emote] { loadEmotes(channelEmotesKey(login)) }

    func saveChannelEmotes(_ login: String, _ emotes: [Emote]) {
        touch(login)
        saveEmotes(channelEmotesKey(login), emotes)
    }

    func loadChannelBadges(_ login: String) -> [CustomBadge] { loadBadges(channelBadgesKey(login)) }

    func saveChannelBadges(_ login: String, _ badges: [CustomBadge]) {
        touch(login)
        saveBadges(channelBadgesKey(login), badges)
    }

    func loadHistory(_ login: String) -> [String] { load([String].self, historyKey(login)) ?? [] }

    func saveHistory(_ login: String, _ messages: [String]) {
        touch(login)
        save(messages, historyKey(login))
    }
}
