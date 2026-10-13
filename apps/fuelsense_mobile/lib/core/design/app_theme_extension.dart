import 'package:flutter/material.dart';

import 'design_tokens.dart';

@immutable
class FuelSenseThemeExtension extends ThemeExtension<FuelSenseThemeExtension> {
  const FuelSenseThemeExtension({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceInteractive,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSecondary,
    required this.intelligence,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceInteractive;

  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color accent;
  final Color accentSecondary;
  final Color intelligence;

  final Color success;
  final Color warning;
  final Color danger;

  static const fuelSense = FuelSenseThemeExtension(
    background: FuelSenseDesignTokens.darkBackground,
    surface: FuelSenseDesignTokens.darkSurface,
    surfaceElevated: FuelSenseDesignTokens.darkElevated,
    surfaceInteractive: FuelSenseDesignTokens.darkInteractive,
    border: FuelSenseDesignTokens.darkBorder,
    borderStrong: FuelSenseDesignTokens.darkBorderStrong,
    textPrimary: FuelSenseDesignTokens.darkTextPrimary,
    textSecondary: FuelSenseDesignTokens.darkTextSecondary,
    textMuted: FuelSenseDesignTokens.darkTextMuted,
    accent: FuelSenseDesignTokens.copper,
    accentSecondary: FuelSenseDesignTokens.sage,
    intelligence: FuelSenseDesignTokens.plum,
    success: FuelSenseDesignTokens.success,
    warning: FuelSenseDesignTokens.warning,
    danger: FuelSenseDesignTokens.danger,
  );

  static const dark = FuelSenseThemeExtension(
    background: Color(0xFF101211),
    surface: Color(0xFF191C1A),
    surfaceElevated: Color(0xFF232622),
    surfaceInteractive: Color(0xFF2B302C),
    border: Color(0xFF343934),
    borderStrong: Color(0xFF454C46),
    textPrimary: Color(0xFFF3EFE9),
    textSecondary: Color(0xFFAAA59D),
    textMuted: Color(0xFF77736D),
    accent: FuelSenseDesignTokens.copper,
    accentSecondary: FuelSenseDesignTokens.sage,
    intelligence: FuelSenseDesignTokens.plum,
    success: FuelSenseDesignTokens.success,
    warning: FuelSenseDesignTokens.warning,
    danger: FuelSenseDesignTokens.danger,
  );

  static const light = FuelSenseThemeExtension(
    background: FuelSenseDesignTokens.lightBackground,
    surface: FuelSenseDesignTokens.lightSurface,
    surfaceElevated: FuelSenseDesignTokens.lightElevated,
    surfaceInteractive: FuelSenseDesignTokens.lightInteractive,
    border: FuelSenseDesignTokens.lightBorder,
    borderStrong: FuelSenseDesignTokens.lightBorderStrong,
    textPrimary: FuelSenseDesignTokens.lightTextPrimary,
    textSecondary: FuelSenseDesignTokens.lightTextSecondary,
    textMuted: FuelSenseDesignTokens.lightTextMuted,
    accent: FuelSenseDesignTokens.copperDeep,
    accentSecondary: FuelSenseDesignTokens.sageDeep,
    intelligence: FuelSenseDesignTokens.plum,
    success: Color(0xFF58704F),
    warning: Color(0xFF996628),
    danger: Color(0xFF873E45),
  );

  @override
  FuelSenseThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceInteractive,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentSecondary,
    Color? intelligence,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return FuelSenseThemeExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceInteractive: surfaceInteractive ?? this.surfaceInteractive,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      intelligence: intelligence ?? this.intelligence,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  FuelSenseThemeExtension lerp(
    ThemeExtension<FuelSenseThemeExtension>? other,
    double t,
  ) {
    if (other is! FuelSenseThemeExtension) {
      return this;
    }

    return FuelSenseThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceInteractive: Color.lerp(
        surfaceInteractive,
        other.surfaceInteractive,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      intelligence: Color.lerp(intelligence, other.intelligence, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension FuelSenseThemeContext on BuildContext {
  FuelSenseThemeExtension get fuelTheme {
    return Theme.of(this).extension<FuelSenseThemeExtension>()!;
  }
}
