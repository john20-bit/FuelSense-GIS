import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/satellite_hotspot_model.dart';

class SatelliteHotspotRepository {
  SatelliteHotspotRepository();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SatelliteHotspot>> getHotspots() async {
    final snapshot = await _firestore
        .collection('satelliteHotspots')
        .orderBy('capturedAt', descending: true)
        .limit(100)
        .get();

    return snapshot.docs
        .map(
          (document) => SatelliteHotspot.fromJson({
            ...document.data(),
          }),
        )
        .toList();
  }
}
