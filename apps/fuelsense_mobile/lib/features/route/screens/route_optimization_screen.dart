import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/vehicle.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../models/route_plan.dart';
import '../services/route_service.dart';
import '../services/route_station_service.dart';

class RouteOptimizationScreen extends ConsumerStatefulWidget {
  const RouteOptimizationScreen({super.key});

  @override
  ConsumerState<RouteOptimizationScreen> createState() =>
      _RouteOptimizationScreenState();
}

class _RouteOptimizationScreenState
    extends ConsumerState<RouteOptimizationScreen> {
  final _destinationController = TextEditingController();

  RoutePlan? _routePlan;
  List<RouteStationRecommendation> _stations = const [];
  Vehicle? _selectedVehicle;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _optimizeRoute() async {
    final destination = _destinationController.text.trim();

    if (destination.isEmpty) {
      setState(() {
        _error = 'Enter a destination.';
      });
      return;
    }

    final vehicles = await ref.read(vehicleProvider.future);

    if (!mounted) return;

    if (vehicles.isEmpty) {
      setState(() {
        _error = 'Add a vehicle before planning a route.';
      });
      return;
    }

    final vehicle = _selectedVehicle ?? vehicles.first;

    setState(() {
      _loading = true;
      _error = null;
      _routePlan = null;
      _stations = const [];
      _selectedVehicle = vehicle;
    });

    try {
      final routePlan = await RouteService.instance.buildRoute(
        vehicle: vehicle,
        destination: destination,
      );

      final stations = await RouteStationService.instance.findStationsNearRoute(
        routeGeometry: routePlan.geometry,
        origin: routePlan.origin,
        vehicle: vehicle,
      );

      if (!mounted) return;

      setState(() {
        _routePlan = routePlan;
        _stations = stations;
        _loading = false;
      });
    } on RouteServiceException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to optimize this route. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'ROUTE OPTIMIZATION',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MessageState(
          message: 'Unable to load your vehicles.',
          detail: error.toString(),
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const _MessageState(
              message: 'No vehicle configured',
              detail: 'Add your vehicle before planning a fuel-aware route.',
            );
          }

          final selectedVehicle = _selectedVehicle ?? vehicles.first;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vehicleProvider);
              await ref.read(vehicleProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _HeaderCard(vehicle: selectedVehicle),
                const SizedBox(height: 16),
                _RouteInputCard(
                  controller: _destinationController,
                  vehicle: selectedVehicle,
                  vehicles: vehicles,
                  onVehicleChanged: (vehicle) {
                    setState(() {
                      _selectedVehicle = vehicle;
                      _routePlan = null;
                      _stations = const [];
                      _error = null;
                    });
                  },
                  onOptimize: _optimizeRoute,
                  loading: _loading,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _ErrorCard(message: _error!),
                ],
                if (_loading) ...[
                  const SizedBox(height: 24),
                  const _LoadingCard(),
                ],
                if (_routePlan != null && !_loading) ...[
                  const SizedBox(height: 20),
                  _RouteResultCard(routePlan: _routePlan!),
                  const SizedBox(height: 14),
                  _FuelStatusCard(routePlan: _routePlan!),
                  const SizedBox(height: 20),
                  _StationSection(stations: _stations),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Vehicle vehicle;

  const _HeaderCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surface,
            ),
            child: const Icon(Icons.route_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FUEL-AWARE ROUTE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${vehicle.normalizedFuelType} • '
                  '${vehicle.currentMileage > 0 ? '${vehicle.currentMileage.toStringAsFixed(1)} km/L' : 'Mileage unavailable'}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteInputCard extends StatelessWidget {
  final TextEditingController controller;
  final Vehicle vehicle;
  final List<Vehicle> vehicles;
  final ValueChanged<Vehicle> onVehicleChanged;
  final VoidCallback onOptimize;
  final bool loading;

  const _RouteInputCard({
    required this.controller,
    required this.vehicle,
    required this.vehicles,
    required this.onVehicleChanged,
    required this.onOptimize,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLAN JOURNEY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<Vehicle>(
            initialValue: vehicle,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Vehicle',
              prefixIcon: Icon(Icons.directions_car_outlined),
              border: OutlineInputBorder(),
            ),
            items: vehicles
                .map(
                  (item) => DropdownMenuItem<Vehicle>(
                    value: item,
                    child: Text(
                      item.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onVehicleChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onOptimize(),
            decoration: const InputDecoration(
              labelText: 'Destination',
              hintText: 'Enter a city, place or address',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: loading ? null : onOptimize,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.alt_route_rounded),
              label: Text(loading ? 'CALCULATING...' : 'OPTIMIZE ROUTE'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteResultCard extends StatelessWidget {
  final RoutePlan routePlan;

  const _RouteResultCard({required this.routePlan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ROUTE RESULT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            routePlan.destinationLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.route_rounded,
                  label: 'DISTANCE',
                  value: routePlan.distanceLabel,
                ),
              ),
              Expanded(
                child: _Metric(
                  icon: Icons.schedule_rounded,
                  label: 'TIME',
                  value: routePlan.travelTimeLabel,
                ),
              ),
              Expanded(
                child: _Metric(
                  icon: Icons.local_gas_station_outlined,
                  label: 'FUEL',
                  value: routePlan.fuelRequiredLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _FuelStatusCard extends StatelessWidget {
  final RoutePlan routePlan;

  const _FuelStatusCard({required this.routePlan});

  @override
  Widget build(BuildContext context) {
    final needsFuel = routePlan.requiresRefuelling;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                needsFuel
                    ? Icons.local_gas_station_rounded
                    : Icons.check_circle_outline_rounded,
                color: needsFuel ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                routePlan.fuelStatus,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Current fuel: '
            '${routePlan.availableFuelLitres.toStringAsFixed(2)} L',
          ),
          const SizedBox(height: 5),
          Text('Estimated range: ${routePlan.rangeLabel}'),
          if (needsFuel) ...[
            const SizedBox(height: 5),
            Text(
              'Minimum fuel gap: '
              '${routePlan.fuelDeficitLitres.toStringAsFixed(2)} L',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            const SizedBox(height: 5),
            Text(
              'Estimated fuel remaining at destination: '
              '${routePlan.remainingFuelLitres.toStringAsFixed(2)} L',
            ),
          ],
        ],
      ),
    );
  }
}

class _StationSection extends StatelessWidget {
  final List<RouteStationRecommendation> stations;

  const _StationSection({required this.stations});

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return const _MessageState(
        message: 'No compatible station found near this route',
        detail:
            'The available station data does not contain a matching fuel product within the route corridor.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FUEL STATIONS NEAR ROUTE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ...stations.map(
          (station) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StationCard(station: station),
          ),
        ),
      ],
    );
  }
}

class _StationCard extends StatelessWidget {
  final RouteStationRecommendation station;

  const _StationCard({required this.station});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
            ),
            child: const Icon(
              Icons.local_gas_station_outlined,
              size: 20,
              color: AppColors.primary,
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
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${station.brand} • ${station.matchedFuelProduct}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 5),
                Text(
                  '${station.distanceFromRouteKm.toStringAsFixed(1)} km from route',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            station.priceLabel,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Finding the road, calculating fuel, and checking stations...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final String detail;

  const _MessageState({required this.message, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.route_outlined,
              size: 42,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
