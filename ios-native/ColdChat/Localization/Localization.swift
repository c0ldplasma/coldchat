import Foundation

/// Looks up strings in the language chosen in Settings → Language, or the system language when none is set.
///
/// iOS has its own per-app language setting, but the Flutter app had an in-app picker (including English
/// (Pirate), which no iOS language matches), so this keeps it.
enum Localization {
    private static let lock = NSLock()
    private static var bundle: Bundle = .main

    /// The language tag from the picker, e.g. `de` or `en-PT`, or nil for the system language.
    static func use(_ locale: String?) {
        lock.lock()
        defer { lock.unlock() }
        if let locale, let path = Bundle.main.path(forResource: locale, ofType: "lproj"), let localized = Bundle(path: path) {
            bundle = localized
        } else {
            bundle = .main
        }
    }

    static func string(_ key: String, _ arguments: String...) -> String {
        lock.lock()
        let bundle = self.bundle
        lock.unlock()
        var format = bundle.localizedString(forKey: key, value: nil, table: nil)
        // A language without this string falls back to English instead of showing the key.
        if format == key, bundle != .main {
            format = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        }
        guard !arguments.isEmpty else { return format }
        return String(format: format, arguments: arguments.map { $0 as CVarArg })
    }
}
