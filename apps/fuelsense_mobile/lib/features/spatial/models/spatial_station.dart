class SpatialFuelProduct {
  final String name;
  final double? priceInr;

  const SpatialFuelProduct({required this.name, this.priceInr});

  factory SpatialFuelProduct.fromJson(Map<String, dynamic> json) {
    return SpatialFuelProduct(
      name: json['name']?.toString() ?? 'Unknown fuel',
      priceInr: (json['priceInr'] as num?)?.toDouble(),
    );
  }
}

class SpatialStation {
  final String id;
  final String outletId;
  final String name;
  final String brand;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final double latitude;
  final double longitude;
  final String geohash;
  final String hours;
  final String mapsLink;
  final String sourceUrl;
  final List<SpatialFuelProduct> fuelProducts;
  final DateTime? capturedAt;
  final String source;
  final double? distanceKm;

  const SpatialStation({
    required this.id,
    required this.outletId,
    required this.name,
    required this.brand,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.hours,
    required this.mapsLink,
    required this.sourceUrl,
    required this.fuelProducts,
    required this.capturedAt,
    required this.source,
    this.distanceKm,
  });

  factory SpatialStation.fromJson(Map<String, dynamic> json) {
    final products = json['fuelProducts'];

    return SpatialStation(
      id: json['id']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed station',
      brand: json['brand']?.toString() ?? 'Unknown',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      geohash: json['geohash']?.toString() ?? '',
      hours: json['hours']?.toString() ?? '',
      mapsLink: json['mapsLink']?.toString() ?? '',
      sourceUrl: json['sourceUrl']?.toString() ?? '',
      fuelProducts: products is List
          ? products
                .whereType<Map>()
                .map(
                  (product) => SpatialFuelProduct.fromJson(
                    Map<String, dynamic>.from(product),
                  ),
                )
                .toList()
          : const [],
      capturedAt: DateTime.tryParse(json['capturedAt']?.toString() ?? ''),
      source: json['source']?.toString() ?? 'unknown',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  String get locationLabel {
    final parts = <String>[
      if (city.trim().isNotEmpty) city.trim(),
      if (state.trim().isNotEmpty) state.trim(),
      if (pincode.trim().isNotEmpty) pincode.trim(),
    ];

    return parts.join(', ');
  }

  String get priceSummary {
    if (fuelProducts.isEmpty) {
      return 'Price unavailable';
    }

    final priced = fuelProducts.where((product) => product.priceInr != null);

    if (priced.isEmpty) {
      return 'Price unavailable';
    }

    return priced
        .map(
          (product) =>
              '${product.name}: ₹${product.priceInr!.toStringAsFixed(2)}',
        )
        .join(' • ');
  }
}
