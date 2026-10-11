import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/spatial_station.dart';

class SpatialStationRepository {
  SpatialStationRepository();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionName = 'stations';
  static const int _geohashPrecision = 5;
  static const double _earthRadiusKm = 6371.0088;

  Future<List<SpatialStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? brand,
    String? fuelProduct,
    int limit = 100,
  }) async {
    if (!_isValidCoordinate(latitude, longitude)) {
      throw ArgumentError('Invalid station search coordinates.');
    }

    if (radiusKm <= 0) {
      throw ArgumentError('Radius must be greater than zero.');
    }

    if (limit <= 0) {
      throw ArgumentError('Limit must be greater than zero.');
    }

    final prefixes = _nearbyGeohashPrefixes(latitude, longitude);

    final snapshots = await Future.wait(
      prefixes.map(
        (prefix) => _firestore
            .collection(_collectionName)
            .where('geohash', isGreaterThanOrEqualTo: prefix)
            .where('geohash', isLessThan: '$prefix\uf8ff')
            .get(),
      ),
    );

    final documents = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    for (final snapshot in snapshots) {
      for (final document in snapshot.docs) {
        documents[document.id] = document;
      }
    }

    final normalizedBrand = brand?.trim().toLowerCase();
    final normalizedFuelProduct = fuelProduct?.trim().toLowerCase();

    final stations = <SpatialStation>[];

    for (final document in documents.values) {
      final data = document.data();

      final station = _stationFromFirestore(document.id, data);

      if (station == null) {
        continue;
      }

      final distanceKm = _distanceKm(
        latitude,
        longitude,
        station.latitude,
        station.longitude,
      );

      if (distanceKm > radiusKm) {
        continue;
      }

      if (normalizedBrand != null &&
          normalizedBrand.isNotEmpty &&
          station.brand.trim().toLowerCase() != normalizedBrand) {
        continue;
      }

      if (normalizedFuelProduct != null &&
          normalizedFuelProduct.isNotEmpty &&
          !station.fuelProducts.any(
            (product) =>
                product.name.trim().toLowerCase() == normalizedFuelProduct,
          )) {
        continue;
      }

      stations.add(
        SpatialStation(
          id: station.id,
          outletId: station.outletId,
          name: station.name,
          brand: station.brand,
          address: station.address,
          city: station.city,
          state: station.state,
          pincode: station.pincode,
          phone: station.phone,
          latitude: station.latitude,
          longitude: station.longitude,
          geohash: station.geohash,
          hours: station.hours,
          mapsLink: station.mapsLink,
          sourceUrl: station.sourceUrl,
          fuelProducts: station.fuelProducts,
          capturedAt: station.capturedAt,
          source: station.source,
          distanceKm: distanceKm,
        ),
      );
    }

    stations.sort(
      (a, b) => (a.distanceKm ?? double.infinity).compareTo(
        b.distanceKm ?? double.infinity,
      ),
    );

    if (stations.length > limit) {
      return stations.sublist(0, limit);
    }

    return stations;
  }

  Future<SpatialStation> getStation(String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw ArgumentError('Station ID cannot be empty.');
    }

    final document = await _firestore
        .collection(_collectionName)
        .doc(cleanId)
        .get();

    if (!document.exists || document.data() == null) {
      throw Exception('Station not found.');
    }

    final station = _stationFromFirestore(document.id, document.data()!);

    if (station == null) {
      throw Exception('Invalid station data.');
    }

    return station;
  }

  SpatialStation? _stationFromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();

    if (latitude == null ||
        longitude == null ||
        !_isValidCoordinate(latitude, longitude)) {
      return null;
    }

    final capturedAt = _timestampToDateTime(data['capturedAt']);

    final mapped = <String, dynamic>{
      'id': documentId,
      'outletId': data['outletId'],
      'name': data['name'],
      'brand': data['brand'],
      'address': data['address'],
      'city': data['city'],
      'state': data['state'],
      'pincode': data['pincode'],
      'phone': data['contact'],
      'latitude': latitude,
      'longitude': longitude,
      'geohash': data['geohash'],
      'hours': data['hours'],
      'mapsLink': data['mapsLink'],
      'sourceUrl': data['sourceUrl'],
      'fuelProducts': data['fuelProducts'],
      'capturedAt': capturedAt?.toIso8601String(),
      'source': data['source'] ?? data['brand'] ?? 'firebase',
    };

    return SpatialStation.fromJson(mapped);
  }

  DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  Set<String> _nearbyGeohashPrefixes(double latitude, double longitude) {
    final center = _encodeGeohash(latitude, longitude, _geohashPrecision);

    final bounds = _decodeGeohash(center);

    final latitudeStep = bounds.maxLatitude - bounds.minLatitude;
    final longitudeStep = bounds.maxLongitude - bounds.minLongitude;

    final prefixes = <String>{};

    for (var latOffset = -2; latOffset <= 2; latOffset++) {
      for (var lonOffset = -2; lonOffset <= 2; lonOffset++) {
        final candidateLatitude = latitude + (latOffset * latitudeStep);
        final candidateLongitude = longitude + (lonOffset * longitudeStep);

        if (candidateLatitude < -90 ||
            candidateLatitude > 90 ||
            candidateLongitude < -180 ||
            candidateLongitude > 180) {
          continue;
        }

        prefixes.add(
          _encodeGeohash(
            candidateLatitude,
            candidateLongitude,
            _geohashPrecision,
          ),
        );
      }
    }

    prefixes.add(center);

    return prefixes;
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

  double _distanceKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    final latitude1Radians = _degreesToRadians(latitude1);
    final latitude2Radians = _degreesToRadians(latitude2);

    final deltaLatitude = _degreesToRadians(latitude2 - latitude1);
    final deltaLongitude = _degreesToRadians(longitude2 - longitude1);

    final a =
        math.pow(math.sin(deltaLatitude / 2), 2) +
        math.cos(latitude1Radians) *
            math.cos(latitude2Radians) *
            math.pow(math.sin(deltaLongitude / 2), 2);

    final clampedA = a.clamp(0.0, 1.0);

    final c = 2 * math.atan2(math.sqrt(clampedA), math.sqrt(1 - clampedA));

    return _earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  bool _isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
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
