import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  // ---------------------------------------------------------------------------
  // FONT
  // ---------------------------------------------------------------------------

  static const String fontFamily = 'Inter';

  // ---------------------------------------------------------------------------
  // EXISTING / COMPATIBILITY STYLES
  // ---------------------------------------------------------------------------

  static const TextStyle heading = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 28,
    height: 1.12,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
  );

  static const TextStyle title = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle caption = TextStyle(
    color: Color(0xFF718692),
    fontSize: 11,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodySecondary = TextStyle(
    color: Color(0xFF81959E),
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelTechnical = TextStyle(
    color: Color(0xFF53E0D0),
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
  );

  static const TextStyle dataValue = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 24,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle button = TextStyle(
    color: Color(0xFF071017),
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
  );

  // ---------------------------------------------------------------------------
  // DISPLAY
  // ---------------------------------------------------------------------------

  static const TextStyle displayLarge = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 34,
    height: 1.08,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 30,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );

  static const TextStyle displaySmall = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 26,
    height: 1.12,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  // ---------------------------------------------------------------------------
  // HEADLINES
  // ---------------------------------------------------------------------------

  static const TextStyle headlineLarge = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle headlineMedium = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static const TextStyle headlineSmall = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );

  // ---------------------------------------------------------------------------
  // TITLES
  // ---------------------------------------------------------------------------

  static const TextStyle titleLarge = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle titleMedium = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle titleSmall = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  static const TextStyle bodyLarge = TextStyle(
    color: Color(0xFFB4C3C9),
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: Color(0xFF9AACB3),
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    color: Color(0xFF718692),
    fontSize: 11,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  // ---------------------------------------------------------------------------
  // LABELS
  // ---------------------------------------------------------------------------

  static const TextStyle labelLarge = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static const TextStyle labelMedium = TextStyle(
    color: Color(0xFF9AACB3),
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static const TextStyle labelSmall = TextStyle(
    color: Color(0xFF718692),
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );

  // ---------------------------------------------------------------------------
  // TECHNICAL
  // ---------------------------------------------------------------------------

  static const TextStyle technical = TextStyle(
    color: Color(0xFF53E0D0),
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  );

  static const TextStyle technicalSecondary = TextStyle(
    color: Color(0xFF718692),
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static const TextStyle technicalBright = TextStyle(
    color: Color(0xFF6FF7E8),
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
  );

  // ---------------------------------------------------------------------------
  // METRICS
  // ---------------------------------------------------------------------------

  static const TextStyle metricLarge = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 30,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );

  static const TextStyle metricMedium = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 24,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle metricSmall = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 18,
    height: 1,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle metricSuffix = TextStyle(
    color: Color(0xFF53E0D0),
    fontSize: 10,
    height: 1,
    fontWeight: FontWeight.w700,
  );

  // ---------------------------------------------------------------------------
  // STATUS
  // ---------------------------------------------------------------------------

  static const TextStyle statusOnline = TextStyle(
    color: Color(0xFF53E0D0),
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
  );

  static const TextStyle statusWarning = TextStyle(
    color: Color(0xFFF5B84B),
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
  );

  static const TextStyle statusCritical = TextStyle(
    color: Color(0xFFFF5C68),
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
  );

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------

  static const TextStyle navigationActive = TextStyle(
    color: Color(0xFF53E0D0),
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle navigationInactive = TextStyle(
    color: Color(0xFF607782),
    fontSize: 9,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  // ---------------------------------------------------------------------------
  // BRAND
  // ---------------------------------------------------------------------------

  static const TextStyle brand = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 15,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.4,
  );

  static const TextStyle brandSubtitle = TextStyle(
    color: Color(0xFF718692),
    fontSize: 8,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );

  // ---------------------------------------------------------------------------
  // BUTTONS
  // ---------------------------------------------------------------------------

  static const TextStyle buttonLarge = TextStyle(
    color: Color(0xFF071017),
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle buttonMedium = TextStyle(
    color: Color(0xFF071017),
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle buttonSmall = TextStyle(
    color: Color(0xFFF5FAFC),
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w800,
  );

  // ===========================================================================
  // LEGACY / COMPATIBILITY ALIASES
  // ===========================================================================

  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );

  static const TextStyle sectionHeading = headlineSmall;

  static const TextStyle subHeading = titleMedium;

  static const TextStyle body = bodyMedium;

  static const TextStyle statLabel = labelMedium;

  static const TextStyle display = displayLarge;

}
