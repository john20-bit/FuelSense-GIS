import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    developer.log(
      'Starting location request',
      name: 'LocationService',
    );

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    developer.log(
      'Location service enabled: $serviceEnabled',
      name: 'LocationService',
    );

    if (!serviceEnabled) {
      throw Exception('Location service disabled');
    }

    var permission = await Geolocator.checkPermission();

    developer.log(
      'Initial permission: $permission',
      name: 'LocationService',
    );

    if (permission == LocationPermission.denied) {
      developer.log(
        'Requesting location permission',
        name: 'LocationService',
      );

      permission = await Geolocator.requestPermission();

      developer.log(
        'Permission after request: $permission',
        name: 'LocationService',
      );
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. '
        'Enable location permission in Android Settings.',
      );
    }

    developer.log(
      'Requesting GPS position...',
      name: 'LocationService',
    );

    try {
      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 15),
      );

      developer.log(
        'GPS position received: '
        '${position.latitude}, ${position.longitude}',
        name: 'LocationService',
      );

      return position;
    } catch (e) {
      developer.log(
        'GPS request failed: $e',
        name: 'LocationService',
        error: e,
      );

      throw Exception(
        'Unable to get your current location. '
        'Please make sure GPS is enabled.',
      );
    }
  }
}
