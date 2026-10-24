import Foundation

// MARK: - Response shapes (only the fields the app uses)

private struct SevenTVEmoteSet: Decodable {
    let emotes: [SevenTVEmote]?
}

private struct SevenTVUser: Decodable {
    let emote_set: SevenTVEmoteSet?
}

private struct SevenTVEmote: Decodable {
    struct Data: Decodable {
        struct Host: Decodable {
            struct File: Decodable {
                let name: String
                let format: String
            }

            let url: String
            let files: [File]
        }

        let flags: Int
        let host: Host
    }

    let id: String
    let name: String
    let data: Data
}

private struct SevenTVCosmetics: Decodable {
    struct Badge: Decodable {
        let id: String
        let tooltip: String
        let urls: [[String]]
        let users: [String]
    }

    let badges: [Badge]
}

private struct BTTVEmote: Decodable {
    let id: String
    let code: String
}

private struct BTTVUser: Decodable {
    let id: String?
    let channelEmotes: [BTTVEmote]?
    let sharedEmotes: [BTTVEmote]?
}

private struct BTTVBadge: Decodable {
    struct Info: Decodable {
        let description: String
        let svg: String
    }

    let id: String
    let providerId: String
    let badge: Info
}

private struct FFZEmote: Decodable {
    let id: Int
    let name: String
    let urls: [String: String]
}

private struct FFZSet: Decodable {
    let emoticons: [FFZEmote]
}

private struct FFZGlobal: Decodable {
    let sets: [String: FFZSet]
}

private struct FFZRoom: Decodable {
    let sets: [String: FFZSet]
}

private struct FFZBadges: Decodable {
    struct Badge: Decodable {
        let id: Int
        let title: String
        let urls: [String: String]
    }

    let badges: [Badge]
    let users: [String: [Int]]
}

private struct DankChatBadge: Decodable {
    let type: String
    let url: String
    let users: [String]
}

private struct EmojiData: Decodable {
    let unified: String
    let short_name: String
    let image: String
    let category: String
    let sort_order: Int
    let has_img_apple: Bool?
}

private struct RecentMessagesResponse: Decodable {
    let messages: [String]
}

// MARK: - Providers

/// Emotes and badges from Twitch, 7TV, BetterTTV, FrankerFaceZ, DankChat and emoji-data.
enum Providers {
    static let emoteProviders: [ProviderKind] = [.sevenTV, .betterTTV, .frankerFaceZ, .twitch, .emoji]
    static let userBadgeProviders: [ProviderKind] = [.sevenTV, .betterTTV, .frankerFaceZ, .dankChat]

    /// BetterTTV's zero-width emotes, which its API doesn't flag.
    private static let bttvZeroWidth: Set<String> = ["SoSnowy", "IceCold", "SantaHat", "TopHat", "ReinDeer", "CandyCane", "cvMask", "cvHazmat"]

    static func order(_ provider: ProviderKind) -> Int {
        ProviderKind.allCases.firstIndex(of: provider) ?? 0
    }

    // MARK: Emotes

    static func globalEmotes(_ provider: ProviderKind) async throws -> [Emote] {
        switch provider {
        case .sevenTV:
            let set = try await HTTP.json(SevenTVEmoteSet.self, from: .api("https://7tv.io/v3/emote-sets/global"))
            return (set.emotes ?? []).compactMap(sevenTVEmote)
        case .betterTTV:
            let emotes = try await HTTP.json([BTTVEmote].self, from: .api("https://api.betterttv.net/3/cached/emotes/global"))
            return emotes.map { bttvEmote($0, zeroWidth: bttvZeroWidth.contains($0.code)) }
        case .frankerFaceZ:
            let global = try await HTTP.json(FFZGlobal.self, from: .api("https://api.frankerfacez.com/v1/set/global"))
            return global.sets.sorted { $0.key < $1.key }.flatMap { $0.value.emoticons.map(ffzEmote) }
        case .emoji:
            return try await emojis()
        case .twitch, .dankChat:
            return []
        }
    }

    static func channelEmotes(_ provider: ProviderKind, roomId: String) async throws -> [Emote] {
        switch provider {
        case .sevenTV:
            let (data, status) = try await HTTP.data(.api("https://7tv.io/v3/users/twitch/\(roomId)"))
            guard status == 200 else { return [] }
            return (try JSONDecoder().decode(SevenTVUser.self, from: data).emote_set?.emotes ?? []).compactMap(sevenTVEmote)
        case .betterTTV:
            let (data, status) = try await HTTP.data(.api("https://api.betterttv.net/3/cached/users/twitch/\(roomId)"))
            guard status == 200 else { return [] }
            let user = try JSONDecoder().decode(BTTVUser.self, from: data)
            return ((user.channelEmotes ?? []) + (user.sharedEmotes ?? [])).map { bttvEmote($0, zeroWidth: false) }
        case .frankerFaceZ:
            let (data, status) = try await HTTP.data(.api("https://api.frankerfacez.com/v1/room/id/\(roomId)"))
            guard status == 200 else { return [] }
            return try JSONDecoder().decode(FFZRoom.self, from: data).sets.sorted { $0.key < $1.key }.flatMap { $0.value.emoticons.map(ffzEmote) }
        case .twitch, .emoji, .dankChat:
            return []
        }
    }

