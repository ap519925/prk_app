import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/parking_spot.dart';
import '../services/location_service.dart';
import '../services/directions_service.dart';

class NavigationScreen extends StatefulWidget {
  final ParkingSpot parkingSpot;

  const NavigationScreen({
    super.key,
    required this.parkingSpot,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  DirectionsRoute? _route;
  DirectionsStep? _currentStep;
  int _currentStepIndex = 0;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _hasArrived = false;
  double _remainingDistance = 0;
  int _remainingDuration = 0;

  FlutterTts? _flutterTts;
  bool _voiceEnabled = true;
  String? _lastSpokenInstruction;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts?.setLanguage('en-US');
    await _flutterTts?.setSpeechRate(0.5);
    await _flutterTts?.setVolume(1.0);
    await _flutterTts?.setPitch(1.0);
  }

  Future<void> _initializeNavigation() async {
    setState(() => _isLoading = true);

    try {
      // Get current position
      _currentPosition = await LocationService.instance.getCurrentLocation();

      if (_currentPosition == null) {
        if (mounted) {
          _showError('Unable to get your location');
        }
        return;
      }

      // Fetch directions
      final origin = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      final destination = LatLng(
        widget.parkingSpot.latitude,
        widget.parkingSpot.longitude,
      );

      _route = await DirectionsService.instance.getDirections(
        origin: origin,
        destination: destination,
      );

      if (_route == null) {
        if (mounted) {
          _showError('Unable to get directions');
        }
        return;
      }

      // Set up markers and polyline
      _createMarkers();
      _createPolyline();

      // Get first step
      if (_route!.steps.isNotEmpty) {
        _currentStep = _route!.steps[0];
        _currentStepIndex = 0;
        _speakInstruction(_currentStep!.cleanInstruction);
      }

      _remainingDistance = _route!.totalDistanceValue;
      _remainingDuration = _route!.totalDurationValue;

      setState(() => _isLoading = false);

      // Animate camera to show route
      _animateToRoute();

      // Start tracking location
      _startLocationTracking();
    } catch (e) {
      print('Error initializing navigation: $e');
      if (mounted) {
        _showError('Error starting navigation: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  void _createMarkers() {
    _markers.clear();

    // Destination marker (car)
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(
          widget.parkingSpot.latitude,
          widget.parkingSpot.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Your Car'),
      ),
    );

    // Current location marker
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You are here'),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
  }

  void _createPolyline() {
    _polylines.clear();

    if (_route != null && _route!.polylinePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _route!.polylinePoints,
          color: const Color(0xFF3B82F6), // Blue color matching app theme
          width: 6,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }
  }

  Future<void> _animateToRoute() async {
    if (!_controller.isCompleted || _route == null) return;

    final controller = await _controller.future;

    if (_currentPosition != null) {
      final bounds = _calculateBounds(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(widget.parkingSpot.latitude, widget.parkingSpot.longitude),
      );

      controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  LatLngBounds _calculateBounds(LatLng point1, LatLng point2) {
    final southwest = LatLng(
      point1.latitude < point2.latitude ? point1.latitude : point2.latitude,
      point1.longitude < point2.longitude ? point1.longitude : point2.longitude,
    );

    final northeast = LatLng(
      point1.latitude > point2.latitude ? point1.latitude : point2.latitude,
      point1.longitude > point2.longitude ? point1.longitude : point2.longitude,
    );

    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  void _startLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = LocationService.instance
        .getPositionStream(accuracy: LocationAccuracy.bestForNavigation)
        .listen((position) {
      _updatePosition(position);
    }, onError: (e) {
      print('Location tracking error: $e');
    });
  }

  void _updatePosition(Position position) {
    setState(() {
      _currentPosition = position;
    });

    final currentLatLng = LatLng(position.latitude, position.longitude);

    // Update markers
    _createMarkers();

    // Check if arrived
    final distanceToDestination = LocationService.instance.calculateDistance(
      position.latitude,
      position.longitude,
      widget.parkingSpot.latitude,
      widget.parkingSpot.longitude,
    );

    if (distanceToDestination < 20 && !_hasArrived) {
      // Within 20 meters
      _hasArrived = true;
      _speakInstruction('You have arrived at your destination');
      _showArrivalDialog();
      return;
    }

    // Update current step
    if (_route != null && _route!.steps.isNotEmpty) {
      _updateCurrentStep(currentLatLng);
    }

    // Update remaining distance and duration
    if (_route != null) {
      _remainingDistance = DirectionsService.instance.calculateRemainingDistance(
        currentLatLng,
        _route!,
      );

      // Estimate remaining duration based on distance (assume 40 km/h)
      _remainingDuration = (_remainingDistance / 40000 * 3600).round();
    }

    // Keep camera following user
    _updateCamera(currentLatLng);
  }

  void _updateCurrentStep(LatLng currentPosition) {
    if (_currentStepIndex >= _route!.steps.length) return;

    final currentStep = _route!.steps[_currentStepIndex];
    final distanceToStepEnd = _calculateDistance(
      currentPosition,
      currentStep.endLocation,
    );

    // If close to end of current step, move to next step
    if (distanceToStepEnd < 30 && _currentStepIndex < _route!.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _currentStep = _route!.steps[_currentStepIndex];
      });
      _speakInstruction(_currentStep!.cleanInstruction);
    } else {
      setState(() {
        _currentStep = currentStep;
      });
    }
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371000;
    final dLat = _degreesToRadians(to.latitude - from.latitude);
    final dLon = _degreesToRadians(to.longitude - from.longitude);

    final a = (dLat / 2 * dLat / 2).toDouble() +
        _degreesToRadians(from.latitude).cosApprox() *
            _degreesToRadians(to.latitude).cosApprox() *
            (dLon / 2 * dLon / 2);

    final c = 2 * (a < 0.5 ? a.squareRoot() : (1 - a).squareRoot().asinApprox());
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 3.14159265359 / 180;
  }

  Future<void> _updateCamera(LatLng position) async {
    if (!_controller.isCompleted) return;

    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 17.0,
          tilt: 45.0,
          bearing: _currentPosition?.heading ?? 0,
        ),
      ),
    );
  }

