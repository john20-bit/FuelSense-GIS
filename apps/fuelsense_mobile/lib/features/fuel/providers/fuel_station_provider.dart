import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/location_service.dart';
import '../models/fuel_station_model.dart';
import '../repositories/fuel_repository.dart';

final fuelStationRepositoryProvider = Provider<FuelRepository>((ref) {
  return FuelRepository();
});

final fuelStationsProvider = FutureProvider<List<FuelStation>>((ref) async {
  final repository = ref.watch(fuelStationRepositoryProvider);

  final Position userPosition = await LocationService.getCurrentLocation();

  final stations = await repository.getNearbyStations(
    latitude: userPosition.latitude,
    longitude: userPosition.longitude,
    radiusKm: 100,
  );

  return stations..sort((a, b) => a.distance.compareTo(b.distance));
});

final fuelStationProvider = fuelStationsProvider;
