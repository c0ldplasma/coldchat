import Foundation
import Observation

/// Something shown in a channel's chat: a chat message, a ban, a notice or a connection state change.
@MainActor
class ChannelMessage: Identifiable {
    let dateTime: Date
    weak var channel: Channel?

    /// Twitch's message id, used to drop duplicates when history and live chat overlap.
    var messageId: String? { nil }

    init(dateTime: Date, channel: Channel?) {
        self.dateTime = dateTime
        self.channel = channel
    }

    nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }
}

struct ReplyInfo {
    var parentDisplayName: String
    var parentBody: String
    var parentMessageId: String
    var parentUserId: String
    var parentUserLogin: String
}

struct SubInfo {
    var systemMessage: String
    var wasGifted: Bool
}

/// A word of a chat message.
enum MessageSplit: Hashable {
    case text(String)
    /// An emote with the zero-width emotes drawn on top of it.
    case emote(Emote, overlays: [Emote])
    case url(String)
}

/// A PRIVMSG or USERNOTICE.
@MainActor
@Observable
final class ChannelMessageChat: ChannelMessage {
    // Twitch's classic smileys. Shown smaller than named emotes like Kappa.
    nonisolated static let twitchClassicEmoticons: Set<String> = [
        ":)", ":(", ":D", ">(", ":|", "O_o", "B)", ":O", "<3", ":/", ";)", ":P", ";P", "R)",
        ":-)", ":-(", ":-D", ">:(", ":-|", "O_O", "B-)", ":-O", ":-/", ";-)", ":-P", ";-P", "R-)",
        ":7", ":>", ":S", "#/", "<]", ":z",
    ]

