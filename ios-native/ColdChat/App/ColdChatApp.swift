import SwiftUI

@main
struct ColdChatApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(model.settings)
                .environment(model.accounts)
                .environment(model.client)
                .environment(model.notifications)
                .environment(model.uploads)
                .tint(model.settings.accentColor)
                .preferredColorScheme(model.settings.colorScheme)
                // Re-renders every string when the language changes in Settings.
                .id(model.settings.locale ?? "system")
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                // Chat is meant to be watched; keep the screen on like the Flutter app did.
                UIApplication.shared.isIdleTimerDisabled = true
                Task { await model.client.onAppResumed() }
            default:
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }
}

/// Owns the app-wide state that the Flutter app provided at the root.
@MainActor
@Observable
final class AppModel {
    let settings: AppSettings
    let accounts: AccountStore
    let client: Client
    let notifications = NotificationCenterModel()
    let uploads = UploadQueue()

    init() {
        UIScreen.mainScale = UIScreen.main.scale
        let settings = AppSettings()
        let accounts = AccountStore()
        self.settings = settings
        self.accounts = accounts
        client = Client(settings: settings, accounts: accounts)
        client.onMessageReceived = { [notifications] message in
            // Mentions stay highlighted either way; this only avoids notifying again for one surfaced in an earlier
            // session that comes back with history.
            guard message.mentioned, let id = message.messageId, !SeenMentions.contains(id) else { return }
            notifications.add(message)
            SeenMentions.insert(id)
        }
    }
}

/// Mentions collected while the app runs, with an unread count for the bell.
@MainActor
@Observable
final class NotificationCenterModel {
    private(set) var messages: [ChannelMessageChat] = []
    private(set) var unread = 0

    func add(_ message: ChannelMessageChat) {
        guard !messages.contains(where: { $0.messageId == message.messageId }) else { return }
        messages.append(message)
        unread += 1
    }

    func clearUnread() { unread = 0 }

    func clear() {
        messages = []
        unread = 0
    }
}
