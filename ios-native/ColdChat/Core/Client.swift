import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.plasmari.coldchat", category: "client")

/// Twitch chat: two IRC connections (one receives, one sends, so a slow send never stalls reading), the joined
/// channels, and the global emotes and badges.
@MainActor
@Observable
final class Client {
    let settings: AppSettings
    let accounts: AccountStore
    let receiver = Connection(name: "receiver")
    let transmitter = Connection(name: "transmitter")
    let bttvSocket = BetterTTVSocket()
    @ObservationIgnored private(set) var cache: EmoteBadgeCache?

    private(set) var channels: [Channel] = []

    private(set) var globalEmotes: [Emote] = [] {
        didSet { channels.forEach { $0.invalidateGlobalLookups() } }
    }
    private(set) var globalBadges: [CustomBadge] = [] {
        didSet { channels.forEach { $0.invalidateGlobalLookups() } }
    }
    private(set) var globalUserBadges: [BadgeUsers] = [] {
        didSet { indexUserBadges() }
    }
    /// The logged-in account's Twitch emotes (subscriptions, follower emotes, globals).
    private(set) var twitchUserEmotes: [Emote] = []

    /// Called for every chat message, live or from history. Used for mention notifications.
    @ObservationIgnored var onMessageReceived: ((ChannelMessageChat) -> Void)?

    @ObservationIgnored private var userBadgeIndex: [String: [CustomBadge]] = [:]
    // BetterTTV Pro badges by Twitch user id, oldest sighting first. They only arrive when a Pro user opens a
    // channel we're in, so they're kept on disk to show on history and later launches too.
    @ObservationIgnored private var bttvProBadges: [String: CustomBadge] = [:]
    @ObservationIgnored private var bttvProOrder: [String] = []
    @ObservationIgnored private var saveBttvTimer: Timer?
    private static let maxBttvProBadges = 5000

    /// The account whose token is used for Helix requests, such as badges.
    @ObservationIgnored private var apiAccount: TwitchAccount?
    @ObservationIgnored private var firstJoinPass = true
    @ObservationIgnored private var joinTimer: Timer?

    /// The token for Helix requests, or nil while browsing anonymously.
    var apiTokenData: TokenData? {
        guard let token = apiAccount?.tokenData, token.accessToken != nil else { return nil }
        return token
    }

