import Foundation

/// Why an attempt failed, coarse enough to map to a short message.
enum UploadFailureKind {
    /// No HTTP response at all: DNS, refused, unreachable, TLS. Every host failing like this means offline.
    case network
    /// Stalled mid-upload, no answer after the upload, or the attempt cap.
    case timeout
    /// The host answered with a non-200 status.
    case http
    /// 200, but the body wasn't a link.
    case badResponse
    case unknown
}

struct UploadFailure: Error {
    let hostName: String
    let kind: UploadFailureKind
    /// Technical detail, only shown in the details dialog.
    let message: String
    var statusCode: Int?
}

/// A file host that takes an anonymous multipart upload and answers with the link.
struct UploadHost {
    let name: String
    /// Roughly how long links survive; nil when it's up to the host.
    let retention: TimeInterval?
    let endpoint: URL
    let fileField: String
    var fields: [String: String] = [:]

    /// Tried in order; each is only reached when the previous one failed.
    static let chain: [UploadHost] = [
        // catbox.moe's temporary host. Links expire; 72h is its maximum.
        UploadHost(name: "Litterbox", retention: 72 * 3600, endpoint: .api("https://litterbox.catbox.moe/resources/internals/api.php"), fileField: "fileToUpload", fields: ["reqtype": "fileupload", "time": "72h"]),
        // What Chatterino uploads to by default.
        UploadHost(name: "nuuls", retention: nil, endpoint: .api("https://i.nuuls.com/upload"), fileField: "attachment"),
        // Retention scales with file size, 30 to 365 days.
        UploadHost(name: "0x0.st", retention: 30 * 86400, endpoint: .api("https://0x0.st"), fileField: "file"),
    ]

    /// Writes the multipart body to a file, so the upload streams from disk and reports real progress.
    func makeBody(filename: String, file: URL, boundary: String) throws -> URL {
        let body = FileManager.default.temporaryDirectory.appendingPathComponent("upload-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: body.path, contents: nil)
        let handle = try FileHandle(forWritingTo: body)
        defer { try? handle.close() }
        for (key, value) in fields {
            handle.write(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".utf8))
        }
        let safeName = filename.replacingOccurrences(of: "\"", with: "")
        handle.write(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(fileField)\"; filename=\"\(safeName)\"\r\nContent-Type: \(Self.mimeType(filename))\r\n\r\n".utf8))
        handle.write(try Data(contentsOf: file, options: .mappedIfSafe))
        handle.write(Data("\r\n--\(boundary)--\r\n".utf8))
        return body
    }

    private static func mimeType(_ filename: String) -> String {
        switch (filename as NSString).pathExtension.lowercased() {
        case "jpg", "jpeg": "image/jpeg"
        case "png": "image/png"
        case "gif": "image/gif"
        case "webp": "image/webp"
        case "heic": "image/heic"
        case "mp4": "video/mp4"
        case "mov": "video/quicktime"
        default: "application/octet-stream"
        }
    }

    /// Anything that means no usable HTTP response came back counts as a network failure.
    static func classify(_ error: Error) -> UploadFailureKind {
        guard let urlError = error as? URLError else { return .unknown }
        switch urlError.code {
        case .timedOut: return .timeout
        case .notConnectedToInternet, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .dnsLookupFailed,
             .secureConnectionFailed, .internationalRoamingOff, .dataNotAllowed, .cannotLoadFromNetwork:
            return .network
        default: return .unknown
        }
    }

    static func short(_ body: String) -> String {
        let single = body.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return single.count <= 120 ? single : "\(single.prefix(120))…"
    }
}
