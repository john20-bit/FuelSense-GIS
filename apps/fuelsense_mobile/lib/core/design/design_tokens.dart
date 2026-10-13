import 'package:flutter/material.dart';

abstract class FuelSenseDesignTokens {
  // ============================================================
  // PRIMARY BRAND PALETTE
  // ============================================================

  static const Color electricCyan = Color(0xFF20D9E8);
  static const Color cyanSoft = Color(0xFF5BE7F0);
  static const Color cyanDeep = Color(0xFF0FA7B5);

  static const Color deepNavy = Color(0xFF071216);
  static const Color navy = Color(0xFF0B1A20);
  static const Color navySoft = Color(0xFF12272E);

  static const Color steel = Color(0xFF52666D);
  static const Color steelSoft = Color(0xFF7A8D94);

  static const Color white = Color(0xFFF3FAFC);
  static const Color whiteSoft = Color(0xFFDCE9EC);

  static const Color blue = Color(0xFF397BFF);
  static const Color blueSoft = Color(0xFF6B9BFF);

  // PREMIUM VIOLET ACCENTS
  static const Color fusion = Color(0xFF8B7CFF);
  static const Color fusionSoft = Color(0xFFAAA0FF);

  // ============================================================
  // ENERGY TYPES
  // ============================================================

  static const Color petrol = Color(0xFF20D9E8);
  static const Color premiumPetrol = Color(0xFF5BE7F0);

  static const Color diesel = Color(0xFF6B9BFF);
  static const Color premiumDiesel = Color(0xFF8FB4FF);


  static const Color hybrid = Color(0xFF65D6A0);

  static const Color ethanol = Color(0xFFB58CFF);

  // ============================================================
  // STATUS
  // ============================================================

  static const Color success = Color(0xFF35C98A);
  static const Color warning = Color(0xFFFFB454);
  static const Color danger = Color(0xFFFF5F6D);
  static const Color info = Color(0xFF5AA9FF);

  // ============================================================
  // DARK SIGNATURE SURFACES
  // ============================================================

  static const Color darkBackground = Color(0xFF071216);
  static const Color darkSurface = Color(0xFF0B1A20);
  static const Color darkElevated = Color(0xFF10232A);
  static const Color darkInteractive = Color(0xFF163038);

  static const Color darkBorder = Color(0xFF203C44);
  static const Color darkBorderStrong = Color(0xFF31535C);

  // ============================================================
  // LIGHT SURFACES
  // ============================================================

  static const Color lightBackground = Color(0xFFF2F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightInteractive = Color(0xFFE7F1F4);

  static const Color lightBorder = Color(0xFFD5E1E5);
  static const Color lightBorderStrong = Color(0xFFB9CBD1);

  // ============================================================
  // DARK TEXT
  // ============================================================

  static const Color darkTextPrimary = Color(0xFFF3FAFC);
  static const Color darkTextSecondary = Color(0xFFB8C9CE);
  static const Color darkTextMuted = Color(0xFF7A8D94);

  // ============================================================
  // LIGHT TEXT
  // ============================================================

  static const Color lightTextPrimary = Color(0xFF071216);
  static const Color lightTextSecondary = Color(0xFF52666D);
  static const Color lightTextMuted = Color(0xFF7A8D94);

  // ============================================================
  // SPACING
  // ============================================================

  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space40 = 40;

  // ============================================================
  // RADII
  // ============================================================

  static const double radiusXs = 7;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  // ============================================================
  // COMPATIBILITY
  // ============================================================

  // Legacy names retained so existing widgets continue to compile.
  // They now resolve to the new Fusion visual language.
  static const Color copper = electricCyan;
  static const Color copperSoft = cyanSoft;
  static const Color copperDeep = cyanDeep;

  // Old names still referenced by existing screens/theme code.
  static const Color graphiteDeep = deepNavy;
  static const Color graphite = navy;
  static const Color graphiteSoft = navySoft;

  static const Color sage = hybrid;
  static const Color sageSoft = Color(0xFF8BE3BA);
  static const Color sageDeep = Color(0xFF3FAF7D);

  static const Color plum = fusion;
}
