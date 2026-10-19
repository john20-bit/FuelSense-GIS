
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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

class _SpatialMappingScreenState
    extends ConsumerState<SpatialMappingScreen> {
  static const Color _black = Color(0xFF050709);
  static const Color _panel = Color(0xF20B1015);
  static const Color _panelRaised = Color(0xFF111820);
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _green = Color(0xFF39FF88);
  static const Color _violet = Color(0xFFB56BFF);
  static const Color _text = Color(0xFFF2F7FA);
  static const Color _muted = Color(0xFF8B9AA5);
  static const Color _border = Color(0xFF26343E);

  static const LatLng _initialPosition = LatLng(9.9252, 78.1198);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  SpatialStation? _selectedStation;
  List<SpatialStation>? _locatedStations;
  LatLng? _userLocation;

  String _searchQuery = '';
  String? _selectedBrand;
  String? _selectedFuelProduct;
  bool _isLocating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(spatialStationsProvider);

    final stations = _locatedStations ??
        stationsAsync.asData?.value ??
        const <SpatialStation>[];

    final visibleStations = _visibleStations(stations);

    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 12.5,
                minZoom: 4,
                maxZoom: 19,
                onTap: _clearSelection,
              ),
              children: [
                // Normal OpenStreetMap tiles with a subtle dark treatment.
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fuelsense_mobile',
                  maxZoom: 19,
                ),

                IgnorePointer(
                  child: ColoredBox(
                    color: _black.withValues(alpha: 0.38),
                    child: const SizedBox.expand(),
                  ),
                ),

                // Fuel station markers.
                MarkerLayer(
                  markers: visibleStations
                      .where((station) =>
                          station.latitude.abs() > 0.0001 &&
                          station.longitude.abs() > 0.0001)
                      .map(
                        (station) => Marker(
                          point: LatLng(
                            station.latitude,
                            station.longitude,
                          ),
                          width: 48,
                          height: 58,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _selectedStation = station;
                              });
                            },
                            child: _buildStationMarker(
                              selected: _selectedStation == station,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                // Current location has its own cyan marker and halo.
                if (_userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userLocation!,
                        width: 54,
                        height: 54,
                        child: _buildUserMarker(),
                      ),
                    ],
                  ),

                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      onTap: () {
                        launchUrl(
                          Uri.parse(
                            'https://www.openstreetmap.org/copyright',
                          ),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Gentle edge shading keeps controls readable.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      _black.withValues(alpha: 0.04),
                      _black.withValues(alpha: 0.32),
                    ],
                    stops: const [0.45, 0.78, 1],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),

            _buildHeader(),
            _buildSearchAndFilters(stations),
            _buildMapControls(),
            _buildStationCount(visibleStations, stationsAsync.isLoading),

            if (_selectedStation != null)
              _buildStationSheet(_selectedStation!),
          ],
        ),
      ),
    );
  }

  Widget _buildStationMarker({required bool selected}) {
    final color = selected ? _violet : _green;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected)
          Container(
            width: 19,
            height: 19,
            margin: const EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(
              color: _black,
              shape: BoxShape.circle,
              border: Border.all(color: _violet, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: _violet.withValues(alpha: 0.28),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: _violet,
              size: 12,
            ),
          ),
        Icon(
          Icons.location_on_rounded,
          color: color,
          size: selected ? 36 : 34,
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: selected ? 12 : 8,
            ),
            const Shadow(
              color: Colors.black87,
              blurRadius: 4,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _cyan.withValues(alpha: 0.10),
        border: Border.all(
          color: _cyan.withValues(alpha: 0.5),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.18),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(
            color: _cyan,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: _panelDecoration(accent: _cyan),
              child: Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      color: _cyan,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FUEL SENSE',
                          style: TextStyle(
                            color: _text,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'SPATIAL MAPPING',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.4),
                          blurRadius: 7,
                        ),
                      ],
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

  Widget _buildSearchAndFilters(List<SpatialStation> stations) {
    final brands = stations
        .map((station) => station.brand.trim())
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final fuels = stations
        .expand((station) => station.fuelProducts)
        .map((product) => product.name.trim())
        .where((fuel) => fuel.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Positioned(
      top: 76,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            height: 49,
            decoration: _panelDecoration(),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              cursorColor: _cyan,
              style: const TextStyle(
                color: _text,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Search stations, city or brand',
                hintStyle: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _cyan,
                  size: 21,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _muted,
                          size: 18,
                        ),
                      ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(
                  'ALL',
                  _selectedBrand == null &&
                      _selectedFuelProduct == null,
                  () {
                    setState(() {
                      _selectedBrand = null;
                      _selectedFuelProduct = null;
                    });
                  },
                ),
                ...brands.map(
                  (brand) => _filterChip(
                    brand,
                    _selectedBrand == brand,
                    () {
                      setState(() {
                        _selectedBrand =
                            _selectedBrand == brand ? null : brand;
                        _selectedFuelProduct = null;
                      });
                    },
                  ),
                ),
                ...fuels.map(
                  (fuel) => _filterChip(
                    fuel,
                    _selectedFuelProduct == fuel,
                    () {
                      setState(() {
                        _selectedFuelProduct =
                            _selectedFuelProduct == fuel ? null : fuel;
                        _selectedBrand = null;
                      });
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

  Widget _filterChip(
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Material(
        color: selected ? _cyan : _panel,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _cyan : _border,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? _black : _text,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      bottom: _selectedStation == null ? 91 : 300,
      child: Column(
        children: [
          _iconButton(
            icon: Icons.my_location_rounded,
            color: _cyan,
            onPressed: _locateMe,
            loading: _isLocating,
          ),
          const SizedBox(height: 9),
          _iconButton(
            icon: Icons.add_rounded,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                (_mapController.camera.zoom + 1).clamp(4.0, 19.0),
              );
            },
          ),
          const SizedBox(height: 7),
          _iconButton(
            icon: Icons.remove_rounded,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                (_mapController.camera.zoom - 1).clamp(4.0, 19.0),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStationCount(
    List<SpatialStation> stations,
    bool loading,
  ) {
    return Positioned(
      left: 16,
      bottom: 25,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        decoration: _panelDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: loading ? Colors.orangeAccent : _green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              loading ? 'LOADING STATIONS' : '${stations.length} STATIONS',
              style: const TextStyle(
                color: _text,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
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
        constraints: const BoxConstraints(maxHeight: 285),
        padding: const EdgeInsets.fromLTRB(17, 12, 17, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF080D12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _green.withValues(alpha: 0.32),
          ),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.07),
              blurRadius: 22,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 33,
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      station.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close station details',
                    onPressed: () {
                      setState(() {
                        _selectedStation = null;
                      });
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${station.brand} • ${station.locationLabel}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
              ),
              if (station.distanceKm != null) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      color: _cyan,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${station.distanceKm!.toStringAsFixed(2)} km away',
                      style: const TextStyle(
                        color: _cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              if (station.fuelProducts.isEmpty)
                const Text(
                  'Fuel pricing unavailable',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                )
              else
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: station.fuelProducts
                      .map(_fuelProductPill)
                      .toList(),
                ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.navigation_rounded,
                      label: 'Navigate',
                      accent: _cyan,
                      onPressed: () => _navigateToStation(station),
                    ),
                  ),
                  if (station.phone.trim().isNotEmpty) ...[
                    const SizedBox(width: 9),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        accent: _green,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _panelRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Text(
        price == null
            ? '${product.name}: unavailable'
            : '${product.name}: ₹${price.toStringAsFixed(2)}',
        style: const TextStyle(
          color: _text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: _black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = _text,
    bool loading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color == _cyan
              ? _cyan.withValues(alpha: 0.55)
              : _border,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 21),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration({Color? accent}) {
    return BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: accent == null
            ? _border
            : accent.withValues(alpha: 0.35),
      ),
      boxShadow: [
        BoxShadow(
          color: (accent ?? _cyan).withValues(alpha: 0.035),
          blurRadius: 15,
        ),
      ],
    );
  }

  List<SpatialStation> _visibleStations(
    List<SpatialStation> stations,
  ) {
    final query = _searchQuery.toLowerCase();
    final brand = _selectedBrand?.toLowerCase();
    final fuel = _selectedFuelProduct?.toLowerCase();

    return stations.where((station) {
      final matchesSearch = query.isEmpty ||
          station.name.toLowerCase().contains(query) ||
          station.brand.toLowerCase().contains(query) ||
          station.city.toLowerCase().contains(query) ||
          station.state.toLowerCase().contains(query) ||
          station.address.toLowerCase().contains(query);

      final matchesBrand = brand == null ||
          station.brand.trim().toLowerCase() == brand;

      final matchesFuel = fuel == null ||
          station.fuelProducts.any(
            (product) => product.name.trim().toLowerCase() == fuel,
          );

      return matchesSearch && matchesBrand && matchesFuel;
    }).toList();
  }

  Future<void> _locateMe() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
    });

    try {
      final Position position =
          await LocationService.getCurrentLocation();

      if (!mounted) return;

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _userLocation = location;
        _selectedStation = null;
      });

      _mapController.move(location, 15);

      final stations = await ref
          .read(spatialStationRepositoryProvider)
          .getNearbyStations(
            latitude: position.latitude,
            longitude: position.longitude,
            radiusKm: 10,
            brand: _selectedBrand,
            fuelProduct: _selectedFuelProduct,
            limit: 100,
          );

      if (!mounted) return;

      setState(() {
        _locatedStations = stations;
      });

      _showMessage('Showing stations within 10 km of your location.');
    } catch (error) {
      if (mounted) {
        _showMessage(
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _navigateToStation(SpatialStation station) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${station.latitude},${station.longitude}'
      '&travelmode=driving',
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage('Unable to open navigation.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open navigation.');
      }
    }
  }

  Future<void> _callStation(SpatialStation station) async {
    final phone = station.phone.trim();

    if (phone.isEmpty) {
      _showMessage('Phone number unavailable.');
      return;
    }

    try {
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: phone),
      );

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
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _panelRaised,
        ),
      );
  }

  void _clearSelection(TapPosition tapPosition, LatLng point) {
    if (_selectedStation != null) {
      setState(() {
        _selectedStation = null;
      });
    }
  }
}
