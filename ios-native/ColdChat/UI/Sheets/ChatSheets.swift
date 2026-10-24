import SwiftUI

/// A user's profile, Block and Report, moderation for the channel, and their messages in it.
struct UserSheet: View {
    let login: String
    let channel: Channel?

    @Environment(Client.self) private var client
    @State private var profile: TwitchProfile?
    @State private var loading = true

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if loading || profile != nil {
                    ProfileHeader(profile: profile, name: login)
                }
                if let profile {
                    SafetyActions(user: profile.user)
                    if let channel { ModerationBar(channel: channel, userId: profile.user.id) }
                }
                if loading == false && profile == nil {
                    SheetHeader(title: login)
                }
                if let channel {
                    ChatView(channel: channel, filter: { message in
                        (message as? ChannelMessageChat)?.message.nick == login
                    }, showsChrome: false)
                    .frame(height: 350)
                }
            }
        }
        .task {
            // Profiles come from Helix, which needs a login. Without one the sheet still shows the messages.
            if let token = client.apiTokenData {
                profile = try? await Twitch.profile(token, login: login)
            }
            loading = false
        }
    }
}

/// Block and Report, which both stores require wherever users see each other's messages. Blocking uses the
/// account's Twitch block list, so it applies everywhere. Twitch has no API for reports, so Report points there.
private struct SafetyActions: View {
    let user: TwitchUser
    @Environment(Client.self) private var client
    @Environment(\.openURL) private var openURL
    @State private var busy = false
    @State private var blockFailed = false
    @State private var confirmReport = false

    var body: some View {
        let ownId = client.blockingUserId
        let blocked = client.isBlocked(user.id)
        HStack {
            if let ownId, ownId != user.id {
                Spacer()
                Button {
                    Task {
                        busy = true
                        do {
                            try await client.setBlocked(user.id, !blocked)
                        } catch {
                            blockFailed = true
                        }
                        busy = false
                    }
                } label: {
                    Label(blocked ? L10n.unblock : L10n.block, systemImage: blocked ? "person" : "person.slash")
                }
                .disabled(busy)
            }
            Spacer()
            Button {
                confirmReport = true
            } label: {
                Label(L10n.report, systemImage: "flag")
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .alert(L10n.blockFailed, isPresented: $blockFailed) {
            Button(L10n.close, role: .cancel) {}
        }
        .alert(L10n.reportUserTitle(user.displayName), isPresented: $confirmReport) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.openOnTwitch) { openURL(URL.api("https://www.twitch.tv/\(user.login)")) }
        } message: {
            Text(L10n.reportUserDescription(user.displayName))
        }
    }
}

/// Ban, timeouts and unban for moderators. Twitch refuses them for everyone else.
private struct ModerationBar: View {
    let channel: Channel
    let userId: String
    @Environment(Client.self) private var client
    @Environment(\.palette) private var palette

    private static let timeouts: [(String, Int)] = [("1s", 1), ("30s", 30), ("1m", 60), ("5m", 300), ("30m", 1800), ("1h", 3600), ("1d", 86400), ("1w", 604_800)]

    var body: some View {
        HStack(spacing: 0) {
            Button {
                moderate { token, broadcaster, moderator in try await Twitch.ban(token, broadcasterId: broadcaster, moderatorId: moderator, userId: userId) }
            } label: {
                Image(systemName: "nosign").foregroundStyle(.red).frame(width: 44, height: 44)
            }
            .accessibilityLabel(L10n.ban)
            ScrollView(.horizontal) {
                HStack {
                    ForEach(Self.timeouts, id: \.0) { label, seconds in
                        Button(label) {
                            moderate { token, broadcaster, moderator in
                                try await Twitch.ban(token, broadcasterId: broadcaster, moderatorId: moderator, userId: userId, duration: seconds)
                            }
                        }
                        .accessibilityLabel(L10n.timeoutUserForDuration(formatDuration(TimeInterval(seconds))))
                    }
                }
                .padding(.horizontal, 4)
            }
            .scrollIndicators(.hidden)
            Button {
                moderate { token, broadcaster, moderator in try await Twitch.unban(token, broadcasterId: broadcaster, moderatorId: moderator, userId: userId) }
            } label: {
                Image(systemName: "nosign").foregroundStyle(.green).frame(width: 44, height: 44)
            }
            .accessibilityLabel(L10n.unban)
        }
        .buttonStyle(.borderless)
        .background(palette.secondaryContainer)
    }

