class Vehicle {
  final int id;
  final String? documentId;
  final String name;
  final String registrationNumber;
  final String fuelType;
  final String? powertrainType;

  final double tankCapacity;
  final double currentMileage;
  final double currentOdometer;
  final double currentFuelLevel;

  final int? catalogId;
  final String? make;
  final String? model;
  final String? variant;
  final int? modelYear;
  final bool? e20Compatible;
  final bool? e85Compatible;

  const Vehicle({
    required this.id,
    this.documentId,
    required this.name,
    required this.registrationNumber,
    required this.fuelType,
    required this.tankCapacity,
    required this.currentMileage,
    required this.currentOdometer,
    required this.currentFuelLevel,
    this.powertrainType,
    this.catalogId,
    this.make,
    this.model,
    this.variant,
    this.modelYear,
    this.e20Compatible,
    this.e85Compatible,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    dynamic value(String snake, String camel) {
      return json[snake] ?? json[camel];
    }

    double number(String snake, String camel) {
      final value = json[snake] ?? json[camel];
      return value is num ? value.toDouble() : 0.0;
    }

    int? integer(String snake, String camel) {
      final value = json[snake] ?? json[camel];
      return value is num ? value.toInt() : null;
    }

    return Vehicle(
      id: integer('id', 'id') ?? 0,
      documentId:
          json['document_id']?.toString() ?? json['documentId']?.toString(),
      name: json['name']?.toString() ?? 'Unknown Vehicle',

      registrationNumber:
          value('registration_number', 'registrationNumber')?.toString() ?? '',

      fuelType: value('fuel_type', 'fuelType')?.toString() ?? 'Unknown',

      powertrainType: value('powertrain_type', 'powertrainType')?.toString(),

      tankCapacity: number('fuel_capacity', 'tankCapacity'),

      currentMileage: number('current_mileage', 'currentMileage'),
      currentOdometer: number('current_odometer', 'currentOdometer'),

      currentFuelLevel: number('current_fuel', 'currentFuelLevel'),

      catalogId: integer('catalog_id', 'catalogId'),

      make: value('brand', 'make')?.toString(),

      model: json['model']?.toString(),

      variant: json['variant']?.toString(),

      modelYear: integer('model_year', 'modelYear'),

      e20Compatible: value('e20_compatible', 'e20Compatible') as bool?,

      e85Compatible: value('e85_compatible', 'e85Compatible') as bool?,
    );
  }

  String get normalizedFuelType => fuelType.trim().toUpperCase();

  String get normalizedPowertrainType =>
      (powertrainType ?? '').trim().toUpperCase();

  bool get isHybrid =>
      normalizedPowertrainType == 'HEV' ||
      normalizedPowertrainType == 'PHEV' ||
      normalizedFuelType == 'HYBRID' ||
      normalizedFuelType == 'HEV' ||
      normalizedFuelType == 'PHEV';

  bool get hasFuelTank => tankCapacity > 0;

  double get fuelPercentage {
    if (tankCapacity <= 0) return 0.0;
    return ((currentFuelLevel / tankCapacity) * 100).clamp(0.0, 100.0);
  }

  double get energyLevelPercentage => fuelPercentage;

  String get energyUnit => '%';

  String get efficiencyLabel {
    return currentMileage > 0
        ? '${currentMileage.toStringAsFixed(1)} km/L'
        : '--';
  }

  String get displayName {
    final parts = <String>[];

    if (make != null && make!.trim().isNotEmpty) {
      parts.add(make!.trim());
    }

    if (model != null && model!.trim().isNotEmpty) {
      parts.add(model!.trim());
    }

    if (variant != null && variant!.trim().isNotEmpty) {
      parts.add(variant!.trim());
    }

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return name;
  }
}
