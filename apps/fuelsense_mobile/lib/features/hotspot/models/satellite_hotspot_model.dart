class SatelliteHotspot {
  final int id;
  final double latitude;
  final double longitude;
  final int humanActivityHotspot;
  final String source;
  final String detectionPeriod;
  final String status;

  const SatelliteHotspot({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.humanActivityHotspot,
    required this.source,
    required this.detectionPeriod,
    required this.status,
  });

  factory SatelliteHotspot.fromJson(Map<String, dynamic> json) {
    return SatelliteHotspot(
      id: (json['id'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      humanActivityHotspot:
          (json['humanActivityHotspot'] as num?)?.toInt() ?? 0,
      source: json['source']?.toString() ?? 'UNKNOWN',
      detectionPeriod: json['detectionPeriod']?.toString() ?? '',
      status: json['status']?.toString() ?? 'UNKNOWN',
    );
  }
}
