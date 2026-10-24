import Combine
import SwiftUI

/// Search, a carousel of recommended streams and the top streams. Without a login, a welcome screen instead.
struct HomeTab: View {
    @Environment(AccountStore.self) private var accounts
    @Environment(\.present) private var present
    @Environment(\.openChannel) private var openChannel
    @Environment(\.palette) private var palette

    @State private var query = ""
    @State private var results: [SearchData]?
    @State private var searchFailed = false
    @State private var recommended: [StreamData] = []
    @State private var top: [StreamData]?

    private static let recommendedLogins = ["forsen", "btmc", "nymn", "vaxei_osu", "mrekkosu", "shigetora", "kitboga", "cdawgva", "gigguk", "vedal987"]

    private var token: TokenData? {
        guard let account = accounts.active, !account.isAnonymous else { return nil }
        return account.tokenData
    }

    var body: some View {
        if token == nil {
            welcome
        } else {
            NavigationStack {
                List {
                    searchField
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    if results != nil || !query.isEmpty {
                        searchResults
                    } else {
                        if !recommended.isEmpty {
                            RecommendedCarousel(streams: recommended)
                                .frame(height: UIScreen.main.bounds.height * 0.222)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
                                .listRowSeparator(.hidden)
                        }
                        if let top {
                            ForEach(top) { stream in
                                StreamRow(stream: stream)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                        } else {
                            ProgressView().frame(maxWidth: .infinity).listRowSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await refresh() }
                .navigationTitle(L10n.appName)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { AvatarButton() }
                }
            }
            .task(id: accounts.activeHash) { await refresh() }
            .task(id: query) { await search() }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(L10n.searchForChannels, text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit { if !query.isEmpty { open(query) } }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(palette.surfaceVariant, in: Capsule())
    }

    @ViewBuilder private var searchResults: some View {
        if !query.isEmpty {
            channelRow(title: query, icon: "plus.circle") { open(query) }
        }
        if searchFailed {
            Text("Error").foregroundStyle(.secondary)
        } else if let results {
            ForEach(results) { result in
                Button {
                    open(result.broadcasterLogin)
                } label: {
                    HStack(spacing: 16) {
                        RemoteFillImage(url: URL(string: result.thumbnailUrl), maxPixelSize: 128)
                            .frame(width: 40, height: 40)
                            .background(Color.primary.opacity(0.1))
                            .clipShape(Circle())
                        Text(result.displayName)
                        Spacer()
                        if result.isLive { Circle().fill(.red).frame(width: 8, height: 8) }
                    }
                }
                .buttonStyle(.plain)
            }
        } else if !query.isEmpty {
            ProgressView().frame(maxWidth: .infinity)
        }
    }

    private func channelRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).frame(width: 40, height: 40).background(Color.primary.opacity(0.1), in: Circle())
                Text(title)
            }
        }
        .buttonStyle(.plain)
    }

    /// Joins and switches to the channel, then resets the search.
    private func open(_ login: String) {
        let name = login.trimmingCharacters(in: .whitespaces).lowercased().replacingOccurrences(of: "#", with: "")
        guard !name.isEmpty else { return }
        openChannel("#\(name)")
        query = ""
        results = nil
    }

    private func refresh() async {
        guard let token else { return }
        async let recommendedRequest = try? Twitch.streams(token, userLogins: Self.recommendedLogins)
        async let topRequest = try? Twitch.streams(token)
        recommended = await recommendedRequest ?? []
        top = await topRequest ?? []
    }

    private func search() async {
        guard let token, !query.isEmpty else {
            results = nil
            return
        }
        // Waits for a pause in typing; a newer query cancels this one.
        try? await Task.sleep(nanoseconds: 250_000_000)
        guard !Task.isCancelled else { return }
        do {
            let found = try await Twitch.searchChannels(token, query: query)
            guard !Task.isCancelled else { return }
            searchFailed = false
            results = found
        } catch {
            if !Task.isCancelled { searchFailed = true }
        }
    }

    // Without a login there's no search (it needs Twitch's API), but chat can still be read anonymously.
    private var welcome: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                AvatarButton()
            }
            .padding(.horizontal, 16)
            Spacer()
            Text(L10n.appName).font(.largeTitle)
            Text(L10n.startUsingTheApp).font(.title3).multilineTextAlignment(.center)
            Button {
                present(.account)
            } label: {
                Image(systemName: "plus.circle").font(.system(size: 56))
            }
            .accessibilityLabel(L10n.addAnotherAccount)
            .padding(.top, 16)
            HStack {
                Image(systemName: "number").foregroundStyle(.secondary)
                TextField(L10n.searchForChannels, text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit { open(query) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(palette.surfaceVariant, in: Capsule())
            .padding(.horizontal, 32)
            .padding(.top, 24)
            if !query.isEmpty {
                Button(L10n.joinChannelName("#\(query.lowercased())")) { open(query) }
                    .padding(.top, 8)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

private struct RecommendedCarousel: View {
    let streams: [StreamData]
    @State private var index = 0
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView(selection: $index) {
            ForEach(Array(streams.enumerated()), id: \.element.id) { offset, stream in
                StreamCard(stream: stream)
                    .padding(.horizontal, 24)
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onReceive(timer) { _ in
            guard streams.count > 1 else { return }
            withAnimation { index = (index + 1) % streams.count }
        }
    }
}

/// A live stream's thumbnail with the streamer, title, game, viewers and uptime on top.
private struct StreamCard: View {
    let stream: StreamData
    @Environment(\.openChannel) private var openChannel

    var body: some View {
        Button {
            openChannel("#\(stream.userLogin)")
        } label: {
            ZStack(alignment: .bottomLeading) {
                RemoteFillImage(url: stream.thumbnail(width: 960, height: 540))
                LinearGradient(stops: [.init(color: .clear, location: 0.25), .init(color: .black, location: 1)], startPoint: .top, endPoint: .bottom)
                StreamInfo(stream: stream, light: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct StreamRow: View {
    let stream: StreamData
    @Environment(\.openChannel) private var openChannel

    var body: some View {
        Button {
            openChannel("#\(stream.userLogin)")
        } label: {
            HStack(spacing: 12) {
                RemoteFillImage(url: stream.thumbnail(width: 480, height: 270), maxPixelSize: 480)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                StreamInfo(stream: stream, light: false)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StreamInfo: View {
    let stream: StreamData
    let light: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(stream.userName).font(.title3.bold())
            Text(stream.title.trimmingCharacters(in: .whitespacesAndNewlines)).font(.subheadline)
            Text(stream.gameName).font(.subheadline).opacity(0.9)
            HStack(spacing: 4) {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("\(stream.viewerCount)")
                Image(systemName: "alarm").font(.caption2).padding(.leading, 12)
                Text(formatDuration(Date().timeIntervalSince(stream.startedAt)))
            }
            .font(.footnote)
            .opacity(0.9)
        }
        .lineLimit(1)
        .foregroundStyle(light ? Color.white : Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
