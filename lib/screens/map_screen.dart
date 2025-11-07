import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/parking_spot.dart';
import '../services/location_service.dart';
import '../services/navigation_service.dart';
import '../services/google_maps_service.dart';
import '../services/nyc_parking_meter_service.dart';
import '../services/nyc_street_closures_service.dart';
import '../services/nyc_parking_signs_service.dart';
import '../services/nyc_street_resurfacing_service.dart'; // Added import for resurfacing

class MapScreen extends StatefulWidget {
  final ParkingSpot parkingSpot;

  const MapScreen({
    super.key,
    required this.parkingSpot,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  bool _isLoading = true;
  double? _distanceInMeters;
  MapType _currentMapType = MapType.normal;
  String? _routeDistanceText;
  String? _routeDurationText;

  // Animated menu state
  bool _menuExpanded = false;
  late AnimationController _menuAnimationController;
  late Animation<double> _menuAnimation;

  // Overlays
  bool _showMeters = false;
  bool _showClosures = false;
  final Set<Polyline> _closurePolylines = {};
  final Set<Marker> _closureMarkers = {};
  bool _showSigns = false;
  final Set<Marker> _signMarkers = {};
  bool _showResurfacing = false;
  final Set<Polyline> _resurfacingPolylines = {};

  // Navigation and route state
  bool _navigationMode = false;
  List<DirectionStep> _routeSteps = [];
  int _currentStepIndex = 0;
  final Set<Polyline> _routeStepHighlight = {};
  bool _honeInOnRoute = false;

  // Debug and loading states
  bool _isLoadingMeters = false;
  bool _isLoadingClosures = false;
  bool _isLoadingSigns = false;
  bool _isLoadingResurfacing = false;

  // Custom map style (dark mode optional)
  static const String _mapStyleLight = '''
  [
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    }
  ]
  ''';

  static const String _mapStyleDark = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#746855"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#d59563"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#263c3f"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#6b9a76"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#38414e"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#212a37"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#9ca5b3"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#746855"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#1f2835"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#f3d19c"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#17263c"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#515c6d"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#17263c"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    );
    _initializeMap();
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _menuExpanded = !_menuExpanded;
    });
    if (_menuExpanded) {
      _menuAnimationController.forward();
    } else {
      _menuAnimationController.reverse();
    }
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    try {
      // Get current position
      _currentPosition = await LocationService.instance.getCurrentLocation();

      // Calculate distance
      if (_currentPosition != null) {
        _distanceInMeters = LocationService.instance.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          widget.parkingSpot.latitude,
          widget.parkingSpot.longitude,
        );
      }

      // Create markers
      await _createMarkers();

      // Create circle around parking spot
      _createCircles();

      setState(() => _isLoading = false);

      // Animate to show both markers
      _animateToFitMarkers();

