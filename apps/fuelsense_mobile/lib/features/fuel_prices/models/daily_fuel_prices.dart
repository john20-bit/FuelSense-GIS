class DailyFuelPrices {
  const DailyFuelPrices({
    required this.city,
    required this.petrol,
    required this.diesel,
    required this.updatedAt,
    required this.source,
  });

  final String city;
  final double petrol;
  final double diesel;
  final DateTime? updatedAt;
  final String source;

  factory DailyFuelPrices.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final petrolData = json['petrol'];
    final dieselData = json['diesel'];

    if (location is! String ||
        location.trim().isEmpty ||
        petrolData is! Map ||
        dieselData is! Map) {
      throw const FormatException('Incomplete fuel price response.');
    }

    final petrol = _price(petrolData['price']);
    final diesel = _price(dieselData['price']);

    if (petrol <= 0 || diesel <= 0) {
      throw const FormatException('Invalid fuel prices.');
    }

    final rawUpdated = json['updated_at'] ?? json['fetched_at'];
    final updatedAt = rawUpdated is String
        ? DateTime.tryParse(rawUpdated)
        : null;

    return DailyFuelPrices(
      city: location.trim(),
      petrol: petrol,
      diesel: diesel,
      updatedAt: updatedAt,
      source: 'API Mitra',
    );
  }

  static double _price(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');

    if (parsed == null || !parsed.isFinite) {
      throw const FormatException('Invalid fuel price value.');
    }

    return parsed;
  }
}