    private static let imageExtension = try! NSRegularExpression(pattern: #"\.(png|apng|gif|webp|jpg|jpeg)$"#, options: [.caseInsensitive])

    let message: IRCMessage
    private(set) var twitchId: String = ""
    private(set) var action = false
    private(set) var splits: [MessageSplit] = []
    private(set) var badges: [CustomBadge] = []
    private(set) var body = ""
    private(set) var replyInfo: ReplyInfo?
    private(set) var subInfo: SubInfo?
    private(set) var mentioned = false
    private(set) var blocked = false
    private(set) var user = ChatUser()
    private(set) var imageEmbeds: [String] = []

    override var messageId: String? { twitchId }

    init(message: IRCMessage, dateTime: Date, channel: Channel?) {
        self.message = message
        super.init(dateTime: dateTime, channel: channel)
        build()
    }

    /// Resolves emotes, badges, links and triggers. Called again when the channel's emotes or badges change.
    func build() {
        let tags = message.tags
        twitchId = tags["id"] ?? UUID().uuidString

        if let name = tags["reply-parent-display-name"], let body = tags["reply-parent-msg-body"], let msgId = tags["reply-parent-msg-id"],
           let userId = tags["reply-parent-user-id"], let login = tags["reply-parent-user-login"] {
            replyInfo = ReplyInfo(parentDisplayName: name, parentBody: body.ircUnescaped, parentMessageId: msgId, parentUserId: userId, parentUserLogin: login)
        }

        if let systemMessage = tags["system-msg"], let gifted = tags["msg-param-was-gifted"] {
            subInfo = SubInfo(systemMessage: systemMessage.ircUnescaped, wasGifted: gifted != "false")
        }

        var color: UInt32?
        if let hex = tags["color"], hex.count == 7 { color = UInt32(hex.dropFirst(), radix: 16) }
        user = ChatUser(login: message.nick, displayName: tags["display-name"], id: tags["user-id"], color: color)

        var text = message.parameters.dropFirst().joined(separator: ":")
        action = text.hasPrefix("\u{1}ACTION ")
        if action {
            text = String(text.dropFirst("\u{1}ACTION ".count))
            if text.hasSuffix("\u{1}") { text.removeLast() }
        }
        // Clients send U+E0002 where they mean a zero width joiner.
        text = text.replacingOccurrences(of: "\u{E0002}", with: "\u{200D}")
        body = text

        // Twitch emote positions count Unicode scalars. Replace each with a marker word, back to front so earlier
        // positions stay valid.
        var scalars = Array(text.unicodeScalars)
        var instances: [(id: String, start: Int, end: Int)] = []
        for emoteData in (tags["emotes"] ?? "").split(separator: "/") where !emoteData.isEmpty {
            let parts = emoteData.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            for range in parts[1].split(separator: ",") {
                let bounds = range.split(separator: "-")
                guard bounds.count == 2, let start = Int(bounds[0]), let end = Int(bounds[1]) else { continue }
                instances.append((String(parts[0]), start, end))
            }
        }
        for instance in instances.sorted(by: { $0.start > $1.start }) {
            guard instance.start >= 0, instance.end < scalars.count, instance.start <= instance.end else { continue }
            let code = String(String.UnicodeScalarView(scalars[instance.start...instance.end]))
            scalars.replaceSubrange(instance.start...instance.end, with: " \u{1}\(instance.id)|\(code) ".unicodeScalars)
        }
        // U+E0000 is what clients append to get around Twitch's duplicate message check.
        text = String(String.UnicodeScalarView(scalars)).replacingOccurrences(of: "\u{E0000}", with: "")

        let client = channel?.client
        badges = []
        if let lookup = channel?.badgeLookup {
            for badgeId in (tags["badges"] ?? "").split(separator: ",") {
                if let badge = lookup[String(badgeId)] { badges.append(badge) }
            }
        }
        if let userId = user.id, let client {
            badges.append(contentsOf: client.userBadges(for: userId))
        }

        let emoteLookup = channel?.emoteLookup ?? [:]
        var words = text.split(separator: " ").map(String.init)
        if replyInfo != nil, !words.isEmpty { words.removeFirst() }

        splits = []
        imageEmbeds = []
        for word in words {
            var emote = emoteLookup[word]
            if word.hasPrefix("\u{1}") {
                let data = word.dropFirst().split(separator: "|", maxSplits: 1).map(String.init)
                let id = data.first ?? ""
                emote = Emote(
                    id: id,
                    name: data.last ?? "",
                    mipmap: (1...3).map { "https://static-cdn.jtvnw.net/emoticons/v2/\(id)/default/dark/\($0).0" },
                    provider: .twitch
                )
            }

            if let emote {
                if emote.isOverlay, case .emote(let base, let overlays) = splits.last {
                    splits[splits.count - 1] = .emote(base, overlays: overlays + [emote])
                } else {
                    splits.append(.emote(emote, overlays: []))
                }
            } else if word.hasPrefix("http"), let url = URL(string: word), url.scheme != nil, url.host != nil {
                splits.append(.url(word))
                var withoutFragment = URLComponents(url: url, resolvingAgainstBaseURL: false)
                withoutFragment?.fragment = nil
                let plain = withoutFragment?.string ?? word
                if Self.imageExtension.firstMatch(in: plain, range: NSRange(plain.startIndex..., in: plain)) != nil {
                    imageEmbeds.append(word)
                }
            } else {
                splits.append(.text(word))
            }
        }

        mentioned = false
        blocked = false
        guard let client else { return }
        let settings = client.settings
        let login = user.login?.lowercased()

        if let trigger = settings.userTriggers.first(where: { $0.login.lowercased() == login }) {
            switch trigger.type {
            case .mention: mentioned = true
            case .block: blocked = true
            }
        }

        let plainWords = words
        func matchesWord(_ pattern: String, lowercase: Bool) -> Bool {
            plainWords.map { lowercase ? $0.lowercased() : $0 }.contains { [pattern, "@\(pattern)", "\(pattern),", "@\(pattern),"].contains($0) }
        }
        if let trigger = settings.messageTriggers.first(where: { trigger in
            if trigger.enableRegex {
                guard let regex = try? NSRegularExpression(pattern: trigger.pattern) else { return false }
                return regex.firstMatch(in: body, range: NSRange(body.startIndex..., in: body)) != nil
            }
            if trigger.caseSensitive {
                return words.count > 1 ? body.contains(trigger.pattern) : matchesWord(trigger.pattern, lowercase: false)
            }
            let pattern = trigger.pattern.lowercased()
            return words.count > 1 ? body.lowercased().contains(pattern) : matchesWord(pattern, lowercase: true)
        }) {
            switch trigger.type {
            case .mention: mentioned = true
            case .block: blocked = true
            }
        }

        let receiver = client.receiver
        if case .connected(let account) = receiver.state {
            if let userId = user.id, receiver.blockedUserIds.contains(userId) { blocked = true }
            if !account.isAnonymous && matchesWord(account.tokenData.login.lowercased(), lowercase: true) { mentioned = true }
        }
    }
}

/// CLEARCHAT: a ban, a timeout, or the whole chat being cleared.
@MainActor
final class ChannelMessageBan: ChannelMessage {
    let message: IRCMessage
    let user: ChatUser?
    let duration: TimeInterval?

    init(message: IRCMessage, dateTime: Date, channel: Channel?) {
        self.message = message
        if message.tags["target-user-id"] != nil, message.parameters.count > 1 {
            let login = message.parameters[1]
            user = ChatUser(login: login, displayName: login, id: message.tags["target-user-id"])
            duration = message.tags["ban-duration"].flatMap(TimeInterval.init)
        } else {
            user = nil
            duration = nil
        }
        super.init(dateTime: dateTime, channel: channel)
    }

    /// CLEARCHAT has no id tag. Without one, every history pass would add the same ban again.
    override var messageId: String? {
        "clearchat:\(message.tags["target-user-id"] ?? ""):\(message.tags["tmi-sent-ts"] ?? "\(dateTime.timeIntervalSince1970)")"
    }
}

@MainActor
final class ChannelMessageNotice: ChannelMessage {
    let message: IRCMessage
    let text: String

    init(message: IRCMessage, dateTime: Date, channel: Channel?) {
        self.message = message
        text = message.parameters.dropFirst().joined(separator: ":")
        super.init(dateTime: dateTime, channel: channel)
    }
}

/// The channel's connection state, shown as the last line of the chat.
@MainActor
final class ChannelMessageStateChange: ChannelMessage {
    let state: Channel.State

    init(state: Channel.State, dateTime: Date, channel: Channel?) {
        self.state = state
        super.init(dateTime: dateTime, channel: channel)
    }
}

extension String {
    /// IRCv3 tag values escape spaces as `\s`.
    var ircUnescaped: String {
        replacingOccurrences(of: "\\s", with: " ")
    }
}
