import PhotosUI
import SwiftUI

/// What the message sheet can do to the composer of the channel it was opened from.
struct ComposerActions {
    var reply: (ChannelMessageChat) -> Void = { _ in }
    /// Appends a word, e.g. `@login`.
    var addWord: (String) -> Void = { _ in }
}

private struct ComposerActionsKey: EnvironmentKey {
    static let defaultValue: ComposerActions? = nil
}

extension EnvironmentValues {
    var composer: ComposerActions? {
        get { self[ComposerActionsKey.self] }
        set { self[ComposerActionsKey.self] = newValue }
    }
}

/// A channel's chat with the composer under it.
struct ChannelView: View {
    let channel: Channel

    @Environment(AppSettings.self) private var settings
    @Environment(UploadQueue.self) private var uploads
    @Environment(\.palette) private var palette

    @State private var text = ""
    @State private var selection: TextSelection?
    @FocusState private var focused: Bool
    @State private var reply: ChannelMessageChat?
    @State private var emotePicker = false
    /// The emote menu is open to choose the button's emote (long-press on it).
    @State private var pickingButtonIcon = false
    /// Keeps the text after sending, for repeating a message.
    @State private var spamming = false
    @State private var attachChoice = false
    @State private var camera = false
    @State private var library = false
    @State private var libraryItems: [PhotosPickerItem] = []
    @State private var cameraUnavailable = false