    private func moderate(_ action: @escaping (TokenData, String, String) async throws -> Void) {
        guard let token = client.transmitter.account?.tokenData, let moderator = token.userId, let broadcaster = channel.roomId else { return }
        Task { try? await action(token, broadcaster, moderator) }
    }
}

/// The banner, avatar, name, followers and, when live, the stream.
struct ProfileHeader: View {
    let profile: TwitchProfile?
    let name: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let user = profile?.user {
                    RemoteFillImage(url: URL(string: user.offlineImageUrl ?? user.profileImageUrl))
                }
                Color(uiColor: .systemBackground).opacity(0.75)
                VStack(spacing: 8) {
                    Group {
                        if let user = profile?.user {
                            RemoteFillImage(url: URL(string: user.profileImageUrl), maxPixelSize: 192)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(radius: 8)
                    (Text(profile?.user.displayName ?? name).font(.title2)
                        + Text(profile.map { "#\($0.user.id)" } ?? "").font(.title2).foregroundColor(.secondary))
                        .textSelection(.enabled)
                    // Always laid out, so the height doesn't change when the count arrives.
                    Label("\(profile?.followerCount ?? 0)", systemImage: "person.2.fill")
                        .font(.subheadline)
                        .opacity(profile?.followerCount == nil ? 0 : 1)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                SheetHeader()
            }
            .clipped()

            if let stream = profile?.stream {
                ZStack {
                    RemoteFillImage(url: URL(string: stream.thumbnailUrl.replacingOccurrences(of: "{width}", with: "960").replacingOccurrences(of: "{height}", with: "540")))
                    Color(uiColor: .systemBackground).opacity(0.75)
                    HStack(spacing: 12) {
                        if let boxArt = stream.gameBoxArtUrl {
                            RemoteFillImage(url: URL(string: boxArt), maxPixelSize: 192)
                                .frame(width: 48, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .shadow(radius: 8)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stream.title).font(.headline)
                            Text(stream.gameName).foregroundStyle(.secondary)
                            HStack(spacing: 16) {
                                TimelineView(.periodic(from: .now, by: 1)) { context in
                                    Label(formatDuration(context.date.timeIntervalSince(stream.startedAt)), systemImage: "clock")
                                }
                                Label("\(stream.viewerCount)", systemImage: "eye.fill")
                            }
                            .font(.subheadline.bold())
                        }
                        .textSelection(.enabled)
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                }
                .clipped()
            }
        }
    }
}

/// Reply, copy, delete, mention and copy id for one message.
struct MessageSheet: View {
    let message: ChannelMessageChat
    @Environment(\.composer) private var composer
    @Environment(\.dismiss) private var dismiss
    @Environment(Client.self) private var client

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }()

