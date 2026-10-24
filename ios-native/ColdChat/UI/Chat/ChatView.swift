import SwiftUI

/// A channel's chat, newest at the bottom. Scrolling up pauses it on a snapshot so lines don't move while being
/// read; scrolling back down (or the button) resumes.
struct ChatView: View {
    let channel: Channel
    /// Only these messages, e.g. one user's in the user sheet.
    var filter: ((ChannelMessage) -> Bool)?
    /// The search bar and the notifications/account button on top.
    var showsChrome = true

    @Environment(NotificationCenterModel.self) private var notifications
    @Environment(\.palette) private var palette
    @State private var paused: [ChannelMessage]?
    @State private var position = ScrollPosition(edge: .bottom)
    @State private var phase = ScrollPhase.idle
    @State private var atBottom = true
    @State private var search = ""
    @FocusState private var searchFocused: Bool
    @State private var chromeVisible = false
    @State private var hideChrome: Task<Void, Never>?

    private var visibleMessages: [ChannelMessage] {
        var messages = paused ?? channel.messages.items
        let query = search.lowercased()
        if !query.isEmpty {
            messages = messages.filter { message in
                guard let chat = message as? ChannelMessageChat else { return false }
                return "\(chat.user.name.lowercased()): \(chat.body.lowercased())".contains(query)
            }
        }
        if let filter { messages = messages.filter(filter) }
        return messages
    }

    private var chromeShown: Bool { paused != nil || chromeVisible || !search.isEmpty || searchFocused }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    Color.clear.frame(height: showsChrome ? 64 : 8)
                    ForEach(visibleMessages) { message in
                        ChatMessageRow(message: message)
                    }
                    Color.clear.frame(height: 8)
                }
            }
            .scrollPosition($position)
            // Starts at the newest message and stays there as messages arrive.
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .defaultScrollAnchor(.bottom, for: .sizeChanges)
            .scrollDismissesKeyboard(.interactively)
            .onScrollPhaseChange { _, newPhase in
                phase = newPhase
                if newPhase != .idle { showChrome() }
                updatePause()
            }
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.containerSize.height >= geometry.contentSize.height - 24
            } action: { _, bottom in
                atBottom = bottom
                updatePause()
            }

            if showsChrome {
                chrome
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                search = ""
                paused = nil
                withAnimation { position.scrollTo(edge: .bottom) }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.body.weight(.semibold))
                    .padding(12)
                    .background(palette.tertiaryContainer, in: Circle())
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(24)
            .opacity(paused != nil ? 1 : 0)
            .allowsHitTesting(paused != nil)
            .accessibilityHidden(paused == nil)
            .animation(.easeInOut(duration: 0.2), value: paused != nil)
        }
        .task {
            await channel.client.ensureRecentMessages(channel)
        }
        .onAppear { showChrome(linger: 6) }
    }

    /// Pauses only when the user scrolled away; new messages growing the content don't count.
    private func updatePause() {
        if atBottom {
            if paused != nil { paused = nil }
        } else if paused == nil, phase != .idle {
            paused = channel.messages.items
        }
    }

    private var chrome: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(L10n.search, text: $search)
                    .focused($searchFocused)
                    .submitLabel(.search)
                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .opacity(chromeShown ? 1 : 0)
            .allowsHitTesting(chromeShown)

            AvatarButton()
                .opacity(chromeShown || notifications.unread > 0 ? 1 : 0)
                .allowsHitTesting(chromeShown || notifications.unread > 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: chromeShown)
    }

    /// Keeps the chrome visible for a while after the last interaction instead of hiding it right away.
    private func showChrome(linger: Double = 3) {
        hideChrome?.cancel()
        if !chromeVisible { chromeVisible = true }
        hideChrome = Task {
            try? await Task.sleep(nanoseconds: UInt64(linger * 1_000_000_000))
            if !Task.isCancelled { chromeVisible = false }
        }
    }
}
