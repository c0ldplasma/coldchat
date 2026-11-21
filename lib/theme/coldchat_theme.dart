import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import '../l10n/app_localizations.dart';

/// One of the accent colors users can pick in Settings → Accent color.
///
/// The accent only changes the primary color: the selected tab, the send button, the cursor, highlighted mentions,
/// toggles and checkmarks. The backgrounds and everything else stay Indigo's in every accent ([ColdChatTheme.base]).
/// An earlier version tinted the backgrounds too, which can't work for warm colors: a dark pink, red, orange or
/// yellow reads as maroon, brown or olive, never as the color itself.
///
/// An accent is a hue and a chroma (colorfulness) in HCT, Material's perceptual color space, rather than a seed
/// color, so each one keeps its saturation: [ColorScheme.fromSeed] fixes chroma at 36, which made pink look dusty.
///
/// Stored by [id] (see `SettingsRepository.accent`), which never changes; the order and names may.
class AccentColor {
  final String id;
  final double hue;
  final double chroma;

  const AccentColor(this.id, this.hue, this.chroma);

  String name(AppLocalizations l10n) => switch (id) {
    'ice' => l10n.themeIce,
    'indigo' => l10n.themeIndigo,
    'blue' => l10n.themeBlue,
    'teal' => l10n.themeTeal,
    'green' => l10n.themeGreen,
    'lime' => l10n.themeLime,
    'amber' => l10n.themeAmber,
    'orange' => l10n.themeOrange,
    'red' => l10n.themeRed,
    'pink' => l10n.themePink,
    'purple' => l10n.themePurple,
    ColdChatTheme.customId => l10n.customColor,
    _ => id,
  };

  /// The full color scheme with this accent, as the app uses it.
  ColorScheme colorScheme(Brightness brightness, {bool highContrast = false, bool oledBlack = false}) {
    var scheme = _toColorScheme(_dynamicScheme(brightness), brightness);
    if (highContrast) {
      // Only text and outlines get Material's high-contrast tones. At full contrast Material also pushes the accent
      // to nearly white and the surfaces to the extremes, which erased the accent color entirely.
      final contrast = _toColorScheme(_dynamicScheme(brightness, highContrast: true), brightness);
      scheme = scheme.copyWith(
        onSurface: contrast.onSurface,
        onSurfaceVariant: contrast.onSurfaceVariant,
        outline: contrast.outline,
        outlineVariant: contrast.outlineVariant,
      );
    }
    return brightness == Brightness.dark && oledBlack ? _oled(scheme) : scheme;
  }

  DynamicScheme _dynamicScheme(Brightness brightness, {bool highContrast = false}) {
    const base = ColdChatTheme.base;
    return DynamicScheme(
      sourceColorHct: Hct.from(hue, chroma, 50.0),
      variant: Variant.tonalSpot,
      contrastLevel: highContrast ? 1.0 : 0.0,
      isDark: brightness == Brightness.dark,
      primaryPalette: TonalPalette.of(hue, chroma),
      // The rest is Material's tonal spot scheme for Indigo, which is what ColdChat has always looked like.
      secondaryPalette: TonalPalette.of(base.hue, 16.0),
      tertiaryPalette: TonalPalette.of(MathUtils.sanitizeDegreesDouble(base.hue + 60.0), 24.0),
      neutralPalette: _neutral,
      neutralVariantPalette: TonalPalette.of(base.hue, 8.0),
    );
  }

  static final TonalPalette _neutral = TonalPalette.of(ColdChatTheme.base.hue, 6.0);

  /// Dark mode for OLED screens: the chat (the surface) is pure black, and everything that sits on it, like the
  /// containers, gets a few tones lighter than usual so it still stands apart from black.
  static ColorScheme _oled(ColorScheme scheme) {
    Color tone(double t) => Color(_neutral.get(t.round()));
    return scheme.copyWith(
      surface: Colors.black,
      surfaceDim: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: tone(6.0),
      surfaceContainer: tone(10.0),
      surfaceContainerHigh: tone(14.0),
      surfaceContainerHighest: tone(18.0),
    );
  }
}

/// The single place ColdChat's colors come from: the accents and the [ThemeData] built from them.
abstract final class ColdChatTheme {
  /// The palette all backgrounds come from, whatever the accent.
  static const AccentColor base = AccentColor('indigo', 279.0, 36.0);

