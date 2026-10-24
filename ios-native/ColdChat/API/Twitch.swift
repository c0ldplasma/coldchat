import Foundation

/// A Twitch user from Helix `GET /users`.
struct TwitchUser: Decodable, Hashable {
    let id: String
    let login: String
    let displayName: String
    let profileImageUrl: String
    let offlineImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, login
        case displayName = "display_name"
        case profileImageUrl = "profile_image_url"
        case offlineImageUrl = "offline_image_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        login = try c.decode(String.self, forKey: .login)
        displayName = try c.decode(String.self, forKey: .displayName)
        profileImageUrl = try c.decode(String.self, forKey: .profileImageUrl)
        let offline = try c.decodeIfPresent(String.self, forKey: .offlineImageUrl)
        offlineImageUrl = offline?.isEmpty == false ? offline : nil
    }
}

struct TwitchLiveStream: Hashable {
    let title: String
    let gameName: String
    let gameBoxArtUrl: String?
    let thumbnailUrl: String
    let viewerCount: Int
    let startedAt: Date
}

/// What the user card and the channel header show about a user.
struct TwitchProfile: Hashable {
    let user: TwitchUser
    /// Nil when Twitch didn't report it.
    let followerCount: Int?
    /// Nil when the user isn't live.
    let stream: TwitchLiveStream?
}

struct StreamData: Decodable, Identifiable, Hashable {
    let id: String
    let userId: String
    let userLogin: String
    let userName: String
    let gameName: String
    let title: String
    let viewerCount: Int
    let startedAt: Date
    let thumbnailUrl: String

    enum CodingKeys: String, CodingKey {
        case id, title
        case userId = "user_id"
        case userLogin = "user_login"
        case userName = "user_name"
        case gameName = "game_name"
        case viewerCount = "viewer_count"
        case startedAt = "started_at"
        case thumbnailUrl = "thumbnail_url"
    }

    func thumbnail(width: Int = 1920, height: Int = 1080) -> URL? {
        URL(string: thumbnailUrl.replacingOccurrences(of: "{width}", with: "\(width)").replacingOccurrences(of: "{height}", with: "\(height)"))
    }
}

struct SearchData: Decodable, Identifiable, Hashable {
    let id: String
    let broadcasterLogin: String
    let displayName: String
    let isLive: Bool
    let thumbnailUrl: String

    enum CodingKeys: String, CodingKey {
        case id
        case broadcasterLogin = "broadcaster_login"
        case displayName = "display_name"
        case isLive = "is_live"
        case thumbnailUrl = "thumbnail_url"
    }
}

struct TwitchEmote: Decodable {
    let id: String
    let name: String
    let images: [String: String]
}

/// Twitch rejected the access token (401 from /oauth2/validate). Distinct from other failures so callers can tell
/// "sign in again" apart from "the network is down".
struct TwitchTokenInvalid: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

private struct HelixPage<T: Decodable>: Decodable {
    let data: [T]
}

private struct HelixBadgeSet: Decodable {
    struct Version: Decodable {
        let id: String
        let title: String
        let description: String?
        let image_url_1x: String
        let image_url_2x: String
        let image_url_4x: String
    }

    let set_id: String
    let versions: [Version]
}

private let iso8601: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

enum Twitch {
    private static func headers(_ token: TokenData) -> [String: String] {
        ["Authorization": "Bearer \(token.accessToken ?? "")", "Client-Id": token.clientId ?? ""]
    }

    private static func helixGet(_ token: TokenData, _ pathAndQuery: String) async throws -> [String: Any] {
        let (object, status) = try await HTTP.object(.api("https://api.twitch.tv/helix/\(pathAndQuery)"), headers: headers(token))
        guard status == 200, let json = object as? [String: Any] else {
            throw HTTPError(status: status, message: "Twitch request \(pathAndQuery) failed with HTTP \(status)")
        }
        return json
    }

