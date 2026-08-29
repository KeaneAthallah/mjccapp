import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware semantic colors.
///
/// Brand/status colors (emerald, blue, red, amber, teal) are identical in
/// light and dark mode and live on [AppColors]. The neutrals that must flip
/// between modes (surfaces, text, borders) are exposed here via
/// [AppThemeColors.of] so widgets resolve the correct value for the current
/// brightness instead of hardcoding light-only values.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.cardBorder,
    required this.inputFill,
    required this.inputBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onBrand,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color cardBorder;
  final Color inputFill;
  final Color inputBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color onBrand;

  /// Semantic colors for the current theme (requires [AppTheme] themes).
  static AppThemeColors of(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>()!;

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? cardBorder,
    Color? inputFill,
    Color? inputBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? onBrand,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      cardBorder: cardBorder ?? this.cardBorder,
      inputFill: inputFill ?? this.inputFill,
      inputBorder: inputBorder ?? this.inputBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      onBrand: onBrand ?? this.onBrand,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
    );
  }
}

/// Central theme for the MJCC app, mirroring the Laravel website's visual
/// language (emerald primary brand). Provides both light and dark variants.
class AppTheme {
  AppTheme._();

  static const double radiusSm = 12; // rounded-xl
  static const double radiusMd = 16; // rounded-2xl
  static const double radiusLg = 24; // rounded-3xl

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static const _lightColors = AppThemeColors(
    background: AppColors.gray100,
    surface: AppColors.white,
    surfaceAlt: AppColors.gray50,
    cardBorder: AppColors.gray100,
    inputFill: AppColors.white,
    inputBorder: AppColors.gray300,
    textPrimary: AppColors.gray900,
    textSecondary: AppColors.gray600,
    textMuted: AppColors.gray400,
    onBrand: Colors.white,
  );

  static const _darkColors = AppThemeColors(
    background: Color(0xFF0F1419),
    surface: Color(0xFF1A2129),
    surfaceAlt: Color(0xFF232C36),
    cardBorder: Color(0xFF2A343F),
    inputFill: Color(0xFF1A2129),
    inputBorder: Color(0xFF39424D),
    textPrimary: Color(0xFFE6EAEF),
    textSecondary: Color(0xFFB0B8C1),
    textMuted: Color(0xFF7B8794),
    onBrand: Colors.white,
  );

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = dark ? _darkColors : _lightColors;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      onPrimary: colors.onBrand,
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.cardBorder,
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: _textTheme(base.textTheme, colors),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
          side: BorderSide(color: colors.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        labelStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        prefixIconColor: colors.textMuted,
        suffixIconColor: colors.textMuted,
        errorStyle: const TextStyle(color: AppColors.red600, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.red400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.red400),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: colors.onBrand,
          disabledBackgroundColor: AppColors.emerald500.withValues(alpha: 0.4),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          backgroundColor: colors.surface,
          side: BorderSide(color: colors.inputBorder),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.gray900,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        secondaryLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      dividerTheme: DividerThemeData(color: colors.cardBorder, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, AppThemeColors colors) {
    return base
        .copyWith(
          displaySmall: TextStyle(
            color: colors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          headlineSmall: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          titleLarge: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          titleMedium: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: colors.textPrimary, fontSize: 14),
          bodyMedium: TextStyle(color: colors.textSecondary, fontSize: 13),
          bodySmall: TextStyle(color: colors.textMuted, fontSize: 12),
          labelLarge: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        )
        .apply(
          bodyColor: colors.textPrimary,
          displayColor: colors.textPrimary,
        );
  }
}
