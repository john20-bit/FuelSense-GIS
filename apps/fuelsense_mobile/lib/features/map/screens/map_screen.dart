import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/location_service.dart';
import '../../fuel/models/fuel_station_model.dart';
import '../../fuel/repositories/fuel_repository.dart';

class MapScreen extends ConsumerStatefulWidget {
  final int? initialStationId;

  const MapScreen({super.key, this.initialStationId});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  Timer? _debounceTimer;

  LatLng? _mapCenter;
  Position? _userPosition;

  double _zoom = 13;

  List<FuelStation> _stations = [];

  bool _loadingStations = true;
  bool _fetchingStations = false;

  String? _error;

  String _selectedFilter = 'All';

  bool _isValidCoordinate(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  bool _isValidLatLng(LatLng value) {
    return _isValidCoordinate(value.latitude, value.longitude);
  }

  double _safeZoom(double value) {
    if (!value.isFinite) return 13;

    return value.clamp(3.0, 19.0).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      final position = await LocationService.getCurrentLocation();

      if (!mounted) return;

      if (!_isValidCoordinate(position.latitude, position.longitude)) {
        throw Exception('Invalid GPS coordinates received.');
      }

      final location = LatLng(position.latitude, position.longitude);

      setState(() {
        _userPosition = position;
        _mapCenter = location;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        try {
          _mapController.move(location, _zoom);
        } catch (e) {
          debugPrint('FuelSense Map: initial move failed: $e');
        }
      });

      await _fetchStations(position.latitude, position.longitude);

      _focusInitialStation();
    } catch (e) {
      debugPrint('FuelSense Map initialization failed: $e');

      if (!mounted) return;

      setState(() {
        _loadingStations = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _fetchStations(double latitude, double longitude) async {
    if (_fetchingStations) return;

    if (!_isValidCoordinate(latitude, longitude)) return;

    _fetchingStations = true;

    try {
      if (mounted) {
        setState(() {
          _loadingStations = true;
        });
      }

      final repository = FuelRepository();

      final stations = await repository.getNearbyStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: 10,
      );

      if (!mounted) return;

      setState(() {
        _stations = stations;
        _loadingStations = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('FuelSense station fetch failed: $e');

      if (!mounted) return;

      setState(() {
        _loadingStations = false;
        _error = e.toString();
      });
    } finally {
      _fetchingStations = false;
    }
  }

  void _focusInitialStation() {
    if (widget.initialStationId == null) return;

    FuelStation? station;

    for (final item in _stations) {
      if (item.id == widget.initialStationId) {
        station = item;
        break;
      }
    }

    if (station == null) return;

    if (!_isValidCoordinate(station.latitude, station.longitude)) {
      return;
    }

    final location = LatLng(station.latitude, station.longitude);

    _mapCenter = location;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        _mapController.move(location, 15);
      } catch (e) {
        debugPrint('FuelSense Map station focus failed: $e');
      }
    });
  }

  void _onMapEvent(MapEvent event) {
    if (event is! MapEventMoveEnd) return;

    final center = event.camera.center;
    final zoom = event.camera.zoom;

    if (!_isValidLatLng(center)) return;

    _mapCenter = center;
    _zoom = _safeZoom(zoom);

    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;

      _fetchStations(center.latitude, center.longitude);
    });
  }

  void _recenter() {
    final position = _userPosition;

    if (position == null) return;

    final location = LatLng(position.latitude, position.longitude);

    try {
      _mapController.move(location, 14);
    } catch (e) {
      debugPrint('FuelSense Map recenter failed: $e');
    }
  }

  void _zoomIn() {
    final center = _mapCenter;

    if (center == null) return;

    try {
      _mapController.move(center, (_zoom + 1).clamp(3.0, 19.0));
    } catch (_) {}
  }

  void _zoomOut() {
    final center = _mapCenter;

    if (center == null) return;

    try {
      _mapController.move(center, (_zoom - 1).clamp(3.0, 19.0));
    } catch (_) {}
  }

