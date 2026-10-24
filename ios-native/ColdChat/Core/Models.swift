import Foundation

/// Where an emote or badge comes from. The raw values are the provider names the Flutter app used, which
/// also key the on-disk cache.
enum ProviderKind: String, Codable, CaseIterable {
    case sevenTV = "7TV"
    case betterTTV = "BetterTTV"
    case frankerFaceZ = "FrankerFaceZ"
    case dankChat = "DankChat"
    case twitch = "Twitch"
    case emoji = "Emoji"

    var name: String { rawValue }

    var servesEmotes: Bool { self != .dankChat }

    /// The provider's web page for an emote, if it has one.
    func emoteURL(_ id: String) -> URL? {
        switch self {
        case .sevenTV: URL(string: "https://7tv.app/emotes/\(id)")
        case .betterTTV: URL(string: "https://betterttv.com/emotes/\(id)")
        case .frankerFaceZ: URL(string: "https://www.frankerfacez.com/emoticon/\(id)")
        default: nil
        }
    }
}

struct EmoteFlags {
    /// Zero-width: drawn on top of the emote before it.
    static let overlay = 1 << 0
}

struct Emote: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    /// What to type for it when it differs from the name (emojis).
    var code: String?
    var description: String?
    /// Image URLs from smallest to largest.
    var mipmap: [String]
    var flags: Int = 0
    var provider: ProviderKind
    var category: String?

    var text: String { code ?? name }
    var isOverlay: Bool { flags & EmoteFlags.overlay != 0 }
    var largestURL: URL? { mipmap.last.flatMap(URL.init(string:)) }
    var isEmoji: Bool { provider == .emoji && code != nil }
}

struct CustomBadge: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var description: String?
    var mipmap: [String]
    var flags: Int = 0
    var provider: ProviderKind

    var largestURL: URL? { mipmap.last.flatMap(URL.init(string:)) }
}

/// A badge that a provider gives to a list of users rather than through IRC tags.
struct BadgeUsers: Codable {
    var badge: CustomBadge
    var users: [String]
}

struct ChatUser: Hashable {
    var login: String?
    var displayName: String?
    var id: String?
    /// 0xRRGGBB from the `color` tag.
    var color: UInt32?

    var name: String { displayName ?? login ?? "" }
}

// MARK: - Accounts

struct TokenData: Codable, Hashable {
    var clientId: String?
    var login: String
    var scopes: [String]
    var userId: String?
    var expiresAt: Date?
    var accessToken: String?

    var hash: String { "\(userId ?? "null")@\(clientId ?? "null")" }

    /// Whether the token is past (or within 30 seconds of) its expiry. Implicit-grant tokens can't be refreshed, so
    /// an expired one means signing in again.
    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() > expiresAt.addingTimeInterval(-30)
    }
}

struct UserData: Codable, Hashable {
    var displayName: String
    var avatarUrl: String
    var offlineUrl: String
}

struct TwitchAccount: Codable, Hashable, Identifiable {
    var tokenData: TokenData
    var userData: UserData?

    var id: String { tokenData.hash }
    var name: String { userData?.displayName ?? tokenData.login }
    var isAnonymous: Bool { tokenData.accessToken == nil }

    /// Reads chat without logging in.
    static let anonymous = TwitchAccount(
        tokenData: TokenData(clientId: nil, login: "justinfan6969", scopes: [], userId: nil, expiresAt: nil, accessToken: nil),
        userData: nil
    )
}

// MARK: - Triggers and commands

enum TriggerType: Int, Codable {
    case mention = 0
    case block = 1
}

struct MessageTrigger: Codable, Hashable, Identifiable {
    var id = UUID()
    var type: TriggerType
    var pattern: String
    var enableRegex = false
    var caseSensitive = false
    var showInMentions = true
    var sendNotification = true
    var playSound = true
}

struct UserTrigger: Codable, Hashable, Identifiable {
    var id = UUID()
    var type: TriggerType
    var login: String
    var enableRegex = false
    var caseSensitive = false
    var showInMentions = true
    var sendNotification = true
    var playSound = true
}

struct CustomCommand: Codable, Hashable, Identifiable {
    var id = UUID()
    var trigger: String
    var command: String
}
