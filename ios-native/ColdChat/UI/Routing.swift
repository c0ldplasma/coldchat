import SwiftUI

/// The sheets the app shows. The Flutter app stacked bottom sheets on top of each other; every sheet here can
/// present the next one the same way.
enum Route: Identifiable {
    case account
    case settings
    case notifications
    case channel(Channel)
    case user(login: String, channel: Channel?)
    case message(ChannelMessageChat)
    case emote(Emote)
    case chatters(Channel)
    case twitchAccount(TwitchAccount)
    case login
    case tokenInput
    case verifyToken(String)
    case appearance
    case theme
    case chatSettings
    case language
    case messageAppearance
    case customCommands
    case customCommand(CustomCommand?)
    case messageTriggers
    case messageTrigger(MessageTrigger?)
    case userTriggers
    case userTrigger(UserTrigger?)
    case credits
    case about
    case emoteButtonPicker

    var id: String {
        switch self {
        case .account: "account"
        case .settings: "settings"
        case .notifications: "notifications"
        case .channel(let channel): "channel-\(channel.name)"
        case .user(let login, _): "user-\(login)"
        case .message(let message): "message-\(ObjectIdentifier(message).hashValue)"
        case .emote(let emote): "emote-\(emote.id)"
        case .chatters(let channel): "chatters-\(channel.name)"
        case .twitchAccount(let account): "twitchAccount-\(account.id)"
        case .login: "login"
        case .tokenInput: "tokenInput"
        case .verifyToken: "verifyToken"
        case .appearance: "appearance"
        case .theme: "theme"
        case .chatSettings: "chatSettings"
        case .language: "language"
        case .messageAppearance: "messageAppearance"
        case .customCommands: "customCommands"
        case .customCommand(let command): "customCommand-\(command?.id.uuidString ?? "new")"
        case .messageTriggers: "messageTriggers"
        case .messageTrigger(let trigger): "messageTrigger-\(trigger?.id.uuidString ?? "new")"
        case .userTriggers: "userTriggers"
        case .userTrigger(let trigger): "userTrigger-\(trigger?.id.uuidString ?? "new")"
        case .credits: "credits"
        case .about: "about"
        case .emoteButtonPicker: "emoteButtonPicker"
        }
    }
}

struct PresentAction {
    let action: (Route) -> Void
    func callAsFunction(_ route: Route) { action(route) }
}

private struct PresentKey: EnvironmentKey {
    static let defaultValue = PresentAction { _ in }
}

extension EnvironmentValues {
    /// Shows a sheet on top of the current screen or sheet.
    var present: PresentAction {
        get { self[PresentKey.self] }
        set { self[PresentKey.self] = newValue }
    }
}

private struct RouteHost: ViewModifier {
    @State private var route: Route?

    func body(content: Content) -> some View {
        content
            .environment(\.present, PresentAction { route = $0 })
            .sheet(item: $route) { route in
                RouteView(route: route)
                    .routeHost()
            }
    }
}

extension View {
    /// Lets this view and everything in it present sheets with `@Environment(\.present)`.
    func routeHost() -> some View { modifier(RouteHost()) }
}

/// The content of each sheet.
struct RouteView: View {
    let route: Route
    @Environment(AppSettings.self) private var settings

    var body: some View {
        content
            .environment(\.palette, settings.palette)
    }

    @ViewBuilder private var content: some View {
        switch route {
        case .account: AccountSheet().presentationDetents([.medium, .large])
        case .settings: SettingsSheet()
        case .notifications: NotificationsSheet().presentationDetents([.medium, .large])
        case .channel(let channel): ChannelSheet(channel: channel).presentationDetents([.medium, .large])
        case .user(let login, let channel): UserSheet(login: login, channel: channel).presentationDetents([.medium, .large])
        case .message(let message): MessageSheet(message: message).presentationDetents([.medium, .large])
        case .emote(let emote): EmoteSheet(emote: emote).presentationDetents([.height(150)])
        case .chatters(let channel): ChattersSheet(channel: channel)
        case .twitchAccount(let account): TwitchAccountSheet(account: account).presentationDetents([.medium, .large])
        case .login: LoginSheet().interactiveDismissDisabled()
        case .tokenInput: TokenInputSheet().presentationDetents([.medium])
        case .verifyToken(let token): VerifyTokenSheet(token: token).presentationDetents([.medium])
        case .appearance: AppearanceSheet().presentationDetents([.medium, .large])
        case .theme: ThemeSheet()
        case .chatSettings: ChatSettingsSheet().presentationDetents([.medium, .large])
        case .language: LanguageSheet()
        case .messageAppearance: MessageAppearanceSheet().presentationDetents([.medium, .large])
        case .customCommands: CustomCommandsSheet()
        case .customCommand(let command): CustomCommandSheet(command: command).presentationDetents([.medium])
        case .messageTriggers: MessageTriggersSheet()
        case .messageTrigger(let trigger): MessageTriggerSheet(trigger: trigger).presentationDetents([.medium, .large])
        case .userTriggers: UserTriggersSheet()
        case .userTrigger(let trigger): UserTriggerSheet(trigger: trigger).presentationDetents([.medium])
        case .credits: CreditsSheet()
        case .about: AboutSheet()
        case .emoteButtonPicker: EmoteButtonPickerSheet().presentationDetents([.medium, .large])
        }
    }
}

/// Title bar for a sheet: a close button, the title, and an optional trailing button, as in the Flutter app.
struct SheetHeader<Trailing: View>: View {
    var title: String?
    @ViewBuilder var trailing: Trailing
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.close)
            Spacer()
            if let title {
                Text(title).font(.title2)
                Spacer()
            }
            trailing.frame(minWidth: 40, minHeight: 40)
        }
        .padding(8)
    }
}

extension SheetHeader where Trailing == EmptyView {
    init(title: String? = nil) {
        self.title = title
        trailing = EmptyView()
    }
}
