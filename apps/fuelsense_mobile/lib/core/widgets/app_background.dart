import 'package:flutter/material.dart';

import '../design/app_theme_extension.dart';
import '../design/design_tokens.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    this.variant = AppBackgroundVariant.standard,
  });

  final AppBackgroundVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.background, const Color(0xFFEDE7DE)],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      );
    }

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: theme.background),

          Positioned(
            top: -130,
            left: -100,
            child: _AmbientOrb(
              size: 300,
              color: FuelSenseDesignTokens.copper.withValues(alpha: 0.045),
            ),
          ),

          Positioned(
            top: 230,
            right: -150,
            child: _AmbientOrb(
              size: 340,
              color: FuelSenseDesignTokens.sage.withValues(alpha: 0.035),
            ),
          ),

          if (variant == AppBackgroundVariant.intense)
            Positioned(
              bottom: -170,
              left: 50,
              child: _AmbientOrb(
                size: 330,
                color: FuelSenseDesignTokens.plum.withValues(alpha: 0.035),
              ),
            ),
        ],
      ),
    );
  }
}

enum AppBackgroundVariant { standard, intense }

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 110, spreadRadius: 20)],
      ),
    );
  }
}
