import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../shared/models/vehicle.dart';
import '../models/route_plan.dart';

class RouteService {
  RouteService._();

  static final RouteService instance = RouteService._();

  static const String _nominatimBaseUrl =
      'https://nominatim.openstreetmap.org/search';

  static const String _osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  static const String _userAgent = 'FuelSenseGIS/1.0';

  Future<RoutePlan> buildRoute({
    required Vehicle vehicle,
    required String destination,
  }) async {
    final cleanedDestination = destination.trim();

    if (cleanedDestination.isEmpty) {
      throw const RouteServiceException(
        'Enter a destination before optimizing the route.',
      );
    }

    final originPosition = await _getCurrentPosition();

    final origin = LatLng(originPosition.latitude, originPosition.longitude);

    final destinationResult = await _geocodeDestination(cleanedDestination);

    final destinationPoint = destinationResult.point;

    final route = await _fetchRoadRoute(
      origin: origin,
      destination: destinationPoint,
    );

    final mileage = vehicle.currentMileage;

    if (mileage <= 0) {
      throw const RouteServiceException(
        'Vehicle mileage is not available. Add a valid mileage value before optimizing the route.',
      );
    }

    final availableFuel = math.max(vehicle.currentFuelLevel, 0).toDouble();
    final fuelRequired = route.distanceKm / mileage;
    final remainingFuel = availableFuel - fuelRequired;
    final estimatedRange = availableFuel * mileage;
    final fuelDeficit = math.max(fuelRequired - availableFuel, 0).toDouble();

    return RoutePlan(
      originLabel: 'Current location',
      destinationLabel: destinationResult.displayName,
      origin: origin,
      destination: destinationPoint,
      distanceKm: route.distanceKm,
      estimatedTravelTime: route.travelTime,
      fuelRequiredLitres: fuelRequired,
      availableFuelLitres: availableFuel,
      remainingFuelLitres: remainingFuel,
      estimatedRangeKm: estimatedRange,
      fuelDeficitLitres: fuelDeficit,
      vehicle: vehicle,
      geometry: route.geometry,
    );
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const RouteServiceException(
        'Location services are disabled. Enable location services and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const RouteServiceException('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const RouteServiceException(
        'Location permission is permanently denied. Enable it from device settings.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      throw const RouteServiceException(
        'Unable to determine the current location.',
      );
    }
  }

  Future<_GeocodedPlace> _geocodeDestination(String destination) async {
    final uri = Uri.parse(_nominatimBaseUrl).replace(
      queryParameters: <String, String>{
        'q': destination,
        'format': 'jsonv2',
        'limit': '1',
        'countrycodes': 'in',
      },
    );

    final response = await http.get(
      uri,
      headers: const <String, String>{
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      },
    );

    if (response.statusCode != 200) {
      throw RouteServiceException(
        'Destination search failed (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List || decoded.isEmpty) {
      throw const RouteServiceException(
        'Destination could not be found. Try a more specific place name.',
      );
    }

    final first = decoded.first;

    if (first is! Map<String, dynamic>) {
      throw const RouteServiceException(
        'The destination search returned an invalid result.',
      );
    }

    final latitude = double.tryParse(first['lat']?.toString() ?? '');
    final longitude = double.tryParse(first['lon']?.toString() ?? '');

    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite) {
      throw const RouteServiceException(
        'The destination does not have valid coordinates.',
      );
    }

    return _GeocodedPlace(
      point: LatLng(latitude, longitude),
      displayName: first['display_name']?.toString() ?? destination,
    );
  }

  Future<_RoadRoute> _fetchRoadRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final coordinates =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';

    final uri = Uri.parse('$_osrmBaseUrl/$coordinates').replace(
      queryParameters: const <String, String>{
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );

    final response = await http.get(
      uri,
      headers: const <String, String>{
        'Accept': 'application/json',
        'User-Agent': _userAgent,
      },
    );

    if (response.statusCode != 200) {
      throw RouteServiceException(
        'Routing service failed (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const RouteServiceException(
        'The routing service returned an invalid response.',
      );
    }

    if (decoded['code'] != 'Ok') {
      throw RouteServiceException(
        'No drivable route was found between the selected locations.',
      );
    }

    final routes = decoded['routes'];

    if (routes is! List || routes.isEmpty) {
      throw const RouteServiceException(
        'No route was returned for the selected destination.',
      );
    }

    final firstRoute = routes.first;

    if (firstRoute is! Map<String, dynamic>) {
      throw const RouteServiceException(
        'The routing service returned an invalid route.',
      );
    }

    final distanceMetres = (firstRoute['distance'] as num?)?.toDouble();
    final durationSeconds = (firstRoute['duration'] as num?)?.toDouble();

    if (distanceMetres == null ||
        durationSeconds == null ||
        !distanceMetres.isFinite ||
        !durationSeconds.isFinite ||
        distanceMetres < 0 ||
        durationSeconds < 0) {
      throw const RouteServiceException(
        'The routing service returned invalid route metrics.',
      );
    }

    final geometry = <LatLng>[];

    final geometryData = firstRoute['geometry'];

    if (geometryData is Map<String, dynamic>) {
      final coordinatesData = geometryData['coordinates'];

      if (coordinatesData is List) {
        for (final coordinate in coordinatesData) {
          if (coordinate is! List || coordinate.length < 2) {
            continue;
          }

          final longitude = (coordinate[0] as num?)?.toDouble();
          final latitude = (coordinate[1] as num?)?.toDouble();

          if (longitude == null ||
              latitude == null ||
              !longitude.isFinite ||
              !latitude.isFinite) {
            continue;
          }

          geometry.add(LatLng(latitude, longitude));
        }
      }
    }

    if (geometry.isEmpty) {
      geometry.add(origin);
      geometry.add(destination);
    }

    return _RoadRoute(
      distanceKm: distanceMetres / 1000,
      travelTime: Duration(seconds: durationSeconds.round()),
      geometry: geometry,
    );
  }
}

class RouteServiceException implements Exception {
  final String message;

  const RouteServiceException(this.message);

  @override
  String toString() => message;
}

class _GeocodedPlace {
  final LatLng point;
  final String displayName;

  const _GeocodedPlace({required this.point, required this.displayName});
}

class _RoadRoute {
  final double distanceKm;
  final Duration travelTime;
  final List<LatLng> geometry;

  const _RoadRoute({
    required this.distanceKm,
    required this.travelTime,
    required this.geometry,
  });
}
