import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/fuel_station_model.dart';

class FuelStationCard extends StatelessWidget {
  const FuelStationCard({
    super.key,
    required this.station,
    this.isNearest = false,
  });

  final FuelStation station;
  final bool isNearest;

  Color get _availabilityColor {
    if (station.availability >= 60) {
      return AppColors.success;
    }

    if (station.availability >= 25) {
      return AppColors.warning;
    }

    return AppColors.error;
  }

  String get _availabilityLabel {
    if (station.availability >= 60) {
      return 'HIGH AVAILABILITY';
    }

    if (station.availability >= 25) {
      return 'MODERATE';
    }

    return 'LOW SUPPLY';
  }

  Future<void> _openGoogleMaps() async {
    final destination = Uri.encodeComponent(
      '${station.name}, ${station.location}',
    );

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destination'
      '&travelmode=driving',
    );

    try {
      final opened = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception('Unable to open Google Maps');
      }
    } catch (e) {
      debugPrint('Google Maps launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final availability = (station.availability / 100).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isNearest
              ? AppColors.primary.withValues(alpha: 0.34)
              : AppColors.border,
        ),
        boxShadow: [
          if (isNearest)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNearest) ...[
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'FUSION RECOMMENDED',
                    style: AppTextStyles.labelTechnical.copyWith(
                      color: AppColors.primary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.fuelE20.withValues(alpha: 0.10),
                    border: Border.all(
                      color: AppColors.fuelE20.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_gas_station_rounded,
                    color: AppColors.fuelE20,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        station.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      station.distance < 10
                          ? station.distance.toStringAsFixed(1)
                          : station.distance.toStringAsFixed(0),
                      style: AppTextStyles.dataValue.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'KM',
                      style: AppTextStyles.labelTechnical.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                _InfoChip(
                  icon: Icons.local_fire_department_rounded,
                  label: station.fuelType,
                  color: AppColors.fuelE20,
                ),
                const SizedBox(width: 7),
                _InfoChip(
                  icon: Icons.circle,
                  label: _availabilityLabel,
                  color: _availabilityColor,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FUEL AVAILABILITY',
                  style: AppTextStyles.labelTechnical.copyWith(fontSize: 9),
                ),
                Text(
                  '${station.availability}%',
                  style: AppTextStyles.dataValue.copyWith(
                    color: _availabilityColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: availability,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.055),
                valueColor: AlwaysStoppedAnimation<Color>(_availabilityColor),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Updated ${station.lastUpdated}',
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('NAVIGATE TO STATION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: AppTextStyles.labelTechnical.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelTechnical.copyWith(
                  color: color,
                  fontSize: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