    var body: some View {
        List {
            ChatMessageRow(message: message)
                .listRowInsets(EdgeInsets())
            if let composer {
                Button {
                    dismiss()
                    composer.reply(message)
                } label: {
                    Label(L10n.reply, systemImage: "arrowshape.turn.up.left")
                }
            }
            Button {
                UIPasteboard.general.string = message.body
                dismiss()
            } label: {
                VStack(alignment: .leading) {
                    Label(L10n.copyText, systemImage: "doc.on.doc")
                    Text(L10n.copyTextSubtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            .simultaneousGesture(LongPressGesture().onEnded { _ in
                UIPasteboard.general.string = "\(Self.timeFormatter.string(from: message.dateTime)) \(message.user.name): \(message.body)"
                dismiss()
            })
            Button {
                dismiss()
                guard let token = client.transmitter.account?.tokenData, let moderator = token.userId, let broadcaster = message.channel?.roomId else { return }
                Task { try? await Twitch.deleteChatMessage(token, broadcasterId: broadcaster, moderatorId: moderator, messageId: message.messageId) }
            } label: {
                Label(L10n.deleteMessage, systemImage: "trash")
            }
            if let composer, let login = message.user.login {
                Button {
                    dismiss()
                    composer.addWord("@\(login)")
                } label: {
                    Label(L10n.mentionUser, systemImage: "at")
                }
            }
            Button {
                UIPasteboard.general.string = message.messageId
                dismiss()
            } label: {
                Label(L10n.copyMessageId, systemImage: "number")
            }
        }
        .listStyle(.plain)
        .padding(.top, 8)
    }
}

/// An emote's image, name and provider, with a link to its page.
struct EmoteSheet: View {
    let emote: Emote
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 16) {
            EmoteGlyph(emote: emote, size: 64)
            VStack(alignment: .leading) {
                Text(emote.name).font(.headline)
                Text(emote.provider.name).foregroundStyle(.secondary)
            }
            Spacer()
            if let url = emote.provider.emoteURL(emote.id) {
                Button(L10n.openInBrowser) { openURL(url) }.buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
    }
}

/// The broadcaster's header, the chatter list and leaving the channel.
struct ChannelSheet: View {
    let channel: Channel
    @Environment(Client.self) private var client
    @Environment(\.present) private var present
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ProfileHeader(profile: channel.info, name: channel.login)
                List {
                    Button {
                        present(.chatters(channel))
                    } label: {
                        Label(L10n.chatters, systemImage: "person.2")
                    }
                    Button(role: .destructive) {
                        client.part(channel)
                        dismiss()
                    } label: {
                        Label(L10n.leaveChannel, systemImage: "trash")
                    }
                }
                .listStyle(.plain)
                .frame(height: 120)
                .scrollDisabled(true)
            }
        }
        // Live status and viewer count change; the header shows the last known profile meanwhile.
        .task { await channel.refreshInfo() }
    }
}

/// Everyone who wrote in the loaded chat, with their avatars when logged in.
struct ChattersSheet: View {
    let channel: Channel
    @Environment(Client.self) private var client
    @Environment(\.present) private var present
    @State private var search = ""
    @State private var avatars: [String: String] = [:]
    @State private var chatters: [ChatUser] = []

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.chatters)
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(L10n.search, text: $search).textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(uiColor: .secondarySystemBackground), in: Capsule())
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            List {
                ForEach(chatters.filter { search.isEmpty || ($0.login ?? "").contains(search.lowercased()) || $0.name.lowercased().contains(search.lowercased()) }, id: \.self) { chatter in
                    Button {
                        if let login = chatter.login { present(.user(login: login, channel: channel)) }
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle().fill(Color.secondary.opacity(0.3))
                                if let url = chatter.login.flatMap({ avatars[$0] }).flatMap(URL.init(string:)) {
                                    RemoteFillImage(url: url, maxPixelSize: 128).clipShape(Circle())
                                } else {
                                    Text(String(chatter.name.prefix(1)).uppercased())
                                }
                            }
                            .frame(width: 36, height: 36)
                            Text(chatter.name)
                        }
                    }
                    .buttonStyle(.row)
                }
            }
            .listStyle(.plain)
        }
        .task {
            chatters = channel.recentChatters
            // One batched request per 100 chatters. Without a login the list shows initials.
            guard let token = client.apiTokenData else { return }
            if let users = try? await Twitch.users(token, logins: chatters.compactMap(\.login)) {
                avatars = Dictionary(users.map { ($0.login, $0.profileImageUrl) }, uniquingKeysWith: { first, _ in first })
            }
        }
    }
}

/// Mentions collected while the app runs.
struct NotificationsSheet: View {
    @Environment(NotificationCenterModel.self) private var notifications
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.notifications) {
                Button {
                    notifications.clear()
                    dismiss()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease").frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.clearAll)
            }
            if notifications.messages.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "info.circle")
                    Text(L10n.noNotifications)
                }
                .padding(16)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(notifications.messages) { message in
                            ChatMessageRow(message: message, renderMentions: false)
                        }
                    }
                }
            }
        }
        .onAppear { notifications.clearUnread() }
    }
}
