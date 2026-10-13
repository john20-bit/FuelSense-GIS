import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/vehicle.dart';

class RouteStationRecommendation {
  final String stationId;
  final String name;
  final String brand;
  final String? city;
  final String? state;
  final String? mapsLink;
  final LatLng location;
  final double distanceFromRouteKm;
  final double distanceFromOriginKm;
  final String matchedFuelProduct;
  final double? priceInr;
  final bool priceAvailable;

  const RouteStationRecommendation({
    required this.stationId,
    required this.name,
    required this.brand,
    required this.location,
    required this.distanceFromRouteKm,
    required this.distanceFromOriginKm,
    required this.matchedFuelProduct,
    required this.priceInr,
    required this.priceAvailable,
    this.city,
    this.state,
    this.mapsLink,
  });

  String get priceLabel {
    final price = priceInr;

    if (!priceAvailable || price == null || !price.isFinite) {
      return 'PRICE UNAVAILABLE';
    }

    return '₹${price.toStringAsFixed(2)}/L';
  }
}

class RouteStationService {
  RouteStationService._();

  static final RouteStationService instance = RouteStationService._();

  static const String _collectionName = 'stations';
  static const int _geohashPrecision = 5;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<RouteStationRecommendation>> findStationsNearRoute({
    required List<LatLng> routeGeometry,
    required LatLng origin,
    required Vehicle vehicle,
    double corridorKm = 3.0,
    int limit = 5,
  }) async {
    if (routeGeometry.isEmpty || corridorKm <= 0 || limit <= 0) {
      return const [];
    }

    final prefixes = _routeGeohashPrefixes(routeGeometry, corridorKm);

    final documents = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    final snapshots = await Future.wait(
      prefixes.map(
        (prefix) => _firestore
            .collection(_collectionName)
            .where('geohash', isGreaterThanOrEqualTo: prefix)
            .where('geohash', isLessThan: '$prefix\uf8ff')
            .get(),
      ),
    );

    for (final snapshot in snapshots) {
      for (final document in snapshot.docs) {
        documents[document.id] = document;
      }
    }

    final candidates = <RouteStationRecommendation>[];

    for (final document in documents.values) {
      final data = document.data();

      final latitude = _finiteDouble(data['latitude']);
      final longitude = _finiteDouble(data['longitude']);

      if (latitude == null || longitude == null) {
        continue;
      }

      final location = LatLng(latitude, longitude);

      final product = _findCompatibleProduct(data['fuelProducts'], vehicle);

      if (product == null) {
        continue;
      }

      final routeDistance = _distanceToRouteKm(location, routeGeometry);

      if (routeDistance > corridorKm) {
        continue;
      }

      final originDistance = _distanceKm(
        origin.latitude,
        origin.longitude,
        latitude,
        longitude,
      );

      candidates.add(
        RouteStationRecommendation(
          stationId: document.id,
          name: data['name']?.toString() ?? 'Unnamed station',
          brand: data['brand']?.toString() ?? 'Unknown brand',
          city: data['city']?.toString(),
          state: data['state']?.toString(),
          mapsLink: data['mapsLink']?.toString(),
          location: location,
          distanceFromRouteKm: routeDistance,
          distanceFromOriginKm: originDistance,
          matchedFuelProduct: product.name,
          priceInr: product.priceInr,
          priceAvailable: product.priceInr != null,
        ),
      );
    }

    candidates.sort((a, b) {
      final routeDistance = a.distanceFromRouteKm.compareTo(
        b.distanceFromRouteKm,
      );

      if (routeDistance != 0) {
        return routeDistance;
      }

      return a.distanceFromOriginKm.compareTo(b.distanceFromOriginKm);
    });

    return candidates.take(limit).toList(growable: false);
  }