    init(settings: AppSettings, accounts: AccountStore) {
        self.settings = settings
        self.accounts = accounts

        // The cache has to exist before the channels, which hydrate from it when they're created.
        let cache = EmoteBadgeCache()
        self.cache = cache
        globalEmotes = cache.loadEmotes(EmoteBadgeCache.globalEmotesKey)
        globalBadges = cache.loadBadges(EmoteBadgeCache.globalBadgesKey)
        globalUserBadges = cache.loadUserBadges(EmoteBadgeCache.globalUserBadgesKey)
        indexUserBadges()
        for (userId, url) in cache.loadBttvProBadges() {
            bttvProBadges[userId] = Self.bttvProBadge(url)
            bttvProOrder.append(userId)
        }

        channels = settings.channels.map { Channel(client: self, name: $0) }
        // The channel the user last had open goes into the first, larger JOIN burst.
        channels.first { $0.name == settings.lastChannel }?.joinPriority = true

        receiver.onReceive = { [weak self] connection, message in self?.receive(connection, message) }
        transmitter.onReceive = { [weak self] connection, message in self?.receive(connection, message) }
        receiver.onStateChange = { [weak self] connection, _, state in self?.stateChange(connection, state) }
        bttvSocket.onLookupUser = { [weak self] userId, url in self?.onBttvLookupUser(userId, url) }

        // Steady-state fallback; a pass also runs as soon as the connection is up.
        joinTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.joinPass() }
        }

        connectAs(accounts.active ?? .anonymous)

        Task { await refreshGlobalEmotes() }
        Task { await refreshGlobalBadges() }
        Task { await refreshGlobalUserBadges() }
    }

    // MARK: Channels

    func channel(named name: String) -> Channel? { channels.first { $0.name == name } }

    /// Joins `#login` unless it's already joined.
    @discardableResult
    func join(_ name: String) -> Channel {
        if let existing = channel(named: name) { return existing }
        let channel = Channel(client: self, name: name)
        channels.append(channel)
        settings.channels = channels.map(\.name)
        if receiver.state.isConnected {
            channel.join()
            receiver.send("JOIN \(name)")
        }
        return channel
    }

    func part(_ channel: Channel) {
        if let roomId = channel.roomId { bttvSocket.part(roomId) }
        if channel.state != .disconnected { receiver.send("PART \(channel.name)") }
        channels.removeAll { $0 === channel }
        settings.channels = channels.map(\.name)
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        channels.move(fromOffsets: source, toOffset: destination)
        settings.channels = channels.map(\.name)
    }

    // Twitch allows ~20 JOINs per 10 seconds. The first pass after connecting joins a larger burst so the channels
    // the user cares about come up quickly; later ticks stay conservative.
    private func joinPass() {
        guard receiver.state.isConnected else { return }
        let waiting = channels.filter { $0.state == .disconnected }.sorted { $0.joinPriority && !$1.joinPriority }
        guard !waiting.isEmpty else { return }
        let batch = Array(waiting.prefix(firstJoinPass ? 12 : 4))
        firstJoinPass = false
        batch.forEach { $0.join() }
        receiver.send("JOIN \(batch.map(\.name).joined(separator: ","))")
    }

    private func stateChange(_ connection: Connection, _ state: Connection.State) {
        channels.forEach { $0.part() }
        firstJoinPass = true
        if state.isConnected { joinPass() }
    }

    // MARK: Global emotes and badges

    func refreshGlobalEmotes() async {
        let results = await withTaskGroup(of: (ProviderKind, [Emote]).self) { group in
            for provider in Providers.emoteProviders {
                group.addTask {
                    do {
                        return (provider, try await Providers.globalEmotes(provider))
                    } catch {
                        logger.info("Couldn't get \(provider.name) global emotes: \(error.localizedDescription)")
                        return (provider, [])
                    }
                }
            }
            var all: [(ProviderKind, [Emote])] = []
            for await result in group { all.append(result) }
            return all
        }
        // A provider that failed keeps its cached emotes instead of losing them until the next launch.
        var merged: [Emote] = []
        for provider in Providers.emoteProviders {
            let fresh = results.first { $0.0 == provider }?.1 ?? []
            merged += fresh.isEmpty ? globalEmotes.filter { $0.provider == provider } : fresh
        }
        globalEmotes = merged
        cache?.saveEmotes(EmoteBadgeCache.globalEmotesKey, merged)
    }

    func refreshGlobalBadges() async {
        guard let fresh = try? await Providers.globalBadges(token: apiTokenData), !fresh.isEmpty else { return }
        let changed = globalBadges.map(\.id) != fresh.map(\.id)
        globalBadges = fresh
        cache?.saveBadges(EmoteBadgeCache.globalBadgesKey, fresh)
        if changed { rebuildAllMessages() }
    }

    func refreshGlobalUserBadges() async {
        let results = await withTaskGroup(of: (ProviderKind, [BadgeUsers]).self) { group in
            for provider in Providers.userBadgeProviders {
                group.addTask { (provider, (try? await Providers.globalUserBadges(provider)) ?? []) }
            }
            var all: [(ProviderKind, [BadgeUsers])] = []
            for await result in group { all.append(result) }
            return all
        }
        var merged: [BadgeUsers] = []
        for provider in Providers.userBadgeProviders {
            let fresh = results.first { $0.0 == provider }?.1 ?? []
            merged += fresh.isEmpty ? globalUserBadges.filter { $0.badge.provider == provider } : fresh
        }
        let signature: ([BadgeUsers]) -> [String] = { $0.map { "\($0.badge.id):\($0.users.count)" } }
        let changed = signature(globalUserBadges) != signature(merged)
        globalUserBadges = merged
        cache?.saveUserBadges(EmoteBadgeCache.globalUserBadgesKey, merged)
        if changed { rebuildAllMessages() }
    }

    private func indexUserBadges() {
        var index: [String: [CustomBadge]] = [:]
        for entry in globalUserBadges {
            for user in entry.users { index[user, default: []].append(entry.badge) }
        }
        userBadgeIndex = index
    }

    /// Badges given by user rather than by IRC tag: 7TV, BetterTTV, FrankerFaceZ, DankChat and BetterTTV Pro.
    func userBadges(for userId: String) -> [CustomBadge] {
        var badges = userBadgeIndex[userId] ?? []
        if let pro = bttvProBadges[userId] { badges.append(pro) }
        return badges
    }

    private static func bttvProBadge(_ url: String) -> CustomBadge {
        CustomBadge(id: "bttv-pro", name: "BetterTTV Pro", mipmap: [url], provider: .betterTTV)
    }

    private func onBttvLookupUser(_ userId: String, _ url: String?) {
        let previous = bttvProBadges.removeValue(forKey: userId)
        bttvProOrder.removeAll { $0 == userId }
        if let url {
            // Re-inserting keeps the order by last sighting, so the cap drops the users seen longest ago.
            bttvProBadges[userId] = previous?.mipmap.first == url ? previous : Self.bttvProBadge(url)
            bttvProOrder.append(userId)
            while bttvProOrder.count > Self.maxBttvProBadges {
                bttvProBadges.removeValue(forKey: bttvProOrder.removeFirst())
            }
        }
        if previous?.mipmap.first != url {
            channels.forEach { $0.rebuildMessages(from: userId) }
        }
        saveBttvTimer?.invalidate()
        saveBttvTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.cache?.saveBttvProBadges(self.bttvProOrder.compactMap { id in self.bttvProBadges[id]?.mipmap.first.map { (id, $0) } })
            }
        }
    }

    /// Messages resolve badges when they're built, so history from before the badges arrived needs a rebuild.
    private func rebuildAllMessages() {
        for channel in channels {
            Task { await channel.rebuildMessages() }
        }
    }

    // MARK: Blocking

    /// The connected, logged-in account, whose Twitch block list hides messages.
    private var blockingAccount: TwitchAccount? {
        guard case .connected(let account) = receiver.state, !account.isAnonymous else { return nil }
        return account
    }

    /// The account that can block users, or nil while anonymous or disconnected.
    var blockingUserId: String? { blockingAccount?.tokenData.userId }

    func isBlocked(_ userId: String) -> Bool { blockingAccount != nil && receiver.blockedUserIds.contains(userId) }

    /// Blocks or unblocks on Twitch and re-renders the user's messages everywhere.
    func setBlocked(_ userId: String, _ blocked: Bool) async throws {
        guard let account = blockingAccount else { throw HTTPError(status: 401, message: "Not logged in") }
        if blocked {
            try await Twitch.block(account.tokenData, userId: userId)
            receiver.blockedUserIds.insert(userId)
        } else {
            try await Twitch.unblock(account.tokenData, userId: userId)
            receiver.blockedUserIds.remove(userId)
        }
        channels.forEach { $0.rebuildMessages(from: userId) }
    }

    // MARK: History

    /// Building chat messages is expensive, so history goes in newest first, in chunks: the first (smaller) one is
    /// what's visible at the bottom of the chat, the older ones are added above it, yielding in between.
    func insertHistory(_ connection: Connection, _ lines: [String]) async {
        // ROOMSTATE and NOTICE describe past room state; replaying them is noise, and NOTICEs have no id to dedup.
        let parsed = lines.compactMap { try? IRCMessage(parsing: $0) }.filter { $0.command != "ROOMSTATE" && $0.command != "NOTICE" }
        guard !parsed.isEmpty else { return }
        let channel = parsed.first { ($0.command == "PRIVMSG" || $0.command == "USERNOTICE") && !$0.parameters.isEmpty }.flatMap { channel(named: $0.parameters[0]) }

        var end = parsed.count
        var first = true
        while end > 0 {
            let start = max(0, end - (first ? 30 : 40))
            first = false
            channel?.messages.beginBulk()
            for message in parsed[start..<end] {
                if let id = message.tags["id"], channel?.messages.contains(id: id) == true { continue }
                receive(connection, message)
            }
            channel?.messages.endBulk()
            end = start
            await Task.yield()
        }
    }

    /// Fetches recent-messages when a channel's chat is first opened.
    func ensureRecentMessages(_ channel: Channel) async {
        // The user is looking at it, so it's joined before any other waiting channel.
        channel.joinPriority = true
        guard !channel.recentMessagesFetched else { return }
        channel.recentMessagesFetched = true
        channel.recentMessagesEverFetched = true
        if !(await fetchHistory(channel)) { channel.recentMessagesFetched = false }
    }

    /// Fetches again right after a JOIN, for messages sent while waiting for it: Twitch only delivers them once
    /// we're in.
    private func backfillAfterJoin(_ channel: Channel) async {
        guard !channel.joinBackfillDone else { return }
        channel.joinBackfillDone = true
        if !(await fetchHistory(channel)) { channel.joinBackfillDone = false }
    }

    private func fetchHistory(_ channel: Channel) async -> Bool {
        guard settings.chatHistory else { return true }
        do {
            let lines = try await Providers.recentMessages(channel.login)
            cache?.saveHistory(channel.login, lines)
            await insertHistory(receiver, lines)
            return true
        } catch {
            return false
        }
    }

    // MARK: Lifecycle and credentials

    /// Runs on every return to the foreground. Probes each socket and reconnects only the dead ones, then fills
    /// in what was missed while away.
    func onAppResumed() async {
        // A token can expire while the app sits in the background for days.
        let account = receiver.account ?? transmitter.account
        if let account, !account.isAnonymous, account.tokenData.isExpired {
            rejectCredentials(account)
            return
        }
        if receiver.credentialsRejected || transmitter.credentialsRejected { return }
        if let account { Task { await validateCredentials(account) } }

        async let receiverAlive = receiver.probeAlive()
        async let transmitterAlive = transmitter.probeAlive()
        let (receiverOK, transmitterOK) = await (receiverAlive, transmitterAlive)
        bttvSocket.reconnect()
        if receiverOK && transmitterOK { return }

        if !receiverOK { receiver.forceReconnect() }
        if !transmitterOK { transmitter.forceReconnect() }

        let viewed = channels.filter(\.recentMessagesEverFetched).sorted { $0.joinPriority && !$1.joinPriority }
        await withTaskGroup(of: Void.self) { group in
            for channel in viewed {
                channel.joinBackfillDone = false
                group.addTask { _ = await self.fetchHistory(channel) }
            }
        }
    }

    /// Twitch refuses a bad token with an untagged NOTICE to `*`, before we're authenticated.
    private static func isAuthFailure(_ message: IRCMessage) -> Bool {
        guard message.parameters.first == "*" else { return false }
        let text = message.parameters.count > 1 ? message.parameters.last!.lowercased() : ""
        return text.contains("login authentication failed") || text.contains("login unsuccessful") || text.contains("improperly formatted auth")
    }

    private func rejectCredentials(_ account: TwitchAccount) {
        receiver.rejectCredentials(account)
        transmitter.rejectCredentials(account)
    }

    /// Asks Twitch whether the token is still good. A 401 means the login is dead; network failures are ignored,
    /// since being offline doesn't mean the token expired.
    func validateCredentials(_ account: TwitchAccount) async {
        guard let accessToken = account.tokenData.accessToken else { return }
        if account.tokenData.isExpired {
            rejectCredentials(account)
            return
        }
        do {
            let fresh = try await Twitch.validateToken(accessToken)
            var updated = account
            updated.tokenData.expiresAt = fresh.expiresAt
            updated.tokenData.scopes = fresh.scopes
            accounts.update(updated)
            if updated.tokenData.isExpired { rejectCredentials(updated) }
        } catch is TwitchTokenInvalid {
            rejectCredentials(account)
        } catch {
            logger.info("Couldn't validate the Twitch token: \(error.localizedDescription)")
        }
    }

    func connectAs(_ account: TwitchAccount) {
        // Don't open a socket with a token known to be dead: every channel would be parted with no feedback.
        if !account.isAnonymous && account.tokenData.isExpired {
            rejectCredentials(account)
            return
        }

        // Twitch badges need a token, so a first login after browsing anonymously loads them now.
        let gainedApiAccess = apiTokenData == nil && !account.isAnonymous
        apiAccount = account
        if gainedApiAccess { Task { await refreshGlobalBadges() } }

        // This account's emotes from the last session, until GLOBALUSERSTATE brings the fresh list.
        twitchUserEmotes = account.tokenData.userId.map { cache?.loadEmotes(EmoteBadgeCache.twitchUserEmotesKey($0)) ?? [] } ?? []

        receiver.connect(account)
        transmitter.connect(account)
        Task { await validateCredentials(account) }
    }

    // MARK: Receiving

    private func receive(_ connection: Connection, _ message: IRCMessage) {
        switch message.command {
        case "001":
            guard case .connecting(let account) = connection.state else { break }
            // Joining starts from the state change; the block list fills in afterwards.
            connection.established()
            if !account.isAnonymous {
                Task {
                    let ids = await Twitch.blockedUsers(account.tokenData)
                    connection.blockedUserIds.formUnion(ids)
                }
            }

        case "GLOBALUSERSTATE":
            guard let account = connection.account, !account.isAnonymous, connection === receiver else { break }
            let sets = (message.tags["emote-sets"] ?? "").split(separator: ",").map(String.init)
            Task {
                let emotes = await Twitch.emoteSets(account.tokenData, ids: sets)
                // Every account has at least the global Twitch emotes, so empty means the request failed.
                guard !emotes.isEmpty else { return }
                let userEmotes = emotes.map { emote in
                    Emote(id: emote.id, name: emote.name, mipmap: ["url_1x", "url_2x", "url_4x"].compactMap { emote.images[$0] }, provider: .twitch)
                }
                twitchUserEmotes = userEmotes
                if let userId = account.tokenData.userId {
                    cache?.saveEmotes(EmoteBadgeCache.twitchUserEmotesKey(userId), userEmotes)
                }
            }

        case "JOIN":
            guard let channel = message.parameters.first.flatMap(channel(named:)), let account = receiver.account,
                  message.nick == account.tokenData.login else { break }
            channel.connected()
            channel.pendingHistoryCached = settings.chatHistory ? cache?.loadHistory(channel.login) ?? [] : []
            // Opened before the JOIN went through: fetch again to close the gap to live messages.
            if channel.recentMessagesEverFetched {
                channel.recentMessagesFetched = true
                Task { await backfillAfterJoin(channel) }
            }

        case "USERNOTICE", "PRIVMSG":
            guard let channel = message.parameters.first.flatMap(channel(named:)) else { break }
            let chat = ChannelMessageChat(message: message, dateTime: message.sentDate, channel: channel)
            onMessageReceived?(chat)
            channel.messages.add(chat)

        case "ROOMSTATE":
            guard let channel = message.parameters.first.flatMap(channel(named:)) else { break }
            channel.roomId = message.tags["room-id"] ?? channel.roomId
            if let roomId = channel.roomId { bttvSocket.join(roomId) }
            // Paint cached history first with the emotes already hydrated from disk, then refresh.
            let cached = channel.pendingHistoryCached
            channel.pendingHistoryCached = []
            Task {
                if !cached.isEmpty { await insertHistory(connection, cached) }
                await channel.refresh()
            }

        case "CLEARCHAT":
            guard let channel = message.parameters.first.flatMap(channel(named:)) else { break }
            channel.messages.add(ChannelMessageBan(message: message, dateTime: message.sentDate, channel: channel))

        case "NOTICE":
            // The handshake rejection targets `*`, so no channel matches it.
            if Self.isAuthFailure(message) {
                if let account = connection.account { rejectCredentials(account) }
                break
            }
            guard let channel = message.parameters.first.flatMap(channel(named:)) else { break }
            if message.tags["msg-id"] == "msg_channel_suspended" { channel.suspend() }
            channel.messages.add(ChannelMessageNotice(message: message, dateTime: message.sentDate, channel: channel))

        default:
            break
        }
    }
}
