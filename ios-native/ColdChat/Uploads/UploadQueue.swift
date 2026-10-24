import Foundation
import Observation

/// What the failed chip tells the user, one short line each.
enum UploadErrorKind {
    /// Every host failed without a single HTTP response: the phone is offline.
    case offline
    case timeout
    /// The host answered but refused.
    case rejected
    /// The host answered 200 without a link.
    case badResponse
    /// This host couldn't be reached while others behaved differently.
    case network
    /// The picked file couldn't be read; no host was tried.
    case unreadableFile
    case unknown
}

enum UploadStatus {
    /// Bytes are going out; `progress` is meaningful.
    case uploading
    /// Every byte is out and the host hasn't answered yet. Shown indeterminate.
    case processing
    case done
    case failed
    case cancelled
}

/// One file on its way to a host.
@MainActor
@Observable
final class UploadTask: Identifiable {
    let id = UUID()
    let filename: String
    /// Kept so a failed upload can be retried without picking the file again.
    let file: URL
    /// Uploads stay bound to where they started, so switching tabs can't drop a link into another chat.
    let channelName: String

    var status: UploadStatus = .uploading
    var sent: Int64 = 0
    var size: Int64 = 0
    /// The host being tried, for "uploading to Litterbox…".
    var hostName: String
    /// Every host that failed in this run. Non-empty while uploading means the chain moved on.
    var attempts: [UploadFailure] = []
    var url: String?
    var errorKind: UploadErrorKind?
    var errorHost: String?
    var errorStatus: Int?
    /// Detail when no host was involved, e.g. the file couldn't be read.
    var errorDetail: String?
    /// Re-renders the processing timer once a second.
    var tick = 0

    @ObservationIgnored var lastProgressAt = Date()
    @ObservationIgnored var processingSince: Date?
    @ObservationIgnored var attemptStartedAt = Date()
    /// Why the watchdog aborted the attempt. Cancelling surfaces as a generic error, so the reason is kept here.
    @ObservationIgnored var abortFailure: UploadFailure?
    @ObservationIgnored var attempt: Task<String, Error>?

    init(filename: String, file: URL, channelName: String, hostName: String) {
        self.filename = filename
        self.file = file
        self.channelName = channelName
        self.hostName = hostName
    }

    var progress: Double? {
        guard status == .uploading, size > 0 else { return nil }
        return min(1, max(0, Double(sent) / Double(size)))
    }

    /// Whole seconds spent waiting on the host.
    var processingSeconds: Int? {
        guard status == .processing, let processingSince else { return nil }
        _ = tick
        return Int(Date().timeIntervalSince(processingSince))
    }
}

/// Every upload in flight. Lives above the channel views so an upload survives switching tabs, and the composer
/// never waits on it: finished links show up in `finished` for the channel's composer to insert.
@MainActor
@Observable
final class UploadQueue {
    private(set) var tasks: [UploadTask] = []
    /// Links waiting to be inserted, by channel name.
    var finished: [String: [String]] = [:]

    private static let stallTimeout: TimeInterval = 45
    /// How long to wait for the host once every byte is out.
    private static let processingTimeout: TimeInterval = 60
    private static let attemptTimeout: TimeInterval = 300

    @ObservationIgnored private var watchdog: Timer?

    func tasks(for channelName: String) -> [UploadTask] { tasks.filter { $0.channelName == channelName } }

    /// Copies [file] somewhere it survives for a retry, then uploads it.
    func upload(file: URL, filename: String, channelName: String) {
        let task = UploadTask(filename: filename, file: file, channelName: channelName, hostName: UploadHost.chain[0].name)
        tasks.append(task)
        ensureWatchdog()
        Task { await runChain(task) }
    }

    func upload(data: Data, filename: String, channelName: String) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("uploads", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("\(UUID().uuidString)-\(filename)")
        do {
            try data.write(to: file)
        } catch {
            let task = UploadTask(filename: filename, file: file, channelName: channelName, hostName: UploadHost.chain[0].name)
            tasks.append(task)
            failUnreadable(task, error)
            return
        }
        upload(file: file, filename: filename, channelName: channelName)
    }

    func retry(_ task: UploadTask) {
        Task { await runChain(task) }
    }

    func cancel(_ task: UploadTask) {
        task.status = .cancelled
        task.attempt?.cancel()
        remove(task)
    }

    func remove(_ task: UploadTask) {
        tasks.removeAll { $0 === task }
        if task.status != .uploading && task.status != .processing { try? FileManager.default.removeItem(at: task.file) }
        if tasks.isEmpty {
            watchdog?.invalidate()
            watchdog = nil
        }
    }