  /// The default accent: the icy blue of ColdChat's snowflake icon (its colors sit at hue 215–262, chroma 30–44).
  /// It's 45° away from the Indigo backgrounds, so it reads as a color of its own; Indigo as the accent was the
  /// backgrounds' own hue and looked like slightly tinted white text.
  static const AccentColor defaultAccent = AccentColor('ice', 235.0, 44.0);

  static const List<AccentColor> accents = [
    defaultAccent,
    // Exactly the scheme ColorScheme.fromSeed(Colors.indigo) produced, so people who had picked it see no change.
    base,
    AccentColor('blue', 255.0, 48.0),
    AccentColor('teal', 185.0, 40.0),
    AccentColor('green', 145.0, 48.0),
    AccentColor('lime', 120.0, 56.0),
    AccentColor('amber', 85.0, 56.0),
    AccentColor('orange', 55.0, 64.0),
    AccentColor('red', 25.0, 72.0),
    AccentColor('pink', 350.0, 64.0),
    AccentColor('purple', 305.0, 56.0),
  ];

  static AccentColor accentById(String? id) => accents.firstWhere((a) => a.id == id, orElse: () => defaultAccent);

  /// A color the user mixed from a hue and a saturation (chroma). Only those two are stored: the lightness of every
  /// accent comes from the mode, which is what keeps any choice readable.
  static const String customId = 'custom';

  /// Chroma beyond this is out of gamut for most hues at the tones the scheme uses, so the slider stops here.
  static const double maxChroma = 80.0;

  static AccentColor custom(double hue, double chroma) => AccentColor(customId, hue, chroma);

  /// The color wheel on the custom accent's swatch before a custom color is picked.
  static const customAccentWheel = SweepGradient(
    colors: [
      Color(0xFFFF5A5A),
      Color(0xFFFFC23D),
      Color(0xFF7BD86B),
      Color(0xFF3FC9D9),
      Color(0xFF6B7CFF),
      Color(0xFFD86BE0),
      Color(0xFFFF5A5A),
    ],
  );

  /// The accent whose hue is closest to [color]'s. Greys and brown-greys (Blue Grey, Brown) get the default.
  static AccentColor closestAccent(Color color) {
    final hct = Hct.fromInt(color.toARGB32());
    if (hct.chroma < 16.0) return defaultAccent;
    double distance(AccentColor a) {
      final d = (a.hue - hct.hue).abs() % 360.0;
      return d > 180.0 ? 360.0 - d : d;
    }

    return accents.reduce((a, b) => distance(b) < distance(a) ? b : a);
  }

  /// Narrows Google Sans Flex and sets its optical size so it matches the Product Sans the app used before.
  /// Weight is left to [TextStyle.fontWeight]: an explicit `wght` here would override it.
  static const fontVariations = [FontVariation('wdth', 94), FontVariation('opsz', 22)];

