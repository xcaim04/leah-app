import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'PlusJakartaSans';

  static ThemeData light() => _base(_lightScheme, Brightness.light);
  static ThemeData dark() => _base(_darkScheme, Brightness.dark);

  static ThemeData _base(ColorScheme colorScheme, Brightness brightness) {
    // Component themes below read styles from here, so the font must be on it too.
    final textTheme = _textTheme(colorScheme).apply(fontFamily: _fontFamily);

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: const StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.primary,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primaryContainer, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    final onSurface = colorScheme.onSurface;
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 38 / 30,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        height: 14 / 10,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF62328C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF7B4BA6),
    onPrimaryContainer: Color(0xFFEDD4FF),
    secondary: Color(0xFF6F518E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDBB8FE),
    onSecondaryContainer: Color(0xFF624581),
    tertiary: Color(0xFF733646),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF8F4D5E),
    onTertiaryContainer: Color(0xFFFFD1DA),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFFF7FE),
    onSurface: Color(0xFF241433),
    surfaceDim: Color(0xFFEAD1FA),
    surfaceBright: Color(0xFFFFF7FE),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFCF0FF),
    surfaceContainer: Color(0xFFF8E9FF),
    surfaceContainerHigh: Color(0xFFF4E2FF),
    surfaceContainerHighest: Color(0xFFF1DBFF),
    onSurfaceVariant: Color(0xFF4C4450),
    outline: Color(0xFF7D7481),
    outlineVariant: Color(0xFFCEC3D2),
    inverseSurface: Color(0xFF3A2949),
    onInverseSurface: Color(0xFFFAECFF),
    inversePrimary: Color(0xFFDFB7FF),
    surfaceTint: Color(0xFF7848A3),
    primaryFixed: Color(0xFFF1DAFF),
    primaryFixedDim: Color(0xFFDFB7FF),
    onPrimaryFixed: Color(0xFF2D004F),
    onPrimaryFixedVariant: Color(0xFF5F2F89),
    secondaryFixed: Color(0xFFEFDBFF),
    secondaryFixedDim: Color(0xFFDBB8FE),
    onSecondaryFixed: Color(0xFF290A46),
    onSecondaryFixedVariant: Color(0xFF563975),
    tertiaryFixed: Color(0xFFFFD9E0),
    tertiaryFixedDim: Color(0xFFFFB1C2),
    onTertiaryFixed: Color(0xFF390819),
    onTertiaryFixedVariant: Color(0xFF6F3444),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFDFB7FF),
    onPrimary: Color(0xFF2D004F),
    primaryContainer: Color(0xFF5F2F89),
    onPrimaryContainer: Color(0xFFF1DAFF),
    secondary: Color(0xFFDBB8FE),
    onSecondary: Color(0xFF290A46),
    secondaryContainer: Color(0xFF563975),
    onSecondaryContainer: Color(0xFFEFDBFF),
    tertiary: Color(0xFFFFB1C2),
    onTertiary: Color(0xFF390819),
    tertiaryContainer: Color(0xFF6F3444),
    onTertiaryContainer: Color(0xFFFFD9E0),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1B0E26),
    onSurface: Color(0xFFEDE0F5),
    surfaceDim: Color(0xFF1B0E26),
    surfaceBright: Color(0xFF42304F),
    surfaceContainerLowest: Color(0xFF160A1F),
    surfaceContainerLow: Color(0xFF241433),
    surfaceContainer: Color(0xFF281839),
    surfaceContainerHigh: Color(0xFF33233F),
    surfaceContainerHighest: Color(0xFF3E2E4A),
    onSurfaceVariant: Color(0xFFCEC3D2),
    outline: Color(0xFF978D9B),
    outlineVariant: Color(0xFF4C4450),
    inverseSurface: Color(0xFFEDE0F5),
    onInverseSurface: Color(0xFF3A2949),
    inversePrimary: Color(0xFF62328C),
    surfaceTint: Color(0xFFDFB7FF),
    primaryFixed: Color(0xFFF1DAFF),
    primaryFixedDim: Color(0xFFDFB7FF),
    onPrimaryFixed: Color(0xFF2D004F),
    onPrimaryFixedVariant: Color(0xFF5F2F89),
    secondaryFixed: Color(0xFFEFDBFF),
    secondaryFixedDim: Color(0xFFDBB8FE),
    onSecondaryFixed: Color(0xFF290A46),
    onSecondaryFixedVariant: Color(0xFF563975),
    tertiaryFixed: Color(0xFFFFD9E0),
    tertiaryFixedDim: Color(0xFFFFB1C2),
    onTertiaryFixed: Color(0xFF390819),
    onTertiaryFixedVariant: Color(0xFF6F3444),
  );
}