    private static func sevenTVEmote(_ emote: SevenTVEmote) -> Emote? {
        // WebP where there is one: iOS decodes it natively, and animated ones are a fraction of the GIF's size.
        let webp = emote.data.host.files.filter { $0.format == "WEBP" }
        let files = webp.isEmpty ? emote.data.host.files.filter { $0.format != "AVIF" } : webp
        guard !files.isEmpty else { return nil }
        return Emote(
            id: emote.id,
            name: emote.name,
            mipmap: files.map { "https:\(emote.data.host.url)/\($0.name)" },
            flags: emote.data.flags & (1 << 8) != 0 ? EmoteFlags.overlay : 0,
            provider: .sevenTV
        )
    }

    private static func bttvEmote(_ emote: BTTVEmote, zeroWidth: Bool) -> Emote {
        Emote(
            id: emote.id,
            name: emote.code,
            mipmap: (1...3).map { "https://cdn.betterttv.net/emote/\(emote.id)/\($0)x" },
            flags: zeroWidth ? EmoteFlags.overlay : 0,
            provider: .betterTTV
        )
    }

    private static func ffzEmote(_ emote: FFZEmote) -> Emote {
        Emote(
            id: "\(emote.id)",
            name: emote.name,
            mipmap: emote.urls.sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }.map(\.value),
            provider: .frankerFaceZ
        )
    }

    /// Emojis render as text in Apple's emoji font, so only the ones it has are listed, in Unicode's order with
    /// the bare skin tone swatches last.
    private static func emojis() async throws -> [Emote] {
        let list = try await HTTP.json([EmojiData].self, from: .api("https://raw.githubusercontent.com/iamcal/emoji-data/master/emoji.json"))
        func rank(_ entry: EmojiData) -> Int { (entry.category == "Component" ? 100_000 : 0) + entry.sort_order }
        return list.filter { $0.has_img_apple == true }.sorted { rank($0) < rank($1) }.map { entry in
            let code = String(String.UnicodeScalarView(entry.unified.split(separator: "-").compactMap { UInt32($0, radix: 16).flatMap(Unicode.Scalar.init) }))
            return Emote(
                id: entry.unified,
                name: entry.short_name,
                code: code,
                mipmap: ["https://raw.githubusercontent.com/iamcal/emoji-data/master/img-twitter-72/\(entry.image)"],
                provider: .emoji,
                category: entry.category
            )
        }
    }

    // MARK: Badges

    /// Only Twitch has global and channel badges; it needs a login for them.
    static func globalBadges(token: TokenData?) async throws -> [CustomBadge] {
        guard let token, token.accessToken != nil else { return [] }
        return try await Twitch.globalBadges(token)
    }

    static func channelBadges(roomId: String, token: TokenData?) async throws -> [CustomBadge] {
        guard let token, token.accessToken != nil else { return [] }
        return try await Twitch.channelBadges(token, roomId: roomId)
    }

    static func globalUserBadges(_ provider: ProviderKind) async throws -> [BadgeUsers] {
        switch provider {
        case .sevenTV:
            let cosmetics = try await HTTP.json(SevenTVCosmetics.self, from: .api("https://7tv.io/v2/cosmetics?user_identifier=twitch_id"))
            return cosmetics.badges.map { badge in
                BadgeUsers(badge: CustomBadge(id: badge.id, name: badge.tooltip, mipmap: badge.urls.compactMap(\.last), provider: .sevenTV), users: badge.users)
            }
        case .betterTTV:
            let badges = try await HTTP.json([BTTVBadge].self, from: .api("https://api.betterttv.net/3/cached/badges"))
            return badges.map { badge in
                BadgeUsers(badge: CustomBadge(id: badge.id, name: badge.badge.description, mipmap: [badge.badge.svg], provider: .betterTTV), users: [badge.providerId])
            }
        case .frankerFaceZ:
            let badges = try await HTTP.json(FFZBadges.self, from: .api("https://api.frankerfacez.com/v1/badges/ids"))
            return badges.badges.map { badge in
                BadgeUsers(
                    badge: CustomBadge(
                        id: "\(badge.id)",
                        name: badge.title,
                        mipmap: badge.urls.sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }.map(\.value),
                        provider: .frankerFaceZ
                    ),
                    users: badges.users["\(badge.id)"]?.map { "\($0)" } ?? []
                )
            }
        case .dankChat:
            let badges = try await HTTP.json([DankChatBadge].self, from: .api("https://flxrs.com/api/badges"))
            return badges.map { badge in
                BadgeUsers(badge: CustomBadge(id: Data(badge.url.utf8).base64EncodedString(), name: badge.type, mipmap: [badge.url], provider: .dankChat), users: badge.users)
            }
        case .twitch, .emoji:
            return []
        }
    }

    // MARK: History

    static func recentMessages(_ channelLogin: String) async throws -> [String] {
        try await HTTP.json(RecentMessagesResponse.self, from: .api("https://recent-messages.robotty.de/api/v2/recent-messages/\(channelLogin)")).messages
    }
}
