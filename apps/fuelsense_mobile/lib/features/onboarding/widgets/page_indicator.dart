import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Animated dash indicator for the onboarding PageView.
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    this.activeColor = AppColors.primary,
  });

  final int count;
  final int currentIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: active ? 26 : 6,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