    var body: some View {
        VStack(spacing: 0) {
            ChatView(channel: channel)
                .contentShape(Rectangle())
                .onTapGesture { focused = false }
            composer
        }
        // Sheets opened from this chat see its composer. The host goes inside the environment below so the sheet
        // inherits it.
        .routeHost()
        .environment(\.composer, ComposerActions(
            reply: { reply = $0; focused = true },
            addWord: { word in
                let words = (text.split(separator: " ").map(String.init) + [word]).filter { !$0.isEmpty }
                text = words.joined(separator: " ")
                focused = true
            }
        ))
        .onChange(of: uploads.finished[channel.name] ?? []) { _, urls in
            guard !urls.isEmpty else { return }
            uploads.finished[channel.name] = nil
            urls.forEach(insertUploaded)
        }
        .confirmationDialog("", isPresented: $attachChoice, titleVisibility: .hidden) {
            Button(L10n.takePhoto) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) { camera = true } else { cameraUnavailable = true }
            }
            Button(L10n.chooseFromLibrary) { library = true }
        }
        .photosPicker(isPresented: $library, selection: $libraryItems, maxSelectionCount: 10, matching: .images)
        .onChange(of: libraryItems) { _, items in
            guard !items.isEmpty else { return }
            libraryItems = []
            for item in items { Task { await upload(item) } }
        }
        .fullScreenCover(isPresented: $camera) {
            CameraPicker { image in
                if let data = image.jpegData(compressionQuality: 0.9) {
                    uploads.upload(data: data, filename: "photo-\(Int(Date().timeIntervalSince1970)).jpg", channelName: channel.name)
                }
            }
            .ignoresSafeArea()
        }
        .alert(L10n.cameraUnavailable, isPresented: $cameraUnavailable) {
            Button(L10n.close, role: .cancel) {}
        }
    }

    // MARK: Composer

    private var composer: some View {
        VStack(spacing: 0) {
            UploadQueueBar(channelName: channel.name)
            if let reply {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.replyingTo).font(.caption)
                        MessageContent(message: reply).lineLimit(2)
                    }
                    Spacer()
                    Button {
                        self.reply = nil
                    } label: {
                        Image(systemName: "xmark").frame(width: 40, height: 40).background(Color.white.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(palette.errorContainer)
            }
            autocompletion
            HStack(spacing: 0) {
                Button {
                    attachChoice = true
                } label: {
                    Image(systemName: "photo").frame(width: 48, height: 48)
                }
                TextField(L10n.sendMessageIn(channel.name), text: $text, selection: $selection)
                    .focused($focused)
                    // Autocorrect turns emote names into words.
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.send)
                    .onSubmit {
                        send()
                        focused = true
                    }
                    .padding(.horizontal, 4)
                EmoteButtonIconView()
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.22)) {
                            emotePicker.toggle()
                            pickingButtonIcon = false
                        }
                    }
                    .onLongPressGesture {
                        withAnimation(.easeOut(duration: 0.22)) {
                            emotePicker = true
                            pickingButtonIcon = true
                        }
                    }
                    .accessibilityElement()
                    .accessibilityLabel(L10n.emoteMenuButton)
                    .accessibilityAddTraits(.isButton)
                Image(systemName: spamming ? "paperplane.circle" : "paperplane")
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
                    .onTapGesture { send() }
                    .onLongPressGesture { spamming.toggle() }
            }
            .buttonStyle(.plain)
            .frame(height: 48)
            if emotePicker {
                EmotePicker(channel: channel, pickingButtonIcon: pickingButtonIcon) { emote in
                    insert(emote.text)
                } onPickButtonIcon: { done in
                    if done {
                        withAnimation {
                            emotePicker = false
                            pickingButtonIcon = false
                        }
                    }
                }
                .frame(height: 350)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .foregroundStyle(palette.barForeground)
        .tint(palette.barForeground)
        .background(palette.barBackground.ignoresSafeArea(edges: .bottom))
        .environment(\.colorScheme, .dark)
    }

    // MARK: Autocompletion

    private struct Completion: Identifiable {
        enum Kind { case user(ChatUser), command(CustomCommand), emote(Emote) }
        let id: String
        let kind: Kind
        let title: String
        let subtitle: String?
        let insert: String
    }

    private var completions: [Completion] {
        let lastWord = text.split(separator: " ", omittingEmptySubsequences: false).last.map(String.init) ?? ""
        guard lastWord.count >= 2 else { return [] }
        let search = lastWord.lowercased()

        let emotes = channel.emotes + channel.client.globalEmotes + channel.client.twitchUserEmotes
        let matching = emotes.filter { (!settings.emoteAutocompletionWithColon || search.hasPrefix(":")) && ":\($0.name):".lowercased().contains(search) }
        // Names starting with the search first, then the ones matching further in.
        let prefix = search.hasPrefix(":") ? search : ":\(search)"
        let sortedEmotes = matching.filter { ":\($0.name):".lowercased().hasPrefix(prefix) } + matching.filter { !":\($0.name):".lowercased().hasPrefix(prefix) }

        let users = channel.recentChatters.filter { (!settings.userAutocompletionWithAt || search.hasPrefix("@")) && "@\($0.login ?? "")".lowercased().contains(search) }
        let commands = settings.customCommands.filter { $0.trigger.lowercased().hasPrefix(text.lowercased()) }

        var seen: Set<String> = []
        var result: [Completion] = []
        func add(_ completion: Completion) {
            if seen.insert(completion.id).inserted { result.append(completion) }
        }
        for user in users {
            add(Completion(id: "u-\(user.login ?? "")", kind: .user(user), title: user.name, subtitle: user.login, insert: user.login ?? ""))
        }
        for command in commands {
            add(Completion(id: "c-\(command.id)", kind: .command(command), title: command.trigger, subtitle: command.command, insert: command.trigger))
        }
        for emote in sortedEmotes.prefix(100) {
            add(Completion(id: "e-\(emote.provider.rawValue)-\(emote.id)", kind: .emote(emote), title: emote.name, subtitle: emote.provider.name, insert: emote.text))
        }
        return result
    }

    @ViewBuilder private var autocompletion: some View {
        let items = completions
        if !items.isEmpty {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        Button {
                            var words = text.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
                            if !words.isEmpty { words.removeLast() }
                            words.append("\(item.insert) ")
                            text = words.joined(separator: " ")
                        } label: {
                            HStack(spacing: 16) {
                                completionIcon(item.kind).frame(width: 36, height: 36)
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                    if let subtitle = item.subtitle { Text(subtitle).font(.caption).opacity(0.75).lineLimit(1) }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: min(CGFloat(items.count) * 56, 56 * 4.5))
            .background(palette.secondaryContainer)
        }
    }

    @ViewBuilder private func completionIcon(_ kind: Completion.Kind) -> some View {
        switch kind {
        case .user: Image(systemName: "person")
        case .command: Image(systemName: "command")
        case .emote(let emote): EmoteView(emote: emote, scale: 0.75)
        }
    }

    // MARK: Sending

    private func send() {
        var message = text
        let words = message.trimmingCharacters(in: .whitespaces).split(separator: " ").map(String.init)
        if let first = words.first, let command = settings.customCommands.first(where: { $0.trigger.lowercased() == first.lowercased() }) {
            message = Self.expand(command.command, words: words)
        }
        guard !message.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var tags: [String: String] = [:]
        if let id = reply?.messageId { tags["reply-parent-msg-id"] = id }
        channel.send(message, tags: tags)
        reply = nil
        if !spamming { text = "" }
    }

    /// `{1}` is the first argument, `{2+}` the second and everything after it.
    static func expand(_ command: String, words: [String]) -> String {
        var result = command
        let single = try! NSRegularExpression(pattern: #"\{(\d*)\}"#)
        let rest = try! NSRegularExpression(pattern: #"\{(\d*)\+\}"#)
        func replace(_ regex: NSRegularExpression, _ value: (Int) -> String) {
            let ns = result as NSString
            var output = ""
            var last = 0
            for match in regex.matches(in: result, range: NSRange(location: 0, length: ns.length)) {
                output += ns.substring(with: NSRange(location: last, length: match.range.location - last))
                let index = Int(ns.substring(with: match.range(at: 1))) ?? -1
                output += index > 0 && index < words.count ? value(index) : ""
                last = match.range.location + match.range.length
            }
            output += ns.substring(from: last)
            result = output
        }
        replace(single) { words[$0] }
        replace(rest) { words[$0...].joined(separator: " ") }
        return result
    }

    /// Inserts at the caret with spaces around it as needed.
    private func insert(_ word: String) {
        let caret: String.Index
        if case .selection(let range) = selection?.indices {
            caret = range.upperBound
        } else {
            caret = text.endIndex
        }
        var insertion = word
        if caret == text.endIndex || text[caret] != " " { insertion += " " }
        if caret > text.startIndex, text[text.index(before: caret)] != " " { insertion = " " + insertion }
        let offset = text.distance(from: text.startIndex, to: caret) + insertion.count
        text.insert(contentsOf: insertion, at: caret)
        let newCaret = text.index(text.startIndex, offsetBy: offset)
        selection = TextSelection(insertionPoint: newCaret)
    }

    /// Drops a finished upload's link where the caret is, keeping whatever was typed in the meantime.
    private func insertUploaded(_ url: String) {
        insert(url)
    }

    private func upload(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        let type = item.supportedContentTypes.first
        // HEIC isn't accepted everywhere; anything but GIF and PNG becomes JPEG.
        if let type, type.conforms(to: .gif) {
            uploads.upload(data: data, filename: "image-\(Int(Date().timeIntervalSince1970)).gif", channelName: channel.name)
        } else if let type, type.conforms(to: .png) {
            uploads.upload(data: data, filename: "image-\(Int(Date().timeIntervalSince1970)).png", channelName: channel.name)
        } else if let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.9) {
            uploads.upload(data: jpeg, filename: "image-\(Int(Date().timeIntervalSince1970)).jpg", channelName: channel.name)
        }
    }
}

/// The system camera.
struct CameraPicker: UIViewControllerRepresentable {
    let onPick: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onPick(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