    /// Walks the host chain until one succeeds. Only a failure moves on; cancelling stops everything.
    private func runChain(_ task: UploadTask) async {
        guard FileManager.default.isReadableFile(atPath: task.file.path) else {
            failUnreadable(task, CocoaError(.fileReadNoSuchFile))
            return
        }
        task.attempts = []
        task.errorKind = nil
        task.errorHost = nil
        task.errorStatus = nil
        task.errorDetail = nil
        ensureWatchdog()

        for (index, host) in UploadHost.chain.enumerated() {
            if task.status == .cancelled { return }
            task.hostName = host.name
            task.sent = 0
            task.status = .uploading
            task.lastProgressAt = Date()
            task.attemptStartedAt = Date()
            task.processingSince = nil
            task.abortFailure = nil

            let attempt = Task { try await self.upload(task, to: host) }
            task.attempt = attempt
            do {
                let url = try await attempt.value
                if task.status == .cancelled { return }
                task.status = .done
                task.url = url
                finished[task.channelName, default: []].append(url)
                remove(task)
                try? FileManager.default.removeItem(at: task.file)
                return
            } catch {
                if task.status == .cancelled { return }
                // Prefer the watchdog's reason: cancelling to abort shows up here as an opaque error.
                let failure = task.abortFailure ?? (error as? UploadFailure) ?? UploadFailure(hostName: host.name, kind: UploadHost.classify(error), message: error.localizedDescription)
                task.attempts.append(failure)
                if index == UploadHost.chain.count - 1 { failChain(task) }
            }
        }
    }

    private func upload(_ task: UploadTask, to host: UploadHost) async throws -> String {
        let boundary = "ColdChat-\(UUID().uuidString)"
        let body = try host.makeBody(filename: task.filename, file: task.file, boundary: boundary)
        defer { try? FileManager.default.removeItem(at: body) }

        var request = URLRequest(url: host.endpoint)
        request.httpMethod = "POST"
        // Some hosts (notably 0x0.st) reject generic user agents.
        request.setValue(HTTP.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Self.attemptTimeout

        let delegate = ProgressDelegate { [weak task] sent, total in
            Task { @MainActor in
                guard let task, task.status != .cancelled else { return }
                task.sent = sent
                task.size = total
                task.lastProgressAt = Date()
                if sent >= total && task.status == .uploading {
                    task.status = .processing
                    task.processingSince = Date()
                }
            }
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await HTTP.session.upload(for: request, fromFile: body, delegate: delegate)
        } catch {
            throw UploadFailure(hostName: host.name, kind: UploadHost.classify(error), message: error.localizedDescription)
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let text = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard status == 200 else {
            throw UploadFailure(hostName: host.name, kind: .http, message: "HTTP \(status): \(UploadHost.short(text))", statusCode: status)
        }
        guard text.hasPrefix("http") else {
            throw UploadFailure(hostName: host.name, kind: .badResponse, message: "unexpected response: \(UploadHost.short(text))")
        }
        return text
    }

    /// Turns the per-host failures into the one thing worth telling the user. Offline is decided at the end: one
    /// host's failed lookup can just mean its domain is dead, and bailing early would skip the fallback.
    private func failChain(_ task: UploadTask) {
        guard let last = task.attempts.last else { return }
        // A drop mid-upload shows as a stall on the host carrying it, then instant network errors on the rest.
        let offline = last.kind == .network && task.attempts.allSatisfy { $0.kind == .network || $0.kind == .timeout }
        let kind: UploadErrorKind = switch last.kind {
        case .network: .network
        case .timeout: .timeout
        case .http: .rejected
        case .badResponse: .badResponse
        case .unknown: .unknown
        }
        task.errorKind = offline ? .offline : kind
        task.errorHost = last.hostName
        task.errorStatus = last.statusCode
        task.status = .failed
    }

    private func failUnreadable(_ task: UploadTask, _ error: Error) {
        task.errorKind = .unreadableFile
        task.errorDetail = error.localizedDescription
        task.status = .failed
    }

    /// A socket that goes quiet produces no error, the request just hangs. This aborts it so the chain can move on.
    /// Ticks every second because it also drives the elapsed-seconds label.
    private func ensureWatchdog() {
        guard watchdog == nil else { return }
        watchdog = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkStalls() }
        }
    }

    private func checkStalls() {
        let now = Date()
        for task in tasks {
            switch task.status {
            case .uploading:
                if now.timeIntervalSince(task.lastProgressAt) > Self.stallTimeout {
                    abort(task, UploadFailure(hostName: task.hostName, kind: .timeout, message: "stalled for \(Int(Self.stallTimeout))s"))
                }
            case .processing:
                task.tick += 1
                if let since = task.processingSince, now.timeIntervalSince(since) > Self.processingTimeout {
                    abort(task, UploadFailure(hostName: task.hostName, kind: .timeout, message: "no response \(Int(Self.processingTimeout))s after upload"))
                }
            default:
                break
            }
            if (task.status == .uploading || task.status == .processing) && now.timeIntervalSince(task.attemptStartedAt) > Self.attemptTimeout {
                abort(task, UploadFailure(hostName: task.hostName, kind: .timeout, message: "timed out after \(Int(Self.attemptTimeout))s"))
            }
        }
    }

    private func abort(_ task: UploadTask, _ reason: UploadFailure) {
        guard task.abortFailure == nil else { return }
        task.abortFailure = reason
        task.attempt?.cancel()
    }
}

private final class ProgressDelegate: NSObject, URLSessionTaskDelegate {
    let onProgress: (Int64, Int64) -> Void

    init(onProgress: @escaping (Int64, Int64) -> Void) {
        self.onProgress = onProgress
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        onProgress(totalBytesSent, totalBytesExpectedToSend)
    }
}
