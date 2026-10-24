import Foundation
import Observation

enum ThemeMode: String, CaseIterable {
    case light, dark, system
}

/// Everything from Settings, plus the channel list, triggers and custom commands. Stored in UserDefaults; none
/// of it is sensitive.
@MainActor
@Observable
final class AppSettings {
    private let defaults = UserDefaults.standard

    // Application appearance
    var themeMode: ThemeMode { didSet { defaults.set(themeMode.rawValue, forKey: "themeMode") } }
    var highContrast: Bool { didSet { defaults.set(highContrast, forKey: "highContrast") } }
    /// 0xAARRGGBB, like the Flutter app's `themeColor`.
    var themeColor: UInt32 { didSet { defaults.set(Int(themeColor), forKey: "themeColor") } }
    /// A language tag from `L10n.locales`, or nil for the system language.
    var locale: String? {
        didSet {
            defaults.set(locale, forKey: "locale")
            Localization.use(locale)
        }
    }

    // Message appearance
    var showTimestamps: Bool { didSet { defaults.set(showTimestamps, forKey: "timestamps") } }
    var showBadges: Bool { didSet { defaults.set(showBadges, forKey: "badges") } }
    var compactMessages: Bool { didSet { defaults.set(compactMessages, forKey: "compactMessages") } }
    var messageScale: Double { didSet { defaults.set(messageScale, forKey: "messageScale") } }

    // Chat settings
    var userAutocompletionWithAt: Bool { didSet { defaults.set(userAutocompletionWithAt, forKey: "userAutocompletionWithAt") } }
    var emoteAutocompletionWithColon: Bool { didSet { defaults.set(emoteAutocompletionWithColon, forKey: "emoteAutocompletionWithColon") } }
    var emoteButtonGrayscale: Bool { didSet { defaults.set(emoteButtonGrayscale, forKey: "emoteButtonGrayscale") } }
    /// Load chat from before joining from recent-messages.robotty.de.
    var chatHistory: Bool { didSet { defaults.set(chatHistory, forKey: "recentMessagesChatHistory") } }

    /// The channel tab that was open last, or "" for the home tab.
    var lastChannel: String { didSet { defaults.set(lastChannel, forKey: "lastChannel") } }

    var channels: [String] { didSet { defaults.set(channels, forKey: "channels") } }
    var messageTriggers: [MessageTrigger] { didSet { store(messageTriggers, "messageTriggers") } }
    var userTriggers: [UserTrigger] { didSet { store(userTriggers, "userTriggers") } }
    var customCommands: [CustomCommand] { didSet { store(customCommands, "customCommands") } }

    init() {
        let d = UserDefaults.standard
        themeMode = ThemeMode(rawValue: d.string(forKey: "themeMode") ?? "") ?? .dark
        highContrast = d.bool(forKey: "highContrast")
        themeColor = (d.object(forKey: "themeColor") as? Int).map { UInt32(truncatingIfNeeded: $0) } ?? 0xFF2196F3
        locale = d.string(forKey: "locale")
        showTimestamps = d.object(forKey: "timestamps") as? Bool ?? true
        showBadges = d.object(forKey: "badges") as? Bool ?? true
        compactMessages = d.bool(forKey: "compactMessages")
        messageScale = d.object(forKey: "messageScale") as? Double ?? 1.0
        userAutocompletionWithAt = d.bool(forKey: "userAutocompletionWithAt")
        emoteAutocompletionWithColon = d.bool(forKey: "emoteAutocompletionWithColon")
        emoteButtonGrayscale = d.bool(forKey: "emoteButtonGrayscale")
        chatHistory = d.object(forKey: "recentMessagesChatHistory") as? Bool ?? true
        lastChannel = d.string(forKey: "lastChannel") ?? ""
        channels = d.stringArray(forKey: "channels") ?? []
        messageTriggers = Self.load("messageTriggers") ?? []
        userTriggers = Self.load("userTriggers") ?? []
        customCommands = Self.load("customCommands") ?? []
        Localization.use(locale)
    }

    private func store<T: Encodable>(_ value: T, _ key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private static func load<T: Decodable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

/// Ids of mentions already surfaced as notifications, so history replayed on launch doesn't notify again.
@MainActor
enum SeenMentions {
    private static let key = "seenMentions"
    private static let maxEntries = 500
    private static var cache: [String: Double] = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]

    static func contains(_ id: String) -> Bool { cache[id] != nil }

    static func insert(_ id: String) {
        guard !id.isEmpty, cache[id] == nil else { return }
        cache[id] = Date().timeIntervalSince1970
        if cache.count > maxEntries {
            for (oldId, _) in cache.sorted(by: { $0.value < $1.value }).prefix(cache.count - maxEntries) {
                cache.removeValue(forKey: oldId)
            }
        }
        UserDefaults.standard.set(cache, forKey: key)
    }
}
