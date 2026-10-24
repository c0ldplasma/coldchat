import SwiftUI
import WebKit

let repositoryURL = URL.api("https://github.com/c0ldplasma/coldchat")
// Published from docs/ with GitHub Pages.
let privacyPolicyURL = URL.api("https://c0ldplasma.github.io/coldchat/privacy.html")
let termsOfServiceURL = URL.api("https://c0ldplasma.github.io/coldchat/terms.html")

/// ColdChat's own Twitch app (dev.twitch.tv console). A public client using the implicit grant: the client id
/// isn't a secret, it's part of every login URL.
let twitchClientId = "y05nqtxmuntv88n98uhfz4sfpr0u17"
/// Registered redirect. Never actually loaded: the web view intercepts it and reads the token from the fragment.
/// Must match the console entry exactly, trailing slash included.
private let redirectURI = "https://localhost/"

/// The accounts, adding one, settings and the legal links.
struct AccountSheet: View {
    @Environment(AccountStore.self) private var accounts
    @Environment(Client.self) private var client
    @Environment(\.present) private var present
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.appName) {
                Button {
                    present(.settings)
                } label: {
                    Image(systemName: "gearshape").frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.settings)
            }
            List {
                if let active = accounts.active {
                    AccountRow(account: active, active: true)
                }
                ForEach(accounts.accounts.filter { $0.id != accounts.activeHash }) { account in
                    AccountRow(account: account, active: false)
                }
                Button {
                    present(.login)
                } label: {
                    Label(L10n.addAnotherAccount, systemImage: "person.badge.plus")
                }
                .simultaneousGesture(LongPressGesture().onEnded { _ in present(.tokenInput) })

                Section {
                    HStack(spacing: 12) {
                        Spacer()
                        Button(L10n.privacyPolicy) { openURL(privacyPolicyURL) }
                        Circle().fill(.primary).frame(width: 4, height: 4)
                        Button(L10n.termsOfService) { openURL(termsOfServiceURL) }
                        Spacer()
                    }
                    .font(.caption)
                    .buttonStyle(.row)
                    .listRowBackground(Color.clear)
                }
            }
        }
    }
}

private struct AccountRow: View {
    let account: TwitchAccount
    let active: Bool
    @Environment(AccountStore.self) private var accounts
    @Environment(Client.self) private var client
    @Environment(\.present) private var present

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if let url = account.userData.flatMap({ URL(string: $0.avatarUrl) }) {
                    RemoteFillImage(url: url, maxPixelSize: 128)
                } else {
                    Image(systemName: "questionmark")
                }
            }
            .frame(width: active ? 40 : 36, height: active ? 40 : 36)
            .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(account.name)
                Text(L10n.loggedInVia("Twitch")).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if active { Image(systemName: "checkmark").foregroundStyle(.tint) }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            accounts.activeHash = account.id
            client.connectAs(account)
        }
        .onLongPressGesture { present(.twitchAccount(account)) }
    }
}

/// One account: refresh its login or remove it.
struct TwitchAccountSheet: View {
    let account: TwitchAccount
    @Environment(AccountStore.self) private var accounts
    @Environment(Client.self) private var client
    @Environment(\.present) private var present
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.account)
            List {
                VStack(spacing: 8) {
                    Group {
                        if let url = account.userData.flatMap({ URL(string: $0.avatarUrl) }) {
                            RemoteFillImage(url: url, maxPixelSize: 288)
                        } else {
                            Image(systemName: "questionmark").font(.largeTitle)
                        }
                    }
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
                    Text(account.name).font(.title2).textSelection(.enabled)
                    Text("\(account.tokenData.login)#\(account.tokenData.userId ?? "")").font(.headline).foregroundStyle(.secondary).textSelection(.enabled)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)

                Button {
                    // Re-checks the stored token; an expired one shows the error and needs a new sign-in.
                    present(.verifyToken(account.tokenData.accessToken ?? ""))
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "arrow.clockwise").frame(width: 28)
                        VStack(alignment: .leading) {
                            Text(L10n.refreshAccount)
                            ExpirationText(tokenData: account.tokenData)
                        }
                    }
                }
                Button(role: .destructive) {
                    accounts.remove(account)
                    if client.receiver.account?.id == account.id { client.connectAs(accounts.active ?? .anonymous) }
                    dismiss()
                } label: {
                    Label(L10n.removeAccount, systemImage: "trash")
                }
            }
        }
    }
}

/// Counts down to the token's expiry, or says it expired.
private struct ExpirationText: View {
    let tokenData: TokenData

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            if tokenData.isExpired {
                Text(L10n.loginExpired).foregroundStyle(.red)
            } else if let expiresAt = tokenData.expiresAt {
                Text(L10n.expiresIn(formatDuration(expiresAt.timeIntervalSince(context.date)))).foregroundStyle(.secondary)
            } else {
                Text(L10n.expiresNever).foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }
}

// MARK: - Login

/// Twitch's sign-in page in a web view. The redirect to https://localhost/ carries the token and is intercepted.
struct LoginSheet: View {
    @Environment(\.present) private var present
    @Environment(\.dismiss) private var dismiss
    @State private var failure: String?
    @State private var token: String?

