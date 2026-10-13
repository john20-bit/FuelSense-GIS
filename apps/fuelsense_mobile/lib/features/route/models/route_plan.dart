import 'package:latlong2/latlong.dart';

import '../../../shared/models/vehicle.dart';

class RoutePlan {
  final String originLabel;
  final String destinationLabel;
  final LatLng origin;
  final LatLng destination;
  final double distanceKm;
  final Duration estimatedTravelTime;
  final double fuelRequiredLitres;
  final double availableFuelLitres;
  final double remainingFuelLitres;
  final double estimatedRangeKm;
  final double fuelDeficitLitres;
  final Vehicle vehicle;
  final String? fuelPriceSource;
  final double? estimatedFuelCostInr;
  final List<LatLng> geometry;

  const RoutePlan({
    required this.originLabel,
    required this.destinationLabel,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.estimatedTravelTime,
    required this.fuelRequiredLitres,
    required this.availableFuelLitres,
    required this.remainingFuelLitres,
    required this.estimatedRangeKm,
    required this.fuelDeficitLitres,
    required this.vehicle,
    required this.geometry,
    this.fuelPriceSource,
    this.estimatedFuelCostInr,
  });

  bool get canReachDestination => fuelDeficitLitres <= 0;

  bool get requiresRefuelling => fuelDeficitLitres > 0;

  String get travelTimeLabel {
    final hours = estimatedTravelTime.inHours;
    final minutes = estimatedTravelTime.inMinutes.remainder(60);

    if (hours == 0) {
      return '${minutes}m';
    }

    if (minutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${minutes}m';
  }

  String get distanceLabel {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get fuelRequiredLabel => '${fuelRequiredLitres.toStringAsFixed(2)} L';

  String get rangeLabel => '${estimatedRangeKm.toStringAsFixed(0)} km';

  String get fuelStatus {
    if (canReachDestination) {
      return 'SUFFICIENT FUEL';
    }

    return 'REFUELLING REQUIRED';
  }
}
