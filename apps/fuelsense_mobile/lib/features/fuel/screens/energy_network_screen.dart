import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/fuel_station_model.dart';
import '../providers/fuel_station_provider.dart';

enum FuelFilter { all, petrol, diesel }

class EnergyNetworkScreen extends ConsumerStatefulWidget {
  const EnergyNetworkScreen({super.key});

  @override
  ConsumerState<EnergyNetworkScreen> createState() =>
      _EnergyNetworkScreenState();
}

class _EnergyNetworkScreenState extends ConsumerState<EnergyNetworkScreen> {
  FuelFilter _filter = FuelFilter.all;

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(fuelStationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF071018),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF52E3D0),
          backgroundColor: const Color(0xFF101D27),
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
                padding: EdgeInsets.fromLTRB(18, 22, 18, 14),
                sliver: SliverToBoxAdapter(child: _FuelHeader()),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(
                  child: _FuelNetworkSummary(stationsAsync: stationsAsync),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: _FuelFilterBar(
                    selected: _filter,
                    onChanged: (filter) {
                      setState(() {
                        _filter = filter;
                      });
                    },
                  ),
                ),
              ),
              stationsAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LoadingView(),
                ),
                error: (error, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorView(
                    onRetry: () {
                      ref.invalidate(fuelStationsProvider);
                    },
                  ),
                ),
                data: (stations) {
                  final filtered = stations.where(_matchesFilter).toList();

                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyView(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final station = filtered[index];

                        return _FuelStationCard(
                          station: station,
                          onTap: () {
                            context.push('/station-details', extra: station);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesFilter(FuelStation station) {
    switch (_filter) {
      case FuelFilter.all:
        return station.hasFuel;

      case FuelFilter.petrol:
        return station.petrolAvailable ||
            station.premiumPetrolAvailable ||
            station.e20Available ||
            station.e85Available;

      case FuelFilter.diesel:
        return station.dieselAvailable || station.premiumDieselAvailable;
    }
  }
}

class _FuelHeader extends StatelessWidget {
  const _FuelHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF10232D),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_gas_station_rounded,
                color: Color(0xFF52E3D0),
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FUEL NETWORK',
                    style: TextStyle(
                      color: Color(0xFF52E3D0),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Find fuel near you',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        const Text(
          'Explore nearby fuel stations and available fuel types.',
          style: TextStyle(color: Color(0xFF8FA3AF), fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}

class _FuelNetworkSummary extends StatelessWidget {
  const _FuelNetworkSummary({required this.stationsAsync});

  final AsyncValue<List<FuelStation>> stationsAsync;

  @override
  Widget build(BuildContext context) {
    return stationsAsync.when(
      loading: () => const SizedBox(height: 92),
      error: (_, _) => const SizedBox(height: 92),
      data: (stations) {
        final fuelStations = stations
            .where((station) => station.hasFuel)
            .toList();

        final petrolCount = fuelStations
            .where(
              (station) =>
                  station.petrolAvailable ||
                  station.premiumPetrolAvailable ||
                  station.e20Available ||
                  station.e85Available,
            )
            .length;

        final dieselCount = fuelStations
            .where(
              (station) =>
                  station.dieselAvailable || station.premiumDieselAvailable,
            )
            .length;

        return Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'STATIONS',
                value: '${fuelStations.length}',
                icon: Icons.location_on_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                label: 'PETROL',
                value: '$petrolCount',
                icon: Icons.local_gas_station_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                label: 'DIESEL',
                value: '$dieselCount',
                icon: Icons.local_gas_station_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 10, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A23),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1B303B)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF52E3D0)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF718793),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .7,
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

class _FuelFilterBar extends StatelessWidget {
  const _FuelFilterBar({required this.selected, required this.onChanged});

  final FuelFilter selected;
  final ValueChanged<FuelFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'ALL',
          selected: selected == FuelFilter.all,
          onTap: () => onChanged(FuelFilter.all),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'PETROL',
          selected: selected == FuelFilter.petrol,
          onTap: () => onChanged(FuelFilter.petrol),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'DIESEL',
          selected: selected == FuelFilter.diesel,
          onTap: () => onChanged(FuelFilter.diesel),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFF163B3C) : const Color(0xFF0D1A23),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF52E3D0)
                    : const Color(0xFF1B303B),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF52E3D0)
                    : const Color(0xFF8FA3AF),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FuelStationCard extends StatelessWidget {
  const _FuelStationCard({required this.station, required this.onTap});

  final FuelStation station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fuelTags = <String>[];

    if (station.petrolAvailable) fuelTags.add('PETROL');
    if (station.premiumPetrolAvailable) {
      fuelTags.add('PREMIUM PETROL');
    }
    if (station.e20Available) fuelTags.add('E20');
    if (station.e85Available) fuelTags.add('E85');
    if (station.dieselAvailable) fuelTags.add('DIESEL');
    if (station.premiumDieselAvailable) {
      fuelTags.add('PREMIUM DIESEL');
    }

    final tags = fuelTags.take(4).toList();

    return Material(
      color: const Color(0xFF0D1A23),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1B303B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF102A30),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.local_gas_station_rounded,
                      color: Color(0xFF52E3D0),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name.trim().isEmpty
                              ? 'Fuel Station'
                              : station.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          station.location.trim().isEmpty
                              ? 'Location unavailable'
                              : station.location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8196A1),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF627984),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _StationMeta(
                    icon: Icons.near_me_outlined,
                    value: _distanceLabel(station.distance),
                  ),
                  const SizedBox(width: 14),
                  _StationMeta(
                    icon: Icons.local_gas_station_outlined,
                    value: _fuelCountLabel(station),
                  ),
                ],
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 13),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: tags.map((tag) => _FuelTag(label: tag)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _distanceLabel(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  String _fuelCountLabel(FuelStation station) {
    final count = [
      station.petrolAvailable,
      station.premiumPetrolAvailable,
      station.e20Available,
      station.e85Available,
      station.dieselAvailable,
      station.premiumDieselAvailable,
    ].where((available) => available).length;

    return '$count fuel types';
  }
}

class _StationMeta extends StatelessWidget {
  const _StationMeta({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF52E3D0)),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFB5C4CB),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FuelTag extends StatelessWidget {
  const _FuelTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF13242D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF91A7B1),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF52E3D0)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFF8196A1),
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'FUEL DATA UNAVAILABLE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'FuelSense could not retrieve nearby fuel stations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8196A1),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF52E3D0),
                side: const BorderSide(color: Color(0xFF28535A)),
              ),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_gas_station_outlined,
              color: Color(0xFF8196A1),
              size: 42,
            ),
            SizedBox(height: 14),
            Text(
              'NO FUEL STATIONS FOUND',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No matching fuel stations are available for this category.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8196A1),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
