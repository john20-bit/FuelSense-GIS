class VehicleCatalog {
  final int id;
  final String make;
  final String model;
  final String? variant;
  final int? modelYear;
  final String? market;
  final String? country;
  final String fuelType;
  final String? recommendedFuel;
  final bool? e20Compatible;
  final bool? e85Compatible;
  final double? tankCapacity;
  final double? claimedMileage;
  final double? engineDisplacement;
  final double? horsepower;
  final double? torque;
  final String? transmission;
  final String? drivetrain;
  final String? sourceName;
  final String? sourceUrl;
  final String? verifiedAt;

  const VehicleCatalog({
    required this.id,
    required this.make,
    required this.model,
    this.variant,
    this.modelYear,
    this.market,
    this.country,
    required this.fuelType,
    this.recommendedFuel,
    this.e20Compatible,
    this.e85Compatible,
    this.tankCapacity,
    this.claimedMileage,
    this.engineDisplacement,
    this.horsepower,
    this.torque,
    this.transmission,
    this.drivetrain,
    this.sourceName,
    this.sourceUrl,
    this.verifiedAt,
  });

  factory VehicleCatalog.fromJson(Map<String, dynamic> json) {
    double? number(String key) {
      final value = json[key];
      return value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
    }

    int? integer(String key) {
      final value = json[key];
      return value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '');
    }

    bool? boolean(String key) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
      return null;
    }

    return VehicleCatalog(
      id: integer('id') ?? 0,
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      variant: json['variant']?.toString(),
      modelYear: integer('modelYear') ?? integer('model_year'),
      market: json['market']?.toString(),
      country: json['country']?.toString(),
      fuelType:
          json['fuelType']?.toString() ?? json['fuel_type']?.toString() ?? '',
      recommendedFuel:
          json['recommendedFuel']?.toString() ??
          json['recommended_fuel']?.toString(),
      e20Compatible: boolean('e20Compatible') ?? boolean('e20_compatible'),
      e85Compatible: boolean('e85Compatible') ?? boolean('e85_compatible'),
      tankCapacity: number('tankCapacity') ?? number('tank_capacity'),
      claimedMileage: number('claimedMileage') ?? number('claimed_mileage'),
      engineDisplacement:
          number('engineDisplacement') ?? number('engine_displacement'),
      horsepower: number('horsepower'),
      torque: number('torque'),
      transmission: json['transmission']?.toString(),
      drivetrain: json['drivetrain']?.toString(),
      sourceName:
          json['sourceName']?.toString() ?? json['source_name']?.toString(),
      sourceUrl:
          json['sourceUrl']?.toString() ?? json['source_url']?.toString(),
      verifiedAt:
          json['verifiedAt']?.toString() ?? json['verified_at']?.toString(),
    );
  }

  String get displayName {
    final parts = <String>[make, model];
    if (variant != null && variant!.trim().isNotEmpty) {
      parts.add(variant!.trim());
    }
    if (modelYear != null) parts.add(modelYear.toString());
    return parts.where((e) => e.trim().isNotEmpty).join(' ');
  }

  String get fuelLabel => fuelType.trim().toUpperCase();

  String get compatibilityLabel {
    if (fuelLabel == 'PETROL') {
      if (e85Compatible == true) return 'E20 / E85 compatible';
      if (e20Compatible == true) return 'E20 compatible';
      if (e20Compatible == false) return 'E20 not verified';
    }
    return recommendedFuel?.trim().isNotEmpty == true
        ? 'Recommended: ${recommendedFuel!.trim()}'
        : 'Compatibility not verified';
  }
}
