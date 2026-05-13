import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

/// BrainForge color palette.
///
/// Vibrant, WCAG AA compliant on both light and dark surfaces.
/// High-contrast variants are available for accessibility mode.
abstract final class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const primary = Color(0xFF6C63FF);
  static const primaryDark = Color(0xFF4B44CC);
  static const primaryLight = Color(0xFFEDE9FF);

  static const secondary = Color(0xFFFF6584);
  static const secondaryDark = Color(0xFFCC4466);
  static const secondaryLight = Color(0xFFFFE0E7);

  // ── ScienceSpark accent ───────────────────────────────────────────────────
  static const scienceSpark = Color(0xFF00C9A7);
  static const scienceSparkDark = Color(0xFF009E83);
  static const scienceSparkLight = Color(0xFFD0FFF6);

  // ── Feedback ──────────────────────────────────────────────────────────────
  static const success = Color(0xFF4CAF50);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFFFC107);
  static const warningLight = Color(0xFFFFF8E1);
  static const error = Color(0xFFF44336);
  static const errorLight = Color(0xFFFFEBEE);

  // ── XP / gamification ─────────────────────────────────────────────────────
  static const xpGold = Color(0xFFFFD700);
  static const xpSilver = Color(0xFFC0C0C0);
  static const xpBronze = Color(0xFFCD7F32);

  // ── Neutrals (light) ──────────────────────────────────────────────────────
  static const background = Color(0xFFF0EFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF4F4FF);
  static const outline = Color(0xFFE0DEFF);
  static const onBackground = Color(0xFF1A1A2E);
  static const onSurface = Color(0xFF1A1A2E);
  static const onSurfaceVariant = Color(0xFF5C5A7A);

  // ── Neutrals (dark) ───────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF0F0F1A);
  static const darkSurface = Color(0xFF1A1A2E);
  static const darkSurfaceVariant = Color(0xFF252540);
  static const darkOutline = Color(0xFF3A3A5C);
  static const darkOnBackground = Color(0xFFF0EFFF);
  static const darkOnSurface = Color(0xFFF0EFFF);
  static const darkOnSurfaceVariant = Color(0xFFAAAAAC);
}

/// Typography scale using Nunito (body) and Fredoka (display).
///
/// All sizes are large enough for children to read comfortably on tablets.
/// No style renders more than 2 lines by default — enforced via maxLines
/// in the design-system widgets.
abstract final class AppTextStyles {
  static const _bodyFamily = 'Nunito';
  static const _displayFamily = 'Fredoka';

  static const displayXl = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static const displayLg = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static const headingMd = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const headingSm = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const bodyLg = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const bodyMd = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const caption = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static const label = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: 0.4,
  );
}

/// Centralised theme factory.
///
/// All screens consume these themes exclusively — no ad-hoc colour or
/// text-style values are permitted in widget files.
abstract final class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: _textTheme(AppColors.onBackground),
        elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary),
        filledButtonTheme: _filledButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(),
        cardTheme: _cardTheme(AppColors.surface),
        iconTheme: const IconThemeData(size: AppSpacing.iconSizeMd),
        chipTheme: _chipTheme(),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.primaryLight,
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.darkSurface,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: _textTheme(AppColors.darkOnBackground),
        elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary),
        filledButtonTheme: _filledButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(),
        cardTheme: _cardTheme(AppColors.darkSurface),
        iconTheme: const IconThemeData(size: AppSpacing.iconSizeMd),
        chipTheme: _chipTheme(),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.darkSurfaceVariant,
        ),
      );

  // ── Text theme ─────────────────────────────────────────────────────────────
  static TextTheme _textTheme(Color color) => TextTheme(
        displayLarge:
            AppTextStyles.displayXl.copyWith(color: color),
        displayMedium:
            AppTextStyles.displayLg.copyWith(color: color),
        headlineLarge:
            AppTextStyles.headingMd.copyWith(color: color),
        headlineMedium:
            AppTextStyles.headingSm.copyWith(color: color),
        bodyLarge: AppTextStyles.bodyLg.copyWith(color: color),
        bodyMedium: AppTextStyles.bodyMd.copyWith(color: color),
        bodySmall: AppTextStyles.caption.copyWith(color: color),
        labelLarge: AppTextStyles.label.copyWith(color: color),
      );

  // ── Button themes ─────────────────────────────────────────────────────────
  static ElevatedButtonThemeData _elevatedButtonTheme(Color bg) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.label,
          elevation: 2,
        ),
      );

  static FilledButtonThemeData _filledButtonTheme() => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.label,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTextStyles.label,
        ),
      );

  // ── Card theme ────────────────────────────────────────────────────────────
  static CardTheme _cardTheme(Color surface) => CardTheme(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        margin: EdgeInsets.zero,
      );

  // ── Chip theme ────────────────────────────────────────────────────────────
  static ChipThemeData _chipTheme() => ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        labelStyle: AppTextStyles.caption,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      );
}