      // Start listening to live location updates
      _startPositionStream();
      if (_currentPosition != null) {
        await _loadDirections();
      }
    } catch (e) {
      print('Error initializing map: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createMarkers() async {
    _markers.clear();

    // Parking spot marker (car icon)
    _markers.add(
      Marker(
        markerId: const MarkerId('parking_spot'),
        position:
            LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude),
        icon: await _getCarMarkerIcon(),
        infoWindow: InfoWindow(
          title: '🚗 Your Car',
          snippet: widget.parkingSpot.address ?? 'Parking Location',
        ),
        onTap: () {
          _showParkingSpotDetails();
        },
      ),
    );

    // Current location marker (if available)
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: await _getCurrentLocationIcon(),
          infoWindow: const InfoWindow(
            title: '📍 You are here',
          ),
        ),
      );
    }
  }

  void _createCircles() {
    // Add a circle around the parking spot for visual reference
    _circles.add(
      Circle(
        circleId: const CircleId('parking_area'),
        center:
            LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude),
        radius: 50, // 50 meters
        fillColor: const Color(0xFF14b8a6).withOpacity(0.1),
        strokeColor: const Color(0xFF14b8a6).withOpacity(0.5),
        strokeWidth: 2,
      ),
    );
  }

  Future<BitmapDescriptor> _getCarMarkerIcon() async {
    // Create custom car marker with teal color matching theme
    const String carSvg = '''
    <svg width="40" height="40" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
      <g filter="url(#shadow)">
        <path d="M8 20 L32 20 L28 28 L12 28 Z" fill="#14b8a6" stroke="#0f172a" stroke-width="1"/>
        <circle cx="12" cy="30" r="3" fill="#94a3b8" stroke="#0f172a" stroke-width="1"/>
        <circle cx="28" cy="30" r="3" fill="#94a3b8" stroke="#0f172a" stroke-width="1"/>
        <rect x="14" y="16" width="12" height="4" fill="#f1f5f9" rx="1"/>
        <rect x="16" y="22" width="8" height="4" fill="#1e293b" rx="1"/>
        <circle cx="12" cy="20" r="1" fill="#0f172a"/>
        <circle cx="28" cy="20" r="1" fill="#0f172a"/>
      </g>
      <defs>
        <filter id="shadow" x="0" y="0" width="40" height="40">
          <feDropShadow dx="1" dy="1" stdDeviation="1" flood-color="#0f172a" flood-opacity="0.3"/>
        </filter>
      </defs>
    </svg>
    ''';
    return _svgToBitmapDescriptor(carSvg, size: 60);
  }

  Future<BitmapDescriptor> _getCurrentLocationIcon() async {
    // Create custom current location marker with pulsing animation effect
    const String locationSvg = '''
    <svg width="40" height="40" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
      <g filter="url(#locationShadow)">
        <!-- Outer ring -->
        <circle cx="20" cy="20" r="12" fill="none" stroke="#22c55e" stroke-width="2" opacity="0.6"/>
        <!-- Middle ring -->
        <circle cx="20" cy="20" r="8" fill="none" stroke="#22c55e" stroke-width="2" opacity="0.8"/>
        <!-- Inner dot -->
        <circle cx="20" cy="20" r="4" fill="#22c55e" stroke="#f1f5f9" stroke-width="2"/>
      </g>
      <defs>
        <filter id="locationShadow" x="0" y="0" width="40" height="40">
          <feDropShadow dx="1" dy="1" stdDeviation="1" flood-color="#0f172a" flood-opacity="0.4"/>
        </filter>
      </defs>
    </svg>
    ''';
    return _svgToBitmapDescriptor(locationSvg, size: 50);
  }

  Future<BitmapDescriptor> _svgToBitmapDescriptor(String svg,
      {required double size}) async {
    try {
      // For now, return a styled default marker with custom color
      // In a full implementation, you'd parse the SVG and draw it to canvas
      return BitmapDescriptor.defaultMarkerWithHue(svg.contains('car')
          ? BitmapDescriptor.hueCyan
          : BitmapDescriptor.hueGreen);
    } catch (e) {
      print('Error creating custom icon: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _animateToFitMarkers() async {
    if (!_controller.isCompleted) return;

    final controller = await _controller.future;

    if (_currentPosition != null) {
      // Fit both markers
      final bounds = _calculateBounds();
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100), // 100 padding
      );
    } else {
      // Just show parking spot
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
                widget.parkingSpot.latitude, widget.parkingSpot.longitude),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = LocationService.instance
        .getPositionStream(accuracy: LocationAccuracy.best)
        .listen((position) async {
      setState(() {
        _currentPosition = position;
        _distanceInMeters = LocationService.instance.calculateDistance(
          position.latitude,
          position.longitude,
          widget.parkingSpot.latitude,
          widget.parkingSpot.longitude,
        );
      });

      await _createMarkers();
      await _loadDirections();
      if (_showMeters) await _loadParkingMeters();
      if (_showClosures) await _loadStreetClosures();
      if (_showSigns) await _loadParkingSigns();
      if (_showResurfacing) await _loadResurfacing();

      // Update step focus while navigating
      if (_navigationMode && _routeSteps.isNotEmpty) {
        final idx = _findNearestStepIndex(
          LatLng(position.latitude, position.longitude),
        );
        if (idx != _currentStepIndex) {
          setState(() => _currentStepIndex = idx);
        }
        _updateCurrentStepHighlight();
        if (_honeInOnRoute) {
          await _focusOnCurrentStep();
        }
      }
    }, onError: (e) {
      print('Location stream error: $e');
    });
  }

  Future<void> _loadDirections() async {
    if (_currentPosition == null) return;
    final theme = Theme.of(context);
    final origin =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final dest =
        LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude);

    print('🧭 Loading real-time directions...');
    final directions =
        await GoogleMapsService.instance.getDirections(origin, dest);

    setState(() {
      _polylines.clear();
      _routeStepHighlight.clear();
      if (directions != null) {
        print('✅ Directions loaded: ${directions.steps.length} steps');

        // Overview route polyline with enhanced styling for navigation mode
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route_overview'),
            points: directions.points,
            width: 6,
            color: theme.colorScheme.primary.withOpacity(0.8),
            // Only add patterns in navigation mode
            patterns: <PatternItem>[
              PatternItem.dash(20),
              PatternItem.gap(10),
            ],
          ),
        );

        // Steps and meta with enhanced real-time tracking
        _routeSteps = directions.steps.map((step) {
          // Pre-calculate distance to start for real-time tracking
          if (_currentPosition != null) {
            // Calculate distance to step for real-time tracking (not stored)
            final distanceToStart = _distanceMeters(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              step.startLocation,
            );
          }
          return step;
        }).toList();

        _currentStepIndex = _findNearestStepIndex(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        );
        _routeDistanceText = directions.distanceText;
        _routeDurationText = directions.durationText;
        _updateCurrentStepHighlight();

        print(
            '🎯 Starting at step ${_currentStepIndex + 1}/${_routeSteps.length}');

        // Auto-focus on current step if in navigation mode
        if (_navigationMode && _honeInOnRoute) {
          _focusOnCurrentStep();
        }
      } else {
        _routeSteps = [];
        _currentStepIndex = 0;
        _routeDistanceText = null;
        _routeDurationText = null;
        print('❌ No directions available');
      }
    });
  }

  Future<void> _showNearbyParking() async {
    final base = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude);
    final places = await GoogleMapsService.instance.getNearbyParking(base);
    setState(() {
      _markers
          .removeWhere((m) => m.markerId.value.startsWith('nearby_parking_'));
      for (int i = 0; i < places.length; i++) {
        final p = places[i];
        _markers.add(
          Marker(
            markerId: MarkerId('nearby_parking_$i'),
            position: p.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: p.name,
              snippet: [
                if (p.vicinity != null) p.vicinity!,
                if (p.rating != null && p.userRatingsTotal != null)
                  '★ ${p.rating} (${p.userRatingsTotal})',
              ].where((e) => e.isNotEmpty).join(' • '),
            ),
          ),
        );
      }
    });
  }

  LatLngBounds _calculateBounds() {
    final parkingLatLng =
        LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude);
    final currentLatLng =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    final southwest = LatLng(
      parkingLatLng.latitude < currentLatLng.latitude
          ? parkingLatLng.latitude
          : currentLatLng.latitude,
      parkingLatLng.longitude < currentLatLng.longitude
          ? parkingLatLng.longitude
          : currentLatLng.longitude,
    );

    final northeast = LatLng(
      parkingLatLng.latitude > currentLatLng.latitude
          ? parkingLatLng.latitude
          : currentLatLng.latitude,
      parkingLatLng.longitude > currentLatLng.longitude
          ? parkingLatLng.longitude
          : currentLatLng.longitude,
    );

    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  void _showParkingSpotDetails() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car,
                    size: 32, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Parking Spot',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.parkingSpot.address != null)
                        Text(
                          widget.parkingSpot.address!,
                          style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_distanceInMeters != null) ...[
              _buildInfoRow(
                Icons.straighten,
                'Distance',
                _formatDistance(_distanceInMeters!),
              ),
              const Divider(),
            ],
            _buildInfoRow(
              Icons.access_time,
              'Saved',
              _formatTimeAgo(widget.parkingSpot.savedAt),
            ),
            if (widget.parkingSpot.alerts != null &&
                widget.parkingSpot.alerts!.isNotEmpty) ...[
              const Divider(),
              _buildInfoRow(
                Icons.warning_amber_rounded,
                'Alerts',
                '${widget.parkingSpot.alerts!.length} parking restriction(s)',
                color: theme.colorScheme.tertiary,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await NavigationService.instance.openNavigation(
                  widget.parkingSpot.latitude,
                  widget.parkingSpot.longitude,
                );
              },
              icon: const Icon(Icons.navigation),
              label: const Text('Start Navigation'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon,
              color: color ?? theme.colorScheme.onSurface.withOpacity(0.6),
              size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: color ?? theme.colorScheme.onSurface.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} meters';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  Future<void> _centerOnParking() async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target:
              LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude),
          zoom: 18.0,
        ),
      ),
    );
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_currentPosition == null) return;

    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 18.0,
        ),
      ),
    );
  }

  Future<void> _toggleMeters() async {
    setState(() {
      _showMeters = !_showMeters;
      if (!_showMeters) {
        _markers.removeWhere((m) => m.markerId.value.startsWith('meter_'));
      }
    });
    if (_showMeters) {
      await _loadParkingMeters();
    }
  }

  Future<void> _loadParkingMeters() async {
    setState(() => _isLoadingMeters = true);

    print('🔄 Loading NYC Parking Meters...');
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude);

    try {
      final meters = await NYCParkingMeterService.instance
          .getMetersNearby(center, radiusMeters: 600);

      print('📊 Meters API Response: ${meters.length} meters found');

      setState(() {
        _markers.removeWhere((m) => m.markerId.value.startsWith('meter_'));
        for (final meter in meters) {
          _markers.add(
            Marker(
              markerId: MarkerId(
                  'meter_${meter.meterId ?? "unknown"}_${meter.latitude}_${meter.longitude}'),
              position: LatLng(meter.latitude, meter.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueViolet),
              infoWindow: InfoWindow(
                title:
                    'Meter ${meter.meterId ?? ''} ${meter.status == null ? '' : '(${meter.status})'}',
                snippet:
                    '${meter.streetName ?? meter.locationDesc ?? ''}${meter.borough != null ? ', ${meter.borough}' : ''}',
              ),
            ),
          );
        }
      });
      print('✅ Meters loaded: ${meters.length} markers added');
    } catch (e) {
      print('❌ Error loading meters: $e');
    } finally {
      setState(() => _isLoadingMeters = false);
    }
  }

  Future<void> _toggleClosures() async {
    setState(() {
      _showClosures = !_showClosures;
      if (!_showClosures) {
        _closurePolylines.clear();
        _closureMarkers.clear();
      }
    });
    if (_showClosures) await _loadStreetClosures();
  }

  Future<void> _loadStreetClosures() async {
    setState(() => _isLoadingClosures = true);

    print('🔄 Loading NYC Street Closures...');
    final theme = Theme.of(context);
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude);

    try {
      final closures = await NYCDOTStreetClosuresService.instance
          .getClosuresNearby(center, radiusMeters: 1200);

      print('📊 Closures API Response: ${closures.length} closures found');

      setState(() {
        _closurePolylines.clear();
        _closureMarkers.clear();
        for (int i = 0; i < closures.length; i++) {
          final c = closures[i];
          if (c.geometry.length > 1) {
            _closurePolylines.add(
              Polyline(
                polylineId: PolylineId('closure_$i'),
                points: c.geometry,
                width: 8,
                color: theme.colorScheme.tertiary,
              ),
            );
            // Info marker at midpoint
            final mid = c.geometry[(c.geometry.length / 2).floor()];
            _closureMarkers.add(
              Marker(
                markerId: MarkerId('closure_marker_$i'),
                position: mid,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange),
                infoWindow: InfoWindow(
                  title: c.reason ?? 'Street Closure',
                  snippet:
                      '${c.closureType ?? ''} - ${c.borough ?? ''}\n${c.streetA ?? ''}${c.streetB != null ? ' & ${c.streetB}' : ''}\n${c.startDate != null ? c.startDate.toString().split('T').first : ''} - ${c.endDate != null ? c.endDate.toString().split('T').first : ''}',
                ),
              ),
            );
          } else if (c.geometry.length == 1) {
            final point = c.geometry.first;
            _closureMarkers.add(
              Marker(
                markerId: MarkerId('closure_marker_$i'),
                position: point,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange),
                infoWindow: InfoWindow(
                  title: c.reason ?? 'Street Closure',
                  snippet:
                      '${c.closureType ?? ''} - ${c.borough ?? ''}\n${c.streetA ?? ''}${c.streetB != null ? ' & ${c.streetB}' : ''}\n${c.startDate != null ? c.startDate.toString().split('T').first : ''} - ${c.endDate != null ? c.endDate.toString().split('T').first : ''}',
                ),
              ),
            );
          }
        }
      });
      print(
          '✅ Closures loaded: ${closures.length} polylines, ${_closureMarkers.length} markers');
    } catch (e) {
      print('❌ Error loading closures: $e');
    } finally {
      setState(() => _isLoadingClosures = false);
    }
  }

  Future<void> _toggleSigns() async {
    setState(() {
      _showSigns = !_showSigns;
      if (!_showSigns) {
        _signMarkers.clear();
      }
    });
    if (_showSigns) await _loadParkingSigns();
  }

  Future<void> _loadParkingSigns() async {
    setState(() => _isLoadingSigns = true);

    print('🔄 Loading NYC Parking Signs...');
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude);

    try {
      final signs = await NYCParkingRegulationSignsService.instance
          .getSignsNearby(center);

      print('📊 Signs API Response: ${signs.length} signs found');

      setState(() {
        _signMarkers.clear();
        for (int i = 0; i < signs.length; i++) {
          final s = signs[i];
          if (s.position != null) {
            final markerHue = HSVColor.fromColor(s.markerColor).hue;
            _signMarkers.add(
              Marker(
                markerId: MarkerId('sign_$i'),
                position: s.position!,
                icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
                infoWindow: InfoWindow(
                  title: '${s.ruleEmoji} ${s.mainRule ?? 'Parking Regulation'}',
                  snippet: [
                    if (s.signDescription != null) s.signDescription!,
                    if (s.hours != null) s.hours!,
                    if (s.fromStreet != null || s.toStreet != null)
                      '${s.fromStreet ?? ''} to ${s.toStreet ?? ''}',
                    if (s.sideOfStreet != null) '${s.sideOfStreet}',
                    if (s.borough != null) s.borough!,
                  ].where((e) => e.isNotEmpty).join('\n'),
                ),
              ),
            );
          }
        }
      });
      print('✅ Signs loaded: ${_signMarkers.length} markers added');
    } catch (e) {
      print('❌ Error loading signs: $e');
    } finally {
      setState(() => _isLoadingSigns = false);
    }
  }

  Future<void> _loadResurfacing() async {
    setState(() => _isLoadingResurfacing = true);

    print('🔄 Loading NYC Street Resurfacing...');
    final theme = Theme.of(context);
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude);

    try {
      final resurfacings = await NYCDOTStreetResurfacingService.instance
          .getResurfacingNearby(center, radiusMeters: 1400);

      print(
          '📊 Resurfacing API Response: ${resurfacings.length} resurfacing projects found');

      setState(() {
        _resurfacingPolylines.clear();
        for (int i = 0; i < resurfacings.length; i++) {
          final surf = resurfacings[i];
          if (surf.geometry.isNotEmpty) {
            _resurfacingPolylines.add(
              Polyline(
                polylineId: PolylineId('resurfacing_$i'),
                points: surf.geometry,
                width: 7,
                color: theme.colorScheme.tertiary.withOpacity(0.7),
              ),
            );
          }
        }
      });
      print('✅ Resurfacing loaded: ${resurfacings.length} polylines added');
    } catch (e) {
      print('❌ Error loading resurfacing: $e');
    } finally {
      setState(() => _isLoadingResurfacing = false);
    }
  }

  // Menu item data
  List<MenuItem> get _menuItems => [
        MenuItem(
          icon: Icons.local_parking_outlined,
          label: 'Meters',
          isEnabled: _showMeters,
          isLoading: _isLoadingMeters,
          onTap: _toggleMeters,
        ),
        MenuItem(
          icon: Icons.block,
          label: 'Closures',
          isEnabled: _showClosures,
          isLoading: _isLoadingClosures,
          onTap: _toggleClosures,
        ),
        MenuItem(
          icon: Icons.rule,
          label: 'Signs',
          isEnabled: _showSigns,
          isLoading: _isLoadingSigns,
          onTap: _toggleSigns,
        ),
        MenuItem(
          icon: Icons.construction,
          label: 'Resurfacing',
          isEnabled: _showResurfacing,
          isLoading: _isLoadingResurfacing,
          onTap: () async {
            setState(() {
              _showResurfacing = !_showResurfacing;
              if (!_showResurfacing) {
                _resurfacingPolylines.clear();
              }
            });
            if (_showResurfacing) await _loadResurfacing();
          },
        ),
      ];

  Widget _buildAnimatedMenu() {
    final theme = Theme.of(context);
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expanded menu items
          AnimatedBuilder(
            animation: _menuAnimation,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_menuItems.length, (index) {
                  final item = _menuItems[index];
                  return Transform.scale(
                    scale: _menuAnimation.value,
                    child: Opacity(
                      opacity: _menuAnimation.value,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _buildMenuItem(item, theme),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          // Main menu toggle button
          FloatingActionButton(
            heroTag: 'overlay_menu',
            backgroundColor: _menuExpanded
                ? theme.colorScheme.secondary
                : theme.colorScheme.primary,
            onPressed: _toggleMenu,
            child: AnimatedRotation(
              turns: _menuExpanded ? 0.125 : 0.0, // 45 degree rotation
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _menuExpanded ? Icons.close : Icons.layers,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item, ThemeData theme) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: item.isEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    item.isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              )
            else
              Icon(
                item.icon,
                color: item.isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            const SizedBox(width: 16),
            Text(
              item.label,
              style: TextStyle(
                color: item.isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: item.isEnabled ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _focusOnRoute() async {
    if (_polylines.isNotEmpty) {
      final points = _polylines.first.points;
      if (_controller.isCompleted && points.isNotEmpty) {
        final controller = await _controller.future;
        LatLngBounds bounds = _calculateBoundsForPoints(points);
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      }
    }
  }

  LatLngBounds _calculateBoundsForPoints(List<LatLng> pts) {
    double? north, south, east, west;
    for (final p in pts) {
      if (north == null || p.latitude > north) north = p.latitude;
      if (south == null || p.latitude < south) south = p.latitude;
      if (east == null || p.longitude > east) east = p.longitude;
      if (west == null || p.longitude < west) west = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(south!, west!),
      northeast: LatLng(north!, east!),
    );
  }

  int _findNearestStepIndex(LatLng current) {
    if (_routeSteps.isEmpty) return 0;
    double best = double.infinity;
    int bestIdx = 0;
    for (int i = 0; i < _routeSteps.length; i++) {
      final step = _routeSteps[i];
      final d = _minDistanceToStep(current, step);
      if (d < best) {
        best = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  double _minDistanceToStep(LatLng p, DirectionStep s) {
    double d = _distanceMeters(p, s.startLocation);
    d = math.min(d, _distanceMeters(p, s.endLocation));
    final pts = s.points;
    if (pts.isNotEmpty) {
      final stride = math.max(1, (pts.length / 10).floor());
      for (int i = 0; i < pts.length; i += stride) {
        d = math.min(d, _distanceMeters(p, pts[i]));
      }
    }
    return d;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const double R = 6371000; // meters
    final double dLat = _deg2rad(b.latitude - a.latitude);
    final double dLon = _deg2rad(b.longitude - a.longitude);
    final double lat1 = _deg2rad(a.latitude);
    final double lat2 = _deg2rad(b.latitude);
    final double h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return R * c;
  }

  double _deg2rad(double deg) => deg * math.pi / 180.0;

  void _updateCurrentStepHighlight() {
    final theme = Theme.of(context);
    _routeStepHighlight.clear();
    if (_routeSteps.isEmpty) return;
    final idx = _currentStepIndex.clamp(0, _routeSteps.length - 1);
    final step = _routeSteps[idx];
    final pts = step.points.isNotEmpty
        ? step.points
        : <LatLng>[step.startLocation, step.endLocation];
    _routeStepHighlight.add(
      Polyline(
        polylineId: const PolylineId('route_step_highlight'),
        points: pts,
        width: 10,
        color: theme.colorScheme.error,
      ),
    );
    setState(() {});
  }

  Future<void> _focusOnCurrentStep() async {
    if (!_controller.isCompleted || _routeSteps.isEmpty) return;
    final controller = await _controller.future;
    final idx = _currentStepIndex.clamp(0, _routeSteps.length - 1);
    final step = _routeSteps[idx];
    final pts = step.points.isNotEmpty
        ? step.points
        : <LatLng>[step.startLocation, step.endLocation];
    if (pts.length >= 2) {
      final bounds = _calculateBoundsForPoints(pts);
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } else if (pts.isNotEmpty) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: pts.first, zoom: 18.0),
        ),
      );
    }
  }

  void _gotoStep(int idx) {
    if (_routeSteps.isEmpty) return;
    final clamped = idx.clamp(0, _routeSteps.length - 1);
    setState(() => _currentStepIndex = clamped);
    _updateCurrentStepHighlight();
    _focusOnCurrentStep();
  }

  void _nextStep() => _gotoStep(_currentStepIndex + 1);
  void _prevStep() => _gotoStep(_currentStepIndex - 1);

  Widget _buildStepHud(ThemeData theme) {
    if (_routeSteps.isEmpty) return const SizedBox.shrink();
    final step = _routeSteps[_currentStepIndex];
    final isDark = theme.brightness == Brightness.dark;

    // Determine step status for visual indicators
    final isCompleted = _currentStepIndex > 0;
    final isCurrent = true;
    final isNext = _currentStepIndex < _routeSteps.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        children: [
          // Step progress indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.1),
              border: Border.all(
                color: isCompleted
                    ? theme.colorScheme.primary
                    : isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check,
                      size: 16, color: theme.colorScheme.primary)
                  : Text(
                      '${_currentStepIndex + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrent
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction.isEmpty ? 'Follow route' : step.instruction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.straighten,
                        size: 14, color: theme.colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      step.distanceText.isEmpty ? '' : step.distanceText,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (step.distanceText.isNotEmpty &&
                        step.durationText.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (step.durationText.isNotEmpty) ...[
                      Icon(Icons.schedule,
                          size: 12, color: theme.colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        step.durationText,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Navigation controls
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.keyboard_arrow_up, size: 20),
                color: _currentStepIndex > 0
                    ? theme.colorScheme.primary
                    : Colors.grey,
                onPressed: _currentStepIndex > 0 ? _prevStep : null,
                tooltip: 'Previous step',
                iconSize: 20,
              ),
              IconButton(
                icon: Icon(Icons.keyboard_arrow_down, size: 20),
                color: _currentStepIndex < _routeSteps.length - 1
                    ? theme.colorScheme.primary
                    : Colors.grey,
                onPressed: _currentStepIndex < _routeSteps.length - 1
                    ? _nextStep
                    : null,
                tooltip: 'Next step',
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Navigation mode: just current location, car, and route polyline
    final navMarkers = _markers
        .where((m) =>
            m.markerId.value == 'parking_spot' ||
            m.markerId.value == 'current_location')
        .toSet();

    final allOverlayMarkers = _markers
        .union(_showMeters
            ? _markers
                .where((m) => m.markerId.value.startsWith('meter_'))
                .toSet()
            : <Marker>{})
        .union(_showClosures ? _closureMarkers : <Marker>{})
        .union(_showSigns ? _signMarkers : <Marker>{});
    final markersToShow = _navigationMode ? navMarkers : allOverlayMarkers;

    final allOverlayPolylines = _polylines
        .union(_routeStepHighlight)
        .union(_showClosures ? _closurePolylines : <Polyline>{})
        .union(_showResurfacing ? _resurfacingPolylines : <Polyline>{});
    final polylinesToShow = _navigationMode
        ? (_polylines.isNotEmpty
            ? {_polylines.first}.union(_routeStepHighlight)
            : _routeStepHighlight)
        : allOverlayPolylines;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Parking Location'),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(_currentMapType == MapType.normal
                ? Icons.satellite
                : Icons.map),
            onPressed: _toggleMapType,
            tooltip: 'Toggle map type',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.parkingSpot.latitude,
                      widget.parkingSpot.longitude,
                    ),
                    zoom: 16.0,
                  ),
                  mapType: _currentMapType,
                  markers: markersToShow,
                  circles: _circles,
                  polylines: polylinesToShow,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                      controller
                          .setMapStyle(isDark ? _mapStyleDark : _mapStyleLight);
                    }
                  },
                ),

                // Distance/ETA card at top
                if (_distanceInMeters != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.straighten,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 16),
                              Text(
                                _routeDistanceText ??
                                    _formatDistance(_distanceInMeters!),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (_routeDurationText != null) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.schedule,
                                    color: theme.colorScheme.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  _routeDurationText!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.75),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'to your car',
                            style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Step HUD (detailed directions)
                if (_navigationMode && _routeSteps.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 80,
                    child: _buildStepHud(theme),
                  ),

                // Location controls - Bottom left
                Positioned(
                  left: 16,
                  bottom: 100,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'parking',
                        mini: true,
                        backgroundColor: theme.colorScheme.primary,
                        onPressed: _centerOnParking,
                        tooltip: 'Center on parking spot',
                        child: const Icon(Icons.directions_car),
                      ),
                      const SizedBox(height: 8),
                      if (_currentPosition != null)
                        FloatingActionButton(
                          heroTag: 'location',
                          mini: true,
                          backgroundColor: theme.colorScheme.secondary,
                          onPressed: _centerOnCurrentLocation,
                          tooltip: 'Center on current location',
                          child: const Icon(Icons.my_location),
                        ),
                    ],
                  ),
                ),

                // Animated overlay menu - Bottom right
                _buildAnimatedMenu(),

                // Navigate button
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          _navigationMode = true;
                          _honeInOnRoute = true;
                        });
                        await _loadDirections();
                        await _focusOnCurrentStep();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.secondary,
                              theme.colorScheme.secondary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  theme.colorScheme.secondary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.navigation,
                                size: 28, color: theme.colorScheme.onSecondary),
                            const SizedBox(width: 12),
                            Text(
                              'START NAVIGATION',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondary,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Navigation exit button
                if (_navigationMode)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: FloatingActionButton(
                      heroTag: 'exit_navigation',
                      backgroundColor: theme.colorScheme.error,
                      onPressed: () => setState(() => _navigationMode = false),
                      child:
                          Icon(Icons.close, color: theme.colorScheme.onError),
                      tooltip: 'Exit Navigation',
                    ),
                  )
              ],
            ),
    );
  }
}

// Menu item model
class MenuItem {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onTap;

  const MenuItem({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.isLoading,
    required this.onTap,
  });
}
