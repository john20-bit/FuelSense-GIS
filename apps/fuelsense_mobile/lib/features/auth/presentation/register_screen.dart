import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../data/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool obscurePassword = true;
  String? errorMessage;

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await AuthService.instance.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(),
      );

      if (!mounted) return;

      context.go('/vehicle-setup');
    } on Exception catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(
    String label,
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: Color(0xFF6F8490),
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
      hintStyle: const TextStyle(color: Color(0xFF627681), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF718590), size: 19),
      suffixIcon: suffix,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AppBackground(variant: AppBackgroundVariant.intense),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _RoundButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: loading ? null : () => context.go('/login'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Text(
                                'F U E L S E N S E',
                                style: AppTextStyles.labelTechnical.copyWith(
                                  color: const Color(0xFFD9E3E7),
                                  fontSize: 9,
                                  letterSpacing: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'CREATE ACCOUNT',
                      style: AppTextStyles.labelTechnical.copyWith(
                        color: AppColors.primaryCyan,
                        fontSize: 8,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build your\nmobility profile.',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: const Color(0xFFE9F0F4),
                        fontSize: 30,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Connect your vehicle and unlock intelligent '
                      'energy, route and spatial insights.',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: const Color(0xFF82919E),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _FieldCard(
                      child: TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: Color(0xFFE1E8EC),
                          fontSize: 14,
                        ),
                        decoration: _decoration(
                          'FULL NAME',
                          'Your name',
                          Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    _FieldCard(
                      child: TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: Color(0xFFE1E8EC),
                          fontSize: 14,
                        ),
                        decoration: _decoration(
                          'EMAIL',
                          'you@example.com',
                          Icons.mail_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email';
                          }

                          final email = value.trim();

                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Enter a valid email';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    _FieldCard(
                      child: TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: Color(0xFFE1E8EC),
                          fontSize: 14,
                        ),
                        decoration: _decoration(
                          'PHONE',
                          'Your phone number',
                          Icons.phone_outlined,
                        ),
                        validator: (value) {
                          final phone = value?.trim() ?? '';

                          if (phone.length < 10) {
                            return 'Enter a valid phone number';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    _FieldCard(
                      child: TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!loading) {
                            register();
                          }
                        },
                        style: const TextStyle(
                          color: Color(0xFFE1E8EC),
                          fontSize: 14,
                        ),
                        decoration: _decoration(
                          'PASSWORD',
                          'At least 6 characters',
                          Icons.lock_outline_rounded,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF728691),
                              size: 19,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }

                          return null;
                        },
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: AppTextStyles.bodySecondary.copyWith(
                                  color: AppColors.error,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: loading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: const Color(0xFF061016),
                          disabledBackgroundColor: const Color(0xFF24343D),
                          disabledForegroundColor: const Color(0xFF70828C),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Color(0xFF061016),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CREATE ACCOUNT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: TextButton(
                        onPressed: loading ? null : () => context.go('/login'),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySecondary,
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign in',
                                style: AppTextStyles.bodySecondary.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'PETROL • DIESEL • ETHANOL • HYBRID • FUEL SENSE GIS',
                        style: AppTextStyles.labelTechnical.copyWith(
                          color: const Color(0xFF50636E),
                          fontSize: 6.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A23),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF21323D)),
      ),
      child: child,
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFF101D27),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF263743)),
        ),
        child: Icon(
          icon,
          color: onTap == null
              ? const Color(0xFF4E606A)
              : const Color(0xFFC8D2D9),
          size: 19,
        ),
      ),
    );
  }
}
