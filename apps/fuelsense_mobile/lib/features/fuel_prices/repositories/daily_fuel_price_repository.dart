import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/daily_fuel_prices.dart';

class DailyFuelPriceRepository {
  DailyFuelPriceRepository({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static final Uri _baseUri = Uri.https('api.apimitra.in', '/fuel');

  static const String _apiKey =
      String.fromEnvironment('API_MITRA_KEY');

  Future<DailyFuelPrices> fetchCityPrices(String city) async {
    final requestedCity = city.trim();

    if (requestedCity.isEmpty) {
      throw ArgumentError.value(
        city,
        'city',
        'City cannot be empty.',
      );
    }

    if (_apiKey.isEmpty) {
      throw StateError('API Mitra key is not configured.');
    }

    final cityResponse = await _fetch(
      requestedCity,
      isState: false,
    );

    if (cityResponse.statusCode == 200) {
      final decoded = _decode(cityResponse.body);

      if (decoded['status'] == 'ok') {
        final price = decoded['price'];

        if (price is! Map<String, dynamic>) {
          throw const FormatException(
            'City price data is unavailable.',
          );
        }

        return DailyFuelPrices.fromJson({
          ...price,
          'updated_at':
              price['updated_at'] ?? decoded['fetched_at'],
        });
      }
    }

    final error = _decodeError(cityResponse.body);
    final cityNotFound =
        error.toLowerCase().contains('not found') &&
        error.toLowerCase().contains('city');

    if (!cityNotFound) {
      throw HttpExceptionForFuelPrices(
        'Fuel price request failed '
        '(HTTP ${cityResponse.statusCode}): $error',
      );
    }

    // Use state-level prices only when the requested city is unsupported.
    final stateResponse = await _fetch(
      'Tamil Nadu',
      isState: true,
    );

    if (stateResponse.statusCode != 200) {
      throw HttpExceptionForFuelPrices(
        'Tamil Nadu fuel prices are unavailable '
        '(HTTP ${stateResponse.statusCode}).',
      );
    }

    final stateJson = _decode(stateResponse.body);

    if (stateJson['status'] != 'ok') {
      throw const FormatException(
        'Provider did not return valid Tamil Nadu prices.',
      );
    }

    final statePrice = stateJson['price'];

    if (statePrice is! Map<String, dynamic>) {
      throw const FormatException(
        'Tamil Nadu price data is unavailable.',
      );
    }

    return DailyFuelPrices.fromJson({
      ...statePrice,
      'updated_at':
          statePrice['updated_at'] ?? stateJson['fetched_at'],
    });
  }

  Future<http.Response> _fetch(
    String location, {
    required bool isState,
  }) {
    final uri = _baseUri.replace(
      queryParameters: isState
          ? {'state': location.toLowerCase()}
          : {'city': location.toLowerCase()},
    );

    return _client
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'x-api-key': _apiKey,
          },
        )
        .timeout(const Duration(seconds: 12));
  }

  Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected fuel price response.',
      );
    }

    return decoded;
  }

  String _decodeError(String body) {
    try {
      final decoded = _decode(body);
      return decoded['message']?.toString() ??
          'Unexpected response from provider.';
    } catch (_) {
      return 'Unexpected response from provider.';
    }
  }

  void close() => _client.close();
}

class HttpExceptionForFuelPrices implements Exception {
  const HttpExceptionForFuelPrices(this.message);

  final String message;

  @override
  String toString() => message;
}
