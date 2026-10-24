import Foundation
import Observation

@MainActor
@Observable
final class Channel: Identifiable {
    enum State: Equatable {
        case disconnected
        case connecting
        case connected
        case suspended
        case banned
    }

    unowned let client: Client
    /// `#login`.
    let name: String
    /// The room id, known once ROOMSTATE arrives.
    var roomId: String?
    let messages = ChannelMessages()
    private(set) var emotes: [Emote] = [] {
        didSet { emoteLookupCache = nil }
    }
    private(set) var badges: [CustomBadge] = [] {
        didSet { badgeLookupCache = nil }
    }
    /// The broadcaster's profile and live stream, for the channel sheet.
    var info: TwitchProfile?

    private(set) var state: State = .disconnected {
        didSet {
            guard state != oldValue else { return }
            suspensionTimer?.invalidate()
            suspensionTimer = nil
            replaceStatusMessage(ChannelMessageStateChange(state: state, dateTime: Date(), channel: self))
        }
    }

    @ObservationIgnored var pendingHistoryCached: [String] = []
    @ObservationIgnored var recentMessagesFetched = false
    @ObservationIgnored var recentMessagesEverFetched = false
    @ObservationIgnored var joinPriority = false
    @ObservationIgnored var joinBackfillDone = false
    @ObservationIgnored private var suspensionTimer: Timer?
    @ObservationIgnored private var statusMessage: ChannelMessage?
    @ObservationIgnored private var emoteLookupCache: [String: Emote]?
    @ObservationIgnored private var badgeLookupCache: [String: CustomBadge]?

    nonisolated var id: String { name }
    var login: String { String(name.dropFirst()).lowercased() }

    init(client: Client, name: String) {
        self.client = client
        self.name = name
        // Hydrate from disk right away, keyed by login (known before ROOMSTATE), so history built early already
        // resolves third-party emotes.
        hydrateFromCache()
    }

    // MARK: Lookups

    /// Emote by code. Channel emotes win over global ones. Emojis stay plain text so they render in the system font.
    var emoteLookup: [String: Emote] {
        if let cached = emoteLookupCache { return cached }
        var map: [String: Emote] = [:]
        for emote in client.globalEmotes where emote.provider != .emoji {
            map[emote.text] = emote
        }
        for emote in emotes {
            map[emote.text] = emote
        }
        emoteLookupCache = map
        return map
    }

    var badgeLookup: [String: CustomBadge] {
        if let cached = badgeLookupCache { return cached }
        var map: [String: CustomBadge] = [:]
        for badge in client.globalBadges { map[badge.id] = badge }
        for badge in badges { map[badge.id] = badge }
        badgeLookupCache = map
        return map
    }

    func invalidateGlobalLookups() {
        emoteLookupCache = nil
        badgeLookupCache = nil
    }

    // MARK: State

    func join() { state = .connecting }

    /// Resets the history latches so the next JOIN pulls fresh recent-messages.
    func part() {
        recentMessagesFetched = false
        joinBackfillDone = false
        state = .disconnected
    }

    func connected() {
        guard state != .disconnected else { return }
        state = .connected
    }

    func suspend() {
        guard state != .disconnected else { return }
        state = .suspended
    }

    func ban(for duration: TimeInterval? = nil) {
        guard state != .disconnected else { return }
        let previous = state
        state = .banned
        if let duration {
            suspensionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.state = previous }
            }
        }
    }

    private func replaceStatusMessage(_ message: ChannelMessage) {
        let previous = statusMessage
        statusMessage = message
        messages.replace(previous, with: message)
    }

    // MARK: Sending

    func send(_ text: String, tags: [String: String] = [:]) {
        guard state != .disconnected else { return }
        var line = "PRIVMSG \(name) :\(text)"
        if !tags.isEmpty {
            line = "@\(tags.map { "\($0.key)=\($0.value)" }.joined(separator: ";")) \(line)"
        }
        client.transmitter.send(line)
    }

    // MARK: Emotes and badges

    func refresh() async {
        // Sampled before hydrating: messages may have been built against an empty set, and the network can return
        // the same set as the cache.
        let before = emoteBadgeSignature
        hydrateFromCache()

        async let emotesDone: Void = refreshEmotes()
        async let badgesDone: Void = refreshBadges()
        async let infoDone: Void = refreshInfo()
        _ = await (emotesDone, badgesDone)

        if emoteBadgeSignature != before {
            await rebuildMessages()
        }
        await infoDone
    }

    private var emoteBadgeSignature: String {
        "\(emotes.count):\(emotes.map(\.id).joined(separator: ","))|\(badges.count):\(badges.map(\.id).joined(separator: ","))"
    }

    /// Rebuilds in batches, yielding in between, so a long backlog doesn't block scrolling.
    func rebuildMessages() async {
        var processed = 0
        for case let message as ChannelMessageChat in messages.items {
            message.build()
            processed += 1
            if processed % 20 == 0 { await Task.yield() }
        }
        messages.touch()
    }

    func rebuildMessages(from userId: String) {
        for case let message as ChannelMessageChat in messages.items where message.user.id == userId {
            message.build()
        }
    }

    func refreshEmotes() async {
        guard let roomId else { return }
        let results = await withTaskGroup(of: [Emote].self) { group in
            for provider in Providers.emoteProviders {
                group.addTask { (try? await Providers.channelEmotes(provider, roomId: roomId)) ?? [] }
            }
            var all: [[Emote]] = []
            for await result in group { all.append(result) }
            return all
        }
        // Keep the provider order stable regardless of which request finished first.
        let merged = results.flatMap { $0 }.sorted { Providers.order($0.provider) < Providers.order($1.provider) }
        emotes = merged
        client.cache?.saveChannelEmotes(login, merged)
    }

    func refreshBadges() async {
        guard let roomId else { return }
        let token = client.apiTokenData
        let merged = (try? await Providers.channelBadges(roomId: roomId, token: token)) ?? []
        badges = merged
        client.cache?.saveChannelBadges(login, merged)
    }

    func refreshInfo() async {
        guard let token = client.apiTokenData else { return }
        if let profile = try? await Twitch.profile(token, login: login) {
            info = profile
        }
    }

    private func hydrateFromCache() {
        guard let cache = client.cache else { return }
        if emotes.isEmpty {
            let cached = cache.loadChannelEmotes(login)
            if !cached.isEmpty { emotes = cached }
        }
        if badges.isEmpty {
            let cached = cache.loadChannelBadges(login)
            if !cached.isEmpty { badges = cached }
        }
    }

    /// Everyone who wrote in the loaded chat, most recent first. Twitch only gives moderators the full viewer list,
    /// so the chatter list and @-autocomplete use the people actually talking.
    var recentChatters: [ChatUser] {
        var seen: Set<String> = []
        var chatters: [ChatUser] = []
        for case let message as ChannelMessageChat in messages.items.reversed() {
            guard let login = message.user.login, seen.insert(login).inserted else { continue }
            chatters.append(message.user)
        }
        return chatters
    }
}
