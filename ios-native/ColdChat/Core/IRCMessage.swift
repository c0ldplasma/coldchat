import Foundation

/// One IRC line, split into IRCv3 tags, prefix, command and parameters.
struct IRCMessage {
    let raw: String
    let tags: [String: String]
    let prefix: String?
    let command: String
    let parameters: [String]

    enum ParseError: Error {
        case empty(String)
    }

    init(raw: String, tags: [String: String], prefix: String?, command: String, parameters: [String]) {
        self.raw = raw
        self.tags = tags
        self.prefix = prefix
        self.command = command
        self.parameters = parameters
    }

    init(parsing event: String) throws {
        var parts = event.split(separator: " ", omittingEmptySubsequences: false)[...]

        var tags: [String: String] = [:]
        if let first = parts.first, first.hasPrefix("@") {
            for tag in first.dropFirst().split(separator: ";") {
                guard let equals = tag.firstIndex(of: "=") else { continue }
                tags[String(tag[..<equals])] = String(tag[tag.index(after: equals)...])
            }
            parts = parts.dropFirst()
        }

        var prefix: String?
        if let first = parts.first, first.hasPrefix(":") {
            prefix = String(first.dropFirst())
            parts = parts.dropFirst()
        }

        guard let command = parts.first else { throw ParseError.empty(event) }
        parts = parts.dropFirst()

        var parameters: [String] = []
        for (offset, part) in parts.enumerated() {
            if part.hasPrefix(":") {
                parameters.append(String(parts.dropFirst(offset).joined(separator: " ").dropFirst()))
                break
            }
            parameters.append(String(part))
        }

        self.init(raw: event, tags: tags, prefix: prefix, command: String(command), parameters: parameters)
    }

    /// The nick in `nick!user@host`.
    var nick: String? { prefix?.split(separator: "!", maxSplits: 1).first.map(String.init) }

    /// `tmi-sent-ts` as a date, or now when it's missing.
    var sentDate: Date {
        if let ts = tags["tmi-sent-ts"], let millis = Double(ts) { return Date(timeIntervalSince1970: millis / 1000) }
        return Date()
    }
}
