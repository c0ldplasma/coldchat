import SwiftUI

/// Opens a channel's tab, joining it first if needed. Used by the home tab's search and stream lists.
struct OpenChannelAction {
    let action: (String) -> Void
    func callAsFunction(_ name: String) { action(name) }
}

private struct OpenChannelKey: EnvironmentKey {
    static let defaultValue = OpenChannelAction { _ in }
}

extension EnvironmentValues {
    var openChannel: OpenChannelAction {
        get { self[OpenChannelKey.self] }
        set { self[OpenChannelKey.self] = newValue }
    }
}

/// The home tab and one tab per channel, swiped between or picked from the bar at the bottom.
struct RootView: View {
    @Environment(Client.self) private var client
    @Environment(AppSettings.self) private var settings
    @State private var selection = ""
    @State private var keyboardVisible = false

    var body: some View {
        VStack(spacing: 0) {
            LoginExpiredBanner()
            // Paged like the Flutter app's TabBarView: swipe between the home tab and the channels.
            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        HomeTab()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .id("")
                        ForEach(client.channels) { channel in
                            ChannelView(channel: channel)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .id(channel.name)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: Binding(get: { selection }, set: { if let id = $0 { selection = id } }))
                .scrollIndicators(.hidden)
                .ignoresSafeArea(.container, edges: .bottom)
            }
            // Like the Flutter app's bottom navigation bar, the channel bar stays behind the keyboard, so the
            // composer sits right on top of it.
            if !keyboardVisible {
                ChannelBar(selection: $selection)
            }
        }
        .background(settings.palette.background)
        // Covers the status bar so chat scrolling under it stays readable, like the Flutter app.
        .overlay(alignment: .top) {
            // Scroll views extend under the status bar. A zero-height view at the top of the safe area whose
            // background ignores it covers exactly the status bar.
            Color.clear
                .frame(height: 0)
                .background(settings.palette.background.ignoresSafeArea(edges: .top))
                .allowsHitTesting(false)
        }
        .environment(\.palette, settings.palette)
        .environment(\.openChannel, OpenChannelAction { name in
            client.join(name)
            settings.lastChannel = name
            withAnimation { selection = name }
        })
        .routeHost()
        .onAppear {
            if client.channel(named: settings.lastChannel) != nil { selection = settings.lastChannel }
        }
        .onChange(of: selection) { _, name in
            settings.lastChannel = name
            client.channel(named: name)?.joinPriority = true
        }
        .onChange(of: client.channels.map(\.name)) { _, names in
            if !selection.isEmpty && !names.contains(selection) { selection = "" }
        }
        // Triggers decide what is highlighted or hidden, so they apply to the messages already loaded too.
        .onChange(of: settings.userTriggers) { rebuildAllMessages() }
        .onChange(of: settings.messageTriggers) { rebuildAllMessages() }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in keyboardVisible = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardVisible = false }
    }

    private func rebuildAllMessages() {
        for channel in client.channels {
            Task { await channel.rebuildMessages() }
        }
    }
}

/// The dark bar with the home button and the channel names. Long-press opens the account or channel sheet.
private struct ChannelBar: View {
    @Binding var selection: String
    @Environment(Client.self) private var client
    @Environment(\.palette) private var palette
    @Environment(\.present) private var present

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    tab(id: "") {
                        Image(systemName: "house")
                            .font(.system(size: 18, weight: selection.isEmpty ? .semibold : .regular))
                    }
                    .onLongPressGesture { present(.account) }
                    ForEach(client.channels) { channel in
                        tab(id: channel.name) {
                            Text(channel.name)
                                .font(.subheadline.weight(selection == channel.name ? .semibold : .regular))
                        }
                        .onLongPressGesture { present(.channel(channel)) }
                    }
                }
                .padding(.horizontal, 4)
            }
            .scrollIndicators(.hidden)
            .onChange(of: selection) { _, id in
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
        }
        .frame(height: 48)
        .foregroundStyle(palette.barForeground)
        .background(palette.barBackground.ignoresSafeArea(edges: .bottom))
    }

    private func tab<Label: View>(id: String, @ViewBuilder label: () -> Label) -> some View {
        let selected = selection == id
        return label()
            .opacity(selected ? 1 : 0.6)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .overlay(alignment: .bottom) {
                Capsule().fill(palette.barForeground).frame(height: 3).padding(.horizontal, 10).opacity(selected ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { selection = id } }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(id.isEmpty ? "Home" : id)
            .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            .id(id)
    }
}

/// Surfaces a dead login. Otherwise Twitch just refuses the handshake and the chat looks empty. Implicit-grant
/// tokens can't be refreshed, so tapping starts a new sign-in.
private struct LoginExpiredBanner: View {
    @Environment(Client.self) private var client
    @Environment(\.present) private var present

    var body: some View {
        if case .invalidCredentials(let account) = client.receiver.state {
            Button {
                present(.login)
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "exclamationmark.circle")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.loginExpired).font(.subheadline.weight(.semibold))
                        Text(L10n.loginExpiredDescription(account.tokenData.login)).font(.caption)
                    }
                    Spacer(minLength: 8)
                    Text(L10n.signInAgain).font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.85))
            }
            .buttonStyle(.plain)
        }
    }
}

/// The bell (opens mentions, shows the unread count) and the account avatar (opens the account sheet; swipe it up
/// or down to switch accounts).
struct AvatarButton: View {
    @Environment(NotificationCenterModel.self) private var notifications
    @Environment(AccountStore.self) private var accounts
    @Environment(Client.self) private var client
    @Environment(\.present) private var present

    var body: some View {
        HStack(spacing: 2) {
            Button {
                present(.notifications)
            } label: {
                Image(systemName: "bell").font(.body).padding(.leading, 10).padding(.trailing, 4).frame(height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.notifications)

            avatar
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .padding(4)
                .background(Color(uiColor: .systemBackground), in: Circle())
                .contentShape(Circle())
                .onTapGesture { present(.account) }
                .accessibilityElement()
                .accessibilityLabel(L10n.account)
                .accessibilityAddTraits(.isButton)
                .gesture(DragGesture(minimumDistance: 10).onEnded { value in
                    if value.translation.height < -10 { switchAccount(by: 1) } else if value.translation.height > 10 { switchAccount(by: -1) }
                })
        }
        .padding(2)
        .background(.regularMaterial, in: Capsule())
        .overlay(alignment: .topLeading) {
            if notifications.unread > 0 {
                Text("\(notifications.unread)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color.red, in: Capsule())
                    .offset(x: -4, y: -4)
            }
        }
    }

    @ViewBuilder private var avatar: some View {
        if let url = accounts.active?.userData.flatMap({ URL(string: $0.avatarUrl) }) {
            RemoteFillImage(url: url, maxPixelSize: 128)
        } else {
            Image(systemName: "person").frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func switchAccount(by step: Int) {
        guard !accounts.accounts.isEmpty else { return }
        let index = accounts.accounts.firstIndex { $0.id == accounts.activeHash } ?? 0
        let next = accounts.accounts[(index + step + accounts.accounts.count) % accounts.accounts.count]
        accounts.activeHash = next.id
        client.connectAs(next)
    }
}
