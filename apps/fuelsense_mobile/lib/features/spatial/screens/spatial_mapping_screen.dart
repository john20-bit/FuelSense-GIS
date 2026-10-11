import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/location_service.dart';
import '../models/spatial_station.dart';
import '../providers/spatial_station_provider.dart';

class SpatialMappingScreen extends ConsumerStatefulWidget {
  const SpatialMappingScreen({super.key});

  @override
  ConsumerState<SpatialMappingScreen> createState() =>
      _SpatialMappingScreenState();
}

class _SpatialMappingScreenState extends ConsumerState<SpatialMappingScreen> {
  static const _initialPosition = LatLng(9.9252, 78.1198);

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  SpatialStation? _selectedStation;

  String _searchQuery = '';
  String? _selectedBrand;
  String? _selectedFuelProduct;

  bool _mapReady = false;

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(spatialStationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF071018),
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(stationsAsync),
            _buildTopBar(),
            _buildSearchAndFilters(stationsAsync),
            _buildLocateButton(),
            _buildSourceBadge(stationsAsync),
            if (_selectedStation != null) _buildStationSheet(_selectedStation!),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(AsyncValue<List<SpatialStation>> stationsAsync) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _initialPosition,
        zoom: 12.5,
      ),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
        _mapReady = true;
        _updateMarkers(stationsAsync.asData?.value ?? const <SpatialStation>[]);
      },
      onTap: (_) {
        if (_selectedStation != null) {
          setState(() => _selectedStation = null);
        }
      },
      markers: _markers,
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Row(
        children: [
          _roundButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1720).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF24404C)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF53E0D0),
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'SPATIAL MAPPING',
                    style: TextStyle(
                      color: Color(0xFFE9F0F4),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    AsyncValue<List<SpatialStation>> stationsAsync,
  ) {
    final stations = stationsAsync.asData?.value ?? const <SpatialStation>[];

    final brands =
        stations
            .map((station) => station.brand.trim())
            .where((brand) => brand.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final fuelProducts =
        stations
            .expand((station) => station.fuelProducts)
            .map((product) => product.name.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Positioned(
      top: 72,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1720).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF24404C)),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
              style: const TextStyle(color: Color(0xFFE9F0F4), fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search station, city or brand',
                hintStyle: TextStyle(color: Color(0xFF718692), fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF53E0D0),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(
                  label: 'All',
                  selected:
                      _selectedBrand == null && _selectedFuelProduct == null,
                  onTap: () {
                    setState(() {
                      _selectedBrand = null;
                      _selectedFuelProduct = null;
                    });
                    _reloadStations();
                  },
                ),
                ...brands.map(
                  (brand) => _filterChip(
                    label: brand,
                    selected: _selectedBrand == brand,
                    onTap: () {
                      setState(() {
                        _selectedBrand = _selectedBrand == brand ? null : brand;
                        _selectedFuelProduct = null;
                      });
                      _reloadStations();
                    },
                  ),
                ),
                ...fuelProducts.map(
                  (fuel) => _filterChip(
                    label: fuel,
                    selected: _selectedFuelProduct == fuel,
                    onTap: () {
                      setState(() {
                        _selectedFuelProduct = _selectedFuelProduct == fuel
                            ? null
                            : fuel;
                        _selectedBrand = null;
                      });
                      _reloadStations();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Material(
        color: selected
            ? const Color(0xFF53E0D0)
            : const Color(0xFF0B1720).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF071018)
                      : const Color(0xFFC9D5DA),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocateButton() {
    return Positioned(
      right: 16,
      bottom: _selectedStation == null ? 24 : 230,
      child: _roundButton(
        icon: Icons.my_location_rounded,
        onPressed: _locateMe,
      ),
    );
  }

  Widget _buildSourceBadge(AsyncValue<List<SpatialStation>> stationsAsync) {
    final stations = stationsAsync.asData?.value ?? const <SpatialStation>[];

    return Positioned(
      left: 16,
      bottom: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1720).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF24404C)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF53E0D0),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              stationsAsync.isLoading
                  ? 'Loading stations'
                  : '${_visibleStations(stations).length} stations',
              style: const TextStyle(
                color: Color(0xFFC9D5DA),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'DEMO DATA',
              style: TextStyle(
                color: Color(0xFF718692),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationSheet(SpatialStation station) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 260),
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1720),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF24404C)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      station.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE9F0F4),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _selectedStation = null);
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF718692),
                    ),
                  ),
                ],
              ),
              Text(
                '${station.brand} • ${station.locationLabel}',
                style: const TextStyle(color: Color(0xFF8FA1AA), fontSize: 12),
              ),
              if (station.distanceKm != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${station.distanceKm!.toStringAsFixed(2)} km away',
                  style: const TextStyle(
                    color: Color(0xFF53E0D0),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 13),
              if (station.fuelProducts.isEmpty)
                const Text(
                  'Fuel pricing unavailable',
                  style: TextStyle(color: Color(0xFF9AAAB2), fontSize: 12),
                )
              else
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: station.fuelProducts.map(_fuelProductPill).toList(),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.navigation_rounded,
                      label: 'Navigate',
                      onPressed: () => _navigateToStation(station),
                    ),
                  ),
                  if (station.phone.trim().isNotEmpty) ...[
                    const SizedBox(width: 9),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        onPressed: () => _callStation(station),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fuelProductPill(SpatialFuelProduct product) {
    final price = product.priceInr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF10242D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF24404C)),
      ),
      child: Text(
        price == null
            ? '${product.name}: unavailable'
            : '${product.name}: ₹${price.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Color(0xFFC9D5DA),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF53E0D0),
          foregroundColor: const Color(0xFF071018),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: const Color(0xFF0B1720).withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: const Color(0xFFE9F0F4), size: 21),
        ),
      ),
    );
  }

  List<SpatialStation> _visibleStations(List<SpatialStation> stations) {
    final query = _searchQuery.trim().toLowerCase();
    final brand = _selectedBrand?.trim().toLowerCase();
    final fuelProduct = _selectedFuelProduct?.trim().toLowerCase();

    return stations.where((station) {
      final matchesSearch =
          query.isEmpty ||
          station.name.toLowerCase().contains(query) ||
          station.brand.toLowerCase().contains(query) ||
          station.city.toLowerCase().contains(query) ||
          station.state.toLowerCase().contains(query) ||
          station.address.toLowerCase().contains(query);

      final matchesBrand =
          brand == null ||
          brand.isEmpty ||
          station.brand.trim().toLowerCase() == brand;

      final matchesFuel =
          fuelProduct == null ||
          fuelProduct.isEmpty ||
          station.fuelProducts.any(
            (product) => product.name.trim().toLowerCase() == fuelProduct,
          );

      return matchesSearch && matchesBrand && matchesFuel;
    }).toList();
  }

  void _updateMarkers(List<SpatialStation> stations) {
    if (!_mapReady || !mounted) return;

    final visible = _visibleStations(stations);
    final markers = <Marker>{};

    for (final station in visible) {
      markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          infoWindow: InfoWindow(title: station.name, snippet: station.brand),
          onTap: () {
            if (mounted) {
              setState(() => _selectedStation = station);
            }
          },
        ),
      );
    }

    setState(() => _markers = markers);
  }

  void _reloadStations() {
    final stations = ref.read(spatialStationsProvider).asData?.value;
    if (stations != null) {
      _updateMarkers(stations);
    }
  }

  Future<void> _locateMe() async {
    try {
      _showMessage('Getting your current location...');

      final Position position = await LocationService.getCurrentLocation();

      final repository = ref.read(spatialStationRepositoryProvider);

      final stations = await repository.getNearbyStations(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 10,
        brand: _selectedBrand,
        fuelProduct: _selectedFuelProduct,
        limit: 100,
      );

      if (!mounted) return;

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 13.5,
          ),
        ),
      );

      _updateMarkers(stations);

      setState(() => _selectedStation = null);

      _showMessage('Showing stations within 10 km of your location.');
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      _showMessage(message);
    }
  }

  Future<void> _navigateToStation(SpatialStation station) async {
    final destination = Uri.encodeComponent(
      '${station.latitude},${station.longitude}',
    );

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destination'
      '&travelmode=driving',
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        _showMessage('Unable to open Google Maps.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open Google Maps.');
      }
    }
  }

  Future<void> _callStation(SpatialStation station) async {
    final phone = station.phone.trim();

    if (phone.isEmpty) {
      _showMessage('Phone number unavailable.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);

    try {
      final opened = await launchUrl(uri);

      if (!opened && mounted) {
        _showMessage('Unable to open the phone app.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open the phone app.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
