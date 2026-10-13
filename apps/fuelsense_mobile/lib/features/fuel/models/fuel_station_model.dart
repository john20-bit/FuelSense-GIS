class FuelStation {
  final int id;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final double distance;

  /// Primary fuel/energy type returned by the backend.
  final String fuelType;

  final int availability;
  final String lastUpdated;
  final String status;

  // Existing blend support.
  final bool e20Available;
  final bool e85Available;

  // Expanded petrol support.
  final bool petrolAvailable;
  final bool premiumPetrolAvailable;

  // Expanded diesel support.
  final bool dieselAvailable;
  final bool premiumDieselAvailable;

  const FuelStation({
    required this.id,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.fuelType,
    required this.availability,
    required this.lastUpdated,
    required this.status,
    required this.e20Available,
    required this.e85Available,
    required this.petrolAvailable,
    required this.premiumPetrolAvailable,
    required this.dieselAvailable,
    required this.premiumDieselAvailable,
  });

  factory FuelStation.fromJson(Map<String, dynamic> json) {
    return FuelStation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      fuelType: json['fuelType']?.toString() ?? 'UNKNOWN',
      availability: (json['availability'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated']?.toString() ?? '',
      status: json['status']?.toString() ?? 'UNKNOWN',

      // Existing backend fields.
      e20Available: json['e20Available'] == true,
      e85Available: json['e85Available'] == true,

      // New fields are deliberately optional on the backend.
      // This means the current API continues working.
      petrolAvailable: json['petrolAvailable'] == true,
      premiumPetrolAvailable: json['premiumPetrolAvailable'] == true,

      dieselAvailable: json['dieselAvailable'] == true,
      premiumDieselAvailable: json['premiumDieselAvailable'] == true,
    );
  }

  FuelStation copyWith({double? distance}) {
    return FuelStation(
      id: id,
      name: name,
      location: location,
      latitude: latitude,
      longitude: longitude,
      distance: distance ?? this.distance,
      fuelType: fuelType,
      availability: availability,
      lastUpdated: lastUpdated,
      status: status,

      e20Available: e20Available,
      e85Available: e85Available,

      petrolAvailable: petrolAvailable,
      premiumPetrolAvailable: premiumPetrolAvailable,

      dieselAvailable: dieselAvailable,
      premiumDieselAvailable: premiumDieselAvailable,
    );
  }

  /// Whether this location offers any liquid fuel.
  bool get hasFuel =>
      petrolAvailable ||
      premiumPetrolAvailable ||
      dieselAvailable ||
      premiumDieselAvailable ||
      e20Available ||
      e85Available;

  /// Human-readable energy categories for the UI.
  List<String> get energyCategories {
    final categories = <String>[];

    if (hasFuel) {
      categories.add('FUEL');
    }

    if (petrolAvailable ||
        premiumPetrolAvailable ||
        e20Available ||
        e85Available) {
      categories.add('PETROL');
    }

    if (dieselAvailable || premiumDieselAvailable) {
      categories.add('DIESEL');
    }

    return categories;
  }
}