    private static let scopes = [
        // Chat
        "chat:edit", "chat:read", "channel:moderate", "channel:read:redemptions", "moderator:manage:automod", "channel:manage:broadcast",
        // Whispers
        "whispers:read", "whispers:edit",
        // Sub emotes
        "user_subscriptions",
        // Blocked users
        "user_blocks_edit", "user_blocks_read", "user:read:blocked_users", "user:manage:blocked_users",
        // Raids
        "channel_editor",
    ]

    static var authorizeURL: URL {
        let redirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? redirectURI
        return .api("https://id.twitch.tv/oauth2/authorize?client_id=\(twitchClientId)&redirect_uri=\(redirect)&response_type=token&scope=\(scopes.joined(separator: "%20"))")
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let token {
                VerifyTokenSheet(token: token)
            } else {
                OAuthWebView { url in
                    let fragment = URLComponents(string: "https://x/?\(url.fragment ?? "")")?.queryItems ?? []
                    let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
                    if let accessToken = fragment.first(where: { $0.name == "access_token" })?.value {
                        token = accessToken
                    } else if let error = query.first(where: { $0.name == "error" })?.value, error != "access_denied" {
                        // Declining is a choice; anything else is a failure the user should see.
                        failure = query.first(where: { $0.name == "error_description" })?.value ?? error
                    } else {
                        dismiss()
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                SheetHeader()
                    .background(.regularMaterial, in: Circle())
                    .padding(4)
                    .fixedSize()
            }
        }
        .alert(L10n.loginFailed, isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil; dismiss() } })) {
            Button(L10n.close, role: .cancel) {}
        } message: {
            Text(failure ?? "")
        }
    }
}

private struct OAuthWebView: UIViewRepresentable {
    let onRedirect: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onRedirect: onRedirect) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // A fresh session each time, so "add another account" doesn't silently sign in as the last one.
        configuration.websiteDataStore = .nonPersistent()
        configuration.allowsInlineMediaPlayback = true
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.load(URLRequest(url: LoginSheet.authorizeURL))
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onRedirect: (URL) -> Void
        init(onRedirect: @escaping (URL) -> Void) { self.onRedirect = onRedirect }

        // URLs aren't logged: the redirect carries the access token.
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, url.scheme == "https", url.host == "localhost" else {
                decisionHandler(.allow)
                return
            }
            decisionHandler(.cancel)
            onRedirect(url)
        }
    }
}

/// Paste a token instead of signing in (long-press "add another account").
struct TokenInputSheet: View {
    @State private var token = ""
    @Environment(\.present) private var present
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: L10n.tokenInput)
            Form {
                SecureField("", text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            HStack {
                Button(L10n.cancel) { dismiss() }.frame(maxWidth: .infinity)
                Divider().frame(height: 32)
                Button(L10n.add) { present(.verifyToken(token.trimmingCharacters(in: .whitespacesAndNewlines))) }
                    .bold()
                    .frame(maxWidth: .infinity)
                    .disabled(token.isEmpty)
            }
            .padding(.vertical, 20)
        }
    }
}

/// Validates a token, loads the user, saves the account and switches to it when it's the first or a re-login.
struct VerifyTokenSheet: View {
    let token: String
    @Environment(AccountStore.self) private var accounts
    @Environment(Client.self) private var client
    @Environment(\.dismiss) private var dismiss

    private enum Step {
        case verifyingToken
        case verifyingUser(TokenData)
        case done(String)
        case failed(title: String, detail: String)
    }

    @State private var step = Step.verifyingToken

    var body: some View {
        VStack(spacing: 16) {
            switch step {
            case .verifyingToken:
                ProgressView()
                Text(L10n.verifyingUserToken)
            case .verifyingUser(let tokenData):
                ProgressView()
                Text(L10n.verifiedUserToken)
                Text(L10n.loggedInAs("\(tokenData.login) (\(tokenData.userId ?? ""))")).foregroundStyle(.secondary)
                Text(L10n.verifyingUserData)
            case .done(let name):
                Image(systemName: "checkmark").font(.system(size: 56)).foregroundStyle(.tint)
                Text(L10n.verifiedUserData)
                Text(L10n.loggedInAs(name)).foregroundStyle(.secondary)
            case .failed(let title, let detail):
                Image(systemName: "nosign").font(.system(size: 56)).foregroundStyle(.red)
                Text(title)
                Text(detail).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button(L10n.close) { dismiss() }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await verify() }
    }

    private func verify() async {
        let tokenData: TokenData
        do {
            tokenData = try await Twitch.validateToken(token)
        } catch {
            step = .failed(title: L10n.anErrorHasOccuredWhenVerifyingUserToken, detail: error.localizedDescription)
            return
        }
        step = .verifyingUser(tokenData)
        do {
            let userData = try await Twitch.userData(tokenData)
            let account = TwitchAccount(tokenData: tokenData, userData: userData)
            let replaced = accounts.upsert(account)
            // A re-login for the account in use (or the first login) takes effect right away; adding a second
            // account doesn't take over the session.
            let active = accounts.activeHash
            if active == nil || active == account.id || replaced.contains(active ?? "") || !accounts.accounts.contains(where: { $0.id == active }) {
                accounts.activeHash = account.id
                client.connectAs(account)
            }
            step = .done(userData.displayName)
            try? await Task.sleep(nanoseconds: 600_000_000)
            dismiss()
        } catch {
            step = .failed(title: L10n.anErrorHasOccuredWhenVerifyingUserData, detail: error.localizedDescription)
        }
    }
}
