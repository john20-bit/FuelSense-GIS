import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/vehicle_repository.dart';
import '../../../shared/models/vehicle.dart';

final vehicleProvider = FutureProvider<List<Vehicle>>((ref) async {
  return VehicleRepository.instance.getMyVehicles();
});
