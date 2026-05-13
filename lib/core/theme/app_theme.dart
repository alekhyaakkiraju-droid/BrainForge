import 'package:flutter/material.dart';

/// BrainForge design tokens.
///
/// Child-friendly palette: vibrant, WCAG AA compliant, high-contrast capable.
/// Typography uses Nunito for body and Fredoka for display headings —
/// both are round, readable fonts proven effective for ADHD users.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF6C63FF);
  static const primaryVariant = Color(0xFF4B44CC);
  static const secondary = Color(0xFFFF6584);
  static const secondaryVariant = Color(0xFFCC4466);

  // ScienceSpark accent
  static const scienceSpark = Color(0xFF00C9A7);
  static const scienceSparkVariant = Color(0xFF009E83);

  // Neutrals
  static const surface = Color(0xFFF8F9FF);
  static const background = Color(0xFFEEF0FF);
  static const onSurface = Color(0xFF1A1A2E);
  static const onBackground = Color(0xFF1A1A2E);

  // Feedback
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);

  // Dark mode
  static const darkSurface = Color(0xFF1A1A2E);
  static const darkBackground = Color(0xFF0F0F1A);
  static const darkOnSurface = Color(0xFFF8F9FF);
}

abstract final class AppTextStyles {
  static const _baseFamily = 'Nunito';
  static const _displayFamily = 'Fredoka';

  static const displayLarge = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const displayMedium = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );

  static const headlineLarge = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 26,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const labelLarge = TextStyle(
    fontFamily: _baseFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}

/// Centralised theme factory — all screens consume these themes; no
/// ad-hoc colour or text style values are permitted in widget files.
abstract final class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: _textTheme(AppColors.onBackground),
        filledButtonTheme: _filledButtonTheme(),
        cardTheme: _cardTheme(),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.darkSurface,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: _textTheme(AppColors.darkOnSurface),
        filledButtonTheme: _filledButtonTheme(),
        cardTheme: _cardTheme(),
      );


  static TextTheme _textTheme(Color onBackground) => TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: onBackground),
        displayMedium:
            AppTextStyles.displayMedium.copyWith(color: onBackground),
        headlineLarge:
            AppTextStyles.headlineLarge.copyWith(color: onBackground),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: onBackground),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: onBackground),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: onBackground),
      );

  static FilledButtonThemeData _filledButtonTheme() => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48), // WCAG AA 48dp touch target
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppTextStyles.labelLarge,
        ),
      );

  static CardTheme _cardTheme() => CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );
}
