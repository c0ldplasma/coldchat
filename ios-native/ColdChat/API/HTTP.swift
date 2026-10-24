import Foundation

struct HTTPError: LocalizedError {
    let status: Int
    let message: String

    var errorDescription: String? { message.isEmpty ? "HTTP \(status)" : message }
}

enum HTTP {
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        return URLSession(configuration: configuration)
    }()

    static let userAgent = "ColdChat (https://github.com/c0ldplasma/coldchat)"

    static func data(_ url: URL, method: String = "GET", headers: [String: String] = [:], body: Data? = nil) async throws -> (Data, Int) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        let (data, response) = try await session.data(for: request)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    // These are nonisolated async functions, so the decoding below runs off the main thread.

    static func json<T: Decodable>(_ type: T.Type, from url: URL, headers: [String: String] = [:]) async throws -> T {
        let (data, status) = try await data(url, headers: headers)
        guard (200..<300).contains(status) else { throw HTTPError(status: status, message: "") }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Untyped JSON, for responses where only a few fields matter.
    static func object(_ url: URL, method: String = "GET", headers: [String: String] = [:], body: Data? = nil) async throws -> (Any, Int) {
        let (data, status) = try await data(url, method: method, headers: headers, body: body)
        if data.isEmpty { return ([String: Any](), status) }
        return ((try? JSONSerialization.jsonObject(with: data)) ?? [String: Any](), status)
    }
}

extension URL {
    /// For URLs built from constants and already-encoded parts.
    static func api(_ string: String) -> URL {
        URL(string: string)!
    }
}
