import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/data/services/auth_service.dart';

class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  String _greetingFor(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingFor(DateTime.now().hour);

    return FutureBuilder<String?>(
      future: AuthService.instance.getSavedEmail(),
      builder: (context, snapshot) {
        final email = snapshot.data ?? AuthService.instance.currentUser?.email;
        final name = email != null && email.contains('@')
            ? email.split('@').first
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name != null ? '$greeting, ${_capitalize(name)}' : greeting,
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Fuel insights active',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
