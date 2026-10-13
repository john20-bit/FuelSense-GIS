import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OnboardingPageModel {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String buttonText;

  const OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.buttonText,
  });
}

const onboardingPages = [
  OnboardingPageModel(
    title: 'Energy Intelligence,\nNot Guesswork',
    subtitle:
        'FuelSense understands petrol, diesel, ethanol-blended fuels, '
        'hybrids and ethanol fuels to help you make smarter fuel decisions.',
    icon: Icons.bolt_rounded,
    accent: AppColors.primary,
    buttonText: 'Get Started',
  ),
  OnboardingPageModel(
    title: 'One Network,\nEvery Energy Stop',
    subtitle:
        'Discover fuel stations using distance, '
        'availability, compatibility and energy-type information.',
    icon: Icons.hub_rounded,
    accent: AppColors.secondary,
    buttonText: 'Continue',
  ),
  OnboardingPageModel(
    title: 'Smarter Mobility,\nBacked by Data',
    subtitle:
        'Track range, efficiency, routes and energy costs while '
        'FuelSense combines vehicle, spatial and network intelligence '
        'to guide your next move.',
    icon: Icons.auto_awesome_rounded,
    accent: AppColors.accentViolet,
    buttonText: 'Start',
  ),
];