  Set<String> _routeGeohashPrefixes(
    List<LatLng> routeGeometry,
    double corridorKm,
  ) {
    final prefixes = <String>{};
    final samplePoints = <LatLng>[];

    for (var index = 0; index < routeGeometry.length; index += 8) {
      samplePoints.add(routeGeometry[index]);
    }

    samplePoints.addAll(_corridorOffsetPoints(routeGeometry, corridorKm));

    for (final point in samplePoints) {
      final center = _encodeGeohash(
        point.latitude,
        point.longitude,
        _geohashPrecision,
      );

      final bounds = _decodeGeohash(center);
      final latitudeStep = bounds.maxLatitude - bounds.minLatitude;
      final longitudeStep = bounds.maxLongitude - bounds.minLongitude;

      for (var latitudeOffset = -2; latitudeOffset <= 2; latitudeOffset++) {
        for (
          var longitudeOffset = -2;
          longitudeOffset <= 2;
          longitudeOffset++
        ) {
          final latitude = point.latitude + latitudeOffset * latitudeStep;
          final longitude = point.longitude + longitudeOffset * longitudeStep;

          if (latitude < -90 ||
              latitude > 90 ||
              longitude < -180 ||
              longitude > 180) {
            continue;
          }

          prefixes.add(_encodeGeohash(latitude, longitude, _geohashPrecision));
        }
      }
    }

    return prefixes;
  }

  _GeohashBounds _decodeGeohash(String geohash) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

    var minLatitude = -90.0;
    var maxLatitude = 90.0;
    var minLongitude = -180.0;
    var maxLongitude = 180.0;
    var evenBit = true;

    for (final character in geohash.toLowerCase().split('')) {
      final characterIndex = base32.indexOf(character);

      if (characterIndex < 0) {
        continue;
      }

      for (var mask = 16; mask > 0; mask >>= 1) {
        if (evenBit) {
          final mid = (minLongitude + maxLongitude) / 2;

          if ((characterIndex & mask) != 0) {
            minLongitude = mid;
          } else {
            maxLongitude = mid;
          }
        } else {
          final mid = (minLatitude + maxLatitude) / 2;

          if ((characterIndex & mask) != 0) {
            minLatitude = mid;
          } else {
            maxLatitude = mid;
          }
        }

        evenBit = !evenBit;
      }
    }

