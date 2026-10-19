import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/state_views.dart';
import '../../fuel/providers/fuel_station_provider.dart';
import '../../fuel/widgets/fuel_station_card.dart';

class NearbyStationSection extends ConsumerWidget {
  const NearbyStationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(fuelStationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stationsAsync.when(
          loading: () => const LoadingPanel(message: 'Scanning fuel radar…'),
          error: (error, _) {
            final friendly = FriendlyError.from(error);
            return ErrorPanel(
              title: 'Unable to load nearby stations',
              message: friendly.message,
              onRetry: () => ref.invalidate(fuelStationProvider),
            );
          },
          data: (stations) {
            final preview = stations.take(3).toList();

            if (preview.isEmpty) {
              return const EmptyPanel(
                icon: Icons.explore_off_rounded,
                title: 'No stations found',
                message: 'No fuel stations detected within range right now.',
              );
            }

            return Column(
              children: preview
                  .map(
                    (station) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FuelStationCard(station: station),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/fuel-stations'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('View All Fuel Stations'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
