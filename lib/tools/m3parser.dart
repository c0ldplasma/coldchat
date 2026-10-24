import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Colors the app's design uses that Material 3 dropped from [ColorScheme].
class AppColors extends ThemeExtension<AppColors> {
  /// The old `ColorScheme.surfaceVariant`. Its replacement,
  /// `surfaceContainerHighest`, is a different tone, so it's kept here to keep
  /// the surfaces that use it looking the same.
  final Color surfaceVariant;

  const AppColors({required this.surfaceVariant});

  /// The `surfaceVariant` that `ColorScheme.fromSeed` used to produce.
  factory AppColors.fromSeed(Color seed, Brightness brightness) {
    final scheme = SchemeTonalSpot(
      sourceColorHct: Hct.fromInt(seed.toARGB32()),
      isDark: brightness == Brightness.dark,
      contrastLevel: 0.0,
    );
    return AppColors(surfaceVariant: Color(MaterialDynamicColors.surfaceVariant.getArgb(scheme)));
  }

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({Color? surfaceVariant}) => AppColors(surfaceVariant: surfaceVariant ?? this.surfaceVariant);

  @override
  AppColors lerp(AppColors? other, double t) => other == null ? this : AppColors(surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!);
}

class M3Parser {
  /// Narrows Google Sans Flex and sets its optical size so it matches the Product Sans the app used before.
  /// Weight is left to [TextStyle.fontWeight]: an explicit `wght` here would override it.
  static const fontVariations = [FontVariation('wdth', 94), FontVariation('opsz', 22)];

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

  static ThemeData patchTheme(ThemeData baseTheme, {required AppColors appColors}) {
    final newThemeData = baseTheme.copyWith(
      extensions: [appColors],
      textTheme: _withFontVariations(baseTheme.textTheme.apply(
        fontFamily: 'GoogleSansFlex',
        bodyColor: baseTheme.colorScheme.onSurface,
        displayColor: baseTheme.colorScheme.onSurface,
        decorationColor: baseTheme.colorScheme.onSurface,
      )),
      tabBarTheme: baseTheme.tabBarTheme.copyWith(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: baseTheme.colorScheme.onPrimaryContainer.withValues(alpha: 0.0),
            // width: 2,
            width: 0,
          ),
        ),
        labelColor: baseTheme.colorScheme.onPrimaryContainer,
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        hintStyle: (baseTheme.inputDecorationTheme.hintStyle ?? const TextStyle()).copyWith(
          color: baseTheme.colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
        ),
      ),
      switchTheme: baseTheme.switchTheme.copyWith(
        trackColor: WidgetStateProperty.all(baseTheme.colorScheme.primaryContainer),
        thumbColor: WidgetStateProperty.all(baseTheme.colorScheme.primaryContainer),
      ),
      checkboxTheme: baseTheme.checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.all(baseTheme.colorScheme.primary),
        checkColor: WidgetStateProperty.all(baseTheme.colorScheme.primaryContainer),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
    return newThemeData;
  }
}
