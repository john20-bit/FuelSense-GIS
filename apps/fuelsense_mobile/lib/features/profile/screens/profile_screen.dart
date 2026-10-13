import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../auth/data/services/auth_service.dart';
import '../../vehicle/providers/vehicle_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to sign out of FuelSense?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await AuthService.instance.signOut();

    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  const SizedBox(height: 22),

                  _ProfileHero(),
                  const SizedBox(height: 22),

                  Text(
                    'MOBILITY',
                    style: AppTextStyles.labelTechnical.copyWith(
                      color: const Color(0xFF6F8490),
                      fontSize: 8,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  vehiclesAsync.when(
                    loading: () => const _RowSkeleton(),
                    error: (_, _) => _ActionTile(
                      icon: Icons.directions_car_rounded,
                      title: 'Add your vehicle',
                      subtitle: 'Set up your mobility profile',
                      color: AppColors.primary,
                      onTap: () => context.push('/vehicle-setup'),
                    ),
                    data: (vehicles) {
                      if (vehicles.isEmpty) {
                        return _ActionTile(
                          icon: Icons.add_road_rounded,
                          title: 'Add your vehicle',
                          subtitle: 'Unlock personalized intelligence',
                          color: AppColors.primary,
                          onTap: () => context.push('/vehicle-setup'),
                        );
                      }

                      final vehicle = vehicles.first;

                      final energyType = vehicle.isHybrid
                          ? 'Hybrid'
                          : vehicle.fuelType;

                      return _ActionTile(
                        icon: vehicle.isHybrid
                            ? Icons.eco_rounded
                            : Icons.directions_car_rounded,
                        title: vehicle.name,
                        subtitle:
                            '${vehicle.registrationNumber.isEmpty ? 'Vehicle connected' : vehicle.registrationNumber} • $energyType',
                        color: AppColors.primary,
                        onTap: () => context.push('/garage'),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  Text(
                    'FUEL',
                    style: AppTextStyles.labelTechnical.copyWith(
                      color: const Color(0xFF6F8490),
                      fontSize: 8,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Fuel history',
                    subtitle: 'Refueling activity',
                    color: const Color(0xFFB8A7FF),
                    onTap: () => context.push('/energy-history'),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'INTELLIGENCE',
                    style: AppTextStyles.labelTechnical.copyWith(
                      color: const Color(0xFF6F8490),
                      fontSize: 8,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    icon: Icons.water_drop_rounded,
                    title: 'Fuel quality',
                    subtitle: 'Quality and fuel-risk signals',
                    color: const Color(0xFF52E3D0),
                    onTap: () => context.push('/fuel-quality'),
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    icon: Icons.satellite_alt_rounded,
                    title: 'Spatial mapping',
                    subtitle: 'Satellite and activity insights',
                    color: const Color(0xFF7DA7FF),
                    onTap: () => context.push('/spatial-mapping'),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'ACCOUNT',
                    style: AppTextStyles.labelTechnical.copyWith(
                      color: const Color(0xFF6F8490),
                      fontSize: 8,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Alerts and vehicle updates',
                    color: const Color(0xFF52E3D0),
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy & security',
                    subtitle: 'Session and data controls',
                    color: const Color(0xFF7D909B),
                  ),
                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 19,
                      ),
                      label: const Text(
                        'LOG OUT',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.55),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Center(
                    child: Text(
                      'FUEL SENSE • ENERGY MOBILITY INTELLIGENCE',
                      style: TextStyle(
                        color: Color(0xFF4E606A),
                        fontSize: 7,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACCOUNT',
                style: AppTextStyles.labelTechnical.copyWith(
                  color: AppColors.primary,
                  fontSize: 8,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text('Profile', style: AppTextStyles.heading),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF95A6AF),
              size: 19,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF132B36), Color(0xFF0D1C25)],
        ),
        border: Border.all(color: const Color(0xFF2B4C54)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 29,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: FutureBuilder<String?>(
              future: AuthService.instance.getSavedEmail(),
              builder: (context, snapshot) {
                final email =
                    snapshot.data ?? AuthService.instance.currentUser?.email;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email?.split('@').first ?? 'FuelSense Driver',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(
                        color: const Color(0xFFEAF0F3),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email ?? 'Signed in',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(
                        color: const Color(0xFFE2E9ED),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}
