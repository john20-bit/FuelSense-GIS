import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/state_views.dart';
import '../../fuel/providers/fuel_station_provider.dart';

/// Compact, real-data summary of the single nearest fuel station —
/// replaces two previous widgets that showed 100% hardcoded numbers
/// ("Indian Oil", "₹85 savings") unconnected to any provider.
class NearestStationBanner extends ConsumerWidget {
  const NearestStationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(fuelStationProvider);

    return stationsAsync.when(
      loading: () => const LoadingPanel(message: 'Scanning nearby stations…'),
      error: (error, _) {
        final friendly = FriendlyError.from(error);
        return ErrorPanel(
          title: 'Location intelligence unavailable',
          message: friendly.message,
        );
      },
      data: (stations) {
        if (stations.isEmpty) {
          return const EmptyPanel(
            icon: Icons.wifi_tethering_off_rounded,
            title: 'No stations in range',
            message: 'FuelSense could not find compatible stations nearby.',
          );
        }

        final nearest = stations.first;

        return GestureDetector(
          onTap: () => context.push('/fuel-stations'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: AppColors.surfaceElevated,
              border: Border.all(
                color: AppColors.fuelE20.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.fuelE20.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.local_gas_station_rounded,
                    color: AppColors.fuelE20,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nearest.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${nearest.fuelType} available • ${nearest.distance.toStringAsFixed(1)} km away',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
