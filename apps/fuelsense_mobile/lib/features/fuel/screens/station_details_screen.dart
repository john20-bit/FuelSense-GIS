import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/fuel_station_model.dart';

class StationDetailsScreen extends StatelessWidget {
  const StationDetailsScreen({super.key, required this.station});

  final FuelStation station;

  @override
  Widget build(BuildContext context) {
    final distance = station.distance < 10
        ? '${station.distance.toStringAsFixed(1)} km'
        : '${station.distance.toStringAsFixed(0)} km';

    final isOpen = station.status.toUpperCase() == 'OPEN';
    final fuels = _availableFuels(station);

    return Scaffold(
      backgroundColor: const Color(0xFF071018),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              sliver: SliverToBoxAdapter(
                child: _Header(station: station, onBack: () => context.pop()),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(
                child: _StationHero(
                  station: station,
                  distance: distance,
                  isOpen: isOpen,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 10),
              sliver: SliverToBoxAdapter(
                child: _SectionLabel('FUEL AVAILABLE'),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(
                child: _FuelAvailabilityCard(station: station, fuels: fuels),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 10),
              sliver: SliverToBoxAdapter(
                child: _SectionLabel('FUEL INSIGHTS'),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(
                child: _FuelIntelligenceCard(station: station, fuels: fuels),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 10),
              sliver: SliverToBoxAdapter(child: _SectionLabel('LOCATION')),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(
                child: _LocationCard(station: station, distance: distance),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 32),
              sliver: SliverToBoxAdapter(
                child: _RouteButton(
                  onTap: () {
                    context.push('/fuel-map?stationId=${station.id}');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<_FuelItem> _availableFuels(FuelStation station) {
    final fuels = <_FuelItem>[];

    if (station.petrolAvailable) {
      fuels.add(
        const _FuelItem(
          name: 'PETROL',
          type: 'PETROL',
          status: 'AVAILABLE',
          icon: Icons.local_gas_station_rounded,
        ),
      );
    }

    if (station.premiumPetrolAvailable) {
      fuels.add(
        const _FuelItem(
          name: 'PREMIUM PETROL',
          type: 'PETROL',
          status: 'AVAILABLE',
          icon: Icons.local_gas_station_rounded,
        ),
      );
    }

    if (station.e20Available) {
      fuels.add(
        const _FuelItem(
          name: 'E20',
          type: 'PETROL',
          status: 'AVAILABLE',
          icon: Icons.local_gas_station_rounded,
        ),
      );
    }

    if (station.e85Available) {
      fuels.add(
        const _FuelItem(
          name: 'E85',
          type: 'PETROL',
          status: 'AVAILABLE',
          icon: Icons.local_gas_station_rounded,
        ),
      );
    }

    if (station.dieselAvailable) {
      fuels.add(
        const _FuelItem(
          name: 'DIESEL',
          type: 'DIESEL',
          status: 'AVAILABLE',
          icon: Icons.local_gas_station_rounded,
        ),
      );
    }

    if (station.premiumDieselAvailable) {
      fuels.add(
        const _FuelItem(
          name: 'PREMIUM DIESEL',
          type: 'DIESEL',
          status: 'AVAILABLE',
          icon: Icons.local_gas_station_rounded,
        ),
      );
    }

    if (fuels.isEmpty && station.fuelType.trim().isNotEmpty) {
      fuels.add(
        _FuelItem(
          name: station.fuelType.toUpperCase(),
          type: station.fuelType.toUpperCase(),
          status: 'UNVERIFIED',
          icon: Icons.local_gas_station_rounded,
        ),
      );
    }

    return fuels;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.station, required this.onBack});

  final FuelStation station;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FUEL STATION',
                style: AppTextStyles.labelTechnical.copyWith(
                  color: const Color(0xFF52E3D0),
                  fontSize: 8,
                  letterSpacing: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                station.name.isEmpty ? 'Fuel Station' : station.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.displayMedium.copyWith(
                  color: const Color(0xFFE9F0F4),
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StationHero extends StatelessWidget {
  const _StationHero({
    required this.station,
    required this.distance,
    required this.isOpen,
  });

  final FuelStation station;
  final String distance;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF132B36), Color(0xFF0D1C25)],
        ),
        border: Border.all(color: const Color(0xFF2C4B51)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF52E3D0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: Color(0xFF52E3D0),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name.isEmpty ? 'Fuel Station' : station.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(
                        color: const Color(0xFFE8F0F3),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      station.location.isEmpty
                          ? 'Location unavailable'
                          : station.location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF718590),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'DISTANCE',
                  value: distance,
                  icon: Icons.near_me_rounded,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _Metric(
                  label: 'STATUS',
                  value: isOpen ? 'OPEN' : station.status.toUpperCase(),
                  icon: isOpen
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  accent: isOpen
                      ? const Color(0xFF52E3D0)
                      : const Color(0xFFFFC857),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FuelAvailabilityCard extends StatelessWidget {
  const _FuelAvailabilityCard({required this.station, required this.fuels});

  final FuelStation station;
  final List<_FuelItem> fuels;

  @override
  Widget build(BuildContext context) {
    if (fuels.isEmpty) {
      return _InfoCard(
        icon: Icons.help_outline_rounded,
        title: 'Fuel information unavailable',
        message:
            'This station does not currently provide verified fuel-type information.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF203640)),
      ),
      child: Column(
        children: fuels
            .map(
              (fuel) => Padding(
                padding: EdgeInsets.only(bottom: fuel == fuels.last ? 0 : 10),
                child: _FuelRow(fuel: fuel),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FuelRow extends StatelessWidget {
  const _FuelRow({required this.fuel});

  final _FuelItem fuel;

  @override
  Widget build(BuildContext context) {
    final verified = fuel.status == 'AVAILABLE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF111F27),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(fuel.icon, color: const Color(0xFF52E3D0), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fuel.name,
                  style: AppTextStyles.title.copyWith(
                    color: const Color(0xFFE4EDF1),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fuel.type,
                  style: AppTextStyles.labelTechnical.copyWith(
                    color: const Color(0xFF6F8490),
                    fontSize: 7,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(label: fuel.status, positive: verified),
        ],
      ),
    );
  }
}

class _FuelIntelligenceCard extends StatelessWidget {
  const _FuelIntelligenceCard({required this.station, required this.fuels});

  final FuelStation station;
  final List<_FuelItem> fuels;

  @override
  Widget build(BuildContext context) {
    final hasE20 = station.e20Available;

    String title;
    String message;
    IconData icon;

    if (hasE20) {
      title = 'E20 available';
      message =
          'E20 is listed at this station. Your vehicle compatibility should be checked before selecting it.';
      icon = Icons.verified_outlined;
    } else if (fuels.isNotEmpty) {
      title = 'Fuel match available';
      message =
          'Fuel types are listed for this station. FuelSense can use your vehicle profile to determine suitability.';
      icon = Icons.local_gas_station_outlined;
    } else {
      title = 'Fuel match unavailable';
      message =
          'There is not enough verified fuel information to make a station-specific fuel recommendation.';
      icon = Icons.info_outline_rounded;
    }

    return _InfoCard(icon: icon, title: title, message: message);
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.station, required this.distance});

  final FuelStation station;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF203640)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF52E3D0).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF52E3D0),
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.location.isEmpty
                      ? 'Location unavailable'
                      : station.location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title.copyWith(
                    color: const Color(0xFFE4EDF1),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$distance from current location',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF718590),
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

class _RouteButton extends StatelessWidget {
  const _RouteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.navigation_rounded, size: 20),
        label: Text(
          'START ROUTE',
          style: AppTextStyles.button.copyWith(
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF52E3D0),
          foregroundColor: const Color(0xFF061014),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF203640)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF52E3D0), size: 22),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.title.copyWith(
                    color: const Color(0xFFE4EDF1),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF7E929D),
                    height: 1.45,
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = const Color(0xFF52E3D0),
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(height: 7),
        Text(
          label,
          style: AppTextStyles.labelTechnical.copyWith(
            color: const Color(0xFF687C87),
            fontSize: 7,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.dataValue.copyWith(color: accent, fontSize: 16),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelTechnical.copyWith(
        color: const Color(0xFF6F8490),
        fontSize: 8,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(0xFF52E3D0) : const Color(0xFFFFC857);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelTechnical.copyWith(
          color: color,
          fontSize: 7,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1B23),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF203640)),
          ),
          child: Icon(icon, color: const Color(0xFFE4EDF1), size: 20),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: const Color(0xFF29404A));
  }
}

class _FuelItem {
  const _FuelItem({
    required this.name,
    required this.type,
    required this.status,
    required this.icon,
  });

  final String name;
  final String type;
  final String status;
  final IconData icon;
}
