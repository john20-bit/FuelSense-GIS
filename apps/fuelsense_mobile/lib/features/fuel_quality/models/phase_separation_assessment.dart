class PhaseSeparationFactor {
  final String code;
  final String label;
  final String impact;
  final double points;
  final String detail;

  const PhaseSeparationFactor({
    required this.code,
    required this.label,
    required this.impact,
    required this.points,
    required this.detail,
  });

  factory PhaseSeparationFactor.fromJson(Map<String, dynamic> json) {
    return PhaseSeparationFactor(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      impact: json['impact']?.toString() ?? '',
      points: json['points'] is num ? (json['points'] as num).toDouble() : 0.0,
      detail: json['detail']?.toString() ?? '',
    );
  }
}

class PhaseSeparationAssessment {
  final int id;
  final String? documentId;
  final int? vehicleId;
  final String? vehicleDocumentId;
  final int? stationId;
  final String? stationDocumentId;
  final String fuelType;
  final double? ethanolPercent;
  final double? fuelAgeDays;
  final double? storageTemperatureC;
  final double? humidityPercent;
  final bool? waterExposure;
  final bool? sealedStorage;
  final double riskScore;
  final String riskLevel;
  final double confidence;
  final List<PhaseSeparationFactor> contributingFactors;
  final String recommendation;
  final String dataSource;
  final DateTime? analyzedAt;

  const PhaseSeparationAssessment({
    required this.id,
    required this.documentId,
    required this.vehicleId,
    required this.vehicleDocumentId,
    required this.stationId,
    required this.stationDocumentId,
    required this.fuelType,
    required this.ethanolPercent,
    required this.fuelAgeDays,
    required this.storageTemperatureC,
    required this.humidityPercent,
    required this.waterExposure,
    required this.sealedStorage,
    required this.riskScore,
    required this.riskLevel,
    required this.confidence,
    required this.contributingFactors,
    required this.recommendation,
    required this.dataSource,
    required this.analyzedAt,
  });

  factory PhaseSeparationAssessment.fromJson(Map<String, dynamic> json) {
    final rawFactors = json['contributing_factors'];

    return PhaseSeparationAssessment(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      documentId:
          json['document_id']?.toString() ?? json['documentId']?.toString(),
      vehicleId: json['vehicle_id'] is num
          ? (json['vehicle_id'] as num).toInt()
          : null,
      vehicleDocumentId:
          json['vehicle_document_id']?.toString() ??
          json['vehicleDocumentId']?.toString(),
      stationId: json['station_id'] is num
          ? (json['station_id'] as num).toInt()
          : null,
      stationDocumentId:
          json['station_document_id']?.toString() ??
          json['stationDocumentId']?.toString(),
      fuelType: json['fuel_type']?.toString() ?? 'UNKNOWN',
      ethanolPercent: json['ethanol_percent'] is num
          ? (json['ethanol_percent'] as num).toDouble()
          : null,
      fuelAgeDays: json['fuel_age_days'] is num
          ? (json['fuel_age_days'] as num).toDouble()
          : null,
      storageTemperatureC: json['storage_temperature_c'] is num
          ? (json['storage_temperature_c'] as num).toDouble()
          : null,
      humidityPercent: json['humidity_percent'] is num
          ? (json['humidity_percent'] as num).toDouble()
          : null,
      waterExposure: json['water_exposure'] as bool?,
      sealedStorage: json['sealed_storage'] as bool?,
      riskScore: json['risk_score'] is num
          ? (json['risk_score'] as num).toDouble()
          : 0.0,
      riskLevel: json['risk_level']?.toString() ?? 'UNKNOWN',
      confidence: json['confidence'] is num
          ? (json['confidence'] as num).toDouble()
          : 0.0,
      contributingFactors: rawFactors is List
          ? rawFactors
                .whereType<Map>()
                .map(
                  (item) => PhaseSeparationFactor.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      recommendation: json['recommendation']?.toString() ?? '',
      dataSource: json['data_source']?.toString() ?? '',
      analyzedAt: DateTime.tryParse(json['analyzed_at']?.toString() ?? ''),
    );
  }
}
