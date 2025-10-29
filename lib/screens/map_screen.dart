import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/parking_spot.dart';
import '../services/location_service.dart';
import '../services/navigation_service.dart';

class MapScreen extends StatefulWidget {
  final ParkingSpot parkingSpot;

  const MapScreen({
    super.key,
    required this.parkingSpot,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  bool _isLoading = true;
  double? _distanceInMeters;
  MapType _currentMapType = MapType.normal;

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
    _initializeMap();
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue.withOpacity(0.5),
        strokeWidth: 2,
      ),
    );
  }

  Future<BitmapDescriptor> _getCarMarkerIcon() async {
    // You can customize this with a custom icon
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
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
      _updatePolyline();
    }, onError: (e) {
      print('Location stream error: $e');
    });
  }

  void _updatePolyline() {
    _polylines.clear();
    if (_currentPosition == null) return;
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('to_parking'),
        points: [
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude),
        ],
        width: 5,
        color: Colors.blueAccent.withOpacity(0.7),
      ),
    );
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
                const Icon(Icons.directions_car, size: 32, color: Colors.blue),
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
                          style: TextStyle(color: Colors.grey.shade600),
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
                color: Colors.orange,
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color ?? Colors.grey.shade700),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

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
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.parkingSpot.latitude,
                      widget.parkingSpot.longitude,
                    ),
                    zoom: 16.0,
                  ),
                  mapType: _currentMapType,
                  markers: _markers,
                  circles: _circles,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                      // Apply custom style
                      controller
                          .setMapStyle(isDark ? _mapStyleDark : _mapStyleLight);
                    }
                  },
                ),

                // Distance card at top
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.straighten,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                _formatDistance(_distanceInMeters!),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
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

                // Control buttons
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'parking',
                        mini: true,
                        backgroundColor: theme.colorScheme.primary,
                        onPressed: _centerOnParking,
                        child: const Icon(Icons.directions_car),
                      ),
                      const SizedBox(height: 8),
                      if (_currentPosition != null)
                        FloatingActionButton(
                          heroTag: 'location',
                          mini: true,
                          backgroundColor: theme.colorScheme.secondary,
                          onPressed: _centerOnCurrentLocation,
                          child: const Icon(Icons.my_location),
                        ),
                    ],
                  ),
                ),

                // Navigate button
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await NavigationService.instance.openNavigation(
                          widget.parkingSpot.latitude,
                          widget.parkingSpot.longitude,
                        );
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.navigation,
                                size: 28, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'START NAVIGATION',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
