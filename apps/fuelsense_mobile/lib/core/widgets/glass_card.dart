import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),

      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),

        child: Container(
          padding: padding,

          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),

            borderRadius: BorderRadius.circular(AppRadius.lg),

            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),

          child: child,
        ),
      ),
    );
  }
}
