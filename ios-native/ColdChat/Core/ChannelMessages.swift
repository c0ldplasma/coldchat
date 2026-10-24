import Foundation
import Observation

/// A channel's chat, sorted by time, capped at 1000 lines and free of duplicate message ids.
@MainActor
@Observable
final class ChannelMessages {
    static let limit = 1000

    private(set) var items: [ChannelMessage] = []

    @ObservationIgnored private var ids: Set<String> = []
    // While a bulk insert runs, add() works on this copy and publishes once at the end, so loading history
    // produces one update instead of one per message.
    @ObservationIgnored private var bulk: [ChannelMessage]?

    func beginBulk() {
        bulk = items
    }

    func endBulk() {
        guard let pending = bulk else { return }
        bulk = nil
        publish(pending)
    }

    func add(_ message: ChannelMessage) {
        if let id = message.messageId {
            guard ids.insert(id).inserted else { return }
        }
        if bulk != nil {
            Self.insertSorted(message, into: &bulk!)
        } else {
            var copy = items
            Self.insertSorted(message, into: &copy)
            publish(copy)
        }
    }

    /// Swaps [previous] for [next] in one update, so the list never shows neither.
    func replace(_ previous: ChannelMessage?, with next: ChannelMessage) {
        var copy = items
        if let previous { copy.removeAll { $0 === previous } }
        Self.insertSorted(next, into: &copy)
        publish(copy)
    }

    /// Republishes after messages were rebuilt in place.
    func touch() {
        items = items
    }

    func contains(id: String) -> Bool { ids.contains(id) }

    /// Inserts after any messages with the same time, so arrival order breaks ties.
    private static func insertSorted(_ message: ChannelMessage, into list: inout [ChannelMessage]) {
        if let last = list.last, last.dateTime <= message.dateTime {
            list.append(message)
            return
        }
        var low = 0
        var high = list.count
        while low < high {
            let mid = (low + high) / 2
            if list[mid].dateTime <= message.dateTime { low = mid + 1 } else { high = mid }
        }
        list.insert(message, at: low)
    }

    private func publish(_ list: [ChannelMessage]) {
        var list = list
        if list.count > Self.limit {
            for dropped in list.prefix(list.count - Self.limit) {
                if let id = dropped.messageId { ids.remove(id) }
            }
            list.removeFirst(list.count - Self.limit)
        }
        items = list
    }
}