  List<FuelStation> get _visibleStations {
    switch (_selectedFilter) {
      case 'Petrol':
        return _stations
            .where(
              (station) =>
                  station.petrolAvailable ||
                  station.premiumPetrolAvailable ||
                  station.e20Available ||
                  station.e85Available,
            )
            .toList();

      case 'Diesel':
        return _stations
            .where(
              (station) =>
                  station.dieselAvailable || station.premiumDieselAvailable,
            )
            .toList();

      case 'Ethanol':
        return _stations
            .where((station) => station.e20Available || station.e85Available)
            .toList();

      case 'All':
      default:
        return _stations;
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    final userPosition = _userPosition;

    if (userPosition != null) {
      markers.add(
        Marker(
          point: LatLng(userPosition.latitude, userPosition.longitude),
          width: 80,
          height: 80,
          child: const _UserLocationMarker(),
        ),
      );
    }

    for (final station in _visibleStations) {
      final point = LatLng(station.latitude, station.longitude);

      if (!_isValidLatLng(point)) continue;

      markers.add(
        Marker(
          point: point,
          width: 64,
          height: 76,
          child: GestureDetector(
            onTap: () => _showStationDetails(station),
            child: _FuelStationMarker(
              e20Available: station.e20Available,
              status: station.status,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showStationDetails(FuelStation station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) {
        return _StationDetailsSheet(station: station);
      },
    );
  }

  void _refreshStations() {
    final center = _mapCenter;

    if (center == null) return;

    _fetchStations(center.latitude, center.longitude);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _mapCenter;

    return Scaffold(
      backgroundColor: const Color(0xFF071017),
      body: center == null
          ? const _MapLoadingView()
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: _safeZoom(_zoom),
                    minZoom: 3,
                    maxZoom: 19,
                    onMapEvent: _onMapEvent,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://server.arcgisonline.com/ArcGIS/rest/services/'
                          'World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.fuelsense.mobile',
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'Esri',
                          textStyle: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const IgnorePointer(child: _MapVignette()),

                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      _MapTopBar(
                        stationCount: _visibleStations.length,
                        loading: _loadingStations,
                        onRefresh: _refreshStations,
                      ),

                      const SizedBox(height: 12),

                      _FilterBar(
                        selected: _selectedFilter,
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value;
                          });
                        },
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _MapErrorBanner(message: _error!),
                        ),
                      ],
                    ],
                  ),
                ),

                Positioned(
                  right: 16,
                  bottom: 245,
                  child: _MapControls(
                    onZoomIn: _zoomIn,
                    onZoomOut: _zoomOut,
                    onLocation: _recenter,
                  ),
                ),

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: _NearbyStationPanel(
                    stationCount: _visibleStations.length,
                    loading: _loadingStations,
                    onRefresh: _refreshStations,
                  ),
                ),
              ],
            ),
    );
  }
}

// -----------------------------------------------------------------------------
// LOADING
// -----------------------------------------------------------------------------

class _MapLoadingView extends StatelessWidget {
  const _MapLoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF071017),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF19D3AE)),
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Finding your location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Preparing nearby fuel stations',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MAP VIGNETTE
// -----------------------------------------------------------------------------

class _MapVignette extends StatelessWidget {
  const _MapVignette();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.34),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.28),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TOP BAR
// -----------------------------------------------------------------------------

class _MapTopBar extends StatelessWidget {
  final int stationCount;
  final bool loading;
  final VoidCallback onRefresh;

