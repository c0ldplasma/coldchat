import SwiftUI

/// The emote menu under the composer: every channel and global emote and emoji, by provider and category, with
/// search and a bar to jump between sections.
struct EmotePicker: View {
    /// Nil outside a chat (from Settings): global emotes only, plus the last opened channel's.
    let channel: Channel?
    /// Choosing the emote menu button instead of typing: tapping sets the button, and a banner offers Kappa.
    var pickingButtonIcon = false
    var onInsert: (Emote) -> Void = { _ in }
    /// Called with true once the button's emote was saved.
    var onPickButtonIcon: (Bool) -> Void = { _ in }

    @Environment(Client.self) private var client
    @State private var search = ""
    @State private var downloadFailed = false

    private static let twitchSection = "Twitch"

    private static let categoryIcons: [String: String] = [
        "Symbols": "star",
        "Activities": "ticket",
        "Flags": "flag",
        "Travel & Places": "car",
        "Food & Drink": "fork.knife",
        "Animals & Nature": "pawprint",
        "People & Body": "person.2",
        "Objects": "lightbulb",
        "Component": "square.on.circle",
        "Smileys & Emotion": "face.smiling",
    ]

    private struct Section: Identifiable {
        let id: String
        var emotes: [Emote]
    }

    private var sections: [Section] {
        let all = (channel?.emotes ?? []) + client.globalEmotes + client.twitchUserEmotes
        var emoteSections: [Section] = []
        var emojiSections: [Section] = []
        // Grouped by provider in order of first appearance, then by category within it.
        var providers: [ProviderKind] = []
        for emote in all where !providers.contains(emote.provider) { providers.append(emote.provider) }
        for provider in providers {
            let emotes = all.filter { $0.provider == provider }
            var categories: [String] = []
            for emote in emotes {
                let key = emote.category ?? provider.name
                if !categories.contains(key) { categories.append(key) }
            }
            for category in categories {
                let section = Section(id: category, emotes: emotes.filter { ($0.category ?? provider.name) == category })
                // Emojis go after every Twitch/7TV/BetterTTV/FrankerFaceZ section.
                if provider == .emoji {
                    emojiSections.append(section)
                } else if let index = emoteSections.firstIndex(where: { $0.id == category }) {
                    emoteSections[index].emotes += section.emotes
                } else {
                    emoteSections.append(section)
                }
            }
        }
        // There are always Twitch emotes, so their section stays in place with a spinner while they load.
        if !emoteSections.contains(where: { $0.id == Self.twitchSection }) {
            emoteSections.append(Section(id: Self.twitchSection, emotes: []))
        }
        return emoteSections + emojiSections
    }

    var body: some View {
        let query = search.lowercased()
        let sections = sections
        let visible = sections.compactMap { section -> Section? in
            if section.emotes.isEmpty { return query.isEmpty ? section : nil }
            let matching = query.isEmpty ? section.emotes : section.emotes.filter { $0.name.lowercased().contains(query) }
            return matching.isEmpty ? nil : Section(id: section.id, emotes: matching)
        }

        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    // Fixed-height rows instead of a LazyVGrid per section: the lazy stack can then place far-away
                    // sections exactly, so the jump bar doesn't land in unrealized blank space.
                    let columns = max(1, Int(geometry.size.width / 52))
                    let cellWidth = geometry.size.width / CGFloat(columns)
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            if pickingButtonIcon {
                                HStack {
                                    Text(L10n.chooseEmoteMenuButton)
                                    Spacer()
                                    Button(L10n.resetToKappa) {
                                        EmoteButtonIcon.shared.reset()
                                        onPickButtonIcon(true)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                            HStack {
                                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                                TextField(L10n.search, text: $search).autocorrectionDisabled().textInputAutocapitalization(.never)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .secondarySystemBackground), in: Capsule())
                            .padding(12)

                            ForEach(visible) { section in
                                Text(section.id)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 32)
                                    .id(section.id)
                                if section.emotes.isEmpty {
                                    ProgressView().frame(maxWidth: .infinity).frame(height: 48)
                                } else {
                                    ForEach(rows(section.emotes, columns: columns), id: \.self) { row in
                                        HStack(spacing: 0) {
                                            ForEach(row, id: \.self) { emote in
                                                Button {
                                                    pick(emote)
                                                } label: {
                                                    EmoteGlyph(emote: emote, size: 32)
                                                        .frame(width: cellWidth, height: 48)
                                                        .contentShape(Rectangle())
                                                }
                                                .buttonStyle(.plain)
                                                .accessibilityLabel(emote.name)
                                            }
                                        }
                                        .frame(height: 48)
                                    }
                                }
                            }
                        }
                    }
                }
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(sections) { section in
                            Button {
                                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(section.id, anchor: .top) }
                            } label: {
                                sectionIcon(section)
                                    .frame(width: 24, height: 24)
                                    .padding(8)
                                    .background(Color(uiColor: .systemBackground), in: Circle())
                                    .overlay(Circle().stroke(Color(uiColor: .separator)))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(section.id)
                        }
                    }
                    .padding(4)
                }
                .scrollIndicators(.hidden)
                .frame(height: 48)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .foregroundStyle(Color.primary)
        .alert(L10n.emoteMenuButtonDownloadFailed, isPresented: $downloadFailed) {
            Button(L10n.close, role: .cancel) {}
        }
    }

    private func rows(_ emotes: [Emote], columns: Int) -> [[Emote]] {
        stride(from: 0, to: emotes.count, by: columns).map { Array(emotes[$0..<min($0 + columns, emotes.count)]) }
    }

    private func pick(_ emote: Emote) {
        guard pickingButtonIcon else {
            onInsert(emote)
            return
        }
        Task {
            do {
                try await EmoteButtonIcon.shared.set(emote)
                onPickButtonIcon(true)
            } catch {
                downloadFailed = true
                onPickButtonIcon(false)
            }
        }
    }

    @ViewBuilder private func sectionIcon(_ section: Section) -> some View {
        if let symbol = Self.categoryIcons[section.id] {
            Image(systemName: symbol)
        } else {
            switch section.id {
            case "Twitch": Image("TwitchLogo").resizable().scaledToFit().foregroundStyle(Color(rgb: 0x9146FF))
            case "7TV": Image("SevenTVLogo").resizable().scaledToFit()
            case "BetterTTV": Image("BTTVLogo").resizable().scaledToFit()
            case "FrankerFaceZ": Image("FFZ").resizable().interpolation(.medium).scaledToFit()
            default:
                if let first = section.emotes.first { EmoteGlyph(emote: first, size: 24) }
            }
        }
    }
}

/// An emote, drawn with the system emoji font for emojis.
struct EmoteGlyph: View {
    let emote: Emote
    let size: CGFloat

    var body: some View {
        if emote.isEmoji, let code = emote.code {
            Text(code).font(.system(size: size * 0.85)).frame(width: size, height: size)
        } else {
            RemoteFillImage(url: emote.largestURL, contentMode: .fit, maxPixelSize: size * 3)
                .frame(width: size, height: size)
        }
    }
}
