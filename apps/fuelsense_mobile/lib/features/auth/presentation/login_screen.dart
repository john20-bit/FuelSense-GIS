import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.login(email, password);

      if (!mounted) return;

      _showMessage(result['message']?.toString() ?? 'Login successful');

      await Future<void>.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      var message = e.toString();

      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }

      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceElevated,
        ),
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
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.20,
                                ),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'F U E L S E N S E',
                          style: AppTextStyles.labelTechnical.copyWith(
                            color: const Color(0xFFD9E3E7),
                            fontSize: 10,
                            letterSpacing: 2.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 56),
                    Text(
                      'WELCOME BACK',
                      style: AppTextStyles.labelTechnical.copyWith(
                        color: AppColors.primaryCyan,
                        fontSize: 8,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your mobility,\nintelligently connected.',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: const Color(0xFFE9F0F4),
                        fontSize: 30,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Access your vehicle insights, energy '
                      'network, routes and live insights.',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: const Color(0xFF82919E),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _FieldCard(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: Color(0xFFE1E8EC),
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          label: 'EMAIL',
                          hint: 'you@example.com',
                          icon: Icons.email_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldCard(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        style: const TextStyle(
                          color: Color(0xFFE1E8EC),
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          label: 'PASSWORD',
                          hint: 'Enter your password',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF728691),
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: const Color(0xFF061016),
                          disabledBackgroundColor: const Color(0xFF24343D),
                          disabledForegroundColor: const Color(0xFF70828C),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: _isLoading
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
                                    'SIGN IN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0xFF22333D)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'NEW TO FUEL SENSE?',
                            style: AppTextStyles.labelTechnical.copyWith(
                              color: const Color(0xFF60747F),
                              fontSize: 7,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Color(0xFF22333D)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.push('/register'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC8D2D9),
                          side: const BorderSide(color: Color(0xFF2A3C46)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'PETROL • DIESEL • ETHANOL • HYBRID • SPATIAL MAPPING',
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
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
      filled: true,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
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
