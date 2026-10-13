import '../models/phase_separation_assessment.dart';

class PhaseSeparationRepository {
  PhaseSeparationRepository._();

  static final PhaseSeparationRepository instance =
      PhaseSeparationRepository._();

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
  }) async {
    final normalizedFuelType = fuelType.trim().toUpperCase();

    if (normalizedFuelType.isEmpty) {
      throw ArgumentError('Fuel type is required.');
    }

    final factors = <PhaseSeparationFactor>[];
    var riskScore = 0.0;
    var availableInputs = 0;

    void addFactor({
      required String code,
      required String label,
      required String impact,
      required double points,
      required String detail,
    }) {
      if (points <= 0) {
        return;
      }

      factors.add(
        PhaseSeparationFactor(
          code: code,
          label: label,
          impact: impact,
          points: points,
          detail: detail,
        ),
      );

      riskScore += points;
    }

    if (ethanolPercent != null) {
      availableInputs++;

      final ethanol = ethanolPercent.clamp(0.0, 100.0);

      if (ethanol >= 20.0) {
        addFactor(
          code: 'HIGH_ETHANOL',
          label: 'High ethanol content',
          impact: 'HIGH',
          points: 20.0,
          detail:
              'Ethanol levels at or above 20% require greater control of water exposure and storage conditions.',
        );
      } else if (ethanol >= 10.0) {
        addFactor(
          code: 'MODERATE_ETHANOL',
          label: 'Ethanol content',
          impact: 'MODERATE',
          points: 10.0,
          detail:
              'Ethanol-blended fuel requires controlled storage because ethanol has greater affinity for water than hydrocarbons.',
        );
      }
    }

    if (fuelAgeDays != null) {
      availableInputs++;

      final age = fuelAgeDays.clamp(0.0, 3650.0);

      if (age > 90.0) {
        addFactor(
          code: 'OLD_FUEL',
          label: 'Extended fuel age',
          impact: 'HIGH',
          points: 20.0,
          detail:
              'Fuel stored for more than 90 days should receive closer quality and storage-condition monitoring.',
        );
      } else if (age > 30.0) {
        addFactor(
          code: 'AGED_FUEL',
          label: 'Fuel age',
          impact: 'MODERATE',
          points: 10.0,
          detail:
              'Fuel stored for more than 30 days has increased need for storage-condition monitoring.',
        );
      }
    }

    if (storageTemperatureC != null) {
      availableInputs++;

      final temperature = storageTemperatureC.clamp(-50.0, 100.0);

      if (temperature >= 35.0) {
        addFactor(
          code: 'HIGH_TEMPERATURE',
          label: 'High storage temperature',
          impact: 'HIGH',
          points: 15.0,
          detail:
              'Elevated storage temperature increases fuel degradation and storage stress.',
        );
      } else if (temperature >= 30.0) {
        addFactor(
          code: 'WARM_STORAGE',
          label: 'Warm storage temperature',
          impact: 'MODERATE',
          points: 8.0,
          detail:
              'Warm storage conditions increase the need for fuel-quality monitoring.',
        );
      }
    }

    if (humidityPercent != null) {
      availableInputs++;

      final humidity = humidityPercent.clamp(0.0, 100.0);

      if (humidity >= 80.0) {
        addFactor(
          code: 'HIGH_HUMIDITY',
          label: 'High ambient humidity',
          impact: 'HIGH',
          points: 15.0,
          detail:
              'High humidity increases the importance of preventing moisture entry into fuel storage.',
        );
      } else if (humidity >= 60.0) {
        addFactor(
          code: 'MODERATE_HUMIDITY',
          label: 'Elevated humidity',
          impact: 'MODERATE',
          points: 7.0,
          detail:
              'Elevated humidity warrants additional attention to storage sealing and water ingress.',
        );
      }
    }

    if (waterExposure == true) {
      availableInputs++;

      addFactor(
        code: 'WATER_EXPOSURE',
        label: 'Water exposure detected',
        impact: 'CRITICAL',
        points: 35.0,
        detail:
            'Known water exposure is the strongest direct risk indicator in this assessment.',
      );
    } else if (waterExposure == false) {
      availableInputs++;
    }

    if (sealedStorage == false) {
      availableInputs++;

      addFactor(
        code: 'UNSEALED_STORAGE',
        label: 'Storage is not sealed',
        impact: 'HIGH',
        points: 15.0,
        detail:
            'Unsealed storage increases the possibility of moisture entering the fuel system.',
      );
    } else if (sealedStorage == true) {
      availableInputs++;
    }

    if (normalizedFuelType == 'E20' && ethanolPercent == null) {
      availableInputs++;

      addFactor(
        code: 'E20_FUEL',
        label: 'E20 fuel',
        impact: 'MODERATE',
        points: 12.0,
        detail:
            'E20 fuel requires careful moisture control and suitable storage conditions.',
      );
    }

    riskScore = riskScore.clamp(0.0, 100.0);

    final riskLevel = switch (riskScore) {
      >= 70.0 => 'CRITICAL',
      >= 45.0 => 'HIGH',
      >= 20.0 => 'MODERATE',
      _ => 'LOW',
    };

    final confidence = availableInputs == 0
        ? 0.20
        : (0.35 + (availableInputs / 6.0) * 0.60).clamp(0.0, 0.95);

    final recommendation = switch (riskLevel) {
      'CRITICAL' =>
        'Inspect the fuel and storage system promptly. Check for water ingress and avoid continued use until fuel quality is confirmed.',
      'HIGH' =>
        'Inspect storage sealing and check for water contamination. Monitor fuel quality before extended storage or continued use.',
      'MODERATE' =>
        'Monitor fuel age, moisture exposure, temperature, and storage sealing. Inspect fuel quality if conditions worsen.',
      _ =>
        'Current supplied conditions indicate low separation risk. Continue normal storage controls and monitor changes.',
    };

    return PhaseSeparationAssessment(
      id: 0,
      documentId: null,
      vehicleId: null,
      vehicleDocumentId: vehicleDocumentId?.trim().isEmpty == true
          ? null
          : vehicleDocumentId?.trim(),
      stationId: null,
      stationDocumentId: stationDocumentId?.trim().isEmpty == true
          ? null
          : stationDocumentId?.trim(),
      fuelType: normalizedFuelType,
      ethanolPercent: ethanolPercent,
      fuelAgeDays: fuelAgeDays,
      storageTemperatureC: storageTemperatureC,
      humidityPercent: humidityPercent,
      waterExposure: waterExposure,
      sealedStorage: sealedStorage,
      riskScore: double.parse(riskScore.toStringAsFixed(1)),
      riskLevel: riskLevel,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      contributingFactors: factors,
      recommendation: recommendation,
      dataSource: 'FuelSense GIS deterministic domain rules',
      analyzedAt: DateTime.now().toUtc(),
    );
  }
}
