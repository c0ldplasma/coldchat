import Observation
import SwiftUI

/// The emote on the button that opens the emote menu. Defaults to Kappa.
///
/// Image emotes are downloaded once into Application Support, so the button survives the emote leaving its
/// provider, the image cache being purged, and being offline. Emojis are stored as text.
@MainActor
@Observable
final class EmoteButtonIcon {
    static let shared = EmoteButtonIcon()

    private static let key = "emoteButtonIcon"
    private let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("emote_button", isDirectory: true)

    private(set) var name: String?
    private(set) var emoji: String?
    private(set) var image: UIImage?
    private var fileName: String?

    private init() {
        let stored = UserDefaults.standard.dictionary(forKey: Self.key) as? [String: String]
        name = stored?["name"]
        emoji = stored?["emoji"]
        fileName = stored?["file"]
        if let fileName, let data = try? Data(contentsOf: directory.appendingPathComponent(fileName)) {
            image = ImageLoader.decode(data, maxPixelSize: 144)
        }
    }

    /// Downloads [emote] and makes it the button. Throws when it can't be downloaded or isn't an image; the
    /// current button stays then.
    func set(_ emote: Emote) async throws {
        if emote.isEmoji, let code = emote.code {
            replace(name: emote.name, emoji: code, fileName: nil, image: nil)
            return
        }
        guard let url = emote.largestURL else { throw URLError(.badURL) }
        let (data, status) = try await HTTP.data(url)
        guard status == 200, !data.isEmpty, let decoded = ImageLoader.decode(data, maxPixelSize: 144) else { throw URLError(.cannotDecodeContentData) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = "\(Int(Date().timeIntervalSince1970 * 1000))"
        try data.write(to: directory.appendingPathComponent(file), options: .atomic)
        replace(name: emote.name, emoji: nil, fileName: file, image: decoded)
    }

    func reset() {
        replace(name: nil, emoji: nil, fileName: nil, image: nil)
    }

    private func replace(name: String?, emoji: String?, fileName: String?, image: UIImage?) {
        if let previous = self.fileName, previous != fileName {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(previous))
        }
        self.name = name
        self.emoji = emoji
        self.fileName = fileName
        self.image = image
        if name == nil {
            UserDefaults.standard.removeObject(forKey: Self.key)
        } else {
            UserDefaults.standard.set(["name": name, "emoji": emoji, "file": fileName].compactMapValues { $0 }, forKey: Self.key)
        }
    }
}

/// The emote menu button's icon: the chosen emote or emoji, or Kappa.
struct EmoteButtonIconView: View {
    var size: CGFloat = 24
    @Environment(AppSettings.self) private var settings
    private var icon = EmoteButtonIcon.shared

    init(size: CGFloat = 24) {
        self.size = size
    }

    var body: some View {
        Group {
            if let image = icon.image {
                AnimatedImageView(image: image).frame(width: size, height: size)
            } else if let emoji = icon.emoji {
                Text(emoji).font(.system(size: size * 0.85)).frame(width: size, height: size)
            } else {
                Image("Kappa").resizable().interpolation(.medium).scaledToFit().frame(width: size, height: size)
            }
        }
        .grayscale(settings.emoteButtonGrayscale ? 1 : 0)
    }
}
