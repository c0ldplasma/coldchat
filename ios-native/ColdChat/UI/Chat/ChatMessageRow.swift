import SwiftUI

/// One line in a chat: a chat message, a sub, a ban, a notice or the connection state.
struct ChatMessageRow: View {
    let message: ChannelMessage
    /// Off in the notifications sheet, where every message is a mention.
    var renderMentions = true

    @Environment(AppSettings.self) private var settings
    @Environment(\.palette) private var palette

    var body: some View {
        switch message {
        case let chat as ChannelMessageChat:
            ChatLine(message: chat, renderMentions: renderMentions)
        case let ban as ChannelMessageBan:
            BanChip(message: ban)
        case let notice as ChannelMessageNotice:
            InfoChip(systemImage: "info.circle", color: palette.tertiaryContainer) {
                Text(notice.text)
            }
        case let change as ChannelMessageStateChange:
            Text(change.state.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
        default:
            EmptyView()
        }
    }
}

extension Channel.State {
    var label: String {
        switch self {
        case .disconnected: "Disconnected"
        case .connecting: "Connecting…"
        case .connected: "Connected"
        case .suspended: "Suspended"
        case .banned: "Banned"
        }
    }
}

/// A rounded chip with an icon, for notices, bans and subs.
struct InfoChip<Content: View>: View {
    let systemImage: String
    let color: Color
    @ViewBuilder var content: Content
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let scale = settings.messageScale
        HStack(alignment: .top, spacing: 8 * scale) {
            Image(systemName: systemImage).font(.system(size: 20 * scale))
            VStack(alignment: .leading, spacing: 4) { content }
                .font(.system(size: settings.messageFontSize))
        }
        .padding(.horizontal, 12 * scale)
        .padding(.vertical, 8 * scale)
        .chip(color, radius: 18 * scale)
        .padding(.horizontal, 12)
        .padding(.vertical, (settings.compactMessages ? 4 : 8))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BanChip: View {
    let message: ChannelMessageBan
    @Environment(\.palette) private var palette

    var body: some View {
        let icon = message.user == nil ? "eraser" : (message.duration != nil ? "timer" : "hand.raised")
        InfoChip(systemImage: icon, color: message.user == nil ? palette.secondaryContainer : palette.errorContainer) {
            if let user = message.user {
                (Text("\(user.name) ").bold() + Text(message.duration.map { L10n.bannedForDuration(formatDuration($0)) } ?? L10n.permabanned))
            } else {
                Text(L10n.chatCleared)
            }
        }
    }
}

/// `h:mm:ss`, like Dart's Duration.toString() without the fraction.
func formatDuration(_ interval: TimeInterval) -> String {
    let total = max(0, Int(interval))
    return String(format: "%d:%02d:%02d", total / 3600, total / 60 % 60, total % 60)
}

private struct ChatLine: View {
    let message: ChannelMessageChat
    let renderMentions: Bool

    @Environment(AppSettings.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.present) private var present
    @State private var revealed = false

