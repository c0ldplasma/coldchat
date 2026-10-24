import Foundation

/// Listens to the BetterTTV socket for Pro badges. BetterTTV has no REST endpoint for these: a Pro user's client
/// announces itself when it opens a channel, and the server relays that to everyone listening on the channel.
@MainActor
final class BetterTTVSocket {
    /// A Pro user's badge url, or nil when they don't show one.
    var onLookupUser: ((_ userId: String, _ url: String?) -> Void)?

    private var roomIds: Set<String> = []
    private var task: URLSessionWebSocketTask?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0

    func join(_ roomId: String) {
        guard roomIds.insert(roomId).inserted else { return }
        if task == nil { connect() } else { send("join_channel", roomId) }
    }

    func part(_ roomId: String) {
        guard roomIds.remove(roomId) != nil else { return }
        send("part_channel", roomId)
    }

    /// iOS can leave a suspended socket half-open without ever reporting it, so this runs on resume.
    func reconnect() {
        guard !roomIds.isEmpty else { return }
        close()
        connect()
    }

    private func connect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        let task = HTTP.session.webSocketTask(with: URL.api("wss://sockets.betterttv.net/ws"))
        self.task = task
        task.resume()
        receiveLoop(task)
        for roomId in roomIds { send("join_channel", roomId) }
    }

    private func close() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    private func scheduleReconnect() {
        close()
        guard !roomIds.isEmpty, reconnectTimer == nil else { return }
        let seconds = min(60, max(1, 1 << reconnectAttempts))
        reconnectAttempts += 1
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.connect() }
        }
    }

    private func send(_ name: String, _ roomId: String) {
        let payload: [String: Any] = ["name": name, "data": ["name": "twitch:\(roomId)"]]
        guard let data = try? JSONSerialization.data(withJSONObject: payload), let text = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(text)) { _ in }
    }

    private func receiveLoop(_ task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            Task { @MainActor in
                guard let self, self.task === task else { return }
                switch result {
                case .success(.string(let text)):
                    self.reconnectAttempts = 0
                    self.handle(text)
                    self.receiveLoop(task)
                case .success:
                    self.receiveLoop(task)
                case .failure:
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              event["name"] as? String == "lookup_user",
              let payload = event["data"] as? [String: Any],
              let userId = payload["providerId"] as? String else { return }
        onLookupUser?(userId, (payload["badge"] as? [String: Any])?["url"] as? String)
    }
}
