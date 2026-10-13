import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/phase_separation_assessment.dart';
import '../repositories/phase_separation_repository.dart';

final phaseSeparationRepositoryProvider =
    Provider<PhaseSeparationRepository>((ref) {
  return PhaseSeparationRepository.instance;
});

final phaseSeparationControllerProvider =
    Provider<PhaseSeparationController>((ref) {
  return PhaseSeparationController(
    ref.read(phaseSeparationRepositoryProvider),
  );
});

class PhaseSeparationController {
  PhaseSeparationController(this._repository);

  final PhaseSeparationRepository _repository;

  Future<PhaseSeparationAssessment> analyze({
    String? vehicleDocumentId,
    String? stationDocumentId,
    required String fuelType,
    double? ethanolPercent,
    double? fuelAgeDays,
    double? storageTemperatureC,
    double? humidityPercent,
    bool? waterExposure,
    bool? sealedStorage,
  }) {
    return _repository.analyze(
      vehicleDocumentId: vehicleDocumentId,
      stationDocumentId: stationDocumentId,
      fuelType: fuelType,
      ethanolPercent: ethanolPercent,
      fuelAgeDays: fuelAgeDays,
      storageTemperatureC: storageTemperatureC,
      humidityPercent: humidityPercent,
      waterExposure: waterExposure,
      sealedStorage: sealedStorage,
    );
  }
}