  const _MapTopBar({
    required this.stationCount,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xE809121A),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color(0xFF19D3AE).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFF19D3AE).withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFF19D3AE),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FuelSense',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        loading
                            ? 'Updating nearby stations...'
                            : '$stationCount stations nearby',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: loading ? null : onRefresh,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    foregroundColor: const Color(0xFF19D3AE),
                  ),
                  icon: loading
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF19D3AE),
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FILTERS
// -----------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  static const filters = [
    ('All', Icons.apps_rounded),
    ('Petrol', Icons.local_gas_station_rounded),
    ('Diesel', Icons.local_shipping_rounded),
    ('Ethanol', Icons.eco_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter = filters[index];
          final active = selected == filter.$1;

          return GestureDetector(
            onTap: () => onChanged(filter.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF19D3AE)
                    : const Color(0xD9091118),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? const Color(0xFF19D3AE)
                      : Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    filter.$2,
                    size: 15,
                    color: active ? const Color(0xFF03130F) : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter.$1,
                    style: TextStyle(
                      color: active ? const Color(0xFF03130F) : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MAP CONTROLS
// -----------------------------------------------------------------------------

class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLocation;

  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ControlButton(icon: Icons.add_rounded, onTap: onZoomIn),
        const SizedBox(height: 8),
        _ControlButton(icon: Icons.remove_rounded, onTap: onZoomOut),
        const SizedBox(height: 14),
        _ControlButton(
          icon: Icons.my_location_rounded,
          active: true,
          onTap: onLocation,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xD9091118),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: active
                      ? const Color(0xFF19D3AE).withValues(alpha: 0.32)
                      : Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Icon(
                icon,
                color: active ? const Color(0xFF19D3AE) : Colors.white,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BOTTOM PANEL
// -----------------------------------------------------------------------------

class _NearbyStationPanel extends StatelessWidget {
  final int stationCount;
  final bool loading;
  final VoidCallback onRefresh;

  const _NearbyStationPanel({
    required this.stationCount,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xF3091118),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 35,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF19D3AE),
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nearby stations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Fuel stations around your location',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF19D3AE).withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$stationCount',
                      style: const TextStyle(
                        color: Color(0xFF19D3AE),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniInfo(
                      icon: Icons.eco_rounded,
                      title: 'Ethanol',
                      value: 'E20 ready',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniInfo(
                      icon: Icons.radar_rounded,
                      title: 'Search',
                      value: '10 km',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniInfo(
                      icon: Icons.auto_awesome_rounded,
                      title: 'FuelSense',
                      value: 'Active',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MiniInfo({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF19D3AE), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// USER LOCATION
// -----------------------------------------------------------------------------

class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker();

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final pulse = _controller.value;

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 28 + pulse * 38,
                height: 28 + pulse * 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(
                      0xFF4285F4,
                    ).withValues(alpha: 0.32 * (1 - pulse)),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4285F4).withValues(alpha: 0.16),
                  border: Border.all(
                    color: const Color(0xFF8BB8FF),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.38),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4285F4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// STATION MARKER
// -----------------------------------------------------------------------------

class _FuelStationMarker extends StatelessWidget {
  final bool e20Available;
  final String status;

  const _FuelStationMarker({required this.e20Available, required this.status});

  @override
  Widget build(BuildContext context) {
    final accent = e20Available ? const Color(0xFF19D3AE) : Colors.orangeAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xF2091118),
            border: Border.all(color: accent, width: 2),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.34), blurRadius: 15),
            ],
          ),
          child: Icon(Icons.local_gas_station_rounded, color: accent, size: 20),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xEE090F16),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            e20Available ? 'E20' : status.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ERROR
// -----------------------------------------------------------------------------

class _MapErrorBanner extends StatelessWidget {
  final String message;

  const _MapErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STATION DETAILS
// -----------------------------------------------------------------------------

class _StationDetailsSheet extends StatelessWidget {
  final FuelStation station;

  const _StationDetailsSheet({required this.station});

  @override
  Widget build(BuildContext context) {
    final accent = station.e20Available
        ? const Color(0xFF19D3AE)
        : Colors.orangeAccent;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              decoration: BoxDecoration(
                color: const Color(0xF2091118),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.10),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Icon(
                          Icons.local_gas_station_rounded,
                          color: accent,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              station.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              station.status,
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailMetric(
                          icon: Icons.eco_rounded,
                          label: 'Ethanol',
                          value: station.e20Available
                              ? 'E20 available'
                              : 'Unavailable',
                          accent: accent,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _DetailMetric(
                          icon: Icons.location_on_rounded,
                          label: 'Location',
                          value: 'Nearby',
                          accent: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _DetailMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
