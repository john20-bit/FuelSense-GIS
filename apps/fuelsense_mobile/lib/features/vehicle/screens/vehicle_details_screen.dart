import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/app_theme_extension.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../../shared/models/vehicle.dart';

class VehicleDetailsScreen extends StatelessWidget {
  const VehicleDetailsScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  Color _accent(BuildContext context) {
    final theme = context.fuelTheme;
    if (vehicle.isHybrid) return const Color(0xFF9A8BFF);
    return theme.accent;
  }

  IconData get _vehicleIcon {
    if (vehicle.isHybrid) return Icons.electric_car_rounded;
    return Icons.directions_car_rounded;
  }

  String get _powertrainLabel {
    if (vehicle.isHybrid) return 'HYBRID';
    return vehicle.normalizedFuelType.isEmpty
        ? 'FUEL VEHICLE'
        : vehicle.normalizedFuelType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;
    final accent = _accent(context);
    final fuelLevel = vehicle.fuelPercentage;

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _Header(vehicle: vehicle, accent: accent),
                      const SizedBox(height: 24),
                      _VehicleIdentityCard(
                        vehicle: vehicle,
                        accent: accent,
                        icon: _vehicleIcon,
                        powertrainLabel: _powertrainLabel,
                      ),
                      const SizedBox(height: 16),
                      _EnergyCard(
                        vehicle: vehicle,
                        accent: accent,
                        fuelLevel: fuelLevel,
                      ),
                      const SizedBox(height: 16),
                      _VehicleSpecsCard(vehicle: vehicle),
                      const SizedBox(height: 16),
                      _FuelCompatibilityCard(vehicle: vehicle),
                      const SizedBox(height: 16),
                      _VerificationCard(vehicle: vehicle),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vehicle, required this.accent});

  final Vehicle vehicle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back_rounded, color: theme.textPrimary),
          tooltip: 'Back',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MY VEHICLE',
                style: AppTextStyles.labelTechnical.copyWith(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 1.7,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                vehicle.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading.copyWith(
                  color: theme.textPrimary,
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push('/vehicle-setup', extra: vehicle),
          tooltip: 'Edit vehicle',
          icon: Icon(Icons.edit_rounded, color: theme.textPrimary),
        ),
      ],
    );
  }
}

class _VehicleIdentityCard extends StatelessWidget {
  const _VehicleIdentityCard({
    required this.vehicle,
    required this.accent,
    required this.icon,
    required this.powertrainLabel,
  });

  final Vehicle vehicle;
  final Color accent;
  final IconData icon;
  final String powertrainLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return _Panel(
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: accent.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, color: accent, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayName,
                  style: AppTextStyles.heading.copyWith(
                    color: theme.textPrimary,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  vehicle.registrationNumber.isEmpty
                      ? 'REGISTRATION NOT ADDED'
                      : vehicle.registrationNumber,
                  style: AppTextStyles.labelTechnical.copyWith(
                    color: theme.textMuted,
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    _Tag(label: powertrainLabel, accent: accent),
                    if (vehicle.modelYear != null)
                      _Tag(
                        label: '${vehicle.modelYear}',
                        accent: theme.textSecondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  const _EnergyCard({
    required this.vehicle,
    required this.accent,
    required this.fuelLevel,
  });

  final Vehicle vehicle;
  final Color accent;
  final double fuelLevel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;
    final level = fuelLevel.clamp(0.0, 100.0);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'FUEL STATUS', accent: accent),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${level.toStringAsFixed(0)}%',
                style: AppTextStyles.heading.copyWith(
                  color: theme.textPrimary,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 9),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '%',
                  style: AppTextStyles.labelTechnical.copyWith(
                    color: theme.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: level / 100,
              backgroundColor: theme.border.withValues(alpha: 0.45),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'MILEAGE',
                  value: vehicle.efficiencyLabel,
                ),
              ),
              if (vehicle.hasFuelTank)
                Expanded(
                  child: _Metric(
                    label: 'TANK',
                    value: '${vehicle.tankCapacity.toStringAsFixed(0)} L',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleSpecsCard extends StatelessWidget {
  const _VehicleSpecsCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'VEHICLE DETAILS'),
          const SizedBox(height: 14),
          _DetailRow(label: 'MAKE', value: vehicle.make),
          _DetailRow(label: 'MODEL', value: vehicle.model),
          _DetailRow(label: 'VARIANT', value: vehicle.variant),
          _DetailRow(
            label: 'ODOMETER',
            value: vehicle.currentOdometer > 0
                ? '${vehicle.currentOdometer.toStringAsFixed(0)} km'
                : null,
          ),
          _DetailRow(
            label: 'CLAIMED MILEAGE',
            value: vehicle.currentMileage > 0
                ? '${vehicle.currentMileage.toStringAsFixed(1)} km/L'
                : null,
          ),
          _DetailRow(label: 'FUEL TYPE', value: vehicle.fuelType),
        ],
      ),
    );
  }
}

class _FuelCompatibilityCard extends StatelessWidget {
  const _FuelCompatibilityCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'FUEL GUIDANCE'),
          const SizedBox(height: 14),
          _CompatibilityRow(
            label: 'E20 COMPATIBILITY',
            value: vehicle.e20Compatible,
          ),
          _CompatibilityRow(
            label: 'E85 COMPATIBILITY',
            value: vehicle.e85Compatible,
          ),
          if (vehicle.e20Compatible == null && vehicle.e85Compatible == null)
            Text(
              'No verified fuel guidance is available for this vehicle yet.',
              style: AppTextStyles.bodySecondary.copyWith(
                color: theme.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;
    final hasSource = vehicle.catalogId != null;

    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: theme.accent, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSource ? 'CATALOG RECORD' : 'VEHICLE RECORD',
                  style: AppTextStyles.labelTechnical.copyWith(
                    color: theme.textPrimary,
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasSource
                      ? 'Vehicle specifications are linked to the selected catalog record.'
                      : 'Vehicle information is stored in your private Firebase account.',
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: theme.textMuted,
                  ),
                ),
                if (vehicle.documentId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'FIRESTORE ID • ${vehicle.documentId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelTechnical.copyWith(
                      color: theme.textMuted,
                      fontSize: 7,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.border.withValues(alpha: 0.8)),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.accent});

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Text(
      label,
      style: AppTextStyles.labelTechnical.copyWith(
        color: accent ?? theme.textMuted,
        fontSize: 9,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelTechnical.copyWith(
            color: theme.textMuted,
            fontSize: 7,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: AppTextStyles.labelTechnical.copyWith(
                color: theme.textMuted,
                fontSize: 8,
                letterSpacing: 0.9,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value == null || value!.trim().isEmpty ? 'NOT AVAILABLE' : value!,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompatibilityRow extends StatelessWidget {
  const _CompatibilityRow({required this.label, required this.value});

  final String label;
  final bool? value;

  @override
  Widget build(BuildContext context) {
    final theme = context.fuelTheme;

    final text = switch (value) {
      true => 'YES',
      false => 'NO',
      null => 'NOT VERIFIED',
    };

    final color = switch (value) {
      true => theme.accent,
      false => theme.textMuted,
      null => theme.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelTechnical.copyWith(
                color: theme.textMuted,
                fontSize: 8,
                letterSpacing: 0.9,
              ),
            ),
          ),
          Text(
            text,
            style: AppTextStyles.labelTechnical.copyWith(
              color: color,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelTechnical.copyWith(
          color: accent,
          fontSize: 7,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
