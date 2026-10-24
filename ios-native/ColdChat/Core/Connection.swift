import Foundation
import Observation

/// One entry in a connection's debug log: a line in either direction, a state change or an error.
struct ConnectionLog: Identifiable {
    let id = UUID()
    let date = Date()
    let text: String
    let outgoing: Bool
}

/// A Twitch IRC-over-WebSocket connection.
///
/// Mobile sockets go half-open all the time (lock screen, Wi-Fi/cellular handoff, NAT timeouts), and an
/// expired token makes Twitch refuse the handshake. So the connection reconnects with backoff, runs a liveness
/// watchdog, and stops retrying once Twitch rejected the credentials until a fresh login arrives.
@MainActor
@Observable
final class Connection {
    enum State: Equatable {
        case disconnected
        case connecting(TwitchAccount)
        case connected(TwitchAccount)
        /// The token expired or was refused. Only a new sign-in recovers.
        case invalidCredentials(TwitchAccount)

        var account: TwitchAccount? {
            switch self {
            case .disconnected: nil
            case .connecting(let account), .connected(let account), .invalidCredentials(let account): account
            }
        }

        var isConnected: Bool { if case .connected = self { true } else { false } }
        var isConnecting: Bool { if case .connecting = self { true } else { false } }
    }

    let name: String
    private(set) var state: State = .disconnected {
        didSet {
            guard state != oldValue else { return }
            log("state: \(oldValue) -> \(state)")
            onStateChange?(self, oldValue, state)
        }
    }

    /// Blocked user ids of the logged-in account. Filled in the background after connecting, so channel joins
    /// don't wait for the (paginated, slow) request.
    var blockedUserIds: Set<String> = []

    @ObservationIgnored var onReceive: ((Connection, IRCMessage) -> Void)?
    @ObservationIgnored var onStateChange: ((Connection, State, State) -> Void)?

    @ObservationIgnored private(set) var logs: [ConnectionLog] = []

    var account: TwitchAccount? { state.account }
    private(set) var credentialsRejected = false

    @ObservationIgnored private var task: URLSessionWebSocketTask?
    @ObservationIgnored private var session = URLSession(configuration: .default)
    @ObservationIgnored private var reconnectAttempts = 0
    @ObservationIgnored private var reconnectTimer: Timer?
    @ObservationIgnored private var watchdog: Timer?
    @ObservationIgnored private var lastAccount: TwitchAccount?
    @ObservationIgnored private var connectStartedAt: Date?
    @ObservationIgnored private var lastInbound: Date?
    @ObservationIgnored private var lastPingSentAt: Date?

    private static let handshakeTimeout: TimeInterval = 8
    private static let inboundTimeout: TimeInterval = 70
    private static let pingInterval: TimeInterval = 60

