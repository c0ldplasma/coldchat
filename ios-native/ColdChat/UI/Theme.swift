import SwiftUI

/// The colors the screens use, derived from the theme color picked in Settings → Theme. The Flutter app built a
/// Material 3 scheme from the same seed; this keeps its roles (containers for chips, a dark bar at the bottom)
/// on top of the system colors.
struct Palette {
    let primary: Color
    let primaryContainer: Color
    let secondaryContainer: Color
    let tertiary: Color
    let tertiaryContainer: Color
    let errorContainer: Color
    let surfaceVariant: Color
    let background: Color
    let barBackground: Color
    let barForeground: Color

    init(seed: Color, highContrast: Bool) {
        let ui = UIColor(seed)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        ui.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let tertiaryHue = (hue + 1.0 / 6.0).truncatingRemainder(dividingBy: 1)

        primary = seed
        primaryContainer = seed.opacity(0.22)
        secondaryContainer = Color(hue: hue, saturation: saturation * 0.35, brightness: brightness).opacity(0.22)
        tertiary = Color(hue: tertiaryHue, saturation: max(0.35, saturation * 0.7), brightness: max(0.55, brightness))
        tertiaryContainer = tertiary.opacity(0.22)
        errorContainer = Color.red.opacity(0.22)
        surfaceVariant = Color(uiColor: .secondarySystemBackground)
        background = highContrast
            ? Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? .black : .white })
            : Color(uiColor: .systemBackground)
        // Always dark, tinted with the theme, like the Flutter app's bottom bar.
        barBackground = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(hue: hue, saturation: saturation * 0.25, brightness: highContrast ? 0 : 0.06, alpha: 1)
                : UIColor(hue: hue, saturation: saturation * 0.3, brightness: 0.18, alpha: 1)
        })
        barForeground = .white
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette(seed: .blue, highContrast: false)
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

extension AppSettings {
    var accentColor: Color { Color(argb: themeColor) }

    var colorScheme: ColorScheme? {
        switch themeMode {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }

    var palette: Palette { Palette(seed: accentColor, highContrast: highContrast) }

    /// Body text size in chat, scaled by Settings → Message appearance.
    var messageFontSize: CGFloat { 15 * messageScale }
}

extension Color {
    init(argb: UInt32) {
        self.init(
            .sRGB,
            red: Double((argb >> 16) & 0xFF) / 255,
            green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255,
            opacity: Double((argb >> 24) & 0xFF) / 255
        )
    }

    init(rgb: UInt32) {
        self.init(argb: 0xFF00_0000 | rgb)
    }
}

/// The Material palette the Flutter app offered under Settings → Theme, with the same names and values.
enum ThemeColors {
    static let all: [(name: String, argb: UInt32)] = [
        ("redAccent", 0xFFFF5252), ("red", 0xFFF44336), ("pinkAccent", 0xFFFF4081), ("pink", 0xFFE91E63),
        ("purpleAccent", 0xFFE040FB), ("purple", 0xFF9C27B0), ("deepPurpleAccent", 0xFF7C4DFF), ("deepPurple", 0xFF673AB7),
        ("indigoAccent", 0xFF536DFE), ("indigo", 0xFF3F51B5), ("blueAccent", 0xFF448AFF), ("blue", 0xFF2196F3),
        ("lightBlueAccent", 0xFF40C4FF), ("lightBlue", 0xFF03A9F4), ("cyanAccent", 0xFF18FFFF), ("cyan", 0xFF00BCD4),
        ("tealAccent", 0xFF64FFDA), ("teal", 0xFF009688), ("greenAccent", 0xFF69F0AE), ("green", 0xFF4CAF50),
        ("lightGreenAccent", 0xFFB2FF59), ("lightGreen", 0xFF8BC34A), ("limeAccent", 0xFFEEFF41), ("lime", 0xFFCDDC39),
        ("yellowAccent", 0xFFFFFF00), ("yellow", 0xFFFFEB3B), ("amberAccent", 0xFFFFD740), ("amber", 0xFFFFC107),
        ("orangeAccent", 0xFFFFAB40), ("orange", 0xFFFF9800), ("deepOrangeAccent", 0xFFFF6E40), ("deepOrange", 0xFFFF5722),
        ("brown", 0xFF795548), ("blueGrey", 0xFF607D8B),
    ]
}

/// A plain list row button that reacts to taps anywhere in the row, not only on its text and icons.
struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

extension ButtonStyle where Self == RowButtonStyle {
    static var row: RowButtonStyle { RowButtonStyle() }
}

extension View {
    /// The rounded tinted chip used for notices, bans and subs in chat.
    func chip(_ color: Color, radius: CGFloat = 18) -> some View {
        background(color, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
