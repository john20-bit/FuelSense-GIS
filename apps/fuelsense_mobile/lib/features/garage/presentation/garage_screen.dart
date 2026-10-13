import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/app_theme_extension.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/state_views.dart';
import '../../../shared/models/vehicle.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../../vehicle/repositories/vehicle_repository.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.fuelTheme;
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: vehiclesAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: theme.accent,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'SYNCING VEHICLES',
                      style: AppTextStyles.labelTechnical.copyWith(
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, stack) {
                final friendly = FriendlyError.from(error);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: ErrorPanel(
                    title: 'Unable to load your vehicles',
                    message: friendly.message,
                    onRetry: () => ref.invalidate(vehicleProvider),
                  ),
                );
              },
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return const _EmptyGarage();
                }

                return RefreshIndicator(
                  color: theme.accent,
                  backgroundColor: theme.surfaceElevated,
                  onRefresh: () async {
                    ref.invalidate(vehicleProvider);
                    await ref.read(vehicleProvider.future);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _GarageHeader(
                              vehicleCount: vehicles.length,
                              onAdd: () => context.push('/vehicle-setup'),
                            ),
                            const SizedBox(height: 26),
                            const SizedBox(height: 18),
                            ...vehicles.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _VehicleCommandCard(
                                  vehicle: entry.value,
                                  index: entry.key,
                                  onTap: () {
                                    context.push(
                                      '/vehicle-details',
                                      extra: entry.value,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _GarageFooter(vehicleCount: vehicles.length),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HEADER
// -----------------------------------------------------------------------------

class _GarageHeader extends StatelessWidget {
  const _GarageHeader({required this.vehicleCount, required this.onAdd});

  final int vehicleCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.accent.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MY VEHICLES',
                    style: AppTextStyles.labelTechnical.copyWith(
                      color: theme.accent,
                      fontSize: 10,
                      letterSpacing: 1.7,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                'Your vehicles',
                style: AppTextStyles.heading.copyWith(
                  color: theme.textPrimary,
                  fontSize: 30,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '$vehicleCount ${vehicleCount == 1 ? 'vehicle' : 'vehicles'} connected to FuelSense.',
                style: AppTextStyles.bodySecondary.copyWith(
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _AddVehicleButton(onTap: onAdd),
      ],
    );
  }
}

class _AddVehicleButton extends StatelessWidget {
  const _AddVehicleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.accent.withValues(alpha: 0.32)),
          ),
          child: Icon(Icons.add_rounded, color: theme.accent, size: 24),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// OVERVIEW
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// FUEL QUALITY ACTION
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// VEHICLE COMMAND CARD
// -----------------------------------------------------------------------------

class _VehicleCommandCard extends ConsumerWidget {
  const _VehicleCommandCard({
    required this.vehicle,
    required this.index,
    required this.onTap,
  });

  final Vehicle vehicle;
  final int index;
  final VoidCallback onTap;

  bool get _isHybrid => vehicle.isHybrid;

  Color _accent(BuildContext context) {
    final theme = context.fuelTheme;

    if (_isHybrid) return FuelSenseDesignTokens.hybrid;
    return theme.accent;
  }

  IconData get _icon {
    if (_isHybrid) return Icons.eco_rounded;
    return Icons.directions_car_rounded;
  }

  String get _typeLabel {
    if (_isHybrid) return 'HYBRID';

    final normalized = vehicle.normalizedFuelType.trim();
    if (normalized.isEmpty) return 'FUEL';

    return normalized.toUpperCase();
  }

  Future<void> _deleteVehicle(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            'Delete Vehicle?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'This will permanently remove ${vehicle.name} and its associated vehicle data.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      if (vehicle.documentId == null) {
        throw StateError('Vehicle record ID is unavailable.');
      }

      await VehicleRepository.instance.deleteVehicle(vehicle.documentId!);

      ref.invalidate(vehicleProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle deleted successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.fuelTheme;
    final accent = _accent(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: theme.borderStrong.withValues(alpha: 0.72),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_icon, color: accent, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(
                        color: theme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      vehicle.registrationNumber.isEmpty
                          ? 'Registration not added'
                          : vehicle.registrationNumber,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        _typeLabel,
                        style: AppTextStyles.labelTechnical.copyWith(
                          color: accent,
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete vehicle',
                onPressed: () => _deleteVehicle(context, ref),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.textMuted,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EMPTY STATE
// -----------------------------------------------------------------------------

class _EmptyGarage extends StatelessWidget {
  const _EmptyGarage();

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'MY VEHICLES',
                      style: AppTextStyles.labelTechnical.copyWith(
                        color: theme.accent,
                        fontSize: 10,
                        letterSpacing: 1.7,
                      ),
                    ),
                    const Spacer(),
                    _AddVehicleButton(
                      onTap: () => GoRouter.of(context).push('/vehicle-setup'),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.accent.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: theme.accent,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No vehicles added yet',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading.copyWith(
                    color: theme.textPrimary,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Add your vehicle to manage its details and keep your '
                  'FuelSense workspace organized.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        GoRouter.of(context).push('/vehicle-setup'),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('ADD VEHICLE', style: AppTextStyles.button),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// FOOTER
// -----------------------------------------------------------------------------

class _GarageFooter extends StatelessWidget {
  const _GarageFooter({required this.vehicleCount});

  final int vehicleCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Row(
      children: [
        Icon(Icons.shield_outlined, color: theme.textMuted, size: 14),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '$vehicleCount ${vehicleCount == 1 ? 'vehicle' : 'vehicles'} monitored by FuelSense',
            style: AppTextStyles.bodySecondary.copyWith(
              color: theme.textMuted,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          'FUEL SENSE GIS',
          style: AppTextStyles.labelTechnical.copyWith(
            color: theme.textMuted,
            fontSize: 7,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
