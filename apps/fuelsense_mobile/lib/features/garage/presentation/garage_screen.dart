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
                            _GarageOverview(vehicleCount: vehicles.length),
                            const SizedBox(height: 14),
                            _FuelQualityActionCard(
                              onTap: () => context.push('/fuel-quality'),
                            ),
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

class _GarageOverview extends StatelessWidget {
  const _GarageOverview({required this.vehicleCount});

  final int vehicleCount;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.accentSecondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.radar_rounded,
              color: theme.accentSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VEHICLE MONITORING',
                  style: AppTextStyles.labelTechnical.copyWith(
                    color: theme.textMuted,
                    fontSize: 8,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Energy telemetry is ready',
                  style: AppTextStyles.body.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'ONLINE',
            style: AppTextStyles.labelTechnical.copyWith(
              color: theme.success,
              fontSize: 8,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FUEL QUALITY ACTION
// -----------------------------------------------------------------------------

class _FuelQualityActionCard extends StatelessWidget {
  const _FuelQualityActionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: theme.accentSecondary.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.accentSecondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: theme.accentSecondary.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  Icons.water_drop_outlined,
                  color: theme.accentSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FUEL QUALITY',
                      style: AppTextStyles.labelTechnical.copyWith(
                        color: theme.accentSecondary,
                        fontSize: 8,
                        letterSpacing: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phase separation assessment',
                      style: AppTextStyles.body.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Screen storage and blend-related fuel risk.',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: theme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: theme.accentSecondary,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  String get _energyLabel => 'FUEL LEVEL';

  String get _typeLabel {
    if (_isHybrid) return 'HYBRID';

    final normalized = vehicle.normalizedFuelType.trim();
    if (normalized.isEmpty) return 'FUEL';

    return normalized.toUpperCase();
  }

  String get _primaryMetric => vehicle.tankCapacity > 0
      ? '${vehicle.tankCapacity.toStringAsFixed(0)} L'
      : '--';

  String get _primaryLabel => 'TANK';

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
    final percentage = vehicle.fuelPercentage.clamp(0.0, 100.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: theme.borderStrong.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.13),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _VehicleIcon(icon: _icon, accent: accent),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vehicle.registrationNumber.isEmpty
                                    ? 'Vehicle connected'
                                    : vehicle.registrationNumber,
                                style: AppTextStyles.bodySecondary.copyWith(
                                  color: theme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _EnergyTypeBadge(label: _typeLabel, accent: accent),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _EnergyGauge(
                      label: _energyLabel,
                      percentage: percentage,
                      accent: accent,
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: theme.border.withValues(alpha: 0.72)),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 15),
                child: Row(
                  children: [
                    Expanded(
                      child: _TelemetryItem(
                        icon: Icons.speed_rounded,
                        label: 'MILEAGE',
                        value: vehicle.efficiencyLabel,
                        accent: accent,
                      ),
                    ),
                    _TelemetryDivider(),
                    Expanded(
                      child: _TelemetryItem(
                        icon: Icons.local_gas_station_rounded,
                        label: _primaryLabel,
                        value: _primaryMetric,
                        accent: accent,
                      ),
                    ),
                    _TelemetryDivider(),
                    Expanded(
                      child: _TelemetryItem(
                        icon: Icons.route_rounded,
                        label: 'STATUS',
                        value: 'READY',
                        accent: theme.success,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 13),
                decoration: BoxDecoration(
                  color: theme.surface.withValues(alpha: 0.48),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'OPEN INTELLIGENCE',
                      style: AppTextStyles.labelTechnical.copyWith(
                        color: theme.textMuted,
                        fontSize: 8,
                        letterSpacing: 1.15,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Delete vehicle',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () => _deleteVehicle(context, ref),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.textMuted,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, color: accent, size: 17),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// VEHICLE ICON
// -----------------------------------------------------------------------------

class _VehicleIcon extends StatelessWidget {
  const _VehicleIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: accent, size: 27),
    );
  }
}

// -----------------------------------------------------------------------------
// ENERGY TYPE
// -----------------------------------------------------------------------------

class _EnergyTypeBadge extends StatelessWidget {
  const _EnergyTypeBadge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelTechnical.copyWith(
          color: accent,
          fontSize: 7.5,
          letterSpacing: 0.85,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ENERGY GAUGE
// -----------------------------------------------------------------------------

class _EnergyGauge extends StatelessWidget {
  const _EnergyGauge({
    required this.label,
    required this.percentage,
    required this.accent,
  });

  final String label;
  final double percentage;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTextStyles.statLabel.copyWith(
                color: theme.textMuted,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: AppTextStyles.dataValue.copyWith(
                color: accent,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Stack(
            children: [
              Container(
                height: 9,
                width: double.infinity,
                color: theme.surfaceInteractive,
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TELEMETRY
// -----------------------------------------------------------------------------

class _TelemetryItem extends StatelessWidget {
  const _TelemetryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Column(
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.statLabel.copyWith(
            color: theme.textMuted,
            fontSize: 7.5,
            letterSpacing: 0.65,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _TelemetryDivider extends StatelessWidget {
  const _TelemetryDivider();

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Container(
      width: 1,
      height: 42,
      color: theme.border.withValues(alpha: 0.7),
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
                    Icons.garage_rounded,
                    color: theme.accent,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your garage is empty',
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