    init(name: String) {
        self.name = name
        // Also fires within ~5s of every wake, since iOS freezes timers while suspended.
        watchdog = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkLiveness() }
        }
    }

    // MARK: Events

    func connect(_ account: TwitchAccount) {
        lastAccount = account
        // A connect with (presumably) fresh credentials clears the auth lock.
        credentialsRejected = false
        blockedUserIds = []
        state = .connecting(account)
        open(nick: account.tokenData.login, pass: account.tokenData.accessToken.map { "oauth:\($0)" })
    }

    /// Twitch accepted the login (IRC 001).
    func established() {
        guard case .connecting(let account) = state else { return }
        state = .connected(account)
    }

    func disconnect() {
        cancel()
        state = .disconnected
    }

    /// Never reconnects with credentials Twitch already refused; only `connect` (after a re-login) resumes.
    func reconnect(_ account: TwitchAccount? = nil) {
        if credentialsRejected && account == nil { return }
        // Falls back to the last account so a reconnect still fires from `.disconnected`.
        guard let account = account ?? lastAccount ?? state.account else { return }
        connect(account)
    }

    func rejectCredentials(_ account: TwitchAccount) {
        credentialsRejected = true
        lastAccount = account
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        connectStartedAt = nil
        cancel()
        state = .invalidCredentials(account)
    }

    // MARK: Socket

    private func open(nick: String, pass: String?) {
        // Kill any pending backoff reconnect: thawing after a suspend, it would tear down the connection being
        // established here.
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        connectStartedAt = Date()
        lastInbound = nil
        lastPingSentAt = nil
        cancel()

        let task = session.webSocketTask(with: URL(string: "wss://irc-ws.chat.twitch.tv:443")!)
        self.task = task
        task.resume()
        receiveLoop(task)

        send("CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership")
        if let pass { send("PASS \(pass)", logged: false) }
        send("NICK \(nick)")
    }

    private func receiveLoop(_ task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            Task { @MainActor in
                guard let self, self.task === task else { return }
                switch result {
                case .success(.string(let text)):
                    for line in text.split(whereSeparator: { $0 == "\r\n" || $0 == "\n" }) {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if trimmed.isEmpty { continue }
                        if let message = try? IRCMessage(parsing: trimmed) { self.receive(message) }
                    }
                    self.receiveLoop(task)
                case .success:
                    self.receiveLoop(task)
                case .failure(let error):
                    self.log("error: \(error.localizedDescription)")
                    self.scheduleReconnect()
                }
            }
        }
    }

    func send(_ line: String, logged: Bool = true) {
        guard let task else {
            log("not connected, dropped: \(line)")
            return
        }
        if logged { log(line, outgoing: true) } else { log("PASS ***", outgoing: true) }
        task.send(.string(line)) { [weak self] error in
            guard let error else { return }
            Task { @MainActor in self?.log("send failed: \(error.localizedDescription)") }
        }
    }

    private func receive(_ message: IRCMessage) {
        reconnectAttempts = 0
        lastInbound = Date()
        log(message.raw)
        onReceive?(self, message)
        if message.command == "PING" {
            send("PONG :\(message.parameters.joined(separator: " "))")
        }
    }

    /// Doesn't wait for the close: a half-open socket can hang on it forever.
    private func cancel() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    // MARK: Reconnecting

    /// Backoff of 1, 2, 4, 8, 16s, reset as soon as any line arrives.
    private func scheduleReconnect() {
        if credentialsRejected { return }
        task = nil
        reconnectTimer?.invalidate()
        let seconds = min(16, max(1, 1 << reconnectAttempts))
        reconnectAttempts += 1
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.reconnect() }
        }
    }

    /// Sends a PING and waits briefly for any reply. Silence alone proves nothing: a quiet channel can receive
    /// nothing for a minute.
    func probeAlive(timeout: TimeInterval = 3) async -> Bool {
        guard state.isConnected else { return false }
        let before = lastInbound
        send("PING :tmi.twitch.tv")
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if lastInbound != before { return true }
        }
        return false
    }

    func forceReconnect() { reconnect() }

    /// Catches what the socket callbacks miss: a handshake that never completes and a half-open socket that
    /// never reports an error.
    private func checkLiveness() {
        if credentialsRejected { return }
        let now = Date()
        switch state {
        case .connecting:
            if let started = connectStartedAt, now.timeIntervalSince(started) > Self.handshakeTimeout {
                reconnect()
            }
        case .connected:
            guard let last = lastInbound ?? connectStartedAt else { return }
            if now.timeIntervalSince(last) > Self.inboundTimeout {
                reconnect()
                return
            }
            // Ping proactively so a dead socket surfaces within the timeout.
            if now.timeIntervalSince(last) > Self.pingInterval, lastPingSentAt.map({ now.timeIntervalSince($0) > Self.pingInterval }) ?? true {
                lastPingSentAt = now
                send("PING :tmi.twitch.tv")
            }
        default:
            break
        }
    }

    private func log(_ text: String, outgoing: Bool = false) {
        logs.append(ConnectionLog(text: text, outgoing: outgoing))
        if logs.count > 1000 { logs.removeFirst(logs.count - 1000) }
    }
}

extension Connection.State: CustomStringConvertible {
    var description: String {
        switch self {
        case .disconnected: "disconnected"
        case .connecting(let account): "connecting(\(account.tokenData.login))"
        case .connected(let account): "connected(\(account.tokenData.login))"
        case .invalidCredentials(let account): "invalidCredentials(\(account.tokenData.login))"
        }
    }
}
