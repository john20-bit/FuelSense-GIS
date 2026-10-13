import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/state_views.dart';
import '../models/fuel_station_model.dart';
import '../providers/fuel_station_provider.dart';
import '../widgets/fuel_station_card.dart';

class NearbyFuelScreen extends ConsumerWidget {
  const NearbyFuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(fuelStationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: stationsAsync.when(
              loading: () => const _FuelNetworkLoading(),
              error: (error, _) => _buildError(context, ref, error),
              data: (stations) => _buildStations(context, ref, stations),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final friendly = FriendlyError.from(error);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        children: [
          const _NetworkHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: ErrorPanel(
              title: 'Fuel network unavailable',
              message: friendly.message,
              onRetry: () => ref.invalidate(fuelStationsProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStations(
    BuildContext context,
    WidgetRef ref,
    List<FuelStation> stations,
  ) {
    if (stations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          children: [
            const _NetworkHeader(stationCount: 0),
            const SizedBox(height: 20),
            const Expanded(
              child: EmptyPanel(
                icon: Icons.radar_rounded,
                title: 'No stations detected',
                message:
                    'Fusion could not find compatible fuel stations '
                    'within the current search radius.',
              ),
            ),
          ],
        ),
      );
    }

    final averageAvailability =
        stations.fold<double>(0, (sum, station) => sum + station.availability) /
        stations.length;

    final highAvailabilityCount = stations
        .where((station) => station.availability >= 60)
        .length;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () async {
        ref.invalidate(fuelStationsProvider);
        await ref.read(fuelStationsProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(child: _NetworkHeader()),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _NetworkSummary(
                stationCount: stations.length,
                nearestDistance: stations.first.distance,
                averageAvailability: averageAvailability,
                highAvailabilityCount: highAvailabilityCount,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'NEAREST INTELLIGENCE',
                    style: AppTextStyles.labelTechnical.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${stations.length} DETECTED',
                    style: AppTextStyles.labelTechnical.copyWith(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            sliver: SliverList.builder(
              itemCount: stations.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FuelStationCard(
                    station: stations[index],
                    isNearest: index == 0,
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

class _NetworkHeader extends StatelessWidget {
  const _NetworkHeader({this.stationCount});

  final int? stationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.primary.withValues(alpha: 0.10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
            ),
          ),
          child: const Icon(
            Icons.radar_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FUEL NETWORK',
                style: AppTextStyles.labelTechnical.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Nearby Intelligence',
                style: AppTextStyles.title.copyWith(fontSize: 20),
              ),
            ],
          ),
        ),
        if (stationCount != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$stationCount',
              style: AppTextStyles.dataValue.copyWith(
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }
}

class _NetworkSummary extends StatelessWidget {
  const _NetworkSummary({
    required this.stationCount,
    required this.nearestDistance,
    required this.averageAvailability,
    required this.highAvailabilityCount,
  });

  final int stationCount;
  final double nearestDistance;
  final double averageAvailability;
  final int highAvailabilityCount;

  @override
  Widget build(BuildContext context) {
    final networkColor = averageAvailability >= 60
        ? AppColors.success
        : averageAvailability >= 25
        ? AppColors.warning
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SummaryItem(
                icon: Icons.radar_rounded,
                value: '$stationCount',
                label: 'STATIONS',
                color: AppColors.primary,
              ),
              _divider(),
              _SummaryItem(
                icon: Icons.near_me_rounded,
                value: _distanceText(nearestDistance),
                label: 'NEAREST',
                color: AppColors.primaryBlue,
              ),
              _divider(),
              _SummaryItem(
                icon: Icons.local_gas_station_rounded,
                value: '${averageAvailability.toStringAsFixed(0)}%',
                label: 'AVG SUPPLY',
                color: networkColor,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: networkColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: networkColor.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: networkColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$highAvailabilityCount stations currently show '
                    'high fuel availability',
                    style: AppTextStyles.caption,
                  ),
                ),
                Text(
                  'LIVE',
                  style: AppTextStyles.labelTechnical.copyWith(
                    color: networkColor,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _distanceText(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    }

    if (distance < 10) {
      return '${distance.toStringAsFixed(1)}km';
    }

    return '${distance.toStringAsFixed(0)}km';
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.border,
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.dataValue.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.labelTechnical.copyWith(
              fontSize: 7,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelNetworkLoading extends StatelessWidget {
  const _FuelNetworkLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.22),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(19),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'SCANNING FUEL NETWORK',
            style: AppTextStyles.labelTechnical.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Locating nearby stations...',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
