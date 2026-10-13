import 'package:flutter/material.dart';

import '../design/app_theme_extension.dart';
import '../design/design_tokens.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get fuelSense => _buildTheme(
    brightness: Brightness.dark,
    extension: FuelSenseThemeExtension.fuelSense,
  );

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    extension: FuelSenseThemeExtension.dark,
  );

  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    extension: FuelSenseThemeExtension.light,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required FuelSenseThemeExtension extension,
  }) {
    final isDark = brightness == Brightness.dark;

    final primary = extension.accent;
    final secondary = extension.accentSecondary;
    final background = extension.background;
    final surface = extension.surfaceElevated;
    final border = extension.border;
    final text = extension.textPrimary;
    final muted = extension.textMuted;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? FuelSenseDesignTokens.graphiteDeep : Colors.white,
      secondary: secondary,
      onSecondary: isDark ? FuelSenseDesignTokens.graphiteDeep : Colors.white,
      error: extension.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[extension],

      textTheme: AppTextStyles.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.sectionHeading.copyWith(color: text),
        iconTheme: IconThemeData(color: text),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border),
        ),
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark
              ? FuelSenseDesignTokens.graphiteDeep
              : Colors.white,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: muted),
        labelStyle: AppTextStyles.bodySecondary.copyWith(color: muted),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: AppTextStyles.body.copyWith(color: text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border.withValues(alpha: 0.45),
      ),
    );
  }
}
