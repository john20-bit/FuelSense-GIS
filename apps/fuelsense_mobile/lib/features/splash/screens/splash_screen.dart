import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../auth/data/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    bool isAuthenticated = false;

    try {
      isAuthenticated = await AuthService.instance.validateSession();
    } catch (_) {
      // Preserve the session when the backend is temporarily unavailable.
      // The protected API client will surface the network error to the app.
      isAuthenticated = await AuthService.instance.isLoggedIn();
    }

    await Future<void>.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;

    context.go(isAuthenticated ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AppBackground(variant: AppBackgroundVariant.intense),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SplashMark()
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.7, 0.7),
                    )
                    .fadeIn(duration: const Duration(milliseconds: 700)),
                const SizedBox(height: 32),
                const Text(
                  'F U E L S E N S E',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                    color: AppColors.primary,
                  ),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 350),
                  duration: const Duration(milliseconds: 500),
                ),
                const SizedBox(height: 10),
                Text(
                  'Energy & Spatial Data',
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: const Color(0xFF94A6B0),
                  ),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 500),
                  duration: const Duration(milliseconds: 500),
                ),
                const SizedBox(height: 18),
                Text(
                  'PETROL • DIESEL • ETHANOL • HYBRID',
                  style: AppTextStyles.labelTechnical.copyWith(
                    color: const Color(0xFF5F7682),
                    fontSize: 7,
                    letterSpacing: 1.15,
                  ),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 700),
                  duration: const Duration(milliseconds: 450),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
          ),
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.28),
                width: 1.2,
              ),
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.textOnPrimary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