    var body: some View {
        if let subInfo = message.subInfo {
            InfoChip(systemImage: subInfo.wasGifted ? "gift" : "star", color: palette.tertiaryContainer) {
                Text(subInfo.systemMessage)
                MessageContent(message: message)
            }
            .contentShape(Rectangle())
            .onLongPressGesture { present(.message(message)) }
        } else if message.blocked {
            VStack(alignment: .leading, spacing: 0) {
                (Text(L10n.blockedMessage) + Text(" ") + Text(revealed ? L10n.hideMessage : L10n.showMessage).foregroundColor(palette.primary))
                    .font(.system(size: settings.messageFontSize))
                    .padding(.horizontal, 12)
                    .padding(.vertical, settings.compactMessages ? 2 : 4)
                if revealed { line(background: palette.errorContainer) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { revealed.toggle() }
        } else {
            line(background: message.mentioned && renderMentions ? palette.primaryContainer : .clear)
        }
    }

    private func line(background: Color) -> some View {
        MessageContent(message: message)
            .padding(.horizontal, 12)
            .padding(.vertical, settings.compactMessages ? 2 : 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .contentShape(Rectangle())
            .onLongPressGesture { present(.message(message)) }
    }
}

/// The reply line, the message itself (timestamp, badges, name, words) and embedded images.
struct MessageContent: View {
    let message: ChannelMessageChat

    @Environment(AppSettings.self) private var settings
    @Environment(\.palette) private var palette
    @Environment(\.present) private var present
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }()

    var body: some View {
        let scale = settings.messageScale
        let fontSize = settings.messageFontSize
        VStack(alignment: .leading, spacing: 4) {
            if let reply = message.replyInfo {
                HStack(spacing: 8 * scale) {
                    ReplyArrow()
                        .stroke(Color.secondary, lineWidth: 2 * scale)
                        .frame(width: 30 * scale, height: 15 * scale)
                        .padding(.leading, settings.showTimestamps ? 8 * scale : 0)
                    (Text("@\(reply.parentDisplayName): ").bold() + Text(reply.parentBody))
                        .font(.system(size: fontSize))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            FlowLayout(spacing: 4 * scale, lineSpacing: 2 * scale) {
                if settings.showTimestamps {
                    Text(Self.timeFormatter.string(from: message.dateTime))
                        .font(.system(size: fontSize).monospacedDigit())
                        .foregroundStyle(.gray)
                }
                if settings.showBadges {
                    ForEach(Array(message.badges.enumerated()), id: \.offset) { _, badge in
                        RemoteImage(url: badge.largestURL, height: 20 * scale)
                            .accessibilityLabel(badge.name)
                    }
                }
                Text(message.action ? message.user.name : "\(message.user.name):")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(message.user.displayColor(colorScheme) ?? palette.primary)
                    .onTapGesture {
                        if let login = message.user.login { present(.user(login: login, channel: message.channel)) }
                    }
                ForEach(Array(message.splits.enumerated()), id: \.offset) { _, split in
                    switch split {
                    case .text(let word):
                        Text(word)
                            .font(.system(size: fontSize))
                            .italic(message.action)
                            .foregroundColor(message.action ? message.user.displayColor(colorScheme) : nil)
                    case .emote(let emote, let overlays):
                        EmoteView(emote: emote, overlays: overlays, scale: scale)
                            .onTapGesture { present(.emote(emote)) }
                    case .url(let url):
                        Text(url)
                            .font(.system(size: fontSize))
                            .foregroundColor(.blue)
                            .underline()
                            .onTapGesture { if let link = URL(string: url) { openURL(link) } }
                    }
                }
            }

            if !message.imageEmbeds.isEmpty {
                ForEach(message.imageEmbeds, id: \.self) { embed in
                    if let url = URL(string: embed) {
                        EmbeddedImage(url: url, scale: scale)
                            .padding(.vertical, 4 * scale)
                    }
                }
            }
        }
    }
}

extension ChatUser {
    /// The user's chat color, lifted or darkened when it would be unreadable on the background (#000000 on
    /// black is common).
    func displayColor(_ scheme: ColorScheme) -> Color? {
        guard let rgb = color else { return nil }
        var r = Double((rgb >> 16) & 0xFF) / 255, g = Double((rgb >> 8) & 0xFF) / 255, b = Double(rgb & 0xFF) / 255
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        if scheme == .dark, luminance < 0.3 {
            let mix = 0.5 - luminance
            (r, g, b) = (r + (1 - r) * mix, g + (1 - g) * mix, b + (1 - b) * mix)
        } else if scheme == .light, luminance > 0.75 {
            let factor = 0.6
            (r, g, b) = (r * factor, g * factor, b * factor)
        }
        return Color(.sRGB, red: r, green: g, blue: b)
    }
}

/// An emote with its zero-width overlays stacked on top.
struct EmoteView: View {
    let emote: Emote
    var overlays: [Emote] = []
    let scale: CGFloat

    var body: some View {
        let height = baseHeight(emote) * scale
        ZStack {
            glyph(emote, height: height)
            ForEach(overlays) { overlay in
                glyph(overlay, height: height)
            }
        }
        .accessibilityLabel(emote.name)
    }

    private func baseHeight(_ emote: Emote) -> CGFloat {
        emote.provider == .emoji || (emote.provider == .twitch && ChannelMessageChat.twitchClassicEmoticons.contains(emote.name)) ? 24 : 32
    }

    @ViewBuilder private func glyph(_ emote: Emote, height: CGFloat) -> some View {
        if emote.isEmoji, let code = emote.code {
            Text(code).font(.system(size: height * 0.85))
        } else {
            RemoteImage(url: emote.largestURL, height: height)
        }
    }
}

/// The curved line in front of a reply, from the Flutter app's ReplyPainter.
struct ReplyArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width / 3, y: rect.height))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: rect.height / 2), control: CGPoint(x: rect.width / 3, y: rect.height / 2))
        return path
    }
}
