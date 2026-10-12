import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/vehicle_catalog.dart';
import '../repositories/vehicle_catalog_repository.dart';

final vehicleCatalogProvider = FutureProvider<List<VehicleCatalog>>((ref) {
  return VehicleCatalogRepository.instance.getCatalog();
});