    return _GeohashBounds(
      minLatitude: minLatitude,
      maxLatitude: maxLatitude,
      minLongitude: minLongitude,
      maxLongitude: maxLongitude,
    );
  }

  List<LatLng> _corridorOffsetPoints(
    List<LatLng> routeGeometry,
    double corridorKm,
  ) {
    final points = <LatLng>[];

    for (var index = 0; index < routeGeometry.length; index += 8) {
      final point = routeGeometry[index];

      final latitudeDelta = corridorKm / 111.0;
      final longitudeScale = math
          .cos(point.latitude * math.pi / 180)
          .abs()
          .clamp(0.1, 1.0);
      final longitudeDelta = corridorKm / (111.0 * longitudeScale);

      points.add(LatLng(point.latitude + latitudeDelta, point.longitude));
      points.add(LatLng(point.latitude - latitudeDelta, point.longitude));
      points.add(LatLng(point.latitude, point.longitude + longitudeDelta));
      points.add(LatLng(point.latitude, point.longitude - longitudeDelta));
    }

    return points;
  }

  String _encodeGeohash(double latitude, double longitude, int precision) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

    var minLatitude = -90.0;
    var maxLatitude = 90.0;
    var minLongitude = -180.0;
    var maxLongitude = 180.0;

    var evenBit = true;
    var bit = 0;
    var characterIndex = 0;
    var geohash = '';

    while (geohash.length < precision) {
      if (evenBit) {
        final mid = (minLongitude + maxLongitude) / 2;

        if (longitude >= mid) {
          characterIndex = (characterIndex << 1) | 1;
          minLongitude = mid;
        } else {
          characterIndex <<= 1;
          maxLongitude = mid;
        }
      } else {
        final mid = (minLatitude + maxLatitude) / 2;

        if (latitude >= mid) {
          characterIndex = (characterIndex << 1) | 1;
          minLatitude = mid;
        } else {
          characterIndex <<= 1;
          maxLatitude = mid;
        }
      }

      evenBit = !evenBit;
      bit++;

      if (bit == 5) {
        geohash += base32[characterIndex];
        bit = 0;
        characterIndex = 0;
      }
    }

    return geohash;
  }

  _FuelProduct? _findCompatibleProduct(Object? rawProducts, Vehicle vehicle) {
    if (rawProducts is! List) {
      return null;
    }

    final fuelType = vehicle.normalizedFuelType;

    for (final rawProduct in rawProducts) {
      if (rawProduct is! Map) {
        continue;
      }

      final name = rawProduct['name']?.toString().trim();

      if (name == null || name.isEmpty) {
        continue;
      }

      if (!_isCompatibleFuelProduct(name, fuelType)) {
        continue;
      }

      return _FuelProduct(
        name: name,
        priceInr: _finiteDouble(rawProduct['priceInr']),
      );
    }

    return null;
  }

  bool _isCompatibleFuelProduct(String productName, String vehicleFuelType) {
    final product = productName.toUpperCase();

    if (vehicleFuelType.contains('DIESEL')) {
      return product.contains('DIESEL');
    }

    if (vehicleFuelType.contains('PETROL') ||
        vehicleFuelType.contains('GASOLINE')) {
      return product.contains('PETROL') || product.contains('GASOLINE');
    }

    if (vehicleFuelType.contains('ETHANOL')) {
      return product.contains('ETHANOL') || product.contains('E85');
    }

    if (vehicleFuelType.contains('CNG')) {
      return product.contains('CNG');
    }

    if (vehicleFuelType.contains('LPG')) {
      return product.contains('LPG');
    }

    return product.contains(vehicleFuelType);
  }

  double _distanceToRouteKm(LatLng point, List<LatLng> route) {
    var minimumDistance = double.infinity;

    for (var index = 0; index < route.length - 1; index++) {
      final distance = _distanceToSegmentKm(
        point,
        route[index],
        route[index + 1],
      );

      minimumDistance = math.min(minimumDistance, distance);
    }

    if (route.length == 1) {
      minimumDistance = _distanceKm(
        point.latitude,
        point.longitude,
        route.first.latitude,
        route.first.longitude,
      );
    }

    return minimumDistance;
  }

  double _distanceToSegmentKm(LatLng point, LatLng start, LatLng end) {
    const latitudeScale = 111.0;

    final longitudeScale =
        111.0 * math.cos(point.latitude * math.pi / 180).abs();

    final px = (point.longitude - start.longitude) * longitudeScale;
    final py = (point.latitude - start.latitude) * latitudeScale;

    final ex = (end.longitude - start.longitude) * longitudeScale;
    final ey = (end.latitude - start.latitude) * latitudeScale;

    final lengthSquared = ex * ex + ey * ey;

    if (lengthSquared == 0) {
      return math.sqrt(px * px + py * py);
    }

    final projection = (px * ex + py * ey) / lengthSquared;
    final t = projection.clamp(0.0, 1.0);

    final closestX = t * ex;
    final closestY = t * ey;

    return math.sqrt(
      math.pow(px - closestX, 2).toDouble() +
          math.pow(py - closestY, 2).toDouble(),
    );
  }

  double _distanceKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadiusKm = 6371.0088;

    final latitude1Radians = latitude1 * math.pi / 180;
    final latitude2Radians = latitude2 * math.pi / 180;
    final deltaLatitude = (latitude2 - latitude1) * math.pi / 180;
    final deltaLongitude = (longitude2 - longitude1) * math.pi / 180;

    final a =
        math.pow(math.sin(deltaLatitude / 2), 2) +
        math.cos(latitude1Radians) *
            math.cos(latitude2Radians) *
            math.pow(math.sin(deltaLongitude / 2), 2);

    final clampedA = a.clamp(0.0, 1.0).toDouble();

    final c = 2 * math.atan2(math.sqrt(clampedA), math.sqrt(1 - clampedA));

    return earthRadiusKm * c;
  }

  double? _finiteDouble(Object? value) {
    if (value is! num) {
      return null;
    }

    final number = value.toDouble();

    return number.isFinite ? number : null;
  }
}

class _FuelProduct {
  final String name;
  final double? priceInr;

  const _FuelProduct({required this.name, required this.priceInr});
}

class _GeohashBounds {
  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  const _GeohashBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });
}
