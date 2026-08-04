import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static TextTheme _scaleTextTheme(TextTheme theme) {
    TextStyle? scaled(TextStyle? style) {
      final fontSize = style?.fontSize;
      if (style == null || fontSize == null) return style;
      return style.copyWith(fontSize: fontSize * AppDensity.scale);
    }

    return theme.copyWith(
      displayLarge: scaled(theme.displayLarge),
      displayMedium: scaled(theme.displayMedium),
      displaySmall: scaled(theme.displaySmall),
      headlineLarge: scaled(theme.headlineLarge),
      headlineMedium: scaled(theme.headlineMedium),
      headlineSmall: scaled(theme.headlineSmall),
      titleLarge: scaled(theme.titleLarge),
      titleMedium: scaled(theme.titleMedium),
      titleSmall: scaled(theme.titleSmall),
      bodyLarge: scaled(theme.bodyLarge),
      bodyMedium: scaled(theme.bodyMedium),
      bodySmall: scaled(theme.bodySmall),
      labelLarge: scaled(theme.labelLarge),
      labelMedium: scaled(theme.labelMedium),
      labelSmall: scaled(theme.labelSmall),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Tajawal',
      fontFamilyFallback: const ['Segoe UI', 'Arial'],
    );

    return base.copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.cursor,
      ),
      textTheme: _scaleTextTheme(
        base.textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
      ),
      iconTheme: base.iconTheme.copyWith(size: AppIconSizes.lg),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: AppTypography.fieldText.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTypography.fieldText.copyWith(
          color: AppColors.textSecondary,
        ),
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 12 * AppDensity.scale,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14 * AppDensity.scale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            120 * AppDensity.scale,
            AppControlHeights.standard,
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onStrong,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            120 * AppDensity.scale,
            AppControlHeights.standard,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            96 * AppDensity.scale,
            AppControlHeights.standard,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
    );
  }
}
