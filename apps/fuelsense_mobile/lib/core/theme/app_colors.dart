import 'package:flutter/material.dart';

/// FuelSense Design System
///
/// Industrial GIS and data-driven visual language.
/// All application colors should come from this class rather than
/// hard-coded values scattered throughout individual screens.

abstract final class AppColors {
  // ===========================================================================
  // CORE SURFACES
  // ===========================================================================

  static const Color background = Color(0xFF050B0F);
  static const Color surface = Color(0xFF0A141A);
  static const Color surfaceElevated = Color(0xFF0E1B22);
  static const Color surfaceBright = Color(0xFF13242C);
  static const Color surfaceGlass = Color(0xCC0B171D);

  // ===========================================================================
  // BRAND / PRIMARY ACCENTS
  // ===========================================================================

  static const Color primary = Color(0xFF55E6D3);
  static const Color primaryBright = Color(0xFF72F5E4);
  static const Color primaryDark = Color(0xFF123A3A);
  static const Color primarySoft = Color(0xFF0D292B);

  static const Color secondary = Color(0xFF4BA7FF);
  static const Color secondaryBright = Color(0xFF73BBFF);
  static const Color secondaryDark = Color(0xFF102C46);

  // ===========================================================================
  // FUEL TYPES
  // ===========================================================================

  static const Color petrol = Color(0xFFFFB84D);
  static const Color diesel = Color(0xFFA9B8C2);
  static const Color ethanol = Color(0xFF55E6D3);

  // ===========================================================================
  // SEMANTIC STATUS
  // ===========================================================================

  static const Color success = Color(0xFF4DE1A8);
  static const Color warning = Color(0xFFFFC857);
  static const Color error = Color(0xFFFF6474);
  static const Color info = Color(0xFF62B7FF);

  // ===========================================================================
  // TEXT
  // ===========================================================================

  static const Color textPrimary = Color(0xFFF3F8FA);
  static const Color textSecondary = Color(0xFFA2B3BB);
  static const Color textMuted = Color(0xFF6E818A);
  static const Color textDisabled = Color(0xFF45565E);
  static const Color textOnPrimary = Color(0xFF031012);

  // ===========================================================================
  // BORDERS
  // ===========================================================================

  static const Color border = Color(0xFF182B33);
  static const Color borderStrong = Color(0xFF24434E);
  static const Color borderPrimary = Color(0xFF2F7776);
  static const Color divider = Color(0xFF14262E);

  // ===========================================================================
  // GIS / SPATIAL DATA
  // ===========================================================================

  static const Color gisGrid = Color(0xFF102A32);
  static const Color gisRoute = Color(0xFF3BAAA5);
  static const Color gisActive = Color(0xFF55E6D3);
  static const Color gisSecondary = Color(0xFF4BA7FF);

  static const Color gisLowRisk = Color(0xFF3FD5A0);
  static const Color gisMediumRisk = Color(0xFFFFC857);
  static const Color gisHighRisk = Color(0xFFFF6474);

  // ===========================================================================
  // DATA VISUALIZATION
  // ===========================================================================

  static const Color chartPrimary = Color(0xFF55E6D3);
  static const Color chartSecondary = Color(0xFF4BA7FF);
  static const Color chartTertiary = Color(0xFFB58CFF);
  static const Color chartWarning = Color(0xFFFFC857);
  static const Color chartDanger = Color(0xFFFF6474);
  static const Color chartTrack = Color(0xFF1A2B32);

  // ===========================================================================
  // GRADIENT COLORS
  // ===========================================================================

  static const Color gradientStart = Color(0xFF0B292D);
  static const Color gradientMiddle = Color(0xFF0A1A22);
  static const Color gradientEnd = Color(0xFF071015);

  // ===========================================================================
  // SHADOWS / GLOW
  // ===========================================================================

  static const Color shadow = Color(0x99000000);
  static const Color primaryGlow = Color(0x6655E6D3);
  static const Color secondaryGlow = Color(0x664BA7FF);
  static const Color successGlow = Color(0x664DE1A8);
  static const Color errorGlow = Color(0x66FF6474);

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  static const Color navigationBackground = Color(0xF20A151B);
  static const Color navigationActive = Color(0xFF55E6D3);
  static const Color navigationInactive = Color(0xFF627781);
  static const Color navigationBorder = Color(0xFF182B33);

  // ===========================================================================
  // OVERLAYS
  // ===========================================================================

  static const Color overlay = Color(0x99000000);
  static const Color scrim = Color(0xB3000000);

  // ===========================================================================
  // LEGACY / COMPATIBILITY ALIASES
  // ===========================================================================

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  static Color primaryAlpha(double opacity) {
    return primary.withValues(alpha: opacity);
  }

  static Color secondaryAlpha(double opacity) {
    return secondary.withValues(alpha: opacity);
  }

  static Color statusAlpha(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // ===========================================================================
  // LEGACY / COMPATIBILITY ALIASES
  // ===========================================================================

  /// Legacy primary cyan alias.
  static const Color primaryCyan = Color(0xFF00E5FF);

  /// Legacy primary blue alias.
  static const Color primaryBlue = Color(0xFF2979FF);

  /// Legacy soft surface alias.
  static const Color surfaceSoft = Color(0xFF151C24);

  /// Legacy card surface alias.
  static const Color surfaceCard = surfaceElevated;

  /// Legacy border alias.
  static const Color surfaceBorder = border;

  /// Violet accent for premium analytics and data visualizations.
  static const Color accentViolet = Color(0xFFB58CFF);

  /// Legacy success/status green alias.
  static const Color statusGreen = success;

  /// Legacy danger/status red alias.
  static const Color statusRed = Color(0xFFFF4D5A);

  /// Legacy warning/status amber alias.
  static const Color statusAmber = Color(0xFFFFB020);

  /// Legacy E20 fuel color.
  static const Color fuelE20 = Color(0xFF00C853);


  /// Hybrid vehicle accent.
  static const Color hybrid = Color(0xFF7C4DFF);


  /// Legacy primary gradient.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryCyan, primaryBlue],
  );
}
