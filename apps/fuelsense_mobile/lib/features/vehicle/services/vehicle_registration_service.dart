import 'dart:convert';

import 'package:http/http.dart' as http;

class VehicleRegistrationDetails {
  final String registrationNumber;
  final String make;
  final String model;
  final String variant;
  final String fuelType;
  final int? manufactureYear;
  final String source;
  final bool verified;

  const VehicleRegistrationDetails({
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.variant,
    required this.fuelType,
    required this.manufactureYear,
    required this.source,
    required this.verified,
  });

  factory VehicleRegistrationDetails.fromJson(Map<String, dynamic> json) {
    return VehicleRegistrationDetails(
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      variant: json['variant']?.toString() ?? '',
      fuelType: json['fuelType']?.toString() ?? '',
      manufactureYear: int.tryParse(
        json['manufactureYear']?.toString() ?? '',
      ),
      source: json['source']?.toString() ?? '',
      verified: json['verified'] == true,
    );
  }
}

class VehicleRegistrationService {
  VehicleRegistrationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Android emulator: 10.0.2.2 points to the development computer.
  // For a physical phone, replace this with your Mac's LAN IP.
  static const String _baseUrl = String.fromEnvironment(
    'FUELSENSE_API_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  Future<VehicleRegistrationDetails> lookup(String registrationNumber) async {
    final uri = Uri.parse('$_baseUrl/api/vehicles/lookup');

    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'registrationNumber': registrationNumber.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = jsonDecode(response.body);
    final body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

    if (response.statusCode != 200) {
      final message = body['message']?.toString() ??
          body['error']?.toString() ??
          'Vehicle registration lookup failed (${response.statusCode}).';
      throw Exception(message);
    }

    final vehicle = body['vehicle'];
    if (vehicle is! Map<String, dynamic>) {
      throw Exception('The server returned an invalid vehicle response.');
    }

    final details = VehicleRegistrationDetails.fromJson(vehicle);
    if (!details.verified) {
      throw Exception('The provider did not verify this vehicle.');
    }
    return details;
  }

  void close() => _client.close();
}
