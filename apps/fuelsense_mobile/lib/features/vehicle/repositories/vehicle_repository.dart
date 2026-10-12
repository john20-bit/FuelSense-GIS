import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/vehicle.dart';

class VehicleRepository {
  VehicleRepository._();

  static final VehicleRepository instance = VehicleRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _vehicles {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No authenticated Firebase user is available.');
    }

    return _firestore.collection('users').doc(user.uid).collection('vehicles');
  }

  Future<List<Vehicle>> getMyVehicles() async {
    final snapshot = await _vehicles.orderBy('createdAt').get();

    return snapshot.docs.map((document) {
      final data = Map<String, dynamic>.from(document.data());

      return Vehicle.fromJson({...data, 'document_id': document.id});
    }).toList();
  }

  Map<String, dynamic>? optionalField(String key, Object? value) {
    return value == null ? null : <String, dynamic>{key: value};
  }

  Future<Vehicle> createVehicle({
    required int catalogId,
    required String name,
    required String registrationNumber,
    required String fuelType,
    String? powertrainType,
    double? tankCapacity,
    double? claimedMileage,
    String? make,
    String? model,
    String? variant,
    int? modelYear,
    String? recommendedFuel,
    bool? e20Compatible,
    bool? e85Compatible,
    String? sourceName,
    String? sourceUrl,
    String? verifiedAt,
    double? currentFuel,
    double? currentOdometer,
  }) async {
    final vehicleReference = _vehicles.doc();

    Map<String, dynamic>? optionalField(String key, Object? value) {
      return value == null ? null : <String, dynamic>{key: value};
    }

    final data = <String, dynamic>{
      'catalogId': catalogId,
      'name': name.trim(),
      'registrationNumber': registrationNumber.trim().toUpperCase(),
      'fuelType': fuelType.trim().toUpperCase(),
      ...?optionalField('powertrainType', powertrainType),
      ...?optionalField('tankCapacity', tankCapacity),
      ...?optionalField('claimedMileage', claimedMileage),
      ...?optionalField('make', make),
      ...?optionalField('model', model),
      ...?optionalField('variant', variant),
      ...?optionalField('modelYear', modelYear),
      ...?optionalField('recommendedFuel', recommendedFuel),
      ...?optionalField('e20Compatible', e20Compatible),
      ...?optionalField('e85Compatible', e85Compatible),
      ...?optionalField('sourceName', sourceName),
      ...?optionalField('sourceUrl', sourceUrl),
      ...?optionalField('verifiedAt', verifiedAt),
      ...?optionalField('currentFuelLevel', currentFuel),
      ...?optionalField('currentOdometer', currentOdometer),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await vehicleReference.set(data);

    return Vehicle.fromJson({
      ...data,
      'id': 0,
      'document_id': vehicleReference.id,
    });
  }

  Future<void> updateVehicle({
    required String vehicleDocumentId,
    required String name,
    required String registrationNumber,
    required String fuelType,
    required double currentMileage,
    required double currentOdometer,
    required double currentFuel,
    double? tankCapacity,
    int? catalogId,
    String? make,
    String? model,
    String? variant,
    int? modelYear,
    bool? e20Compatible,
    bool? e85Compatible,
    bool replaceCatalog = false,
    double? claimedMileage,
    String? recommendedFuel,
    String? sourceName,
    String? sourceUrl,
    String? verifiedAt,
    double? engineDisplacement,
    double? horsepower,
    double? torque,
    String? transmission,
    String? drivetrain,
    String? market,
    String? country,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'registrationNumber': registrationNumber.trim().toUpperCase(),
      'fuelType': fuelType.trim().toUpperCase(),
      'currentMileage': currentMileage,
      'currentOdometer': currentOdometer,
      'currentFuelLevel': currentFuel,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (replaceCatalog) {
      // Write nulls intentionally so the previous catalog's specifications
      // cannot leak into the newly selected vehicle.
      data.addAll({
        'catalogId': catalogId,
        'tankCapacity': tankCapacity,
        'make': make,
        'model': model,
        'variant': variant,
        'modelYear': modelYear,
        'e20Compatible': e20Compatible,
        'e85Compatible': e85Compatible,
        'claimedMileage': claimedMileage,
        'recommendedFuel': recommendedFuel,
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,
        'verifiedAt': verifiedAt,
        'engineDisplacement': engineDisplacement,
        'horsepower': horsepower,
        'torque': torque,
        'transmission': transmission,
        'drivetrain': drivetrain,
        'market': market,
        'country': country,
      });
    } else {
      if (tankCapacity != null) data['tankCapacity'] = tankCapacity;
      if (catalogId != null) data['catalogId'] = catalogId;
      if (make != null) data['make'] = make;
      if (model != null) data['model'] = model;
      if (variant != null) data['variant'] = variant;
      if (modelYear != null) data['modelYear'] = modelYear;
      if (e20Compatible != null) data['e20Compatible'] = e20Compatible;
      if (e85Compatible != null) data['e85Compatible'] = e85Compatible;
    }

    await _vehicles.doc(vehicleDocumentId).update(data);
  }

  Future<void> deleteVehicle(String vehicleDocumentId) async {
    await _vehicles.doc(vehicleDocumentId).delete();
  }
}
