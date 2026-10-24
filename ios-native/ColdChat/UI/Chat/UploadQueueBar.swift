import SwiftUI

/// The upload chips above the composer. Takes space only while something uploads, so the composer stays usable.
struct UploadQueueBar: View {
    let channelName: String
    @Environment(UploadQueue.self) private var uploads

    var body: some View {
        let tasks = uploads.tasks(for: channelName)
        if !tasks.isEmpty {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(tasks) { UploadChip(task: $0) }
                }
            }
            .frame(maxHeight: min(CGFloat(tasks.count) * 64, 64 * 3))
        }
    }
}

private struct UploadChip: View {
    let task: UploadTask
    @Environment(UploadQueue.self) private var uploads
    @Environment(\.palette) private var palette
    @State private var showDetails = false

    var body: some View {
        let failed = task.status == .failed
        HStack(spacing: 12) {
            Image(systemName: failed ? "exclamationmark.circle" : "photo").font(.system(size: 18))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.filename).lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: 8)
                    Text(trailingLabel).font(.caption)
                }
                if failed {
                    Button {
                        showDetails = true
                    } label: {
                        (Text("\(errorMessage) · ") + Text(L10n.uploadErrorDetails).underline())
                            .font(.caption)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                } else {
                    if let progress = task.progress {
                        ProgressView(value: progress)
                    } else {
                        // Every byte is out and the host is working on it.
                        ProgressView(value: nil as Double?).progressViewStyle(.linear)
                    }
                    // Only while a later host carries the upload, so switching hosts is never silent.
                    if !task.attempts.isEmpty {
                        Text(L10n.uploadRetryingWith(task.hostName)).font(.caption).lineLimit(1)
                    }
                }
            }
            if failed {
                Button {
                    uploads.retry(task)
                } label: {
                    Image(systemName: "arrow.clockwise").frame(width: 40, height: 40)
                }
                .accessibilityLabel(L10n.uploadRetry)
            }
            Button {
                failed ? uploads.remove(task) : uploads.cancel(task)
            } label: {
                Image(systemName: "xmark").frame(width: 40, height: 40)
            }
            .accessibilityLabel(failed ? L10n.uploadDismiss : L10n.uploadCancel)
        }
        .buttonStyle(.plain)
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 8)
        .background(failed ? palette.errorContainer : Color.white.opacity(0.08))
        .alert(errorMessage, isPresented: $showDetails) {
            Button(L10n.close, role: .cancel) {}
        } message: {
            Text((task.attempts.map { "\($0.hostName): \($0.message)" } + [task.errorDetail].compactMap { $0 }).joined(separator: "\n\n"))
        }
    }

    private var errorMessage: String {
        let host = task.errorHost ?? task.hostName
        switch task.errorKind {
        case .offline: return L10n.uploadErrorOffline
        case .timeout: return L10n.uploadErrorTimeout(host)
        case .rejected: return L10n.uploadErrorRejected(host, task.errorStatus.map(String.init) ?? "?")
        case .badResponse: return L10n.uploadErrorBadResponse(host)
        case .network: return L10n.uploadErrorNetwork(host)
        case .unreadableFile: return L10n.uploadErrorUnreadableFile
        case .unknown, nil: return L10n.uploadErrorUnknown(host)
        }
    }

    private var trailingLabel: String {
        switch task.status {
        case .uploading:
            let percent = task.progress.map { " \(Int(($0 * 100).rounded()))%" } ?? ""
            return L10n.uploadingTo(task.hostName) + percent
        case .processing:
            // Counting the wait makes a slow host read as slow rather than stuck.
            let seconds = task.processingSeconds ?? 0
            return seconds >= 1 ? "\(L10n.uploadProcessing) \(seconds)s" : L10n.uploadProcessing
        case .failed: return L10n.uploadFailed
        case .done: return L10n.uploadDone
        case .cancelled: return ""
        }
    }
}