  Future<void> _speakInstruction(String instruction) async {
    if (!_voiceEnabled || _flutterTts == null) return;
    if (_lastSpokenInstruction == instruction) return;

    _lastSpokenInstruction = instruction;
    await _flutterTts?.speak(instruction);
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Arrived!'),
          ],
        ),
        content: const Text(
          'You have arrived at your parking spot!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '$hours h $remainingMinutes min';
    }
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'merge':
        return Icons.merge;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      case 'fork-left':
      case 'fork-right':
        return Icons.fork_left;
      case 'ramp-left':
      case 'ramp-right':
        return Icons.ramp_left;
      default:
        return Icons.straight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition?.latitude ?? widget.parkingSpot.latitude,
                      _currentPosition?.longitude ?? widget.parkingSpot.longitude,
                    ),
                    zoom: 16.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                    }
                  },
                ),

                // Navigation instruction panel
                if (_currentStep != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getManeuverIcon(_currentStep!.maneuver),
                                  size: 32,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentStep!.cleanInstruction,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentStep!.distance,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Distance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    _formatDistance(_remainingDistance),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ETA',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_remainingDuration),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Control buttons
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),

                // Voice toggle button
                Positioned(
                  bottom: 32,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'voice',
                    backgroundColor: theme.colorScheme.secondary,
                    onPressed: () {
                      setState(() {
                        _voiceEnabled = !_voiceEnabled;
                      });
                      if (_voiceEnabled && _currentStep != null) {
                        _speakInstruction(_currentStep!.cleanInstruction);
                      }
                    },
                    child: Icon(
                      _voiceEnabled ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Recenter button
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    heroTag: 'recenter',
                    backgroundColor: theme.colorScheme.primary,
                    onPressed: () {
                      if (_currentPosition != null) {
                        _updateCamera(LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ));
                      }
                    },
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _flutterTts?.stop();
    super.dispose();
  }
}

// Helper extensions
extension on double {
  double squareRoot() {
    if (this < 0) return double.nan;
    if (this == 0) return 0;
    double x = this;
    double last;
    do {
      last = x;
      x = (x + this / x) / 2;
    } while ((x - last).abs() > 0.000001);
    return x;
  }

  double asinApprox() {
    if (this < -1 || this > 1) return double.nan;
    return this + (this * this * this) / 6;
  }

  double cosApprox() {
    final x = this % (2 * 3.14159265359);
    return 1 - (x * x) / 2 + (x * x * x * x) / 24;
  }
}