  static ThemeData build(
    AccentColor accent,
    Brightness brightness, {
    bool highContrast = false,
    bool oledBlack = false,
  }) {
    final oled = oledBlack && brightness == Brightness.dark;
    final scheme = accent.colorScheme(brightness, highContrast: highContrast, oledBlack: oled);
    final base = ThemeData(colorScheme: scheme, brightness: brightness);
    return base.copyWith(
      extensions: [ChatColors.from(scheme, oledBlack: oled)],
      textTheme: _withFontVariations(
        base.textTheme.apply(
          fontFamily: 'GoogleSansFlex',
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
          decorationColor: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      checkboxTheme: base.checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.all(scheme.primary),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static TextTheme _withFontVariations(TextTheme textTheme) {
    TextStyle? apply(TextStyle? style) => style?.copyWith(fontVariations: fontVariations);
    return TextTheme(
      displayLarge: apply(textTheme.displayLarge),
      displayMedium: apply(textTheme.displayMedium),
      displaySmall: apply(textTheme.displaySmall),
      headlineLarge: apply(textTheme.headlineLarge),
      headlineMedium: apply(textTheme.headlineMedium),
      headlineSmall: apply(textTheme.headlineSmall),
      titleLarge: apply(textTheme.titleLarge),
      titleMedium: apply(textTheme.titleMedium),
      titleSmall: apply(textTheme.titleSmall),
      bodyLarge: apply(textTheme.bodyLarge),
      bodyMedium: apply(textTheme.bodyMedium),
      bodySmall: apply(textTheme.bodySmall),
      labelLarge: apply(textTheme.labelLarge),
      labelMedium: apply(textTheme.labelMedium),
      labelSmall: apply(textTheme.labelSmall),
    );
  }
}

/// Colors for ColdChat's own surfaces that [ColorScheme] has no role for. Widgets read these instead of picking
/// scheme colors or checking the brightness themselves, so every preset and both modes stay consistent.
class ChatColors extends ThemeExtension<ChatColors> {
  /// The tab bar and the message composer at the bottom of the screen.
  final Color bar;
  final Color onBar;

  /// Bottom sheets (settings, account, user cards).
  final Color sheet;

  /// Pills and fields that float over the chat and the home tab: the scroll-down button, the notification pill, the
  /// search fields. A few tones lighter than the chat, like Material 3's search bar; over moving content, pair it with
  /// [raisedShadow].
  final Color raised;

  static const List<BoxShadow> raisedShadow = [
    BoxShadow(color: Colors.black38, blurRadius: 8.0, offset: Offset(0.0, 2.0)),
  ];

  // Fixed colors that mean the same thing in every accent and mode, so they don't come from the scheme.

  /// The dot next to a live stream's viewer count, on the home tab and over stream thumbnails.
  static const Color live = Colors.red;

  /// The unread-notifications count on the avatar button, and its text.
  static const Color unread = Colors.red;
  static const Color onUnread = Colors.white;

  /// The ban and unban buttons on a user card.
  static const Color ban = Colors.red;
  static const Color unban = Colors.green;

  /// Twitch's brand purple, for the "Log in with Twitch" button and the Twitch logo in the emote picker.
  static const Color twitchPurple = Color(0xFF9146FF);
  static const Color onTwitchPurple = Colors.white;

  /// Links in chat messages, in the accent color like in Telegram.
  final Color link;

  /// Message timestamps and other secondary text in the chat.
  final Color muted;

  final Brightness brightness;

  const ChatColors({
    required this.bar,
    required this.onBar,
    required this.sheet,
    required this.raised,
    required this.link,
    required this.muted,
    required this.brightness,
  });

  factory ChatColors.from(ColorScheme scheme, {bool oledBlack = false}) {
    final dark = scheme.brightness == Brightness.dark;
    return ChatColors(
      // Darker than the chat in dark mode, which is the look ColdChat always had; a light grey in light mode. On a
      // black chat (OLED) a little lighter instead, since nothing is darker than black.
      bar: oledBlack ? scheme.surfaceContainer : (dark ? scheme.surfaceContainerLowest : scheme.surfaceContainer),
      onBar: scheme.onSurface,
      // One grey for everything that sits above the chat, sheets and floating pills alike.
      sheet: scheme.surfaceContainer,
      raised: scheme.surfaceContainer,
      link: scheme.primary,
      muted: scheme.onSurfaceVariant,
      brightness: scheme.brightness,
    );
  }

  static ChatColors of(BuildContext context) => Theme.of(context).extension<ChatColors>()!;

  static final Map<int, Color> _nameCache = {};

  /// A chatter's name color, made readable on the chat background. Twitch lets people pick any color, and one that
  /// works on Twitch's dark chat, like yellow, is unreadable on white; Twitch's own site adjusts them the same way.
  /// Only the lightness changes, so the hue people chose stays recognizable. Without a color, the theme's accent.
  Color nameColor(Color? color, ColorScheme scheme) {
    if (color == null) return scheme.primary;
    final dark = brightness == Brightness.dark;
    final key = color.toARGB32() ^ (dark ? 1 << 31 : 0);
    if (_nameCache.length > 512) _nameCache.clear();
    return _nameCache.putIfAbsent(key, () {
      final hct = Hct.fromInt(color.toARGB32());
      final tone = dark ? hct.tone.clamp(60.0, 100.0) : hct.tone.clamp(0.0, 45.0);
      return tone == hct.tone ? color : Color(Hct.from(hct.hue, hct.chroma, tone).toInt());
    });
  }

  @override
  ChatColors copyWith({
    Color? bar,
    Color? onBar,
    Color? sheet,
    Color? raised,
    Color? link,
    Color? muted,
    Brightness? brightness,
  }) => ChatColors(
    bar: bar ?? this.bar,
    onBar: onBar ?? this.onBar,
    sheet: sheet ?? this.sheet,
    raised: raised ?? this.raised,
    link: link ?? this.link,
    muted: muted ?? this.muted,
    brightness: brightness ?? this.brightness,
  );

  @override
  ChatColors lerp(ChatColors? other, double t) => other == null
      ? this
      : ChatColors(
          bar: Color.lerp(bar, other.bar, t)!,
          onBar: Color.lerp(onBar, other.onBar, t)!,
          sheet: Color.lerp(sheet, other.sheet, t)!,
          raised: Color.lerp(raised, other.raised, t)!,
          link: Color.lerp(link, other.link, t)!,
          muted: Color.lerp(muted, other.muted, t)!,
          brightness: t < 0.5 ? brightness : other.brightness,
        );

  // Value equality, so a rebuilt but unchanged theme compares equal and doesn't rebuild every Theme.of dependent.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatColors &&
          other.bar == bar &&
          other.onBar == onBar &&
          other.sheet == sheet &&
          other.raised == raised &&
          other.link == link &&
          other.muted == muted &&
          other.brightness == brightness;

  @override
  int get hashCode => Object.hash(bar, onBar, sheet, raised, link, muted, brightness);
}

ColorScheme _toColorScheme(DynamicScheme s, Brightness brightness) {
  Color c(DynamicColor color) => Color(color.getArgb(s));
  return ColorScheme(
    brightness: brightness,
    primary: c(MaterialDynamicColors.primary),
    onPrimary: c(MaterialDynamicColors.onPrimary),
    primaryContainer: c(MaterialDynamicColors.primaryContainer),
    onPrimaryContainer: c(MaterialDynamicColors.onPrimaryContainer),
    primaryFixed: c(MaterialDynamicColors.primaryFixed),
    primaryFixedDim: c(MaterialDynamicColors.primaryFixedDim),
    onPrimaryFixed: c(MaterialDynamicColors.onPrimaryFixed),
    onPrimaryFixedVariant: c(MaterialDynamicColors.onPrimaryFixedVariant),
    secondary: c(MaterialDynamicColors.secondary),
    onSecondary: c(MaterialDynamicColors.onSecondary),
    secondaryContainer: c(MaterialDynamicColors.secondaryContainer),
    onSecondaryContainer: c(MaterialDynamicColors.onSecondaryContainer),
    secondaryFixed: c(MaterialDynamicColors.secondaryFixed),
    secondaryFixedDim: c(MaterialDynamicColors.secondaryFixedDim),
    onSecondaryFixed: c(MaterialDynamicColors.onSecondaryFixed),
    onSecondaryFixedVariant: c(MaterialDynamicColors.onSecondaryFixedVariant),
    tertiary: c(MaterialDynamicColors.tertiary),
    onTertiary: c(MaterialDynamicColors.onTertiary),
    tertiaryContainer: c(MaterialDynamicColors.tertiaryContainer),
    onTertiaryContainer: c(MaterialDynamicColors.onTertiaryContainer),
    tertiaryFixed: c(MaterialDynamicColors.tertiaryFixed),
    tertiaryFixedDim: c(MaterialDynamicColors.tertiaryFixedDim),
    onTertiaryFixed: c(MaterialDynamicColors.onTertiaryFixed),
    onTertiaryFixedVariant: c(MaterialDynamicColors.onTertiaryFixedVariant),
    error: c(MaterialDynamicColors.error),
    onError: c(MaterialDynamicColors.onError),
    errorContainer: c(MaterialDynamicColors.errorContainer),
    onErrorContainer: c(MaterialDynamicColors.onErrorContainer),
    surface: c(MaterialDynamicColors.surface),
    onSurface: c(MaterialDynamicColors.onSurface),
    surfaceDim: c(MaterialDynamicColors.surfaceDim),
    surfaceBright: c(MaterialDynamicColors.surfaceBright),
    surfaceContainerLowest: c(MaterialDynamicColors.surfaceContainerLowest),
    surfaceContainerLow: c(MaterialDynamicColors.surfaceContainerLow),
    surfaceContainer: c(MaterialDynamicColors.surfaceContainer),
    surfaceContainerHigh: c(MaterialDynamicColors.surfaceContainerHigh),
    surfaceContainerHighest: c(MaterialDynamicColors.surfaceContainerHighest),
    onSurfaceVariant: c(MaterialDynamicColors.onSurfaceVariant),
    outline: c(MaterialDynamicColors.outline),
    outlineVariant: c(MaterialDynamicColors.outlineVariant),
    shadow: c(MaterialDynamicColors.shadow),
    scrim: c(MaterialDynamicColors.scrim),
    inverseSurface: c(MaterialDynamicColors.inverseSurface),
    onInverseSurface: c(MaterialDynamicColors.inverseOnSurface),
    inversePrimary: c(MaterialDynamicColors.inversePrimary),
    surfaceTint: c(MaterialDynamicColors.surfaceTint),
  );
}
