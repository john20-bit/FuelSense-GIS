import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/vehicle_catalog.dart';

class VehicleCatalogRepository {
  VehicleCatalogRepository._();

  static final VehicleCatalogRepository instance = VehicleCatalogRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _catalog =>
      _firestore.collection('vehicleCatalog');

  Future<List<VehicleCatalog>> getCatalog({
    String? fuelType,
    String? make,
    String? model,
  }) async {
    Query<Map<String, dynamic>> query = _catalog;

    final normalizedFuel = fuelType?.trim().toUpperCase();
    final normalizedMake = make?.trim().toLowerCase();
    final normalizedModel = model?.trim().toLowerCase();

    if (normalizedFuel != null && normalizedFuel.isNotEmpty) {
      query = query.where('fuelType', isEqualTo: normalizedFuel);
    }

    final snapshot = await query.get();

    final vehicles = <VehicleCatalog>[];

    for (final document in snapshot.docs) {
      final data = Map<String, dynamic>.from(document.data());

      final catalog = VehicleCatalog.fromJson({
        ...data,
        'id': data['id'] ?? document.id,
      });

      if (catalog.make.isEmpty || catalog.model.isEmpty) {
        continue;
      }

      if (normalizedMake != null &&
          normalizedMake.isNotEmpty &&
          !catalog.make.toLowerCase().contains(normalizedMake)) {
        continue;
      }

      if (normalizedModel != null &&
          normalizedModel.isNotEmpty &&
          !catalog.model.toLowerCase().contains(normalizedModel)) {
        continue;
      }

      vehicles.add(catalog);
    }

    vehicles.sort((a, b) {
      final makeCompare = a.make.toLowerCase().compareTo(b.make.toLowerCase());
      if (makeCompare != 0) return makeCompare;

      final modelCompare = a.model.toLowerCase().compareTo(
        b.model.toLowerCase(),
      );
      if (modelCompare != 0) return modelCompare;

      final yearCompare = (b.modelYear ?? 0).compareTo(a.modelYear ?? 0);
      if (yearCompare != 0) return yearCompare;

      return (a.variant ?? '').toLowerCase().compareTo(
        (b.variant ?? '').toLowerCase(),
      );
    });

    return vehicles;
  }

  Future<VehicleCatalog?> getCatalogEntry(String documentId) async {
    final snapshot = await _catalog.doc(documentId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(snapshot.data()!);

    return VehicleCatalog.fromJson({...data, 'id': data['id'] ?? snapshot.id});
  }
}
