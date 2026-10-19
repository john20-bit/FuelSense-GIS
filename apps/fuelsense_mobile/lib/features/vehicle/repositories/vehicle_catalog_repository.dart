import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/models/vehicle_catalog.dart';

class VehicleCatalogRepository {
  VehicleCatalogRepository._();

  static final VehicleCatalogRepository instance =
      VehicleCatalogRepository._();

  static const String _baseUrl = String.fromEnvironment(
    'FUELSENSE_API_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  Future<List<VehicleCatalog>> getCatalog({
    String? fuelType,
    String? make,
    String? model,
  }) async {
    final uri = Uri.parse('$_baseUrl/vehicles/catalog').replace(
      queryParameters: {'limit': '100'},
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Vehicle catalogue request failed (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = decoded['results'] as List<dynamic>? ?? [];

    final normalizedMake = make?.trim().toLowerCase() ?? '';
    final normalizedModel = model?.trim().toLowerCase() ?? '';
    final normalizedFuel = fuelType?.trim().toUpperCase() ?? '';

    final vehicles = <VehicleCatalog>[];

    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;

      final rawId = row['id']?.toString() ?? '';
      final numericId = int.tryParse(rawId.split('-').last) ?? 0;
      final vehicleMake = row['make']?.toString() ?? '';
      final vehicleModel = row['model']?.toString() ?? '';

      if (vehicleMake.isEmpty || vehicleModel.isEmpty) continue;

      // The source catalogue contains names, not verified fuel specifications.
      const fuelLabel = 'UNKNOWN';

      if (normalizedMake.isNotEmpty &&
          !vehicleMake.toLowerCase().contains(normalizedMake)) {
        continue;
      }

      if (normalizedModel.isNotEmpty &&
          !vehicleModel.toLowerCase().contains(normalizedModel)) {
        continue;
      }

      if (normalizedFuel.isNotEmpty && normalizedFuel != fuelLabel) {
        continue;
      }

      vehicles.add(
        VehicleCatalog(
          id: numericId,
          make: vehicleMake,
          model: vehicleModel,
          modelYear: row['catalogYear'] is num
              ? (row['catalogYear'] as num).toInt()
              : null,
          market: row['market']?.toString(),
          country: row['country']?.toString(),
          fuelType: fuelLabel,
          sourceName: row['sourceName']?.toString(),
          sourceUrl: row['sourceUrl']?.toString(),
          verifiedAt: row['retrievedAt']?.toString(),
        ),
      );
    }

    vehicles.sort((a, b) {
      final makeCompare =
          a.make.toLowerCase().compareTo(b.make.toLowerCase());
      if (makeCompare != 0) return makeCompare;
      return a.model.toLowerCase().compareTo(b.model.toLowerCase());
    });

    return vehicles;
  }

  Future<VehicleCatalog?> getCatalogEntry(String documentId) async {
    final entries = await getCatalog();
    for (final entry in entries) {
      if (entry.id.toString() == documentId) return entry;
    }
    return null;
  }
}
