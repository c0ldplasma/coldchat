import Foundation
import Observation

/// The signed-in Twitch accounts and which one is active. Tokens live in the Keychain, not in UserDefaults.
@MainActor
@Observable
final class AccountStore {
    private static let keychainAccount = "twitchAccounts"
    private static let activeKey = "activeTwitchAccount"

    private(set) var accounts: [TwitchAccount] = []

    var activeHash: String? {
        didSet { UserDefaults.standard.set(activeHash, forKey: Self.activeKey) }
    }

    var active: TwitchAccount? { accounts.first { $0.id == activeHash } }

    init() {
        if let data = Keychain.read(Self.keychainAccount), let decoded = try? JSONDecoder().decode([TwitchAccount].self, from: data) {
            accounts = decoded
        }
        activeHash = UserDefaults.standard.string(forKey: Self.activeKey)
    }

    /// Adds or replaces [account]. Signing in again as the same user replaces the stale entry, also one stored
    /// under a different client id. Returns the hashes it replaced.
    @discardableResult
    func upsert(_ account: TwitchAccount) -> [String] {
        let replaced = accounts.filter { $0.id != account.id && $0.tokenData.userId == account.tokenData.userId }.map(\.id)
        accounts.removeAll { replaced.contains($0.id) }
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
        save()
        return replaced
    }

    func update(_ account: TwitchAccount) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index] = account
        save()
    }

    func remove(_ account: TwitchAccount) {
        if activeHash == account.id { activeHash = nil }
        accounts.removeAll { $0.id == account.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(accounts) {
            Keychain.write(data, for: Self.keychainAccount)
        }
    }
}
