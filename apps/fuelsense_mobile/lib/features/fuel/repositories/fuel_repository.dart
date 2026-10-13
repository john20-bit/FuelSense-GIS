import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/fuel_station_model.dart';

class FuelRepository {
  FuelRepository();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _stationsCollection = 'stations';
  static const String _fuelRecordsCollection = 'fuelRecords';
  static const int _geohashPrecision = 5;
  static const double _earthRadiusKm = 6371.0088;

  Future<List<FuelStation>> getNearbyStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    if (!_isValidCoordinate(latitude, longitude)) {
      throw ArgumentError('Invalid station search coordinates.');
    }

    if (radiusKm <= 0) {
      throw ArgumentError('Radius must be greater than zero.');
    }

    final prefixes = _nearbyGeohashPrefixes(latitude, longitude);

    final snapshots = await Future.wait(
      prefixes.map(
        (prefix) => _firestore
            .collection(_stationsCollection)
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

    final stations = <FuelStation>[];

    for (final document in documents.values) {
      final data = document.data();

      final stationLatitude = (data['latitude'] as num?)?.toDouble();
      final stationLongitude = (data['longitude'] as num?)?.toDouble();

      if (stationLatitude == null ||
          stationLongitude == null ||
          !_isValidCoordinate(stationLatitude, stationLongitude)) {
        continue;
      }

      final distance = _distanceKm(
        latitude,
        longitude,
        stationLatitude,
        stationLongitude,
      );

      if (distance > radiusKm) {
        continue;
      }

      final mapped = <String, dynamic>{
        'id': document.id,
        'name': data['name'],
        'location': _locationText(data),
        'latitude': stationLatitude,
        'longitude': stationLongitude,
        'distance': distance,
        'fuelType': _fuelType(data),
        'availability': _availability(data),
        'lastUpdated': data['capturedAt']?.toString() ?? '',
        'status': 'Available',
        'e20Available': _hasProduct(data, 'E20'),
        'e85Available': _hasProduct(data, 'E85'),
        'petrolAvailable': _hasProductNames(data, const {
          'petrol',
          'petrol premium',
          'power95',
          'xp95',
        }),
        'premiumPetrolAvailable': _hasProductNames(data, const {
          'power95',
          'power 100',
          'xp95',
          'xp100',
          'speed 97',
          'speed 100 bs iv',
        }),
        'dieselAvailable': _hasProductNames(data, const {
          'diesel',
          'turbojet',
          'xtragreen diesel',
          'speed',
        }),
        'premiumDieselAvailable': _hasProductNames(data, const {
          'xtragreen diesel',
          'turbojet',
        }),
      };

      try {
        stations.add(FuelStation.fromJson(mapped));
      } catch (_) {
        continue;
      }
    }

    stations.sort((a, b) => a.distance.compareTo(b.distance));

    return stations;
  }

  Future<bool> addFuelRecord(Map<String, dynamic> recordData) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'A signed-in Firebase user is required to save a fuel record.',
      );
    }

    final cleanedData = Map<String, dynamic>.from(recordData);

    cleanedData.removeWhere((_, value) => value is double && !value.isFinite);

    cleanedData['userId'] = user.uid;
    cleanedData['createdAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection(_fuelRecordsCollection)
        .add(cleanedData);

    return true;
  }

  String _locationText(Map<String, dynamic> data) {
    final parts = <String>[];

    final address = data['address']?.toString().trim() ?? '';
    final city = data['city']?.toString().trim() ?? '';
    final state = data['state']?.toString().trim() ?? '';

    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);

    return parts.join(', ');
  }

  String _fuelType(Map<String, dynamic> data) {
    final products = data['fuelProducts'];

    if (products is List) {
      for (final product in products) {
        if (product is Map) {
          final name = product['name']?.toString().trim() ?? '';
          if (name.isNotEmpty) {
            return name;
          }
        }
      }
    }

    return 'Unknown';
  }

  int _availability(Map<String, dynamic> data) {
    final products = data['fuelProducts'];

    if (products is List) {
      return products.length;
    }

    return 0;
  }

  bool _hasProduct(Map<String, dynamic> data, String productName) {
    final normalized = productName.trim().toLowerCase();
    final products = data['fuelProducts'];

    if (products is! List) return false;

    return products.any((product) {
      if (product is! Map) return false;

      return product['name']?.toString().trim().toLowerCase() == normalized;
    });
  }

  bool _hasProductNames(Map<String, dynamic> data, Set<String> productNames) {
    final normalizedNames = productNames
        .map((name) => name.toLowerCase())
        .toSet();

    final products = data['fuelProducts'];

    if (products is! List) return false;

    return products.any((product) {
      if (product is! Map) return false;

      final name = product['name']?.toString().trim().toLowerCase() ?? '';

      return normalizedNames.contains(name);
    });
  }

  Set<String> _nearbyGeohashPrefixes(double latitude, double longitude) {
    final center = _encodeGeohash(latitude, longitude, _geohashPrecision);

    final bounds = _decodeGeohash(center);

    final latitudeStep = bounds.maxLatitude - bounds.minLatitude;
    final longitudeStep = bounds.maxLongitude - bounds.minLongitude;

    final prefixes = <String>{};

    for (var latOffset = -2; latOffset <= 2; latOffset++) {
      for (var lonOffset = -2; lonOffset <= 2; lonOffset++) {
        final candidateLatitude = latitude + latOffset * latitudeStep;
        final candidateLongitude = longitude + lonOffset * longitudeStep;

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

      if (characterIndex < 0) continue;

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