    private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            return iso8601.date(from: string) ?? Date()
        }
        return decoder
    }

    private static func helixDecode<T: Decodable>(_ token: TokenData, _ pathAndQuery: String, as type: T.Type) async throws -> T {
        let (data, status) = try await HTTP.data(.api("https://api.twitch.tv/helix/\(pathAndQuery)"), headers: headers(token))
        guard status == 200 else { throw HTTPError(status: status, message: "Twitch request \(pathAndQuery) failed with HTTP \(status)") }
        return try decoder().decode(T.self, from: data)
    }

    /// Throws for anything but [expected], with Twitch's own error message.
    private static func expect(_ status: Int, _ object: Any, _ expected: Int) throws {
        guard status != expected else { return }
        let json = object as? [String: Any]
        throw HTTPError(status: status, message: "\(json?["error"] as? String ?? "HTTP \(status)"): \(json?["message"] as? String ?? "")")
    }

    private static func query(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
    }

    // MARK: Auth

    static func validateToken(_ token: String) async throws -> TokenData {
        let (object, status) = try await HTTP.object(.api("https://id.twitch.tv/oauth2/validate"), headers: ["Authorization": "Bearer \(token)"])
        let json = object as? [String: Any] ?? [:]
        if status == 401 { throw TwitchTokenInvalid(message: json["message"] as? String ?? "invalid access token") }
        guard status == 200, let login = json["login"] as? String else {
            throw HTTPError(status: status, message: "Token validation failed (\(status)): \(json["message"] as? String ?? "")")
        }
        let expiresIn = json["expires_in"] as? Int ?? 0
        return TokenData(
            clientId: json["client_id"] as? String,
            login: login,
            scopes: json["scopes"] as? [String] ?? [],
            userId: json["user_id"] as? String,
            expiresAt: expiresIn == 0 ? nil : Date().addingTimeInterval(TimeInterval(expiresIn)),
            accessToken: token
        )
    }

    static func userData(_ token: TokenData) async throws -> UserData {
        let json = try await helixGet(token, "users")
        guard let user = (json["data"] as? [[String: Any]])?.first else { throw HTTPError(status: 200, message: "No user data") }
        return UserData(
            displayName: user["display_name"] as? String ?? token.login,
            avatarUrl: user["profile_image_url"] as? String ?? "",
            offlineUrl: user["offline_image_url"] as? String ?? ""
        )
    }

    // MARK: Users and streams

    static func blockedUsers(_ token: TokenData) async -> [String] {
        var result: [String] = []
        var cursor: String?
        repeat {
            guard let json = try? await helixGet(token, "users/blocks?broadcaster_id=\(token.userId ?? "")&first=100\(cursor.map { "&after=\($0)" } ?? "")") else { return result }
            result += (json["data"] as? [[String: Any]] ?? []).compactMap { $0["user_id"] as? String }
            cursor = (json["pagination"] as? [String: Any])?["cursor"] as? String
        } while cursor != nil
        return result
    }

    /// Up to 100 users per request; logins that don't exist are left out.
    static func users(_ token: TokenData, logins: [String]) async throws -> [TwitchUser] {
        var users: [TwitchUser] = []
        for start in stride(from: 0, to: logins.count, by: 100) {
            let batch = logins[start..<min(start + 100, logins.count)].map { "login=\(query($0))" }.joined(separator: "&")
            users += try await helixDecode(token, "users?\(batch)", as: HelixPage<TwitchUser>.self).data
        }
        return users
    }

    /// Everything the user card and the channel header show, or nil when the login doesn't exist. The follower
    /// total comes with any user token; only the follower list needs moderator rights.
    static func profile(_ token: TokenData, login: String) async throws -> TwitchProfile? {
        guard let user = try await users(token, logins: [login]).first else { return nil }
        async let streamsRequest = helixGet(token, "streams?user_id=\(user.id)")
        async let followersRequest = try? helixGet(token, "channels/followers?broadcaster_id=\(user.id)&first=1")
        let streams = try await streamsRequest["data"] as? [[String: Any]] ?? []
        let followerCount = await followersRequest?["total"] as? Int

        var stream: TwitchLiveStream?
        if let data = streams.first {
            var boxArt: String?
            if let gameId = data["game_id"] as? String, !gameId.isEmpty,
               let game = (try? await helixGet(token, "games?id=\(gameId)"))?["data"] as? [[String: Any]],
               let url = game.first?["box_art_url"] as? String {
                boxArt = url.replacingOccurrences(of: "{width}", with: "144").replacingOccurrences(of: "{height}", with: "192")
            }
            stream = TwitchLiveStream(
                title: data["title"] as? String ?? "",
                gameName: data["game_name"] as? String ?? "",
                gameBoxArtUrl: boxArt,
                thumbnailUrl: data["thumbnail_url"] as? String ?? "",
                viewerCount: data["viewer_count"] as? Int ?? 0,
                startedAt: (data["started_at"] as? String).flatMap(iso8601.date(from:)) ?? Date()
            )
        }
        return TwitchProfile(user: user, followerCount: followerCount, stream: stream)
    }

    static func streams(_ token: TokenData, userLogins: [String]? = nil) async throws -> [StreamData] {
        let logins = userLogins.map { "&" + $0.map { "user_login=\($0)" }.joined(separator: "&") } ?? ""
        return try await helixDecode(token, "streams?first=100\(logins)", as: HelixPage<StreamData>.self).data
    }

    static func searchChannels(_ token: TokenData, query text: String) async throws -> [SearchData] {
        try await helixDecode(token, "search/channels?query=\(query(text))", as: HelixPage<SearchData>.self).data
    }

    // MARK: Emotes and badges

    /// Skips a batch that fails instead of losing every other batch.
    static func emoteSets(_ token: TokenData, ids: [String]) async -> [TwitchEmote] {
        var emotes: [TwitchEmote] = []
        for start in stride(from: 0, to: ids.count, by: 25) {
            let batch = ids[start..<min(start + 25, ids.count)].map { "emote_set_id=\($0)" }.joined(separator: "&")
            if let page = try? await helixDecode(token, "chat/emotes/set?\(batch)", as: HelixPage<TwitchEmote>.self) {
                emotes += page.data
            }
        }
        return emotes
    }

    /// Badges come from Helix, which takes any user token: Twitch shut down the unauthenticated badge API.
    static func globalBadges(_ token: TokenData) async throws -> [CustomBadge] {
        try await badges(token, "chat/badges/global")
    }

    static func channelBadges(_ token: TokenData, roomId: String) async throws -> [CustomBadge] {
        try await badges(token, "chat/badges?broadcaster_id=\(roomId)")
    }

    private static func badges(_ token: TokenData, _ path: String) async throws -> [CustomBadge] {
        try await helixDecode(token, path, as: HelixPage<HelixBadgeSet>.self).data.flatMap { set in
            set.versions.map { version in
                CustomBadge(
                    id: "\(set.set_id)/\(version.id)",
                    name: version.title,
                    description: version.description,
                    mipmap: [version.image_url_1x, version.image_url_2x, version.image_url_4x],
                    provider: .twitch
                )
            }
        }
    }

    // MARK: Moderation and safety

    static func ban(_ token: TokenData, broadcasterId: String, moderatorId: String, userId: String, duration: Int? = nil, reason: String? = nil) async throws {
        var data: [String: Any] = ["user_id": userId]
        if let duration { data["duration"] = duration }
        if let reason { data["reason"] = reason }
        let body = try JSONSerialization.data(withJSONObject: ["data": data])
        let (object, status) = try await HTTP.object(
            .api("https://api.twitch.tv/helix/moderation/bans?broadcaster_id=\(broadcasterId)&moderator_id=\(moderatorId)"),
            method: "POST", headers: headers(token).merging(["Content-Type": "application/json"]) { $1 }, body: body
        )
        try expect(status, object, 200)
    }

    static func unban(_ token: TokenData, broadcasterId: String, moderatorId: String, userId: String) async throws {
        let (object, status) = try await HTTP.object(
            .api("https://api.twitch.tv/helix/moderation/bans?broadcaster_id=\(broadcasterId)&moderator_id=\(moderatorId)&user_id=\(userId)"),
            method: "DELETE", headers: headers(token)
        )
        try expect(status, object, 204)
    }

    static func deleteChatMessage(_ token: TokenData, broadcasterId: String, moderatorId: String, messageId: String?) async throws {
        let (object, status) = try await HTTP.object(
            .api("https://api.twitch.tv/helix/moderation/chat?broadcaster_id=\(broadcasterId)&moderator_id=\(moderatorId)\(messageId.map { "&message_id=\($0)" } ?? "")"),
            method: "DELETE", headers: headers(token)
        )
        try expect(status, object, 204)
    }

    /// Needs `user:manage:blocked_users`.
    static func block(_ token: TokenData, userId: String) async throws {
        let (object, status) = try await HTTP.object(.api("https://api.twitch.tv/helix/users/blocks?target_user_id=\(userId)"), method: "PUT", headers: headers(token))
        try expect(status, object, 204)
    }

    static func unblock(_ token: TokenData, userId: String) async throws {
        let (object, status) = try await HTTP.object(.api("https://api.twitch.tv/helix/users/blocks?target_user_id=\(userId)"), method: "DELETE", headers: headers(token))
        try expect(status, object, 204)
    }
}
