import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/spatial_station.dart';
import '../repositories/spatial_station_repository.dart';

const double defaultSpatialLatitude = 9.9252;
const double defaultSpatialLongitude = 78.1198;

final spatialStationRepositoryProvider = Provider<SpatialStationRepository>((
  ref,
) {
  return SpatialStationRepository();
});

final spatialStationsProvider = FutureProvider<List<SpatialStation>>((
  ref,
) async {
  final repository = ref.watch(spatialStationRepositoryProvider);

  return repository.getNearbyStations(
    latitude: defaultSpatialLatitude,
    longitude: defaultSpatialLongitude,
    radiusKm: 10,
    limit: 100,
  );
});

final spatialStationProvider = FutureProvider.family<SpatialStation, String>((
  ref,
  stationId,
) async {
  final repository = ref.watch(spatialStationRepositoryProvider);
  return repository.getStation(stationId);
});
