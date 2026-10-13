import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/onboarding_model.dart';

/// A single onboarding page: icon mark, title, supporting copy.
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({super.key, required this.page});

  final OnboardingPageModel page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _OnboardingMark(icon: page.icon, color: page.accent),
          const SizedBox(height: 44),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppTextStyles.bodySecondary.color,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingMark extends StatelessWidget {
  const _OnboardingMark({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 50,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, size: 56, color: color),
    );
  }
}
